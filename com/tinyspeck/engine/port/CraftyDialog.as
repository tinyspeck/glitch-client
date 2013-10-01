package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.data.craftybot.CraftyJob;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.craftybot.CraftyActiveUI;
	import com.tinyspeck.engine.view.ui.craftybot.CraftyFooterUI;
	import com.tinyspeck.engine.view.ui.craftybot.CraftyJobDetailsUI;
	import com.tinyspeck.engine.view.ui.craftybot.CraftyJobsUI;
	import com.tinyspeck.engine.view.ui.craftybot.CraftyRecipesUI;
	import com.tinyspeck.engine.view.ui.craftybot.CraftyToolsUI;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	public class CraftyDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:CraftyDialog = new CraftyDialog();
		
		public static const BODY_H:uint = 343;
		
		private static const ICON_WH:uint = 40;
		
		private var jobs_ui:CraftyJobsUI;
		private var details_ui:CraftyJobDetailsUI;
		private var tools_ui:CraftyToolsUI;
		private var recipes_ui:CraftyRecipesUI;
		private var active_ui:CraftyActiveUI;
		private var back_bt:Button;
		private var footer_ui:CraftyFooterUI;
		private var header_icon:ItemIconView;
		
		private var current_tool_class:String;
		
		private var scroll_y:int;
		
		private var is_built:Boolean;
		
		public function CraftyDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_close_bt_padd_right = 8;
			_close_bt_padd_top = 8;
			_title_padd_left = 20;
			_base_padd = 15;
			_w = 340;
			_head_min_h = 60;
			_body_min_h = BODY_H;
			_body_max_h = BODY_H;
			_foot_min_h = CraftyFooterUI.HEIGHT;
			_graphic_padd_side = 25;
			_draggable = true;
			_construct();
		}
		
		private function buildBase():void {			
			_setTitle('Craftybot');
			
			//job queue
			jobs_ui = new CraftyJobsUI(_w-_border_w*2);
			
			//details
			details_ui = new CraftyJobDetailsUI(_w-_border_w*2);
			
			//tools
			tools_ui = new CraftyToolsUI(_w-_border_w*2);
			tools_ui.x = _w;
			
			//recipes
			recipes_ui = new CraftyRecipesUI(_w-_border_w*2);
			recipes_ui.x = _w*2;
			
			//active
			active_ui = new CraftyActiveUI(_w-_border_w*2-1);
			active_ui.x = _border_w;
			active_ui.y = _head_min_h;
			addChild(active_ui);
			
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
			
			//footer
			footer_ui = new CraftyFooterUI(_w - _border_w*2);
			footer_ui.x = _border_w;
			_foot_sp.visible = true;
			_foot_sp.addChild(footer_ui);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(false)) return;
			
			//build the base stuff 
			if(!is_built) buildBase();
			
			//reset
			current_tool_class = null;
			onBackClick();
			
			//show the queue
			update();
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//make sure none of our things are doing things
			if(is_built){
				jobs_ui.hide();
				details_ui.hide();
				tools_ui.hide();
				recipes_ui.hide();
				footer_ui.hide();
			}
		}
		
		public function update():void {
			//update the job queue with the new details
			jobs_ui.show();
			if(details_ui.parent) details_ui.refresh();
			
			//set the footer
			footer_ui.show();
			
			//do we have an active job
			showActive();
		}
		
		public function showDetails(item_class:String):void {
			//remember where the scroller is
			scroll_y = _scroller.scroll_y;
			
			if(jobs_ui.parent || recipes_ui.parent){				
				_scroller.body.addChild(details_ui);
				
				TSTweener.removeTweens(_scroller.body);
				TSTweener.addTween(_scroller.body, {x:-(recipes_ui.parent ? _w*3 : _w), time:.2, 
					onComplete:function():void {
						setVisible(details_ui);
					}
				});
			}
			else {
				setVisible(details_ui);
			}
			
			details_ui.x = recipes_ui.parent ? _w*3 : _w;
			details_ui.show(item_class);
			_scroller.scrollUpToTop();
			
			//throw the back button up there
			addChild(back_bt);
			showActive();
			
			//set the title to match the job
			const item:Item = model.worldModel.getItemByTsid(item_class);
			if(item){
				header_icon = new ItemIconView(item_class, ICON_WH);
				_setGraphicContents(header_icon);
				_setTitle(item.label);
			}
		}
		
		public function showTools(optional_scroll_y:int = 0):void {			
			//show the recipes and tools
			if(jobs_ui.parent || recipes_ui.parent){
				//remember where the scroller is
				scroll_y = _scroller.scroll_y;
				
				_scroller.body.addChild(tools_ui);
				
				TSTweener.removeTweens(_scroller.body);
				TSTweener.addTween(_scroller.body, {x:-_w, time:.2, 
					onComplete:function():void {
						setVisible(tools_ui);
						_scroller.scrollYToTop(optional_scroll_y);
					}
				});
			}
			else {
				setVisible(tools_ui);
			}
			
			tools_ui.show();
			if(!optional_scroll_y) _scroller.scrollUpToTop();
			
			//throw the back button up there
			addChild(back_bt);
			showActive();
			
			//set the title
			_setTitle('Which tool?');
			_setGraphicContents(null);
			current_tool_class = null;
		}
		
		public function showRecipes(tool_class:String, optional_scroll_y:int = 0):void {
			current_tool_class = tool_class;
			
			//show the recipes
			if(tools_ui.parent || details_ui.parent){
				//remember where the scroller is
				scroll_y = _scroller.scroll_y;
				
				_scroller.body.addChild(recipes_ui);
				
				TSTweener.removeTweens(_scroller.body);
				TSTweener.addTween(_scroller.body, {x:-_w*2, time:.2, 
					onComplete:function():void {
						setVisible(recipes_ui);
						_scroller.scrollYToTop(optional_scroll_y);
					}
				});
			}
			else {
				setVisible(recipes_ui);
			}
			
			recipes_ui.show(tool_class);
			if(!optional_scroll_y) _scroller.scrollUpToTop();
			
			//throw the back button up there
			addChild(back_bt);
			showActive();
			
			//set the title
			const item:Item = model.worldModel.getItemByTsid(tool_class);
			if(item){
				header_icon = new ItemIconView(tool_class, ICON_WH);
				_setGraphicContents(header_icon);
			}
			_setTitle('Which recipe?');
		}
		
		private function showActive():void {
			if(!back_bt.parent){
				const cm:CraftyManager = CraftyManager.instance;
				const total:uint = cm.jobs ? cm.jobs.length : 0;
				var i:int;
				var job:CraftyJob;
				var showing_active:Boolean;
				
				for(i; i < total; i++){
					job = cm.jobs[int(i)];
					if(job.status.is_active){
						active_ui.show(job);
						if(!active_ui.parent) addChild(active_ui);
						showing_active = true;
						break;
					}
				}
				
				//make sure we aren't showing it if nothing is active
				if(!showing_active) active_ui.hide();
			}
			else if(active_ui.parent){
				active_ui.hide();
			}
			
			_jigger();
		}
		
		public function addStatus(is_success:Boolean):void {
			//if we've added it to the queue, let's show the queue again
			if(is_success && !CraftyManager.instance.getJobByItem(details_ui.item_class)){
				current_tool_class = null;
				onBackClick();
			}
			
			update();
		}
		
		public function removeStatus(is_success:Boolean):void {
			if(is_success && !CraftyManager.instance.getJobByItem(details_ui.item_class)){
				onBackClick();
			}
			
			update();
		}
		
		public function costStatus(is_success:Boolean):void {
			update();
		}
		
		public function lockStatus(is_success:Boolean, is_lock:Boolean):void {
			if(is_success && details_ui.parent){
				details_ui.toggleLock(is_lock);
			}
			else {
				update();
			}
		}
		
		public function pauseStatus(is_success:Boolean, is_pause:Boolean):void {
			if(is_success && details_ui.parent){
				details_ui.togglePause(is_pause);
			}
			else {
				update();
			}
		}
		
		public function refuelStatus(is_success:Boolean):void {
			update();
		}
		
		private function setVisible(ui_element:Sprite):void {
			//this takes care of what to show/hide when making something active			
			if(ui_element != jobs_ui) jobs_ui.hide();
			if(ui_element != details_ui) details_ui.hide();
			if(ui_element != tools_ui) tools_ui.hide();
			if(ui_element != recipes_ui) recipes_ui.hide();
			
			_scroller.body.addChild(ui_element);
		}
		
		override protected function _jigger():void {
			super._jigger();
			if(!is_built) return;
			
			_title_tf.x = _head_graphic.numChildren ? _head_graphic.x + _head_graphic.width + 10 : _title_padd_left;
			
			//make sure we give enough space to the active job
			_head_h += (active_ui.parent ? active_ui.height : 0);
			_body_h -= (active_ui.parent ? active_ui.height : 0);
			_body_sp.y = _head_h;
			
			_scroller.h = _body_h-(_divider_h*2);
			
			_foot_h = footer_ui.height+(_divider_h*2);
			_foot_sp.y = _head_h + _body_h;
			
			_h = _head_h + _body_h + _foot_h;
			
			_draw();			
		}
		
		private function onBackClick(event:TSEvent = null):void {
			if(event) SoundMaster.instance.playSound('CLICK_SUCCESS');
			if(back_bt.parent) back_bt.parent.removeChild(back_bt);
			showActive();
			
			if(current_tool_class){
				//show the tool list again
				if(recipes_ui.parent){
					showTools(scroll_y);
				}
				else {
					//back to the recipes, must've been lookin' at details
					showRecipes(current_tool_class, scroll_y);
				}
				return;
			}
			
			_scroller.body.addChild(jobs_ui);
			
			TSTweener.removeTweens(_scroller.body);
			TSTweener.addTween(_scroller.body, {x:0, time:.2, 
				onComplete:function():void {
					setVisible(jobs_ui);
					_scroller.scrollYToTop(scroll_y);
				}
			});
			
			//axe the icon and reset the title
			_setTitle('Craftybot');
			_setGraphicContents(null);
			
			//axe the price check
			CraftyManager.instance.job_cost_req = null;
		}
	}
}