package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.making.MakingInfo;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.making.RecipeComponent;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingMakeKnownVO;
	import com.tinyspeck.engine.net.NetOutgoingMakeUnknownVO;
	import com.tinyspeck.engine.net.NetOutgoingRecipeRequestVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;

	public class MakingManager
	{
		/* singleton boilerplate */
		public static const instance:MakingManager = new MakingManager();
		
		private var api_call:APICall = new APICall();
		private var model:TSModelLocator;
		private var _making_info:MakingInfo;
		
		private var current_recipe_id:String;
		private var current_amount:int;
		
		private var skill_tsids:Array = new Array();
		
		private var complete_func:Function;
		private var loading_skill:Boolean;
		
		public function MakingManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			api_call.addEventListener(TSEvent.COMPLETE, onAPIComplete, false, 0, true);
			//api_call.trace_output = true;
		}
		
		public function start(payload:Object):void {
			//check to see we can load in this new info
			if(MakingDialog.instance.visible && !MakingDialog.instance.canContinue()){
				model.activityModel.activity_message = Activity.createFromCurrentPlayer('Hold on bucko! Let\'s finish one thing at a time.');
				
				//show the toast with the message
				MakingDialog.instance.showToast('Hold on bucko! Let\'s finish one thing at a time.');
				return;
			}
			
			_making_info = MakingInfo.fromAnonymous(payload, payload.item_tsid);
			
			//let the world model know of any new recipes we may have
			var i:int;
			var recipe:Recipe;
			var old_recipe:Recipe;
			var index:int;
			
			for(i; i < making_info.knowns.length; i++){
				recipe = making_info.knowns[int(i)];
				old_recipe = model.worldModel.getRecipeById(recipe.id);
				
				//find and remove the old recipe
				if(old_recipe){
					index = model.worldModel.recipes.indexOf(old_recipe);
					model.worldModel.recipes.splice(index, 1);
				}
				
				//add it to the world
				model.worldModel.recipes.push(recipe);
			}
			
			//open up the dialog!
			MakingDialog.instance.start();
		}
		
		public function isRecipeMakeable(recipe:Recipe):Boolean {
			var i:int;
			var component:RecipeComponent;
			var has_amount:int;
			
			for(i; i < recipe.inputs.length; i++){
				component = recipe.inputs[int(i)];
				
				if(component.item_class != 'fuel_cell'){
					has_amount = model.worldModel.pc.hasHowManyItems(component.item_class, component.consumable);
				}
				else {
					has_amount = MakingManager.instance.making_info.fuel_remaining;
				}
				
				if(has_amount < component.count) return false;
			}
			
			return true;
		}
		
		public function isRecipeInKnowns(recipe_id:String):Boolean {
			var i:int;
			var recipe:Recipe;
			
			for(i; i < making_info.knowns.length; i++){
				recipe = making_info.knowns[int(i)];
				if(recipe.id == recipe_id) return true;
			}
			
			return false;
		}
		
		public function makeKnownRecipe(recipe_id:String, amount:int = 1):void {
			//get the recipe
			var recipe:Recipe = model.worldModel.getRecipeById(recipe_id);
			var itemstack_tsid:String;
			
			if(recipe){
				if(!making_info.no_modal || recipe.tool != making_info.item_class){
					//find a working itemstack
					itemstack_tsid = model.worldModel.pc.getItemstackOfWorkingTool(recipe.tool);
				}
				//get the tsid from the making info
				else {
					itemstack_tsid = making_info.item_tsid;
				}
				
				//got one?! Good, fire it off to the server
				if(itemstack_tsid){
					TSFrontController.instance.genericSend(
						new NetOutgoingMakeKnownVO(
							itemstack_tsid,
							recipe.tool_verb,
							amount,
							recipe_id
						), 
						makeKnownRecipeResponse, 
						makeKnownRecipeResponse
					);
					
					//hold a reference to this so the waiting animation knows what to do
					current_recipe_id = recipe_id;
					current_amount = amount;
				}
				else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('Could not find an itemstack to make this!');
					}
				}
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Could not find a recipe with that id: '+recipe_id);
				}
			}
		}
		
		private function makeKnownRecipeResponse(nrm:NetResponseMessageVO):void {
			if(!nrm.success){
				//show the toast with the error
				MakingDialog.instance.showToast(nrm.payload.error.msg);
				model.activityModel.activity_message = Activity.createFromCurrentPlayer(nrm.payload.error.msg);
			}
			else {
				var recipe:Recipe = model.worldModel.getRecipeById(current_recipe_id);
				
				if(recipe){
					//throw up the waiting animation
					if(!making_info.no_modal || recipe.tool != making_info.item_class){ 
						MakingDialog.instance.animateTool(recipe.tool, int(nrm.payload.wait), current_amount, true);
					}
					//if we are doing something that wants to dismiss the window, make sure we do that
					else {
						MakingDialog.instance.end(true);
					}
				}
			}
		}
		
		public function makeUnknownRecipe(inputs:Array):void {
			if(!inputs || (inputs && !inputs.length)) return;
			
			//find a test tube
			var test_tube_tsid:String;
			var itemstack:Itemstack;
			var i:int;
			var itemstack_tsids:Array = model.worldModel.pc.tsidsOfAllStacksOfItemClass('test_tube');
			
			for(i; i < itemstack_tsids.length; i++){
				itemstack = model.worldModel.getItemstackByTsid(itemstack_tsids[int(i)]);
				if(itemstack && !itemstack.tool_state.is_broken){
					test_tube_tsid = itemstack.tsid;
					break;
				}
			}
			
			if(test_tube_tsid){
				TSFrontController.instance.genericSend(
					new NetOutgoingMakeUnknownVO(
						test_tube_tsid,
						'experiment',
						inputs
					), 
					makeUnknownRecipeResponse, 
					makeUnknownRecipeResponse
				);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Could not find a working test tube.');
				}
			}
		}
		
		private function makeUnknownRecipeResponse(nrm:NetResponseMessageVO):void {
			if(!nrm.success){
				//show the toast with the error
				MakingDialog.instance.showToast(nrm.payload.error.msg);
				model.activityModel.activity_message = Activity.createFromCurrentPlayer(nrm.payload.error.msg);
			}
			else {
				//throw up the waiting animation
				if(!making_info.no_modal){ 
					MakingDialog.instance.animateTool('test_tube', int(nrm.payload.wait), 1, false);
				}
				//if we are doing something that wants to dismiss the window, make sure we do that
				else {
					MakingDialog.instance.end(true);
				}
			}
		}
		
		public function makeRecipeComplete(payload:Object, is_known:Boolean = true):void {
			//what did we get?!
			var rewards:Vector.<Reward> = Rewards.fromAnonymous(payload.effects);
			
			//force a refresh of our recipes
			MakingDialog.instance.onPackChange();
			
			//let the dialog know what's up
			MakingDialog.instance.showComplete(
				is_known ? current_recipe_id : payload.learned, 
				is_known ? current_amount : 1, 
				rewards,
				is_known,
				payload.over_xp_limit,
				is_known ? '' : payload.msg
			);
		}
		
		public function makeRecipeFailed(payload:Object):void {
			if(!payload.error.msg) payload.error.msg = '<span class="making_error">That recipe didn\'t make anything!</span>';
			
			MakingDialog.instance.showError(payload.error.msg);
		}
		
		public function recipeRequest(class_tsids:Array, completeFunction:Function):void {
			TSFrontController.instance.genericSend(new NetOutgoingRecipeRequestVO(class_tsids), completeFunction, completeFunction);
		}
		
		public function toolInfoRequest(tool_tsids:Array, completeFunction:Function):void {
			complete_func = completeFunction;
			api_call.itemsInfo(tool_tsids);
		}
		
		public function skillInfoRequest(skill_tsids:Array, completeFunction:Function):void {
			var i:int;
			
			complete_func = completeFunction;
			loading_skill = true;
			
			for(i; i < skill_tsids.length; i++){
				if(this.skill_tsids.indexOf(skill_tsids[int(i)]) == -1){
					this.skill_tsids.push(skill_tsids[int(i)]);
				}
			}
			
			if(!api_call.loading) api_call.skillsInfo(this.skill_tsids[0]);
		}
		
		private function onAPIComplete(event:TSEvent):void {
			if(!loading_skill){
				complete_func();
			}
			//is the skill array empty now?
			else {
				skill_tsids.shift();
				if(skill_tsids.length){
					api_call.skillsInfo(skill_tsids[0]);
				}
				else {
					loading_skill = false;
					complete_func();
				}
			}
		}
		
		public function get making_info():MakingInfo { return _making_info; }
	}
}