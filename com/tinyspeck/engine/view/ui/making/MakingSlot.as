package com.tinyspeck.engine.view.ui.making {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.ItemstackStatusBar;
	import com.tinyspeck.engine.port.QuantityPicker;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.*;
	import flash.text.*;
	
	public class MakingSlot extends TSSpriteWithModel implements IDragTarget, ITipProvider {
		public static const MAX_COUNT:uint = 9999;
		
		private const STATUS_BAR_HEIGHT:uint = 4;
		
		public var has_tweened:Boolean = false;
		public var itemstack_tsid:String;
		public var item_label:String;
		
		private var slot_graphic:Sprite = new Sprite();
		private var icon_view:ItemIconView;
		private var icon_wh:int;
		private var lit:Boolean = false;
		private var show_quantity_picker:Boolean = true;
		private var itemstack_status_bar:ItemstackStatusBar;
		private var count_label:TextField = new TextField();
		private var current_item:Item;
		
		private var _icon_sprite:Sprite = new Sprite();
		private var _close_bt:DisplayObject;
		private var _quantity_qp:QuantityPicker;
		private var _item_class:String;
		private var _item_count:int;
		private var _padd:int = 10;
		private var show_quantity_on_icon:Boolean;
		
		public function MakingSlot(w:int, h:int):void {
			super();
			
			_w = w;
			_h = h;
			icon_wh = _w-(_padd*2);
						
			_construct();
		}
		
		public function get icon_sprite():Sprite {
			return _icon_sprite;
		}
		
		public function get icon_sprite_y():int {
			return _padd;
		}
		
		override protected function _construct():void {
			super._construct();
			
			var g:Graphics = slot_graphic.graphics;
			g.beginFill(0xffffff);
			g.lineStyle(1, 0xc8cecf, 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			g.drawRoundRect(0, 0, _w, _h, 10);
			addChild(slot_graphic);
			
			_icon_sprite.x = _padd;
			_icon_sprite.y = _padd;
			_icon_sprite.mouseEnabled = false;
			addChild(_icon_sprite);
			
			// close button
			_close_bt = new Button({
				graphic: new AssetManager.instance.assets.close_x_making_slot(),
				name: '_close_bt',
				h: 20,
				w: 20,
				x: _w-20+2,
				y: -2,
				no_draw: true
			});
			addChild(_close_bt);
			_close_bt.addEventListener(TSEvent.CHANGED, onCloseClick);
			
			// quantity picker
			_quantity_qp = new QuantityPicker({
				w: _w,
				h: 20,
				name: '_quantity_qp',
				minus_graphic: new AssetManager.instance.assets.minus_red_small(),
				plus_graphic: new AssetManager.instance.assets.plus_green_small(),
				max_value: 1,
				min_value: 1,
				button_wh: 17,
				button_padd: 2
			});
			_quantity_qp.x = Math.round((_w-_quantity_qp.width)/2)+1; // +1 because of the stroke on the slot
			_quantity_qp.y = _h + 5;
			
			_quantity_qp.visible = false;
			
			addChild(_quantity_qp);
			
			// count label
			count_label.styleSheet = CSSManager.instance.styleSheet;
			count_label.antiAliasType = AntiAliasType.ADVANCED;
			count_label.embedFonts = true;
			count_label.autoSize = TextFieldAutoSize.RIGHT;
			count_label.mouseEnabled = false;
			count_label.x = _w-6;
			
			addChild(count_label);
		}
		
		public function get item_class():String {
			return _item_class;
		}
		
		public function get count():int {
			if(_quantity_qp.visible){
				return parseInt(_quantity_qp.value);
			}else{
				return _item_count;
			}
		}
		
		public function get close_button():DisplayObject {
			return _close_bt;
		}
		
		public function get qty_picker():QuantityPicker { return _quantity_qp; }
		
		public function update(item_class:String, count:int, show_quantity_qp:Boolean, 
							   show_quantity_on_icon:Boolean = false, furn_config:FurnitureConfig=null, force:Boolean=false):void {
			//if (item_class) Console.error(item_class, count, furn_config)
			
			var real_count:int = Math.min(model.worldModel.pc.hasHowManyItems(item_class), count);
			var has_count:int = model.worldModel.pc.hasHowManyItems(item_class);
			var icon_state:String = 'iconic';
			
			_quantity_qp.visible = show_quantity_qp;
			show_quantity_picker = show_quantity_qp;
			this.show_quantity_on_icon = show_quantity_on_icon;
			
			//set the current item so we can get the stackmax
			current_item = item_class ?  model.worldModel.getItemByTsid(item_class) : null;
						
			//remove the status bar if it's there
			if(itemstack_status_bar && contains(itemstack_status_bar)) removeChild(itemstack_status_bar);
						
			if (real_count || show_quantity_on_icon) {
				_quantity_qp.max_value = Math.min(has_count, current_item ? current_item.stackmax : has_count, MAX_COUNT);
				_quantity_qp.value = Math.min(real_count, current_item ? current_item.stackmax : real_count, MAX_COUNT);
				
				if (item_class != _item_class || force) {
					_item_class = item_class;
					if (itemstack_tsid) icon_state = model.worldModel.getItemstackByTsid(itemstack_tsid).itemstack_state.value || icon_state;
					if (_icon_sprite.numChildren) _icon_sprite.removeChild(_icon_sprite.getChildAt(0));
					icon_view = new ItemIconView(_item_class, icon_wh, {state:icon_state, config:furn_config});
					_icon_sprite.addChild(icon_view);
				}
				
				if(show_quantity_on_icon){
					_item_count = count;
					count_label.htmlText = (count > 1) ? '<p class="trade_slot_label">'+count+'</p>' : '';
					count_label.y = int(_h - count_label.height);
					_close_bt.visible = false;
				}else{
					count_label.htmlText = '';
					_close_bt.visible = true;
				}
				
				TipDisplayManager.instance.registerTipTrigger(slot_graphic);
				
			} else {
				_item_class = null;
				if (_icon_sprite.numChildren) _icon_sprite.removeChild(_icon_sprite.getChildAt(0));
				item_label = null;
				icon_view = null;
				itemstack_status_bar = null;
				
				TipDisplayManager.instance.unRegisterTipTrigger(slot_graphic);
			}
			
			if(show_quantity_qp){
				//if it's visible let's add a listener for changes
				if(!_quantity_qp.hasEventListener(TSEvent.QUANTITY_CHANGE)){
					_quantity_qp.addEventListener(TSEvent.QUANTITY_CHANGE, onQuantityChange, false, 0, true);
					_quantity_qp.addEventListener(TSEvent.CHANGED, onChange, false, 0, true);
				}
			}else{
				if(_quantity_qp.hasEventListener(TSEvent.QUANTITY_CHANGE)){
					_quantity_qp.removeEventListener(TSEvent.QUANTITY_CHANGE, onQuantityChange);
					_quantity_qp.removeEventListener(TSEvent.CHANGED, onChange);
				}
			}
		}
		
		public function update_tool(capacity:int, remaining:int, is_broken:Boolean):void {
			if(!itemstack_status_bar){
				itemstack_status_bar = new ItemstackStatusBar(_w-_padd, STATUS_BAR_HEIGHT);
				itemstack_status_bar.x = _padd/2
				itemstack_status_bar.y = _h - STATUS_BAR_HEIGHT - _padd/2;
			}
			
			addChild(itemstack_status_bar);
			
			itemstack_status_bar.update(capacity, remaining, is_broken);
			
			//set the position of the icon
			if(capacity > 0 || is_broken){
				_icon_sprite.y = _padd - 2; //full bar height seemed too much
			}else{
				_icon_sprite.y = _padd;
			}
			
			//if it's broken, change how it looks
			if(is_broken){
				if(icon_view.s != 'broken_iconic'){
					if(_icon_sprite.numChildren) _icon_sprite.removeChild(_icon_sprite.getChildAt(0));
					icon_view = new ItemIconView(_item_class, icon_wh, 'broken_iconic');
					_icon_sprite.addChild(icon_view);
				} 
			}else{
				if(icon_view.s != 'iconic'){
					if(_icon_sprite.numChildren) _icon_sprite.removeChild(_icon_sprite.getChildAt(0));
					icon_view = new ItemIconView(_item_class, icon_wh);
					_icon_sprite.addChild(icon_view);
				} 
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
						
			var txt:String = StringUtil.formatNumberWithCommas(count) + '&nbsp;';
			
			if(item_label){
				txt += item_label;
			}
			else if(itemstack_tsid) {
				//let's see if we already know about this item
				var item:Item = model.worldModel.getItemByItemstackId(itemstack_tsid);
				if(item){
					txt += count != 1 ? item.label_plural : item.label;
				}
				else {
					//we don't know anything about this, so let's trust the server
					var itemstack:Itemstack = model.worldModel.getItemstackByTsid(itemstack_tsid);
					if(itemstack){
						txt += itemstack.label;
					}
				}
			}
			
			return {
				txt: txt,
				offset_y: -4,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		public function unhighlightOnDragOut():void {
			if (!lit) return;
			lit = false;
			slot_graphic.filters = null;
		}
		
		public function highlightOnDragOver():void {
			if (lit) return;
			lit = true;
			slot_graphic.filters = StaticFilters.slot_GlowA;
		}
		
		public function set max_value(value:int):void {
			_quantity_qp.max_value = Math.min(value, current_item ? current_item.stackmax : value, MAX_COUNT);
		}
		
		public function get count_tf():TextField {
			return count_label;
		}
		
		public function set icon_padd(value:int):void {
			_padd = value;
			_icon_sprite.x = _padd;
			_icon_sprite.y = _padd;
			icon_wh = _w-(_padd*2);
			
			//refresh it
			update(item_class, count, show_quantity_picker, show_quantity_on_icon);
		}
		
		private function onCloseClick(event:TSEvent):void {
			update('', 0, show_quantity_picker);
			dispatchEvent(new TSEvent(TSEvent.CLOSE, this));
			has_tweened = false;
		}
		
		private function onQuantityChange(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.QUANTITY_CHANGE, this));
		}
		
		private function onChange(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
	}
}