package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	public class TrophyCaseSlot extends TSSpriteWithModel implements IDragTarget, ITipProvider
	{
		private var slot_graphic:DisplayObject;
		
		private var _slot_icon:Sprite = new Sprite();
		private var _slot_icon_padding:int = 1;
		private var _slot_icon_wh:int;
		private var _item_class:String;
		private var _itemstack:Itemstack;
		private var _is_empty:Boolean;
		private var _type:String;
		
		public var slot:int;
		
		public function TrophyCaseSlot(w:int, h:int, slot:int, type:String){
			super();
			_w = w;
			_h = h;
			this.slot = slot;
			_slot_icon_wh = _w - _slot_icon_padding*2;
			_type = type;
			
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			
			isEmpty = true;
			
			_slot_icon.x = _slot_icon_padding;
			_slot_icon.y = _slot_icon_padding;
			addChild(_slot_icon);
			
			mouseChildren = false;
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if (!_itemstack) return null;
			var item:Item = model.worldModel.getItemByItemstackId(_itemstack.tsid);
			var tsid_str:String = '';
			CONFIG::god {
				tsid_str = ' '+_itemstack.tsid;
			}
			return {
				
				txt: ((_itemstack.count>1) ? _itemstack.count+'&nbsp;'+item.label_plural : getLabel())+tsid_str,
					offset_y: -7,
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		public function getLabel():Object {
			if (!_itemstack) return null;
			var item:Item = model.worldModel.getItemByItemstackId(_itemstack.tsid);
			var label:String = (_itemstack.label && _itemstack.label != item.label) ? _itemstack.label : item.label;
			return label;
		}
		
		public function update(itemstack:Itemstack):void {						
			if(itemstack != null){
				if (itemstack.class_tsid != _item_class) {
					_item_class = itemstack.class_tsid;
					while(_slot_icon.numChildren > 0) _slot_icon.removeChildAt(0);
					_slot_icon.addChild(new ItemIconView(_item_class, _slot_icon_wh));
					_slot_icon.y = 5;
					isEmpty = false;
				}
				_itemstack = itemstack;
				
				TipDisplayManager.instance.registerTipTrigger(this);
			}else{
				_item_class = null;
				while(_slot_icon.numChildren > 0) _slot_icon.removeChildAt(0);
				isEmpty = true;
				_itemstack = null;
				
				TipDisplayManager.instance.unRegisterTipTrigger(this);
			}
		}
		
		public function get item_class():String {
			return _item_class;
		}
		
		public function get icon():Sprite {
			return _slot_icon;
		}
		
		public function get padding():int {
			return _slot_icon_padding;
		}
		
		public function get icon_wh():int {
			return _slot_icon_wh;
		}
		
		public function get itemstack():Itemstack {
			return _itemstack;
		}
		
		public function get type():String {
			return _type;
		}
		
		public function get isEmpty():Boolean {
			return _is_empty;
		}
		
		public function set isEmpty(value:Boolean):void {
			_is_empty = value;
			if(slot_graphic) removeChild(slot_graphic);
			
			if(value){
				while(_slot_icon.numChildren > 0) _slot_icon.removeChildAt(0);
				
				if(_type == 'display'){
					slot_graphic = new AssetManager.instance.assets.trophy_display_slot_empty();
				}else{
					slot_graphic = new AssetManager.instance.assets.cabinet_slot_empty();
				}
				addChildAt(slot_graphic, 0);
			}else{
				slot_graphic = null;
				//slot_graphic = new AssetManager.instance.assets.cabinet_slot_full();
			}
			
			
		}
		
		public function unhighlightOnDragOut():void {
			if(slot_graphic) slot_graphic.filters = null;
			if(!_item_class && !_is_empty){
				//they didn't drop anything, throw it back to the old look
				isEmpty = true;
			}
		}
		
		public function highlightOnDragOver():void {
			if(slot_graphic) slot_graphic.filters = StaticFilters.slot_GlowA;
		}
		
		public function highlightEmpty():void {
			_item_class = null;
			isEmpty = false;
			highlightOnDragOver();
		}
	}
}