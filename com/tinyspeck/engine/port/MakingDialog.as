package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.making.MakingInfo;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Toast;
	import com.tinyspeck.engine.view.ui.making.MakingCompleteUI;
	import com.tinyspeck.engine.view.ui.making.MakingDetailsUI;
	import com.tinyspeck.engine.view.ui.making.MakingErrorUI;
	import com.tinyspeck.engine.view.ui.making.MakingRecipeUI;
	import com.tinyspeck.engine.view.ui.making.MakingToolAnimator;
	import com.tinyspeck.engine.view.ui.making.MakingTryUI;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class MakingDialog extends BigDialog implements IPackChange
	{
		/* singleton boilerplate */
		public static const instance:MakingDialog = new MakingDialog();
		
		private const TITLE_ICON_WH:uint = 45;
		
		private var back_bt:Button;
		private var done_bt:Button;
		private var recipe_bt:Button;
		private var make_more_bt:Button;
		private var recipe_ui:MakingRecipeUI;
		private var complete_ui:MakingCompleteUI;
		//private var broken_ui:MakingBrokenUI;
		private var try_ui:MakingTryUI;
		private var error_ui:MakingErrorUI;
		private var tool_animator:MakingToolAnimator;
		private var toast:Toast;
		
		private var all_holder:Sprite = new Sprite();
		
		private var content_w:int;
		
		private var is_built:Boolean;
		
		public function MakingDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 614;
			_head_min_h = 67;
			_body_min_h = 320;
			_foot_min_h = 64;
			_base_padd = 20;
			_scrolltrack_always = true;
			_draggable = true;
			_graphic_padd_side = 25;
			
			_construct();
		}
		
		private function buildBase():void {
			content_w = _w - _base_padd - _border_w*2 - _scroller_bar_wh;
			
			//back button
			const back_DO:DisplayObject = new AssetManager.instance.assets.back_circle();
			back_bt = new Button({
				label: '',
				name: 'back',
				graphic: back_DO,
				graphic_hover: new AssetManager.instance.assets.back_circle_hover(),
				graphic_disabled: new AssetManager.instance.assets.back_circle_disabled(),
				w: back_DO.width,
				h: back_DO.height,
				draw_alpha: 0
			});
			back_bt.x = -back_DO.width/2 + 1;
			back_bt.y = 12;
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			
			//buttons when complete
			recipe_bt = new Button({
				name: 'recipes',
				label: 'Back to recipes',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			recipe_bt.x = _base_padd;
			recipe_bt.y = int(_foot_min_h/2 - recipe_bt.height/2) - 1;
			recipe_bt.addEventListener(TSEvent.CHANGED, onRecipesBackClick, false, 0, true);
			_foot_sp.addChild(recipe_bt);
			
			make_more_bt = new Button({
				name: 'make_more',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			make_more_bt.x = int(recipe_bt.x + recipe_bt.width + 12);
			make_more_bt.y = recipe_bt.y;
			make_more_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			_foot_sp.addChild(make_more_bt);
			
			done_bt = new Button({
				name: 'done',
				label: 'Done',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			done_bt.y = int(_foot_min_h/2 - done_bt.height/2) - 1;
			done_bt.addEventListener(TSEvent.CHANGED, onDoneClick, false, 0, true);
			_foot_sp.addChild(done_bt);
			
			//all holder
			all_holder.x = all_holder.y = _base_padd/2;
			_scroller.body.addChild(all_holder);
			
			//tool animator
			tool_animator = new MakingToolAnimator();
			tool_animator.x = _border_w;
			
			//error UI
			error_ui = new MakingErrorUI();
			error_ui.addEventListener(TSEvent.CHANGED, onErrorTryAgain, false, 0, true);
			
			is_built = true;
		}
		
		public function cancelIfNeeded():void {
			if (parent) end(true);
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			if(!canContinue()){
				model.activityModel.activity_message = Activity.createFromCurrentPlayer('Hold on bucko! Let\'s finish one thing at a time.');
				model.activityModel.growl_message = 'Hold on bucko! Let\'s finish one thing at a time.';
				return;
			}
			if(parent) end(false);
			
			const info:MakingInfo = MakingManager.instance.making_info;
			
			//set the title	
			setTitle();
			_setSubtitle('');
			
			_foot_sp.visible = false;
			back_bt.disabled = false;
			done_bt.value = null;
			if(contains(tool_animator)) removeChild(tool_animator);
			
			//show the recipes they can make
			if(info.knowns.length || info.can_discover){
				recipe_ui = new MakingRecipeUI(info.knowns, content_w);
				all_holder.addChild(recipe_ui);
				
				//make sure we listen to recipe clicks
				recipe_ui.addEventListener(TSEvent.CHANGED, onRecipeClick, false, 0, true);
			}
			
			all_holder.x = _base_padd/2;
			
			super.start();
			
			//listen to the pack
			PackDisplayManager.instance.registerChangeSubscriber(this);
			
			//listen to api skill changes
			model.worldModel.registerCBProp(onAPISkill, "pc","skill_api_complete");
			
			//listen to stat changes
			model.worldModel.registerCBProp(onStatsChange, "pc", "stats");
			
			//listen to completed quests
			QuestManager.instance.addEventListener(TSEvent.QUEST_COMPLETE, onQuestComplete, false, 0, true);
		}
		
		override public function end(release:Boolean):void {
			//if we are making something, they can't close the window
			if(contains(tool_animator)){
				model.activityModel.activity_message = Activity.createFromCurrentPlayer('Let it finish!');
				model.activityModel.growl_message = 'Let it finish!';
				return;
			}
			
			super.end(release);
			
			SpriteUtil.clean(all_holder, false);
			
			if(back_bt.parent) back_bt.parent.removeChild(back_bt);
			
			//broken_ui.visible = false;
			
			//stop listening to the pack
			PackDisplayManager.instance.unRegisterChangeSubscriber(this);
			
			//stop listening to API changes
			model.worldModel.unRegisterCBProp(onAPISkill, "pc","skill_api_complete");
			
			//stop listening to stats
			model.worldModel.unRegisterCBProp(onStatsChange, "pc", "stats");
			
			//stop listening to completed quests
			QuestManager.instance.removeEventListener(TSEvent.QUEST_COMPLETE, onQuestComplete);
		}
		
		/**
		 * When you want to make a sub-component of a recipe, call this to bring up a new details UI 
		 * @param recipe_id
		 */		
		public function startWithRecipeId(recipe_id:String):void {
			if(!recipe_id) return;
			
			const recipe:Recipe = model.worldModel.getRecipeById(recipe_id);
			
			if(all_holder.numChildren){
				onRecipeClick(new TSEvent(TSEvent.ACTIVITY_HAPPENED, recipe ? recipe_id : 'try'));
			}
			//if nothing is built yet, make sure it gets built
			else {
				if(!canStart(true)) return;
				if(!is_built) buildBase();
				if(!canContinue()){
					model.activityModel.activity_message = Activity.createFromCurrentPlayer('Hold on bucko! Let\'s finish one thing at a time.');
					model.activityModel.growl_message = 'Hold on bucko! Let\'s finish one thing at a time.';
					return;
				}
				if(parent) end(false);
				
				if(recipe){
					setTitle();
					
					//put the details on there
					var details_ui:MakingDetailsUI = new MakingDetailsUI(recipe, content_w);
					
					all_holder.addChild(details_ui);
					all_holder.x = _base_padd/2;
					
					_foot_sp.visible = false;
					back_bt.disabled = false;
					
					super.start();
					
					//listen to the pack
					PackDisplayManager.instance.registerChangeSubscriber(this);
					
					//listen to api skill changes
					model.worldModel.registerCBProp(onAPISkill, "pc","skill_api_complete");
				}
				else {
					model.activityModel.activity_message = Activity.createFromCurrentPlayer('Hmm, you don\'t know that recipe');
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('Invalid recipe!');
					}
				}
			}
		}
		
		public function canContinue():Boolean {
			/** this will make sure:
			 *  a) the player isn't making something already
			 *  b) we are not animating to the "complete" screen
			 **/
			if(!is_built){
				return true;
			}
			else if(contains(tool_animator) || (TSTweener.isTweening(all_holder) && all_holder.contains(complete_ui))){				
				return false;
			}
			else {
				return true;
			}
		}
		
		private function setTitle(recipe:Recipe = null):void {
			var title:String = '<span class="making_title">';
			var item:Item;
			
			if(!recipe){
				const info:MakingInfo = MakingManager.instance.making_info;
				item = model.worldModel.getItemByTsid(info.item_class);
				if(item){
					title += 'You want to <span class="making_make_verb">'+info.verb+'</span> '+
						     'with '+StringUtil.aOrAn(item.label)+' <span class="making_make_item">'+item.label+'</span>?';
					_setGraphicContents(new ItemIconView(item.tsid, TITLE_ICON_WH, model.worldModel.pc.getItemstackOfWorkingTool(item.tsid) ? 'iconic' : 'broken_iconic'));
				}
			}
			else {
				item = model.worldModel.getItemByTsid(recipe.outputs[0].item_class);
				title += 'Make '+item.label_plural;
				_setGraphicContents(new ItemIconView(recipe.tool, TITLE_ICON_WH, model.worldModel.pc.getItemstackOfWorkingTool(recipe.tool) ? 'iconic' : 'broken_iconic'));
			}
			
			title += '</span>';
			
			_setTitle(title);
		}
		
		override protected function _setSubtitle(html:String):void {
			super._setSubtitle(html ? '<span class="making_subtitle">'+html+'</span>' : '');
		}
		
		public function animateTool(tool_class:String, time_ms:int, amount:int, is_known:Boolean):void {
			if(!parent) return;
			
			back_bt.disabled = true;
			
			//prepare everything for the overlay
			addChild(tool_animator);
			tool_animator.y = _head_h + _divider_h;
			tool_animator.setSize(_w - _border_w*2, _body_h - _divider_h*2);
			tool_animator.animate(tool_class, time_ms, amount, is_known);
		}
		
		override protected function _jigger():void {			
			super._jigger();
			_scroller.h = _body_min_h - _divider_h*2;
			
			_body_h = _body_min_h;
			_foot_sp.y = _head_h + _body_h;
			
			//if we are not showing the footer buttons, make the footer small
			if(!_foot_sp.visible){
				_foot_h = 7;
			}
			else {
				_foot_h = _foot_min_h;
			}
			
			_h = _head_h + _body_h + _foot_h;
			
			_draw();
		}
		
		public function showComplete(recipe_id:String, amount:int, rewards:Vector.<Reward>, is_known:Boolean, over_xp_limit:Boolean, extra_msg:String = ''):void {
			if(!parent) return;
			
			var recipe:Recipe = model.worldModel.getRecipeById(recipe_id);
			var item:Item = model.worldModel.getItemByTsid(recipe.outputs[0].item_class);
			
			make_more_bt.label = 'Make more '+item.label_plural;
			make_more_bt.visible = is_known;
			recipe_bt.visible = true;
			
			done_bt.label = 'Done';
			
			_foot_sp.visible = true;
			if(contains(tool_animator)) removeChild(tool_animator);
			
			if(!complete_ui) complete_ui = new MakingCompleteUI(content_w);
			complete_ui.show(recipe_id, amount, rewards, is_known, over_xp_limit, extra_msg);
			
			recipe_ui.scaleX = recipe_ui.scaleY = .01;
			
			complete_ui.x = (all_holder.numChildren * (content_w + _base_padd/2));
			all_holder.addChild(complete_ui);
			
			TSTweener.addTween(all_holder, {x:all_holder.x-content_w-_base_padd/2, time:.5, onComplete:onRecipeTweenComplete});
			
			//they may want to try something else
			if(try_ui) try_ui.start(MakingManager.instance.making_info.slots);
			
			back_bt.disabled = false;
			addChild(back_bt);
			
			if(all_holder.numChildren >= 3 && all_holder.getChildAt(all_holder.numChildren-3) is MakingDetailsUI){
				var child:DisplayObject = all_holder.getChildAt(all_holder.numChildren-3);
				var item_parent:Item = model.worldModel.getItemByTsid(MakingDetailsUI(child).recipe.outputs[0].item_class);
				
				if(item_parent) {
					done_bt.label = 'Back to making '+item_parent.label_plural;
					done_bt.value = item_parent.tsid;
					make_more_bt.visible = false;
					recipe_bt.visible = false;
				}
			}
			
			done_bt.x = int(_w - done_bt.width - _base_padd);
			
			_scroller.scrollUpToTop();
			
			_jigger();
		}
		
		public function showError(msg:String):void {
			if(!parent) return;
			
			var item:Item = model.worldModel.getItemByTsid(MakingManager.instance.making_info.item_class);
	
			done_bt.label = 'Pfft, I\'m done with the '+item.label;
			done_bt.x = int(_w - done_bt.width - _base_padd);
			
			make_more_bt.visible = false;
			
			_foot_sp.visible = true;
			if(contains(tool_animator)) removeChild(tool_animator);
			
			//show the error
			error_ui.show(msg, content_w, _body_min_h - _base_padd);
			
			recipe_ui.scaleX = recipe_ui.scaleY = .01;
			
			error_ui.x = all_holder.numChildren * (content_w + _base_padd/2);
			all_holder.addChild(error_ui);
			
			TSTweener.addTween(all_holder, {x:all_holder.x-content_w-_base_padd/2, time:.5, onComplete:onRecipeTweenComplete});
			
			back_bt.disabled = false;
			addChild(back_bt);
			
			if(try_ui) try_ui.start(MakingManager.instance.making_info.slots);
			
			_scroller.scrollUpToTop();
			
			_jigger();
		}
		
		public function showToast(txt:String):void {
			if(!parent) return;
			
			//allows the dialog to show an error toast
			if(!toast){
				toast = new Toast(_w - _base_padd*2);
				toast.x = _base_padd;
				toast.y = _h - _border_w;
			}
			
			toast.show(txt, 5);
			addChild(toast);
		}
		
		private function showBroken(tool_class:String):void {
			/** No longer using this
			_foot_sp.visible = false;
			_jigger();
			
			_setGraphicContents(new ItemIconView(tool_class, TITLE_ICON_WH, 'broken_iconic'));
			
			broken_ui.show(tool_class, _w - _border_w*2, _body_h - _divider_h*2);
			broken_ui.y = _head_h + _divider_h;
			**/ 
		}
		
		public function onPackChange():void {
			if(!parent) return;
			
			var i:int;
			var child:DisplayObject;
			var old_scale:Number;
			var tool_class:String;
			var itemstack_tsids:Array;
			var itemstack:Itemstack;
			
			for(i; i < all_holder.numChildren; i++){
				child = all_holder.getChildAt(i);
				
				if(child is MakingDetailsUI){
					MakingDetailsUI(child).refresh();
				}
				else if(child is MakingRecipeUI){
					if(child.scaleX < 1){
						old_scale = child.scaleX;
						child.scaleX = child.scaleY = 1;
					}
					
					MakingRecipeUI(child).refresh(MakingManager.instance.making_info.knowns);
					
					if(!isNaN(old_scale)){
						child.scaleX = child.scaleY = old_scale;
					}
				}
			}
			
			//check to make sure we still have a working tool			
			if(!MakingManager.instance.making_info.no_modal){
				child = (all_holder.numChildren) ? all_holder.getChildAt(all_holder.numChildren-1) : null;
				
				setTitle(child is MakingDetailsUI ? MakingDetailsUI(child).recipe : null);
			}
		}
		
		private function onRecipeClick(event:TSEvent):void {
			var recipe:Recipe = model.worldModel.getRecipeById(event.data);
			var all_good:Boolean = true;
			
			if(recipe){				
				var details_ui:MakingDetailsUI;
				
				//if we are making a sub-component, see if the previous child is another details UI
				if(all_holder.getChildAt(all_holder.numChildren-1) is MakingDetailsUI){
					details_ui = all_holder.getChildAt(all_holder.numChildren-1) as MakingDetailsUI;
					
					var item:Item = model.worldModel.getItemByTsid(recipe.outputs[0].item_class);
					var item_parent:Item = model.worldModel.getItemByTsid(details_ui.recipe.outputs[0].item_class);
					if(item && item_parent) _setSubtitle('Making '+item.label_plural+' for '+item_parent.label_plural);
				}
				else {
					_setSubtitle('');
				}
				
				//create the new details
				recipe.inputs.sort(recipe_ui.componentsSort);
				details_ui = new MakingDetailsUI(recipe, content_w);
				details_ui.x = all_holder.numChildren * (content_w + _base_padd/2);
				all_holder.addChild(details_ui);
								
				setTitle(recipe);
			}
			else if(event.data == 'try'){
				if(!try_ui) try_ui = new MakingTryUI();
				try_ui.setWidthAndHeight(content_w, _body_min_h - _base_padd);
				try_ui.start(MakingManager.instance.making_info.slots);
				try_ui.x = (all_holder.numChildren * content_w) + _base_padd;
				try_ui.scaleX = try_ui.scaleY = 1;
				all_holder.addChild(try_ui);
				
				_setGraphicContents(new ItemIconView('test_tube', TITLE_ICON_WH));
				_setSubtitle('Drag elements from your pouch to make something new!');
			}
			else {
				CONFIG::debugging {
					Console.warn('Got some funky data: '+event.data);
				}
				all_good = false;
			}
			
			if(all_good){
				TSTweener.addTween(all_holder, {x:all_holder.x-content_w-_base_padd/2, time:.5, onComplete:onRecipeTweenComplete});

				addChild(back_bt);
				
				_scroller.scrollUpToTop();
			}
		}
		
		private function onRecipeTweenComplete():void {
			//shrink everything except the last thing added
			var i:int;
			var total:int = all_holder.numChildren-1;
			var child:DisplayObject;
			
			for(i; i < total; i++){
				child = all_holder.getChildAt(i);
				child.scaleX = child.scaleY = .01;
			}
			
			_jigger();
			
			_scroller.refreshAfterBodySizeChange(true);
		}
		
		private function onBackClick(event:TSEvent):void {
			//shift the all_holder to the left by content_w
			if(back_bt.disabled) return;
			back_bt.disabled = true;
			
			//if we are done making something, make sure the back button does what the done button does
			if(done_bt.value){
				onDoneClick(event);
				return;
			}
			
			_foot_sp.visible = false;
			//broken_ui.visible = false;
			
			//reset the scale of the child before the last one
			var child:DisplayObject = all_holder.numChildren-2 >= 0 ? all_holder.getChildAt(all_holder.numChildren-2) : null;
			if(child) child.scaleX = child.scaleY = 1;
			
			//make sure we have the proper icon in the header
			if(child && child is MakingDetailsUI) {
				const recipe:Recipe = model.worldModel.getRecipeById(child.name);
				if(recipe) setTitle(recipe);
			}
			
			_scroller.scrollUpToTop();
						
			//if we are making a sub-component, see if the previous child is another details UI
			if(all_holder.numChildren >= 3 && all_holder.getChildAt(all_holder.numChildren-3) is MakingDetailsUI){
				child = all_holder.getChildAt(all_holder.numChildren-3);
				const item_parent:Item = child ? model.worldModel.getItemByTsid(MakingDetailsUI(child).recipe.outputs[0].item_class) : null;
				
				child = all_holder.getChildAt(all_holder.numChildren-2);
				const item:Item = child && child is MakingDetailsUI ? model.worldModel.getItemByTsid(MakingDetailsUI(child).recipe.outputs[0].item_class) : null;
				
				if(item && item_parent) _setSubtitle('Making '+item.label_plural+' for '+item_parent.label_plural);
			}
			else if(!(child && child is MakingTryUI)){
				_setSubtitle('');
			}
			
			//if we only have 2 childen left, reset the title
			if(all_holder.numChildren == 2) setTitle();
			
			_jigger();
			
			TSTweener.addTween(all_holder, {x:all_holder.x + content_w + _base_padd/2, time:.5, onComplete:onBackTweenComplete});
		}
		
		private function onBackTweenComplete():void {
			back_bt.disabled = false;
			if(all_holder.x == _base_padd/2){
				if(back_bt.parent) back_bt.parent.removeChild(back_bt);
			}
			
			var child:DisplayObject = all_holder.getChildAt(all_holder.numChildren-1);
			if(child && child is MakingTryUI) MakingTryUI(child).stop();
			if(child) all_holder.removeChild(child);
			
			_scroller.refreshAfterBodySizeChange(true);
		}
		
		private function onRecipesBackClick(event:TSEvent):void {
			//show the recipes and delete everything after it
			setTitle();
			_setSubtitle('');
			_foot_sp.visible = false;
			
			if(back_bt.parent) back_bt.parent.removeChild(back_bt);
			
			recipe_ui.scaleX = recipe_ui.scaleY = 1;
			
			TSTweener.addTween(all_holder, {x:_base_padd/2, time:.5, onComplete:onRecipesBackTweenComplete});
			
			_scroller.scrollUpToTop();
		}
		
		private function onRecipesBackTweenComplete():void {
			while(all_holder.numChildren > 1) all_holder.removeChildAt(all_holder.numChildren-1);
			
			_scroller.refreshAfterBodySizeChange(true);
		}
		
		private function onDoneClick(event:TSEvent):void {
			//if we are not done with stuff, go to where we need to go
			if(done_bt.value){
				var child:DisplayObject = all_holder.getChildAt(all_holder.numChildren-3);
				var recipe:Recipe = model.worldModel.getRecipeByOutputClass(done_bt.value);
				child.scaleX = child.scaleY = 1;
				TSTweener.addTween(all_holder, {x:all_holder.x+(content_w+_base_padd/2)*2, time:.5, onComplete:onDoneTweenComplete, onCompleteParams:[child]});
				done_bt.value = null;
				
				//broken_ui.visible = false;
				
				setTitle(recipe);
				_setSubtitle('');
				
				_foot_sp.visible = false;
				_jigger();
			}
			else {
				end(true);
			}
		}
		
		private function onDoneTweenComplete(child:DisplayObject):void {
			back_bt.disabled = false;
			
			if (!child.parent) return;
			if (child.parent != all_holder) return;
			//kill all the children after this child
			while(all_holder.numChildren-1 > all_holder.getChildIndex(child)) all_holder.removeChildAt(all_holder.numChildren-1);
		}
		
		private function onErrorTryAgain(event:TSEvent):void {
			onBackClick(event);
		}
		
		private function onAPISkill(pc_skill:PCSkill = null):void {		
			const class_tsids:Array = [];
			const making_info:MakingInfo = MakingManager.instance.making_info;
			
			//if we've got a skill change, go ask the server for updated recipes for everything we have up
			const total:int = making_info && making_info.knowns ? making_info.knowns.length : 0;
			var i:int;
			var recipe:Recipe;
			
			if(total){
				for(i; i < total; i++){
					recipe = MakingManager.instance.making_info.knowns[int(i)];
					if(recipe.outputs && recipe.outputs.length){
						class_tsids.push(recipe.outputs[0].item_class);
					}
				}
				
				//send em off, calls onPackChange() when done
				if(class_tsids.length){
					MakingManager.instance.recipeRequest(class_tsids, null);
				}
			}
		}
		
		private function onStatsChange(pc_stats:PCStats = null):void {
			//loop through what we've got and refresh the make button
			var i:int;
			var child:DisplayObject;
			
			for(i; i < all_holder.numChildren; i++){
				child = all_holder.getChildAt(i);
				if(child is MakingDetailsUI){
					MakingDetailsUI(child).setMakeButton();
				}
			}
		}
		
		private function onQuestComplete(event:TSEvent):void {
			var quest:Quest = event.data as Quest;
			var i:int;
			var reward:Reward;
			var class_tsids:Array = new Array();
			
			if(quest && quest.rewards.length){
				//loop through the rewards and if we have any recipes, go and ask about them from the server
				for(i; i < quest.rewards.length; i++){
					reward = quest.rewards[int(i)];
					if(reward.recipe && reward.recipe.class_tsid) class_tsids.push(reward.recipe.class_tsid);
				}
			}
			
			//send em off, calls onPackChange() when done
			if(class_tsids.length){
				MakingManager.instance.recipeRequest(class_tsids, null);
			}
		}
	}
}