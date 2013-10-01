package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.garden.Garden;
	import com.tinyspeck.engine.data.garden.GardenAction;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingGardenActionVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.garden.GardenSWFData;
	import com.tinyspeck.engine.view.ui.garden.GardenView;
	
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;

	public class GardenManager
	{
		/* singleton boilerplate */
		public static const instance:GardenManager = new GardenManager();
		
		public static const GARDEN_CLASS_TSID:String = 'garden_new';
		public static const WATER_TOOLS:Array = ['watering_can', 'irrigator_9000'];
		public static const HOE_TOOLS:Array = ['hoe', 'high_class_hoe'];
		public static const FERTILIZER:Array = ['guano'];
		public static const FERTILIZE_PERC:Number = .8; //how much % water needs to be on the plot before you can fertilize
		public static const REMOVE_ITEMS:Array = ['wine_of_the_dead']; //these items have the power to remove the garden
		
		public var current_plot_id:int;
		public var is_tending:Boolean;
		
		private var model:TSModelLocator;
		private var garden_tsids:Array;
		private var actions_locked:Boolean;
		private var tending_tsid:String;
		private var last_action:String;
		
		public function GardenManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			model = TSModelLocator.instance;
		}
		
		public function add(tsids:Array):void {
			update(tsids);
		}
		
		public function update(tsids:Array):void {
			if(!tsids) return;
			
			var i:int;
			var tsid:String;
			var itemstack:Itemstack;
			var garden:Garden;
			
			for(i; i < tsids.length; i++){
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if(itemstack && itemstack.class_tsid == GARDEN_CLASS_TSID){					
					garden = buildGardenHash(tsid);
					
					//make sure we have the garden assets loaded first
					if(GardenSWFData.garden_mc){
						buildGarden(garden);
					}
					//no? go get the swf version so we can yank assets from it
					else {
						//push them into the queue
						if(!garden_tsids){
							garden_tsids = new Array();
							
							var item:Item = model.worldModel.getItemByTsid(GARDEN_CLASS_TSID);
							TSFrontController.instance.loadItemstackSWF(item.tsid, item.asset_swf_v, onSWFLoad, onSWFError);
						} 
						
						if(garden_tsids.indexOf(tsid) == -1) garden_tsids.push(tsid);
					}
				}
			}
		}
		
		public function remove(tsids:Array):void {
			if(!tsids) return;
		}
		
		public function sendAction(itemstack_tsid:String, plot_id:int, action:String, seed_class_tsid:String = ''):Boolean {
			//tell the garden that an action has been performed (which allows the surpression of the glow)
			if(action == GardenAction.REMOVE){
				//we tap into seed_class_tsid for the itemstack of the REMOVE_ITEMS. This because it's already there, GardenPlotView sends it
				TSFrontController.instance.genericSend(new NetOutgoingItemstackVerbVO(itemstack_tsid, 'remove', 1, seed_class_tsid), onRemoveReply, onRemoveReply);
				return true;
			}
			
			var garden_view:GardenView = getGardenView(itemstack_tsid);
			if(garden_view) garden_view.actionUpdate();
			
			if(actions_locked) {
				model.activityModel.activity_message = Activity.createFromCurrentPlayer('Slow down! Gardening is a leisure activity.');
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return false;
			}
			
			actions_locked = true;
			last_action = action;
			
			sendActionMsg(new NetOutgoingGardenActionVO(itemstack_tsid, plot_id, action, seed_class_tsid));
			
			return true;
		}
		
		public function sendActionMsg(nogaVO:NetOutgoingGardenActionVO):void {
			nogaVO.check_for_proximity = model.flashVarModel.check_for_proximity;
			TSFrontController.instance.genericSend(
				nogaVO,
				onActionReply,
				onActionReply
			);
		}
		
		public function startEditing(garden_tsid:String):void {
			//throw the view into a tending state
			var garden_view:GardenView = getGardenView(garden_tsid);
			if(garden_view){
				garden_view.is_tending = true;
				is_tending = true;
				tending_tsid = garden_tsid;
								
				//listen for things that make people want to stop
				StageBeacon.mouse_click_sig.add(onStageClick);
				StageBeacon.key_down_sig.add(onKeyDown);
				
				//unlock the actions
				unlockActions();
			}
		}
		
		public function stopEditing():void {
			var garden_view:GardenView = getGardenView(tending_tsid);
			if(garden_view){
				garden_view.is_tending = false;
				is_tending = false;
				
				//stop listening for things that make people want to stop
				StageBeacon.mouse_click_sig.remove(onStageClick);
				StageBeacon.key_down_sig.remove(onKeyDown);
				
				//unlock the actions
				unlockActions();
			}
		}
		
		private function onStageClick(event:MouseEvent):void {
			//let's see if we are clicking off the garden
			var garden_view:GardenView = getGardenView(tending_tsid);
			if(garden_view && !garden_view.hitTestPoint(event.stageX, event.stageY) 
				&& model.stateModel.focused_component == garden_view
				&& TSFrontController.instance.getMainView().masked_container.hitTestPoint(event.stageX, event.stageY))
			{
				stopEditing();
			}
		}
		
		private function onKeyDown(event:KeyboardEvent):void {
			if(event.keyCode == Keyboard.ESCAPE){
				TSFrontController.instance.goNotAFK();
				stopEditing();
			}
		}
		
		private function onActionReply(nrm:NetResponseMessageVO):void {
			if (nrm.payload && nrm.payload.error && nrm.payload.error.code == '101') {
				// move the player closer, then resubmit
				var nogaVO:NetOutgoingGardenActionVO = nrm.request as NetOutgoingGardenActionVO;
				TSFrontController.instance.moveCloserForVerbOrAction(nogaVO, nogaVO.action.toLowerCase(), nrm.payload.error);
			} else if(!nrm.success){
				SoundMaster.instance.playSound('CLICK_FAILURE');
				var garden_tsid:String = NetOutgoingGardenActionVO(nrm.request).itemstack_tsid;
				var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(garden_tsid);
				if(lis_view) {
					lis_view.bubbleHandler({txt:nrm.payload.error.msg, duration:3000});
				} else {
					CONFIG::debugging {
						Console.warn('No lis_view for '+garden_tsid);
					}
					
				}
				model.activityModel.activity_message = Activity.createFromCurrentPlayer(nrm.payload.error.msg);
			}
			
			//unlock the actions, unless it's planting or picking, those need artifical delays
			if(last_action == GardenAction.PLANT || last_action == GardenAction.PICK){
				StageBeacon.waitForNextFrame(unlockActions);
			} else {
				unlockActions();
			}
		}
		
		private function unlockActions():void {
			actions_locked = false;
		}
		
		private function onRemoveReply(nrm:NetResponseMessageVO):void {
			if(!nrm.success){
				//no dice, throw out the error message
				SoundMaster.instance.playSound('CLICK_FAILURE');
				model.activityModel.activity_message = Activity.createFromCurrentPlayer(nrm.payload.error.msg);
			}
		}
		
		private function buildGarden(garden:Garden):void {
			if(!garden) return;
			if(!TSFrontController.instance.getMainView()) return;
			
			//get where to put this thing
			var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(garden.itemstack_tsid);
			if(!lis_view) {
				CONFIG::debugging {
					Console.warn('No lis_view for '+garden.itemstack_tsid);
				}
				return;
			}
			//IF YOU WANNA MESS WITH THE SCALE WITHOUT HAVING TO REBUILD THE ITEM EVERYTIME USE THIS
			//model.worldModel.getItemstackByTsid(garden.itemstack_tsid).item.adjusted_scale = .7;
			var garden_view:GardenView = getGardenView(garden.itemstack_tsid, lis_view);
			
			if(!garden_view) {
				
				garden_view = new GardenView();
				garden_view.build(garden);
				
				// use the new addGardenView method instead of simple addChild, so the the lis_view
				// explicitly knows it has a garden view
				lis_view.addGardenView(garden_view);
				lis_view.mouseClicked.add(onGardenClick);
			}
			else {
				garden_view.update(garden);
			}
		}
		
		/* I believe this is no longer necessary, as the click is handled in LIH._tryActOnClickedElement
		*/private function onGardenClick(event:MouseEvent):void {			
			var lis_view:LocationItemstackView = event.currentTarget as LocationItemstackView;
			if(!lis_view) return;
			
			TSFrontController.instance.goNotAFK();

			//let admins do stuff
			CONFIG::god {
				if(KeyBeacon.instance.pressed(Keyboard.K)) {
					TSFrontController.instance.doVerb(lis_view.tsid, Item.CLIENT_DESTROY);
				}
				else if(KeyBeacon.instance.pressed(Keyboard.P)) {
					TSFrontController.instance.doVerb(lis_view.tsid, Item.CLIENT_EDIT_PROPS);
				}
			}
		}
		
		
		private function onSWFLoad(sl:SmartLoader):void {
			GardenSWFData.garden_mc = sl.content as MovieClip;
			
			//loop through the queue of tsids that we needed to handle
			var i:int;
			var garden:Garden;
			
			for(i; i < garden_tsids.length; i++){
				garden = buildGardenHash(garden_tsids[int(i)]);
				buildGarden(garden);
			}
			
			garden_tsids = null;
		}
		
		private function onSWFError(sl:SmartLoader):void {
			BootError.handleError('onSWFError could load the garden_mc', new Error((sl.totalRetries+1)+" load attempts failed"), ['loader']);
		}
		
		public function getGardenView(garden_tsid:String, lis_view:LocationItemstackView = null):GardenView {
			//skip the lis_view check if we already have one
			if(!lis_view){
				lis_view = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(garden_tsid);
				if(!lis_view) {
					CONFIG::debugging {
						Console.warn('No lis_view for '+garden_tsid);
					}
					return null;
				}
			}
			
			//get the garden
			var garden_view:GardenView = lis_view.garden_view;
			CONFIG::debugging {
				if(!garden_view) {
					Console.warn('No garden_view for '+garden_tsid);
				}
			}
			
			return garden_view;
		}
		
		/**
		 * Checks to see if the item is water/hoe/fertilizer/seed 
		 * @param item_tsid
		 * @return true if it can be used in a garden
		 */		
		public function isUsableItem(item_tsid:String, garden:Garden):Boolean {
			if(!item_tsid) return false;
			
			if(WATER_TOOLS.indexOf(item_tsid) != -1 && model.worldModel.pc.getItemstackOfWorkingTool(item_tsid)){
				return true;
			}
			else if(HOE_TOOLS.indexOf(item_tsid) != -1 && model.worldModel.pc.getItemstackOfWorkingTool(item_tsid)){
				return true;
			}
			else if(FERTILIZER.indexOf(item_tsid) != -1){
				return true;
			}
			else if(REMOVE_ITEMS.indexOf(item_tsid) != -1){
				return true;
			}			
			else {
				const item:Item = model.worldModel.getItemByTsid(item_tsid);
				if(item && item.hasTags(garden.type != Garden.TYPE_DEFAULT ? garden.type+'_seed' : 'seed')){
					return true;
				}
			}
			
			return false;
		}
		
		private function buildGardenHash(tsid:String):Garden {
			var garden:Garden = model.worldModel.getGardenByTsid(tsid);
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
			
			if(!garden){				
				if(itemstack){
					garden = Garden.fromAnonymous(itemstack.itemstack_state.config, tsid);
					
					//throw it in the world
					model.worldModel.gardens.push(garden);
				}
				else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('Garden itemstack not found: '+tsid);
					}
				}
			}
			else {
				//update the world
				model.worldModel.gardens.splice(model.worldModel.gardens.indexOf(garden), 1);
				
				garden = Garden.fromAnonymous(itemstack.itemstack_state.config, tsid);
				model.worldModel.gardens.push(garden);
			}			
			
			return garden;
		}
	}
}