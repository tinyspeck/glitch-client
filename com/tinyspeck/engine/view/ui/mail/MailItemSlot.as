package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.engine.data.item.Item;
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
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class MailItemSlot extends TSSpriteWithModel implements IDragTarget, ITipProvider
	{
		private static const ITEM_PADD:uint = 5;
		
		private static var border_color:int = -1;
		
		private var qty_picker:QuantityPicker;
		private var item_view:ItemIconView;
		private var itemstack_status_bar:ItemstackStatusBar;
		
		private var empty_holder:Sprite = new Sprite();
		private var empty_bg:Sprite = new Sprite();
		private var full_holder:Sprite = new Sprite();
		private var item_holder:Sprite = new Sprite();
		private var close_holder:Sprite = new Sprite();
		private var outline:DisplayObject;
		
		private var tf:TextField = new TextField();
		private var how_many_tf:TextField = new TextField();
		
		private var slot_wh:uint;
		
		private var _itemstack_tsid:String;
		
		public function MailItemSlot(){
			//the stuff for the empty view
			const padd_x:uint = 3;
			const arrow:DisplayObject = new AssetManager.instance.assets.mail_item_arrow();
			
			outline = new AssetManager.instance.assets.mail_item_empty();
			empty_holder.addChild(outline);
			
			var g:Graphics = empty_bg.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRect(2, 2, outline.width-4, outline.height-4, 6);
			empty_holder.addChildAt(empty_bg, 0);
			
			//set the slot w/h to be the same as the height of the outline
			slot_wh = outline.height;
			
			arrow.x = outline.width - 18;
			arrow.y = int(outline.height/2 - arrow.height/2);
			empty_holder.addChild(arrow);
			
			TFUtil.prepTF(tf);
			tf.x = padd_x;
			tf.y = 1; //visual tweak
			tf.width = arrow.x - padd_x;
			tf.htmlText = '<p class="mail_item_slot">To attach, drag an item here from your pack</p>';
			empty_holder.addChild(tf);
			
			addChild(empty_holder);
			
			//stuff for the full view
			if(border_color == -1){
				border_color = CSSManager.instance.getUintColorValueFromStyle('mail_item_slot', 'borderColor', 0xc8cecf);
			}
			
			g = item_holder.graphics;
			g.lineStyle(1, border_color);
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, slot_wh, slot_wh, 6);
			full_holder.addChild(item_holder);
			
			const status_padd:uint = 2;
			itemstack_status_bar = new ItemstackStatusBar(slot_wh - status_padd*2, 4);
			itemstack_status_bar.x = status_padd;
			itemstack_status_bar.y = slot_wh - 6; //height - padd
			item_holder.addChild(itemstack_status_bar);
			
			TFUtil.prepTF(how_many_tf);
			how_many_tf.htmlText = '<p class="mail_item_slot_how_many">How many?</p>';
			how_many_tf.width = 70;
			how_many_tf.x = slot_wh + 13;
			how_many_tf.y = -10;
			full_holder.addChild(how_many_tf);
			
			qty_picker = new QuantityPicker({
				w: how_many_tf.width,
				h: 20,
				name: 'qty_picker',
				minus_graphic: new AssetManager.instance.assets.minus_red_small(),
				plus_graphic: new AssetManager.instance.assets.plus_green_small(),
				min_value: 1,
				button_wh: 17,
				button_padd: 2
			});
			qty_picker.x = how_many_tf.x;
			qty_picker.y = int(how_many_tf.y + how_many_tf.height);
			qty_picker.addEventListener(TSEvent.QUANTITY_CHANGE, onQuantityChange, false, 0, true);
			full_holder.addChild(qty_picker);
			
			const close:DisplayObject = new AssetManager.instance.assets.close_x_making_slot();
			close_holder.addChild(close);
			close_holder.x = slot_wh - close.width/2;
			close_holder.y = -close.height/2;
			close_holder.buttonMode = close_holder.useHandCursor = true;
			close_holder.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			full_holder.addChild(close_holder);
			
			full_holder.visible = false;
			addChild(full_holder);
		}
		
		public function highlightOnDragOver():void {
			outline.visible = false;
			empty_bg.filters = StaticFilters.slot_GlowA;
		}
		
		public function unhighlightOnDragOut():void {
			outline.visible = true;
			empty_bg.filters = null;
		}
		
		public function get count():int {
			//if the full holder is visible, then get the qty picker count, otherwise it's 0
			if(full_holder.visible){
				return qty_picker.value;
			}
			else {
				return 0;
			}
		}
		
		public function get itemstack_tsid():String { return _itemstack_tsid; }
		public function set itemstack_tsid(value:String):void {
			_itemstack_tsid = value;
			
			//remove an item if it's there
			if(item_view && item_view.parent) item_view.parent.removeChild(item_view);
			
			//we are adding/changing an item, get some data about it
			if(value){
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(value);
				
				qty_picker.max_value = itemstack.count;
				qty_picker.value = itemstack.count;
								
				//see how many we have of the item if the stackmax is larger than 1
				if(itemstack.item){
					if(itemstack.item.stackmax > 1){
						const player_item_count:int = model.worldModel.pc ? model.worldModel.pc.hasHowManyItems(itemstack.class_tsid) : 1;
						qty_picker.max_value = Math.min(itemstack.item.stackmax, player_item_count, 999);
					}
					
					//see if this is a tool, and if so, update the status bar
					itemstack_status_bar.visible = itemstack.tool_state != null;

					var icon_state:String = itemstack.itemstack_state.value || 'iconic';
					
					if(itemstack.tool_state){						
						//update the status bar
						itemstack_status_bar.update(itemstack.tool_state.points_capacity, itemstack.tool_state.points_remaining, itemstack.tool_state.is_broken);
					}
					
					//show the item image
					item_view = new ItemIconView(
						itemstack.class_tsid,
						slot_wh - ITEM_PADD*2,
						itemstack.tool_state && itemstack.tool_state.is_broken ? 'broken_iconic' : {state:icon_state, config:itemstack.itemstack_state.furn_config}
					);
					item_view.x = ITEM_PADD;
					item_view.y = ITEM_PADD - (itemstack_status_bar.visible && itemstack_status_bar.capacity ? 2 : 0);
					item_holder.addChildAt(item_view, 0);
					
					empty_holder.visible = false;
					full_holder.visible = true;
				}
			}
			else {
				empty_holder.visible = true;
				full_holder.visible = false;
			}
			
			//let things know we've changed
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !itemstack_tsid) return null;
			
			//check to see if the mouse is over the item or not
			if(mouseX > slot_wh || mouseY > slot_wh) return null;
			
			const item:Item = model.worldModel.getItemByItemstackId(itemstack_tsid);
			var txt:String = StringUtil.formatNumberWithCommas(qty_picker.value) + '&nbsp;';
			
			if(item){
				//populate the right version on the label
				txt += qty_picker.value != 1 ? item.label_plural : item.label;
				
				//if the status bar is up, let's add it to the tip
				if(itemstack_status_bar.visible && itemstack_status_bar.capacity){
					txt += ' ('+(itemstack_status_bar.is_broken ? 'Broken' : itemstack_status_bar.remaining+'/'+itemstack_status_bar.capacity)+')';
				}
			}
			else {
				//can't find the item, no tip for you!
				return null;
			}
			
			return {
				txt: txt,
				offset_x: int(-width/2 + slot_wh/2),
				offset_y: -4,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		private function onCloseClick(event:MouseEvent):void {
			//null out the itemstack
			itemstack_tsid = null;
		}
		
		private function onQuantityChange(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.QUANTITY_CHANGE, qty_picker));
		}
	}
}