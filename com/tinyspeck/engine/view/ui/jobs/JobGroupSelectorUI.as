package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Checkbox;
	import com.tinyspeck.engine.view.ui.TSScroller;
	
	import flash.text.TextField;

	public class JobGroupSelectorUI extends TSSpriteWithModel
	{
		private static const SCROLL_BAR_W:uint = 12;
		private static const DISABLED_ALPHA:Number = .5;
		
		private const checkboxes:Vector.<Checkbox> = new Vector.<Checkbox>();
		
		private var title_tf:TextField = new TextField();
		private var scroller:TSScroller;
				
		public function JobGroupSelectorUI(){
			buildBase();
		}
		
		private function buildBase():void {
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="job_group_selector">Claimed on behalf of:</p>';
			addChild(title_tf);
			
			scroller = new TSScroller({
				name: 'scroller',
				bar_wh: SCROLL_BAR_W,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 36,
				scrolltrack_always: false,
				maintain_scrolling_at_max_y: true,
				start_scrolling_at_max_y: true,
				use_auto_scroll: false,
				show_arrows: true
			});
			scroller.y = title_tf.height;
			addChild(scroller);
		}
		
		public function show():void {
			visible = true;
			
			var i:int;
			var checkbox:Checkbox;
			var current_groups:Array = model.worldModel.getGroupsTsids(false);
			var group:Group;
			var next_y:int;
			
			//clean up any checkboxes we arleady have
			for(i = 0; i < checkboxes.length; i++){
				checkbox = checkboxes[int(i)];
				checkbox.x = checkbox.y = 0;
				checkbox.visible = false;
			}
			
			//loop through the player's groups and toss them in the scroller
			for(i = 0; i < current_groups.length; i++){
				group = model.worldModel.getGroupByTsid(current_groups[int(i)]);
				
				if(checkboxes.length > i){
					checkbox = checkboxes[int(i)];
					checkbox.visible = true;
				}
				else {
					checkbox = new Checkbox({
						graphic: new AssetManager.instance.assets.cb_unchecked(),
						graphic_checked: new AssetManager.instance.assets.cb_checked(),
						w:18,
						h:18,
						name: 'checkbox_'+i
					});
					checkbox.addEventListener(TSEvent.CHANGED, onCheckClick, false, 0, true);
					checkboxes.push(checkbox);
					scroller.body.addChild(checkbox);
				}
				
				checkbox.label = group.label;
				checkbox.value = group.tsid;
				checkbox.checked = i == 0;
				checkbox.alpha = group.owns_property ? DISABLED_ALPHA : 1;
				checkbox.y = next_y;
				next_y += checkbox.height + 3;
			}
			
			scroller.refreshAfterBodySizeChange(true);
		}
		
		public function hide():void {
			visible = false;
		}
		
		public function getSelectedGroupTsid():String {
			var i:int;
			var checkbox:Checkbox;
			
			for(i; i < checkboxes.length; i++){
				checkbox = checkboxes[int(i)];
				if(checkbox.visible && checkbox.checked) return checkbox.value;
			}
			
			return null;
		}
		
		private function draw():void {
			scroller.w = _w + SCROLL_BAR_W/2;
			scroller.h = _h;
			
			title_tf.x = int(_w/2 - title_tf.width/2);
		}
		
		private function onCheckClick(event:TSEvent):void {
			//go through the current checkboxes and uncheck them all except the one that was checked
			var i:int;
			var checkbox:Checkbox = event.data as Checkbox;
			
			//don't want no stinkin' disabled ones
			if(checkbox && checkbox.alpha == DISABLED_ALPHA) {
				checkbox.checked = false;
				return;
			}
			
			for(i; i < checkboxes.length; i++){
				checkboxes[int(i)].checked = false;
			}
			
			checkbox.checked = true;
		}
		
		public function set w(value:int):void {
			_w = value;
			draw();
		}
		public function set h(value:int):void {
			_h = value;
			draw();
		}
		
		override public function get w():int {
			return _w;
		}
		
		override public function get h():int {
			return title_tf.height + _h;
		}
	}
}