package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.storage.Cabinet;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingInventoryMoveVO;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.CabinetShelf;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSScroller;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;

	public class CabinetDialog extends Sprite implements IFocusableComponent, ILocItemstackAddDelConsumer, ILocItemstackUpdateConsumer
	{
		private const INTERIOR_PADDING_H:int = 8;
		private const INTERIOR_PADDING_W:int = 18;
		private const ITEM_PADDING:int = 4;
		private const ITEM_SIZE_WIDTH:int = 50;
		private const ITEM_SIZE_HEIGHT:int = 52;
		private const ROW_PADDING:int = 18;
		private const SLOT_NAME:String = 'slot';
		private const DRAG_THRESHOLD:int = 5;
		private const SCROLL_BAR_WH:uint = 12;
		
		private var blocker:Sprite = new Sprite();
		private var cabinet_holder:Sprite = new Sprite();
		private var cabinet_interior:Sprite = new Sprite();
		private var holder:Sprite = new Sprite();
		private var cabinet_mc:MovieClip;
		
		private var done_button:Button;
		private var cabinet:Cabinet;
		private var model:TSModelLocator;
		private var main_view:TSMainView;
		private var scroller:TSScroller;
		private var dragVO:DragVO = DragVO.vo;
		private var mouse_down_slot:CabinetSlot;
		private var mouse_move_slot:CabinetSlot;
		
		private var item_class:String;
		
		private var blocker_color:uint = 0x213036;
		private var blocker_alpha:Number = .85;
		private var cabinet_slot_count:int;
		private var itemstack:Itemstack;
		
		private var has_focus:Boolean;
		
		/* singleton boilerplate */
		public static const instance:CabinetDialog = new CabinetDialog();
		
		public function CabinetDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init():void {
			model = TSModelLocator.instance;
			registerSelfAsFocusableComponent();
			construct();
		}
		
		private function construct():void {
			blocker.name = 'blocker';
			cabinet_holder.name = 'cabinet_holder';
			cabinet_interior.name = 'cabinet_interior';
			holder.name = 'holder';
			
			
			main_view = TSFrontController.instance.getMainView();
			addChild(blocker);
			
			blocker_color = CSSManager.instance.getUintColorValueFromStyle('blocker', 'color', blocker_color);
			blocker_alpha = CSSManager.instance.getNumberValueFromStyle('blocker', 'alpha', blocker_alpha);
			
			addChild(holder);
			holder.addChild(cabinet_holder);
			
			done_button = new Button({
				label: 'Done',
				name: 'done_button',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_DEFAULT
			});
			
			done_button.addEventListener(MouseEvent.CLICK, end, false, 0, true);
			addChild(done_button);
			
			scroller = new TSScroller({
				name: 'cabinets',
				bar_wh: SCROLL_BAR_WH,
				/*
				bar_blend_mode: BlendMode.OVERLAY,
				bar_handle_min_h: 30,
				bar_handle_color: 0x919698,
				bar_handle_border_color: 0x919698,
				bar_handle_stripes_color: 0x626666,
				bar_border_color: 0x919698,
				show_arrows: true
				*/
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 36,
				scrolltrack_always: false,
				show_arrows: true
			});
			holder.addChild(scroller);
			scroller.body.addChild(cabinet_interior);
		}
		
		public function start(cabinet:Cabinet):void {			
			this.cabinet = cabinet;
			itemstack = model.worldModel.getItemstackByTsid(cabinet.itemstack_tsid);
			
			//try to create the cabinet first
			if(!createCabinet()) return;
			
			TSFrontController.instance.requestFocus(this);
			//TSFrontController.instance.changeLocationItemstackVisibility(cabinet.itemstack_tsid, false);
									
			refresh();
			
			//add this to the TSMainView's main_container
			main_view.main_container.addChildAt(this, main_view.main_container.numChildren - 1);
			
			//subscribe to pack actions
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, onPackDrag);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			
			//sub to mouse down
			addEventListener(MouseEvent.MOUSE_DOWN, onSlotMouseDown);
		}
		
		public function end(event:* = null):void {
			TSFrontController.instance.releaseFocus(this);
			//TSFrontController.instance.changeLocationItemstackVisibility(cabinet.itemstack_tsid, true);
			
			//ub-subscribe to pack actions
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_STARTED, onPackDrag);
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			
			//un-sub to mouse down
			removeEventListener(MouseEvent.MOUSE_DOWN, onSlotMouseDown);
			
			clean();
			
			TSFrontController.instance.cabinetDialogEnded();
			if(parent) parent.removeChild(this);
		}
		
		private const SCROLLER_MARGIN:int = 10;
		public function refresh():void {
			if(holder.numChildren == 0) return;
			
			var g:Graphics = blocker.graphics;
			g.clear();
			g.beginFill(blocker_color, blocker_alpha);
			g.drawRoundRectComplex(
				0,
				0,
				model.layoutModel.loc_vp_w,
				model.layoutModel.loc_vp_h,
				model.layoutModel.loc_vp_elipse_radius,
				0,
				model.layoutModel.loc_vp_elipse_radius,
				0
			);
			
			g = holder.graphics;
			g.clear();
			
			var rect_h:int = scroller.h+(SCROLLER_MARGIN*2);
			
			g.beginFill(blocker_color, 1);
			g.drawRoundRect(
				0,
				0,
				scroller.w+(SCROLLER_MARGIN*2),
				rect_h,
				20
			);
			g.endFill();
			
			// the pointer on the left side
			g.beginFill(blocker_color, 1);
			g.moveTo(0, (rect_h/2)-13);
			g.lineTo(-16, rect_h/2);
			g.lineTo(0, (rect_h/2)+13);
			g.endFill();
			
			var bounds:Rectangle = holder.getBounds(holder);
			holder.x = int((model.layoutModel.loc_vp_w/2) - (bounds.width/2) - bounds.x);
			holder.y = int((model.layoutModel.loc_vp_h/2) - (bounds.height/2) - bounds.y);
			
			//move the 'done' button
			done_button.x = int(holder.x + scroller.x + ((scroller.w/2) - (done_button.width/2)));
			done_button.y = int(holder.y + holder.height)+5;
		}
		
		public function translateSlotCenterToGlobal(slot:int):Point {
			//if the item is out of view, put it in view!
			var pt:Point = cabinet_interior.localToGlobal(getCenterPtForSlot(slot));
			var scroll_pt:Point = scroller.localToGlobal(new Point(0,0));
			
			if(pt.y < scroll_pt.y){
				pt.y = scroll_pt.y;
			}
			else if(pt.y > scroll_pt.y + scroller.height){
				pt.y = scroll_pt.y + scroller.height;
			}
			
			return pt;
		}
		
		private function getCenterPtForSlot(slot_index:int):Point {
			var slot:CabinetSlot = getSlot(slot_index);
			if (slot) {
				return new Point(slot.x+(ITEM_SIZE_WIDTH/2), slot.y+(ITEM_SIZE_HEIGHT/2));
			} else {
				return new Point(0, 0);
			}
		}
		
		private var scroll_bar_w:int;
		private function createCabinet():Boolean {
			cleanSWF();
			item_class = itemstack ? itemstack.item.tsid : '';
			
			const cols:int = cabinet.cols;
			const rows:int = cabinet.rows_display;
			
			scroll_bar_w = 0;
			if (cabinet.rows_display < cabinet.rows) {
				scroll_bar_w = SCROLL_BAR_WH;
			}
			
			var extra:int = 10;

			//set the scroller w/h
			scroller.wh = {
				w: INTERIOR_PADDING_W*2 + ITEM_SIZE_WIDTH*cols + ITEM_PADDING*(cols-1) + scroll_bar_w + getPadding()*2,
				h: INTERIOR_PADDING_H*2 + ITEM_SIZE_HEIGHT*rows + ROW_PADDING*(rows-1) + getPadding() + extra
			}
			
			scroller.x = scroller.y = SCROLLER_MARGIN;
			
			//get the SWF of the cabinet
			ItemSSManager.getFreshMCForItemSWFByUrl(itemstack.swf_url, itemstack.item, onFreshMCReady);
			
			return true;
		}
		
		private function onFreshMCReady(fresh_mc:MovieClip, url:String):void {
			cabinet_mc = fresh_mc;
			
			//clean
			SpriteUtil.clean(cabinet_holder);
			SpriteUtil.clean(cabinet_interior);
			
			cabinet_mc.gotoAndStop(1, '1');
			
			//add to the holder
			cabinet_holder.addChild(cabinet_mc);
			
			var bounds:Rectangle = cabinet_mc.getBounds(cabinet_mc);
			cabinet_mc.x = -bounds.x;
			cabinet_mc.y = -bounds.y;
			cabinet_holder.x = -(bounds.width+20);
			cabinet_holder.y = scroller.x+Math.round((scroller.h/2)-(bounds.height/2));
			
			//put the items in the cabinet
			createShelves();
			createItems();
			scroller.refreshAfterBodySizeChange(true);
			
			refresh();
		}
		
		private function createShelves():void {						
			var i:int;
			var shelf:MovieClip;
			
			for(i; i < cabinet.rows; i++){				
				shelf = new CabinetShelf();
				shelf.width = scroller.w-scroll_bar_w;
				shelf.y = (ITEM_SIZE_HEIGHT+2)+(i*(ITEM_SIZE_HEIGHT+ROW_PADDING)) + getPadding()-8;
				
				cabinet_interior.addChildAt(shelf, 0);
			}
		}
		
		private function createItems():void {
			var cab_slot:CabinetSlot;
			var itemstack:Itemstack;
			var item_index:int;
			var chunks:Array;
			var current:int = 0;
			var nextX:int = INTERIOR_PADDING_W + getPadding();
			var nextY:int = INTERIOR_PADDING_H + getPadding();
			var i:int = 0;
			var k:String;
			var total:uint = cabinet.rows*cabinet.cols;
			//var total:uint = 30;
			
			for(i; i < total; i++){
				cab_slot = new CabinetSlot(ITEM_SIZE_WIDTH, ITEM_SIZE_HEIGHT, i);
				cab_slot.x = nextX;
				cab_slot.y = nextY;
				cab_slot.name = SLOT_NAME+i;
				
				nextX += ITEM_SIZE_WIDTH+ITEM_PADDING;
				if(current == cabinet.cols-1){
					current = 0;
					nextY += ITEM_SIZE_HEIGHT+ROW_PADDING;
					nextX = INTERIOR_PADDING_W + getPadding();
				}else{
					current++;
				}
				
				cabinet_interior.addChild(cab_slot);
			}
			
			cabinet_slot_count = cabinet_interior.numChildren;
			
			//update any slots with items
			for(k in cabinet.itemstack_tsid_list){
				itemstack = model.worldModel.getItemstackByTsid(k);
				if(itemstack && itemstack.path_tsid){
					chunks = itemstack.path_tsid.split('/');
					item_index = chunks.indexOf(k);
					
					if(item_index-1 >= 0 && chunks[item_index-1] == cabinet.itemstack_tsid){
						getSlot(itemstack.slot).update(itemstack);
					}
				}
			}
		}
		
		/**
		 * Certain cabinets have different left/right padding needs (odd shapes) 
		 * @return int of the padding
		 */		
		private function getPadding():int {
			return 0;
			
			
			const FANCY_PADDING:uint = 11; //if the cabinet is 'fancy'
			const BOTTLETREE_PADDING:uint = 25;
			
			var padd:int;
			
			if(item_class.indexOf('fancy') != -1){
				padd = FANCY_PADDING;
			}
			else if(item_class.indexOf('bottletree') != -1){
				padd = BOTTLETREE_PADDING;
			}
			
			return padd;
		}
		
		private function onPackDrag(event:TSEvent):void {
			//we don't want no stinking bags - YES WE DO!
			//if (dragVO.dragged_itemstack.slots) return;
			
			//listen to mouse movement
			StageBeacon.mouse_move_sig.add(onPackMouseMove);
		}
		
		private function onPackMouseMove(e:MouseEvent):void {
			//if we already have a target in the VO, unhighlight it!
			if(dragVO.target && dragVO.target is CabinetSlot){
				dragVO.target.unhighlightOnDragOut();
			}
			
			if (scroller.hitTestObject(Cursor.instance.drag_DO)) {
				//var cab_slot:CabinetSlot = findEmptySlotOrSlotWithThisItem(dragVO.dragged_item);
				var cab_slot:CabinetSlot = findDropTarget();
				dragVO.target = cab_slot; // tuck a reference to the slot in the dragVO
				
				if (cab_slot) {
					Cursor.instance.showTip('Move Here');
				} else {
					Cursor.instance.hideTip();
				}
			} else {
				if (dragVO.target && dragVO.target is CabinetSlot) {
					dragVO.target.unhighlightOnDragOut();
					dragVO.target = null;
					Cursor.instance.hideTip();
				}
			}
			
			//make sure we auto scroll
			autoScroll();
		}
		
		private function onPackDragComplete(event:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(onPackMouseMove);
			
			if (dragVO.target && dragVO.target is CabinetSlot) {
				dragVO.target.unhighlightOnDragOut();
				
				TSFrontController.instance.genericSend(
					new NetOutgoingInventoryMoveVO(
						dragVO.dragged_itemstack.tsid,
						dragVO.dragged_itemstack.container_tsid,
						cabinet.itemstack_tsid,
						int(CabinetSlot(dragVO.target).name.substr(SLOT_NAME.length))
					)
				);
			}
			
			Cursor.instance.hideTip();
			
			//stop plz
			scroller.autoScrollStop();
		}
		
		private function onSlotMouseDown(event:MouseEvent):void {
			if(event.target is CabinetSlot && !CabinetSlot(event.target).isEmpty){
				//we've clicked on a slot, let's move this someplace!
				StageBeacon.mouse_move_sig.add(onSlotMouseMove);
				StageBeacon.mouse_up_sig.add(onSlotMouseUp);
				
				mouse_down_slot = event.target as CabinetSlot;
				mouse_down_slot.alpha = .5;
				
				dragVO.clear();
				dragVO.dragged_itemstack = mouse_down_slot.itemstack;
				dragVO.target = mouse_down_slot;
				dragVO.setReceptiveInventoryItemstacksAndBags(onSlotMouseMove);

				var view_state:String = 'iconic';
				if(mouse_down_slot.itemstack.tool_state && mouse_down_slot.itemstack.tool_state.is_broken) view_state = 'broken_iconic';
				
				Cursor.instance.startDragWith(
					new ItemIconView(mouse_down_slot.item_class, mouse_down_slot.icon_wh, view_state, 'center', false, false)
				);
				
				CabinetManager.instance.dispatchEvent(new TSEvent(TSEvent.DRAG_STARTED, dragVO));
			}
		}
		
		// MouseEvent defaults to null for dragVO.setReceptiveInventoryItemstacksAndBags(onSlotMouseMove);
		private function onSlotMouseMove(event:MouseEvent=null):void {
			if (!Cursor.instance.is_dragging) {
				return;
			}
			//clear the glow if there is an active move slot
			if(mouse_move_slot){
				mouse_move_slot.unhighlightOnDragOut();
			}
			
			//if we are over the cabinet
			if(scroller.hitTestObject(Cursor.instance.drag_DO)) {
				mouse_move_slot = findDropTarget();
				if (mouse_move_slot && mouse_move_slot != mouse_down_slot) {
					Cursor.instance.showTip('Move Here');
				} else {
					Cursor.instance.hideTip();
				}
			}
			
			//make sure we auto scroll
			autoScroll();
			
			if (event) event.updateAfterEvent();
		}
		
		private function onSlotMouseUp(event:MouseEvent):void {
			if (!Cursor.instance.is_dragging) {
				return;
			}
			CabinetManager.instance.dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE));
			Cursor.instance.endDrag();
			Cursor.instance.hideTip();
			
			mouse_down_slot.alpha = 1;
			if(mouse_move_slot) mouse_move_slot.unhighlightOnDragOut();
			
			StageBeacon.mouse_move_sig.remove(onSlotMouseMove);
			StageBeacon.mouse_up_sig.remove(onSlotMouseUp);
			
			//stop plz
			scroller.autoScrollStop();
			
			//check for a modifier key
			//if(!KeyBeacon.instance.shift_is_pressed){
				//normal move
				if(mouse_move_slot && mouse_down_slot != mouse_move_slot){
					TSFrontController.instance.genericSend(
						new NetOutgoingInventoryMoveVO(
							dragVO.dragged_itemstack.tsid,
							dragVO.dragged_itemstack.container_tsid,
							cabinet.itemstack_tsid,
							int(mouse_move_slot.name.substr(SLOT_NAME.length))
						)
					);
				}
//			}
//			else {
//				//move only some
//				
//			}
		}
		
		private function autoScroll():void {
			const SCROLL_BUFFER:uint = 30; //how many px from top/bottom before auto scrolling kicks in
			
			if(Cursor.instance.drag_DO){
				const cursor_pt:Point = Cursor.instance.drag_DO.localToGlobal(new Point(0,0));
				const scroll_pt:Point = scroller.localToGlobal(new Point(0,0));
								
				if(cursor_pt.y < scroll_pt.y + SCROLL_BUFFER && cursor_pt.y > scroll_pt.y - SCROLL_BUFFER){
					//auto scroll up
					scroller.autoScrollUp();
				}
				else if(cursor_pt.y > scroll_pt.y + scroller.height - SCROLL_BUFFER && cursor_pt.y < scroll_pt.y + scroller.height + SCROLL_BUFFER){
					//auto scroll down
					scroller.autoScrollDown();
				}
				else {
					//stop plz
					scroller.autoScrollStop();
				}
			}
		}
		
		/* KABOOM
		private function findEmptySlotOrSlotWithThisItem(item:Item):CabinetSlot {
			var i:int = 0;
			var cab_slot:CabinetSlot;
			var first_empty_slot:CabinetSlot;
			var already_slot:CabinetSlot;
			var child:DisplayObject;
  			var total:int = cabinet_interior.numChildren;
			
			for (i; i < total; i++) {
				child = cabinet_interior.getChildAt(i);
				
				if(child is CabinetSlot){
					cab_slot = child as CabinetSlot;

					if (!cab_slot.item_class && !first_empty_slot) {
						first_empty_slot = cab_slot;
					} else if (cab_slot.item_class == item.tsid && cab_slot.itemstack.count < model.worldModel.getItemByTsid(cab_slot.item_class).stackmax) {
						already_slot = cab_slot;
					}
				}
			}
			
			if (already_slot) return already_slot;
			if (first_empty_slot) return first_empty_slot;
			return null;
		}
		*/
		
		private function findDropTarget():CabinetSlot {
			//figure out where the dragVO is and return the relevent slot
			var i:int = 0;
			var cab_slot:CabinetSlot;
			var child:DisplayObject;
			
			for (i; i < cabinet_interior.numChildren; i++) {
				child = cabinet_interior.getChildAt(i);
				
				if(child is CabinetSlot){
					cab_slot = child as CabinetSlot;
					cab_slot.unhighlightOnDragOut();
										
					if(cab_slot.hitTestPoint(StageBeacon.stage.mouseX, StageBeacon.stage.mouseY)){ 
						if (cab_slot.isEmpty) {
							cab_slot.highlightEmpty()
							return cab_slot;
							
						} else if (cab_slot.item_class == dragVO.dragged_itemstack.class_tsid 
								   && cab_slot.count < model.worldModel.getItemByTsid(cab_slot.item_class).stackmax) {
							if (dragVO.dragged_itemstack.count < dragVO.dragged_itemstack.item.stackmax) {
								cab_slot.highlightOnDragOver();
								return cab_slot;
							}
						}
					}
				}
			}
			
			//if we didn't highlight a slot, make sure we don't drop it in a crazy place
			return null;
		}
		
		private function getSlot(slot:int):CabinetSlot {
			return cabinet_interior.getChildByName(SLOT_NAME+slot) as CabinetSlot;
		}
		
		private function getSlotByItemstackTsid(tsid:String):CabinetSlot {
			var i:int = 0;
			var total:int = cabinet_interior.numChildren;
			var cab_slot:CabinetSlot;
			var child:DisplayObject;
			
			for(i; i < total; i++){
				child = cabinet_interior.getChildAt(i);
				if(child is CabinetSlot){
					cab_slot = child as CabinetSlot;
					if(cab_slot.itemstack && cab_slot.itemstack.tsid == tsid) return cab_slot;
				}
			}
			
			return null;
		}
		
		public function onLocItemstackAdds(tsids:Array):void {
			if (!cabinet) return; // no cabinet means we're not in use 
			
			var i:int;
			var cab_slot:CabinetSlot;
			var tsid:String;
			var itemstack:Itemstack;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if (itemstack.container_tsid != cabinet.itemstack_tsid) { //irrelevant to this cabinet
					continue;
				}
				
				// add it to the cabinet's list of contents
				cabinet.itemstack_tsid_list[tsid] = tsid;
				
				// make sure there is not already a slot filled with this stack
				cab_slot = getSlotByItemstackTsid(tsid);
				if (cab_slot) {
					CONFIG::debugging {
						Console.warn('cabinet slot already exists for stack '+tsid);
					}
					continue;
				}
				
				// make sure the is not already a stack in the slot we're adding to
				cab_slot = getSlot(itemstack.slot);
				if (cab_slot.itemstack) { // this is bad and shoould never happen
					CONFIG::debugging {
						Console.error('there is already a stack in slot '+itemstack.slot);
					}
					continue;
				}
				
				cab_slot.update(itemstack);
			}
		}
		
		public function onLocItemstackDels(tsids:Array):void {
			if (!cabinet) return; // no cabinet means we're not in use
			
			var i:int;
			var cab_slot:CabinetSlot;
			var tsid:String;
			var itemstack:Itemstack;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if (itemstack.container_tsid != cabinet.itemstack_tsid) { //irrelevant to this cabinet
					continue;
				}
				
				// remove it from the list of the cabinet's contents
				if (cabinet.itemstack_tsid_list) delete cabinet.itemstack_tsid_list[tsid];
				
				cab_slot = getSlotByItemstackTsid(tsid);
				
				if (!cab_slot) { // this is bad, but we don't have a slot with this stack, so we can kind of ignore
					CONFIG::debugging {
						Console.warn('cabinet slot not exists for stack '+tsid);
					}
					continue;
				}
				
				cab_slot.update(null);
			}
		}
		
		public function onLocItemstackUpdates(tsids:Array):void {
			if (!cabinet) return; // no cabinet means we're not in use
			
			var i:int;
			var cab_slot:CabinetSlot;
			var tsid:String;
			var itemstack:Itemstack;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if (itemstack.container_tsid != cabinet.itemstack_tsid) { //irrelevant to this cabinet
					continue;
				}
				
				cabinet.itemstack_tsid_list[tsid] = tsid;
				
				// get the slot that holds this itemstack
				cab_slot = getSlotByItemstackTsid(tsid);
				
				if (cab_slot) { // good!
					if (cab_slot.slot != itemstack.slot) { // the itemstack has been moved
						cab_slot.update(null); // empty the old slot for the itemstack
					}
					
					cab_slot = getSlot(itemstack.slot);
					if (cab_slot.itemstack && cab_slot.itemstack.tsid != itemstack.tsid) { // this is bad and should never happen
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('there is already another stack in slot '+itemstack.slot);
						}
					} else {
						cab_slot.update(itemstack);
					}
					
				} else { // no slot? this is bad and should never happen
					CONFIG::debugging {
						Console.error('cabinet slot not exists for stack '+tsid);
					}
				}
			}
		}
		
		private function cleanSWF():void {		
			if (cabinet_mc && item_class) {
				// add the loaded item swf to the pool so it can be reused
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(cabinet.itemstack_tsid);
				var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(itemstack.swf_url);
				if (swf_data) {
					swf_data.addReusableMC(cabinet_mc);
				}
				if (cabinet_mc.parent && !(cabinet_mc.parent is Loader)) cabinet_mc.parent.removeChild(cabinet_mc);
				cabinet_mc.gotoAndStop(1, '1'); // WE MUST DO THIS HERE because for some fucking reason just doing it in onFreshMCReady does not work
				cabinet_mc = null;
			}
		}
		
		private function clean():void {	
			cleanSWF();
			
			cabinet = null;
			SpriteUtil.clean(cabinet_holder);
			SpriteUtil.clean(cabinet_interior);
			blocker.graphics.clear();
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return true;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			has_focus = false;
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, end);
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, end);
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
	}
}