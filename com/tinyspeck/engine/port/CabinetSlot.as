package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class CabinetSlot extends TSSpriteWithModel implements IDragTarget, ITipProvider
	{
		private var slot_graphic:DisplayObject;
		private var count_tf:TextField = new TextField();
		
		private var _icon:Sprite = new Sprite();
		private var _icon_padding:int = 5;
		private var _icon_wh:int;
		private var _item_class:String;
		private var _itemstack:Itemstack;
		private var _count:int;
		private var _is_empty:Boolean;
		public var slot:int;
		
		public function CabinetSlot(w:int, h:int, slot:int){
			super();
			_w = w;
			_h = h;
			this.slot = slot;
			_icon_wh = _w - _icon_padding*2;
			
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			
			isEmpty = true;
			
			_icon.x = _icon_padding;
			_icon.y = _icon_padding;
			_icon.mouseEnabled = false;
			addChild(_icon);
			
			TFUtil.prepTF(count_tf, false);
			count_tf.filters = StaticFilters.disconnectScreen_GlowA;
			addChild(count_tf);
			
			mouseChildren = false;
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if (!_itemstack) return null;
			var tsid_str:String = '';
			CONFIG::god {
				tsid_str = ' '+_itemstack.tsid;
			}
			return {
				
				txt: ((_itemstack.count>1) ? _itemstack.count+'&nbsp;'+_itemstack.item.label_plural : getLabel())+tsid_str,
					offset_y: -7,
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
			};
		}
		
		public function getLabel():Object {
			if (!_itemstack) return null;
			var label:String = (_itemstack.label && _itemstack.label != _itemstack.item.label) ? _itemstack.label : _itemstack.item.label;
			return label;
		}
		
		public function update(itemstack:Itemstack):void {			
			var item_count:int = 0;
			var view_state:String = 'iconic';
			
			if(itemstack != null){
				if (itemstack.class_tsid != _item_class) {
					SpriteUtil.clean(_icon);
					if(itemstack.tool_state && itemstack.tool_state.is_broken) view_state = 'broken_iconic';
					
					_item_class = itemstack.class_tsid;
					
					_icon.addChild(new ItemIconView(_item_class, _icon_wh, view_state));
					isEmpty = false;
				}
				item_count = itemstack.count;
				_itemstack = itemstack;
				
				TipDisplayManager.instance.registerTipTrigger(this);
			}else{
				_item_class = null;
				while(_icon.numChildren > 0) _icon.removeChildAt(0);
				isEmpty = true;
				_itemstack = null;
				
				TipDisplayManager.instance.unRegisterTipTrigger(this);
			}
			
			count = item_count;
		}
		
		public function get item_class():String {
			return _item_class;
		}
		
		public function get count():int {
			return _count;
		}
		
		public function set count(value:int):void {
			_count = value;
			
			if(value == 0){ 
				count_tf.htmlText = '';
				return;
			}
			
			count_tf.htmlText = '<p class="cabinet_slot_count">'+value+'</p>';
			count_tf.x = _w - count_tf.width;
			count_tf.y = _h - count_tf.height;
		}
		
		public function get icon():Sprite {
			return _icon;
		}
		
		public function get padding():int {
			return _icon_padding;
		}
		
		public function get icon_wh():int {
			return _icon_wh;
		}
		
		public function get itemstack():Itemstack {
			return _itemstack;
		}
		
		public function get isEmpty():Boolean {
			return _is_empty;
		}
		
		public function set isEmpty(value:Boolean):void {
			_is_empty = value;
			if(slot_graphic) removeChild(slot_graphic);
			
			if(value){
				count_tf.htmlText = '';
				while(_icon.numChildren > 0) _icon.removeChildAt(0);
				slot_graphic = new AssetManager.instance.assets.cabinet_slot_empty();
			}else{
				slot_graphic = new AssetManager.instance.assets.cabinet_slot_full();
			}
			
			useHandCursor = buttonMode = !value;
			
			addChildAt(slot_graphic, 0);
		}
		
		public function unhighlightOnDragOut():void {
			slot_graphic.filters = null;
			if(!_item_class && !_is_empty){
				//they didn't drop anything, throw it back to the old look
				isEmpty = true;
			}
		}
		
		public function highlightOnDragOver():void {
			slot_graphic.filters = StaticFilters.slot_GlowA;
		}
		
		public function highlightEmpty():void {
			_item_class = null;
			isEmpty = false;
			highlightOnDragOver();
		}
	}
}