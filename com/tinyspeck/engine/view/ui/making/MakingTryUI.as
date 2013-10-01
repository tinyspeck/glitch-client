package com.tinyspeck.engine.view.ui.making
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.MakingManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class MakingTryUI extends TSSpriteWithModel
	{
		private static const ALLOWED_ITEMS:Array = new Array('element_red', 'element_green', 'element_blue', 'element_shiny');
		private static const SLOT_WH:uint = 67;
		private static const SLOT_PADD:uint = 15;
		private static const OFFSET_Y:uint = 60;
		
		private var dragVO:DragVO = DragVO.vo;
		private var empty_slot:MakingSlotEmpty = new MakingSlotEmpty();
		private var try_bt:Button;
		
		private var slots_holder:Sprite = new Sprite();
		
		private var max_slots:int;
		
		public function MakingTryUI(){
			slots_holder.y = OFFSET_Y;
			addChild(slots_holder);
			
			empty_slot.tf.htmlText = '<span class="making_slot_empty">Drag elements from your pouch</span>';
			empty_slot.y = OFFSET_Y;
			empty_slot.placeTextBelowSlot(true);
			addChild(empty_slot);
			
			try_bt = new Button({
				name: 'try',
				label: 'Try it!',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			try_bt.addEventListener(TSEvent.CHANGED, onTryClick, false, 0, true);
			try_bt.visible = false;
			addChild(try_bt);
		}
		
		public function start(max_slots:int):void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRect(0, 0, _w, _h);
			
			this.max_slots = max_slots;
			
			//reset the slots
			buildSlots();
			afterSlotChange(true);
			enabled = true;
			
			//position the try button
			try_bt.x = int(_w/2 - try_bt.width/2);
			try_bt.y = int(slots_holder.y + slots_holder.height + 25);
			
			TSFrontController.instance.disableDropToFloor();
			
			//listen to the pack
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, onDragStart, false, 0, true);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, onDragComplete, false, 0, true);
		}
		
		public function stop():void {
			
			TSFrontController.instance.enableDropToFloor();
			
			//stop listening to the pack
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_STARTED, onDragStart);
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onDragComplete);
		}
		
		private function buildSlots():void {
			if(slots_holder.numChildren != max_slots){
				SpriteUtil.clean(slots_holder);
				
				var i:int;
				var ms:MakingSlot;
				
				for(i; i < max_slots; i++){				
					ms = new MakingSlot(SLOT_WH, SLOT_WH);
					ms.addEventListener(TSEvent.CLOSE, onSlotCloseClick, false, 0, true);
					slots_holder.addChild(ms);
				}
			}
		}
		
		private function onDragStart(event:TSEvent):void {
			//we don't want no stinking bags
			if(dragVO.dragged_itemstack.slots) return;
			if(ALLOWED_ITEMS.indexOf(dragVO.dragged_itemstack.class_tsid) == -1) return;
			
			StageBeacon.mouse_move_sig.add(onDragMove);
		}
		
		private function onDragMove(event:MouseEvent):void {
			if(this.hitTestObject(Cursor.instance.drag_DO)) {
				var ms:MakingSlot = findEmptySlotOrSlotWithThisItem(dragVO.dragged_itemstack.class_tsid);

				if(dragVO.target != ms) {
					if(dragVO.target) dragVO.target.unhighlightOnDragOut();
					Cursor.instance.showTip('Add');
					dragVO.target = ms; // tuck a reference to the makingSlot in the dragVO
					if(ms.item_class) {
						ms.highlightOnDragOver();
					} 
					else {
						empty_slot.highlight();
					}
				}
			} 
			//item isn't here anymore, shut down the glows
			else {
				if(dragVO.target && dragVO.target is MakingSlot) {
					dragVO.target.unhighlightOnDragOut();
					dragVO.target = null;
					Cursor.instance.hideTip();
				}
				empty_slot.unhighlight();
			}
		}
		
		private function onDragComplete(event:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(onDragMove);
			
			Cursor.instance.hideTip();
			empty_slot.unhighlight();
			
			//drop it in the right place
			if(dragVO.target && dragVO.target is MakingSlot) {
				dragVO.target.unhighlightOnDragOut();
				addItemToSlot(dragVO.dragged_itemstack);
			}
		}
		
		private function addItemToSlot(itemstack:Itemstack):void {
			if(!itemstack) return;
			if(itemstack.slots) return;
			
			var specify_quantities:Boolean = true;
			var item_class:String = itemstack.class_tsid;
			var ms:MakingSlot = findEmptySlotOrSlotWithThisItem(item_class);
			if (!ms) return;
			
			ms.itemstack_tsid = itemstack.tsid;
			if(ms.count && ms.visible && ms.item_class == item_class && specify_quantities) {
				ms.update(item_class, ms.count+1, specify_quantities);
			} 
			else {
				ms.update(item_class, 1, specify_quantities);
			}
			
			afterSlotChange();
		}
		
		private function findEmptySlotOrSlotWithThisItem(class_tsid:String):MakingSlot {
			var ms:MakingSlot;
			var first_empty_ms:MakingSlot;
			var already_ms:MakingSlot;
			var i:int;
			
			for(i; i < slots_holder.numChildren; i++) {
				ms = slots_holder.getChildAt(i) as MakingSlot;
				
				if(!ms.item_class && !first_empty_ms) {
					first_empty_ms = ms;
				} 
				else if (ms.item_class == class_tsid) {
					already_ms = ms
				}
			}
			
			if (already_ms) return already_ms;
			if (first_empty_ms) return first_empty_ms;
			
			return null;
		}
		
		private function afterSlotChange(reset:Boolean = false):void {
			var i:int = 0;
			var how_many_full:int = 0;
			var ms:MakingSlot;
			var new_x:int;
			var itemstack:Itemstack;
			var item_totals:Object = {};
			var item:Item;
			var specify_quantities:Boolean = true;
			
			for (i; i < max_slots; i++) {
				ms = MakingSlot(slots_holder.getChildAt(i));
				if(reset){
					ms.update('', 0, true);
					new_x = 0;
				}
				
				ms.x = new_x;

				if(ms.item_class) {
					how_many_full++;
					ms.visible = true;
					item_totals[ms.item_class] = int(item_totals[ms.item_class]) + ms.count;
					new_x += SLOT_WH + SLOT_PADD;
				}
				else{
					ms.visible = false;
					ms.x = 0;
				}
			}
			
			//setup the +/- buttons
			var remainder:int;
			for (i = 0; i < max_slots; i++) {
				ms = MakingSlot(slots_holder.getChildAt(i));
				if(ms.item_class){
					item = model.worldModel.getItemByTsid(ms.item_class);
					remainder = model.worldModel.pc.hasHowManyItems(ms.item_class) - item_totals[ms.item_class];
					
					ms.max_value = Math.min(item.stackmax, ms.count + remainder);
				}
			}
			
			//how to display the empty slot
			empty_slot.visible = how_many_full < max_slots;
			empty_slot.arrow.visible = empty_slot.tf.visible = how_many_full == 0;
			slots_holder.visible = try_bt.visible = how_many_full > 0;
			
			//center it
			slots_holder.x = int(_w/2 - (slots_holder.width + (empty_slot.visible ? empty_slot.slot_width + SLOT_PADD : 0))/2);
			
			//move the empty slot 1 ahead of the one we just dropped
			new_x = slots_holder.x + slots_holder.width + SLOT_PADD;
			if(empty_slot.x != new_x) {
				if(reset) {
					empty_slot.x = new_x;
				}
				else {
					TSTweener.removeTweens(empty_slot);
					TSTweener.addTween(empty_slot, {x:new_x, time:.3});
				}
			}
			
			if(how_many_full >= max_slots) {
				empty_slot.x = int(slots_holder.x + slots_holder.width - empty_slot.slot_width);
			}
			else if(how_many_full == 0){
				empty_slot.x = int(_w/2 - empty_slot.slot_width/2);
			}
		}
		
		private function onSlotCloseClick(event:TSEvent):void {
			//just run the add slot thing again			
			afterSlotChange();
		}
		
		private function onTryClick(event:TSEvent):void {
			//get the slots that have items and fire em off to the server
			var i:int;
			var ms:MakingSlot;
			var inputs:Array = new Array();
			
			for(i; i < slots_holder.numChildren; i++){
				ms = slots_holder.getChildAt(i) as MakingSlot;
				if(ms.item_class) inputs.push([ms.item_class, ms.count]);
			}
			
			if(inputs.length){
				MakingManager.instance.makeUnknownRecipe(inputs);
			}
			
			enabled = false;
		}
		
		public function setWidthAndHeight(w:int, h:int):void {
			_w = w;
			_h = h;
		}
		
		public function set enabled(value:Boolean):void {
			try_bt.disabled = !value;
		}
	}
}