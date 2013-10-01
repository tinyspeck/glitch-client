package com.tinyspeck.engine.view.itemstack {
	
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.ItemstackStatusBar;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class PackItemstackView extends AbstractItemstackView implements ITipProvider {
		private const STATUS_BAR_HEIGHT:uint = 3;
		
		private var count_holder:Sprite = new Sprite();
		private var count_tf:TextField = new TextField();
		private var itemstack_status_bar:ItemstackStatusBar;
		public var wh:int;
		
		public function PackItemstackView(tsid:String, wh:int):void {
			super(tsid);
			this.wh = wh;
			_animateXY_duration = .35;
			_construct();
			buttonMode = true;
			useHandCursor = true;
			
			//put the tool state on
			updateToolState();
		}
		
		override protected function _construct():void {
			animate(false, wh);
			
			// we're not set up for this here. (no resizing is done after a new sceene is set, at the least, probably other problems woudl need to be workd though too)
			//use_mc = CSSManager.instance.getBooleanValueFromStyle('use_mc', itemstack.class_tsid);
			
			graphics.beginFill(0xCC0000, 0);
			graphics.drawRect(0, 0, wh, wh);
			
			var newFormat:TextFormat = new TextFormat();
			newFormat.color = 0x676767;
			newFormat.size = 10;
			newFormat.font = 'Arial';
			newFormat.bold = true;
			count_tf.defaultTextFormat = newFormat;
			count_tf.selectable = false;
			count_tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			count_tf.thickness = -200;
			count_tf.sharpness = 400;
			count_tf.filters = StaticFilters.disconnectScreen_GlowA;
			count_tf.multiline = false;
			count_tf.wordWrap = false;
			
			count_holder.addChild(count_tf);
			count_holder.visible = false;
			//addChild(_count_mc);
			
			super._construct();
			//changeHandler();
		}
		
		// make sure we always specify at_wh for this pack itemstacks! otherwise, blurry
		override protected function animate(force:Boolean = false, at_wh:int = 0):void {
			if (!at_wh) at_wh = wh;
			super.animate(force, at_wh);
		}
		
		public function get slot():int {
			return _itemstack.slot;
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
			
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			var tsid_str:String = '';
			CONFIG::god {
				tsid_str = '<br><span class="pack_itemstack_desc_tip">'+tsid+'</span>';
			}
			
			if (_itemstack.tooltip_label) {
				return {
					txt: '<span class="pack_itemstack_name_tip">'+_itemstack.tooltip_label+'</span>'+tsid_str,
					offset_y: -7,
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			}
			
			return {
				txt: '<span class="pack_itemstack_name_tip">'+
					  		((_itemstack.count>1) ? _itemstack.count+'&nbsp;'+_item.label_plural : _itemstack.getLabel())+
					  '</span>'+
					  tsid_str,
				offset_y: -7,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		override protected function onLoadDone():void {
			if (disposed) return;
			PackDisplayManager.instance.onPISViewLoaded();
		}
		
		override protected function _positionViewDO():void {
			var view_do:DisplayObject;
			if (use_mc) {
				view_do = _mc as DisplayObject;
			} else {
				view_do = ss_view as DisplayObject;
			}
			
			var scale_it:Boolean = true;
			
			if (!view_do) {
				if (!placeholder.parent) view_holder.addChild(placeholder);
				view_do = placeholder;
				scale_it = false;
			} else if (placeholder.parent) {
				placeholder.parent.removeChild(placeholder);
			}
			
			// move this to default position so measuring works!
			view_do.x = view_do.y = 0;

			// hmmm, of course we should do this, right? else view_do.width below will reflect any previous scale applied, and measurement will be off
			view_do.scaleX = view_do.scaleY = 1;
			
			if (scale_it) {
				if (view_do.width > view_do.height) {
					view_do.scaleX = view_do.scaleY = wh/view_do.width;
				} else {
					view_do.scaleX = view_do.scaleY = wh/view_do.height;
				}
			}
			
			var rect:Rectangle = view_do.getBounds(view_holder);
				
			view_do.x = Math.round(-rect.x+(wh-view_do.width)/2);
			view_do.y = Math.round(-rect.y+(wh-view_do.height)/2);
			
			view_do.visible = true;
			
			_changeText();
		}
		
		private function _changeText():void {
			if (_itemstack.count < 2) {
				count_holder.visible = false;
			} else {
				count_holder.visible = true;
				addChild(count_holder);
				count_tf.text = String(_itemstack.count);
				count_tf.width = count_tf.textWidth+4;
				count_tf.height = count_tf.textHeight+4;
				
				count_holder.x = wh-count_holder.width+4; // 3 is to make it go to the edge of the pack frame
				count_holder.y = wh-count_holder.height+7;
			}
		}
		
		private function updateToolState():void {
			if(_itemstack.tool_state){
				if(!itemstack_status_bar){
					itemstack_status_bar = new ItemstackStatusBar(wh, STATUS_BAR_HEIGHT);
					itemstack_status_bar.y = wh;
					addChild(itemstack_status_bar);
				}
								
				itemstack_status_bar.update(_itemstack.tool_state.points_capacity, _itemstack.tool_state.points_remaining, _itemstack.tool_state.is_broken);
				
				//things may have got jacked up with a tool icon change, let's make sure it looks ok
				var rect:Rectangle = view_holder.getBounds(view_holder);
				if(view_holder.width > 0){
					view_holder.x = int(-rect.x+(wh-view_holder.width)/2);
				}
				
				//set the position of the icon
				if(_itemstack.tool_state.points_capacity > 0 || _itemstack.tool_state.is_broken){
					view_holder.y = ((view_holder.height > 0) ? int(-rect.y+(wh-view_holder.height)/2) : 0) - STATUS_BAR_HEIGHT;
				}else{
					view_holder.y = 0;
				}
			}
		}
		
		public function changeHandler():void {
			_changeText();
			
			if (reloadIfNeeded()) {
				return;
			}
			
			// this may cause troubles; watch for itemstacks that move from the location to the pack that have a state already set.
			// we may have to null out itemstack.s when moving it to the pack if this causes problems.
			animate(false, wh); // this does
			
			updateToolState();
			
			// reposition this for the new state
			_positionViewDO();
			
			//this might be useful other than new chrome
			//but this is here so PackSlots can handle the counts and
			//leave this to showing the item graphics/tool states only
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
		
	}
}