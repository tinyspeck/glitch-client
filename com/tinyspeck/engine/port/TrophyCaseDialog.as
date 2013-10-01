package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.storage.TrophyCase;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingInventoryMoveVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.ContainersUtil;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSScroller;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;

	public class TrophyCaseDialog extends Sprite implements IFocusableComponent, ILocItemstackAddDelConsumer, ILocItemstackUpdateConsumer
	{
		private const TYPE_PRIVATE:String = 'private';
		private const TYPE_DISPLAY:String = 'display';
		private const INTERIOR_PADDING:int = 8;
		private const INTERIOR_POINT_NAME:String = 'interior_point';
		private const SHELF_NAME:String = 'shelf';
		private const ITEM_PADDING:int = 4;
		private const private_size_width:int = 50;
		private const private_size_height:int = 52;
		private const display_size_width:int = 70;
		private const display_size_height:int = 72;
		private const ROW_PADDING:int = 16;
		private const SLOT_NAME:String = 'slot';
		private const OPEN_SCENE:String = 'open';
		private const DRAG_THRESHOLD:int = 5;
		
		private var blocker:Sprite;
		private var blocker_color:uint = 0x213036;
		private var blocker_alpha:Number = .85;
		
		private var holder:Sprite;
		private var done_button:Button;
		
		private var trophy_case:TrophyCase;
		private var trophy_display_sp:Sprite;
		private var trophy_private_sp:Sprite;
		private var trophy_mc:MovieClip;
		private var trophy_scroll:TSScroller;
		
		private var has_focus:Boolean;
		private var item_class:String;
		
		private var model:TSModelLocator;
		private var main_view:TSMainView;
		
		private var dragVO:DragVO = DragVO.vo;
		private var mouse_down_slot:TrophyCaseSlot;
		private var mouse_move_slot:TrophyCaseSlot;
		
		
		/* singleton boilerplate */
		public static const instance:TrophyCaseDialog = new TrophyCaseDialog();
		
		public function TrophyCaseDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			registerSelfAsFocusableComponent();
			blocker = new Sprite();
			addChild(blocker);
			
			blocker_color = CSSManager.instance.getUintColorValueFromStyle('blocker', 'color', blocker_color);
			blocker_alpha = CSSManager.instance.getNumberValueFromStyle('blocker', 'alpha', blocker_alpha);
			
			holder = new Sprite();
			addChild(holder);
			
			done_button = new Button({
				label: 'Done',
				name: 'done_button',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_DEFAULT
			});
			done_button.addEventListener(MouseEvent.CLICK, end, false, 0, true);
			addChild(done_button);
			
			this.visible = false;
		}
		
		public function start(trophy_case:TrophyCase):void {
			this.visible = true;
			TSFrontController.instance.requestFocus(this);
			TSFrontController.instance.changeLocationItemstackVisibility(trophy_case.itemstack_tsid, false);
			
			this.trophy_case = trophy_case;
			
			createTrophyCase();
			
			//add this to the TSMainView's main_container
			if(!main_view) main_view = TSFrontController.instance.getMainView();
			main_view.main_container.addChildAt(this, main_view.main_container.numChildren - 1);
			
			//sub to mouse down
			addEventListener(MouseEvent.MOUSE_DOWN, onSlotMouseDown);
		}
		
		public function end(event:* = null):void {
			TSFrontController.instance.releaseFocus(this);
			TSFrontController.instance.changeLocationItemstackVisibility(trophy_case.itemstack_tsid, true);
			
			//un-sub to mouse down
			removeEventListener(MouseEvent.MOUSE_DOWN, onSlotMouseDown);
			
			clean();
			
			TSFrontController.instance.trophyDialogEnded();
			
			this.visible = false;
		}
		
		public function refresh():void {
			if(!visible) return;
			
			var g:Graphics = blocker.graphics;
			g.clear();
			g.beginFill(blocker_color, blocker_alpha);
			g.drawRoundRectComplex(0, 0, model.layoutModel.loc_vp_w, model.layoutModel.loc_vp_h,
								   model.layoutModel.loc_vp_elipse_radius, 0, model.layoutModel.loc_vp_elipse_radius, 0);
			
			holder.x = int(model.layoutModel.loc_vp_w/2 - holder.width/2);
			holder.y = int(model.layoutModel.loc_vp_h/2 - trophy_mc.height/2 + trophy_display_sp.height);
			
			//move the 'done' button
			done_button.x = int(holder.x + (holder.width/2 - done_button.width/2));
			done_button.y = int(holder.y + trophy_mc.height - trophy_display_sp.height + done_button.height/2);
		}
		
		public function translateSlotCenterToGlobal(slot:int, path:String):Point {
			if(!visible){
				CONFIG::debugging {
					Console.warn('Why is the trophy case getting this called? It is HIDDEN!');
				}
				return new Point(0,0);
			} 
			
			var chunks:Array = path.split('/');
			var bag_tsid:String = chunks[0];
			var trophy_holder:Sprite = trophy_display_sp;
			var type:String = TYPE_DISPLAY;
			
			if(trophy_case.private_tsid == bag_tsid){
				trophy_holder = trophy_private_sp;
				type = TYPE_PRIVATE;
			}
			
			return trophy_holder.localToGlobal(getCenterPtForSlot(slot, type));
		}
		
		private function getCenterPtForSlot(slot_index:int, type:String):Point {
			var slot:TrophyCaseSlot = getSlot(slot_index, type);
			if (slot) {
				return new Point(slot.x+(slot.width/2), slot.y+(slot.width/2));
			} else {
				return new Point(0, 0);
			}
		}

		private function createTrophyCase():void {
			cleanSWF();
			//holder for display trophies
			trophy_display_sp = new Sprite();
			var g:Graphics = trophy_display_sp.graphics;
			g.beginFill(0, 0);
			g.drawRect(ITEM_PADDING, 
					   ITEM_PADDING, 
				       (trophy_case.display_cols * display_size_width) + (ITEM_PADDING * trophy_case.display_cols), 
					   display_size_height + ITEM_PADDING*2);
			
			//holder for private trophies
			trophy_private_sp = new Sprite();
			
			//scroller
			trophy_scroll = new TSScroller({
				name: '_scroller',
				bar_wh: 17,
				w: 407,
				h: 167,
				bar_handle_min_h: 30,
				scrolltrack_always: false,
				bar_handle_color: 0x919698,
				bar_handle_border_color: 0x919698,
				bar_handle_stripes_color: 0x626666
			});
			
			trophy_scroll.body.addChild(trophy_private_sp);
			
			item_class = model.worldModel.getItemstackByTsid(trophy_case.itemstack_tsid).class_tsid;
			var item:Item = model.worldModel.getItemByTsid(item_class);
			
			//get the SWF of the case
			ItemSSManager.getFreshMCForItemSWFByUrl(item.asset_swf_v, item, onFreshMCReady);
		}
		
		private function onFreshMCReady(fresh_mc:MovieClip, url:String):void {
			
			//position the interior
			fresh_mc.gotoAndStop(1, '1'); // sometimes this does not seem to work! see note in cleanSWF
			var interior_point:MovieClip = fresh_mc.getChildByName(INTERIOR_POINT_NAME) as MovieClip;
			if(interior_point){
				trophy_scroll.x = interior_point.x;
				trophy_scroll.y = interior_point.y;
				
				//go to the open state and scale to fit our interior spec
				fresh_mc.gotoAndStop(1, OPEN_SCENE);
				trophy_mc = fresh_mc;
				
				createShelves();
				createItems(TYPE_DISPLAY);
				createItems(TYPE_PRIVATE);
				
				//tweak the position of the displayed trophies
				trophy_display_sp.x = int(trophy_mc.width/2 - trophy_display_sp.width/2);
				trophy_display_sp.y = -display_size_height;
				
				//add to the holder
				holder.addChild(trophy_mc);
				holder.addChild(trophy_scroll);
				trophy_mc.addChild(trophy_display_sp);
				
				int(holder.x + (holder.width/2 - done_button.width/2));
				
				refresh();
			}else{
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Trophy case missing an interior_point');
				}
				end();
			}
		}
		
		private function createShelves():void {						
			for(var i:int = 0; i < trophy_case.private_rows; i++){				
				var shelf:MovieClip = trophy_mc.getAssetByName(item_class+'_shelf');
				if (!shelf) shelf = new MovieClip();
				shelf.y = (private_size_height+2)+(i*(private_size_height+ROW_PADDING));
				
				trophy_scroll.body.addChildAt(shelf, 0);
			}
		}
		
		private function createItems(type:String = TYPE_DISPLAY):void {
			var trophy_slot:TrophyCaseSlot;
			var itemstack:Itemstack;
			var current:int = 0;
			var nextX:int = (type == TYPE_DISPLAY) ? INTERIOR_PADDING/2 + 2 : INTERIOR_PADDING;
			var nextY:int = INTERIOR_PADDING;
			var i:int = 0;
			var rows:uint = (type == TYPE_DISPLAY) ? trophy_case.display_rows : trophy_case.private_rows;
			var cols:uint = (type == TYPE_DISPLAY) ? trophy_case.display_cols : trophy_case.private_cols;
			var h:int = (type == TYPE_DISPLAY) ? display_size_height : private_size_height;
			var w:int = (type == TYPE_DISPLAY) ? display_size_width : private_size_width;
			var trophy_sp:Sprite = (type == TYPE_DISPLAY) ? trophy_display_sp : trophy_private_sp;
			
			if(trophy_case){
				for(i; i < rows*cols; i++){
					trophy_slot = new TrophyCaseSlot(w, h, i, type);
					trophy_slot.x = nextX;
					trophy_slot.y = nextY;
					trophy_slot.name = SLOT_NAME+i;
					
					nextX += w+ITEM_PADDING;
					if(current == cols-1){
						current = 0;
						nextY += h+ROW_PADDING;
						nextX = INTERIOR_PADDING;
					}else{
						current++;
					}
					
					trophy_sp.addChild(trophy_slot);
				}
				
				var tsidA:Array;
				
				if (type == TYPE_DISPLAY) {
					// get the stacks in the trophy case display
					tsidA = ContainersUtil.getTsidAForContainerTsid(trophy_case.itemstack_tsid, model.worldModel.location.itemstack_tsid_list, model.worldModel.itemstacks)
				} else {
					// get the stacks in the trophy case storage
					tsidA = ContainersUtil.getTsidAForContainerTsid(trophy_case.private_tsid, model.worldModel.pc.itemstack_tsid_list, model.worldModel.itemstacks)
				}
				
				if (tsidA) {
					//update any slots with items
					for(var m:int;m<tsidA.length;m++){
						itemstack = model.worldModel.getItemstackByTsid(tsidA[m]);
						if (itemstack && getSlot(itemstack.slot, type)) {
							getSlot(itemstack.slot, type).update(itemstack);
						}
					}
				}
			}else{
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('trophy_case is not set!');
				}
			}
		}
		
		private function onSlotMouseDown(event:MouseEvent):void {
			if(event.target is TrophyCaseSlot && !TrophyCaseSlot(event.target).isEmpty){
				//we've clicked on a slot, let's move this someplace!
				StageBeacon.mouse_move_sig.add(onSlotMouseMove);
				StageBeacon.mouse_up_sig.add(onSlotMouseUp);
				
				mouse_down_slot = event.target as TrophyCaseSlot;
				mouse_down_slot.alpha = .5;
				
				dragVO.clear();
				dragVO.dragged_itemstack = mouse_down_slot.itemstack;
				dragVO.target = mouse_down_slot;
				dragVO.setReceptiveInventoryItemstacksAndBags(onSlotMouseMove);
				
				Cursor.instance.startDragWith(
					new ItemIconView(mouse_down_slot.item_class, mouse_down_slot.icon_wh, 'iconic', 'center', false, false)
				);
				
				//WTF was this here for?! We don't want trophies in packs, maybe this was old before private storage?
				//CabinetManager.instance.dispatchEvent(new TSEvent(TSEvent.DRAG_STARTED, dragVO));
			}
		}
		
		// the MouseEvent defaults to null for dragVO.setReceptiveInventoryItemstacksAndBags(onSlotMouseMove);
		private function onSlotMouseMove(event:MouseEvent=null):void {
			//if we are over the cabinet
			if(holder.hitTestObject(Cursor.instance.drag_DO)) {
				findDropTarget();
				if (mouse_move_slot) {
					Cursor.instance.showTip('Move here');
				} else {
					Cursor.instance.hideTip();
				}
			} else {
				Cursor.instance.hideTip();
			}
			
			//make sure we auto scroll
			autoScroll();
		}
		
		private function onSlotMouseUp(event:MouseEvent):void {
			if(Cursor.instance.is_dragging){
				//WTF was this here for?! We don't want trophies in packs, maybe this was old before private storage?
				//CabinetManager.instance.dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE));
				Cursor.instance.endDrag();
				Cursor.instance.hideTip();
				
				mouse_down_slot.alpha = 1;
				if(mouse_move_slot) mouse_move_slot.unhighlightOnDragOut();
				
				if(mouse_move_slot && mouse_down_slot != mouse_move_slot){
					TSFrontController.instance.genericSend(
						new NetOutgoingInventoryMoveVO(
							dragVO.dragged_itemstack.tsid,
							dragVO.dragged_itemstack.container_tsid,
							dragVO.receptive_location_itemstacks.tsid,
							int(mouse_move_slot.name.substr(SLOT_NAME.length))
						), 
						onInventoryMove,
						onInventoryMove
					);
				}
				
				StageBeacon.mouse_move_sig.remove(onSlotMouseMove);
				StageBeacon.mouse_up_sig.remove(onSlotMouseUp);
			}
		}
		
		private function onInventoryMove(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//animate it because serguei doesn't want to anncs for private packs
				model.activityModel.announcements = Announcement.parseMultiple([{
					item_class: dragVO.dragged_itemstack.class_tsid,
					count: 1,
					orig_path: dragVO.dragged_itemstack.container_tsid+'/'+dragVO.dragged_itemstack.tsid,
					orig_slot: dragVO.dragged_itemstack.slot,
					dest_path: dragVO.receptive_location_itemstacks.tsid+'/'+dragVO.dragged_itemstack.tsid,
					dest_slot: int(mouse_move_slot.name.substr(SLOT_NAME.length)),
					type: Announcement.PACK_TO_PACK
				}]);
			}
			else {
				//write the error the the console warn
				CONFIG::debugging {
					Console.warn('Had an issue moving an item from display to private!', 
						dragVO.dragged_itemstack.tsid,
						dragVO.dragged_itemstack.container_tsid,
						dragVO.receptive_location_itemstacks.tsid,
						int(mouse_move_slot.name.substr(SLOT_NAME.length))
					);
				}
			}
		}
		
		private function autoScroll():void {
			const SCROLL_BUFFER:uint = 30; //how many px from top/bottom before auto scrolling kicks in
			
			if(Cursor.instance.drag_DO){
				const cursor_pt:Point = Cursor.instance.drag_DO.localToGlobal(new Point(0,0));
				const scroll_pt:Point = trophy_scroll.localToGlobal(new Point(0,0));
				
				if(cursor_pt.y < scroll_pt.y + SCROLL_BUFFER && cursor_pt.y > scroll_pt.y - SCROLL_BUFFER){
					//auto scroll up
					trophy_scroll.autoScrollUp();
				}
				else if(cursor_pt.y > scroll_pt.y + trophy_scroll.height - SCROLL_BUFFER && cursor_pt.y < scroll_pt.y + trophy_scroll.height + SCROLL_BUFFER){
					//auto scroll down
					trophy_scroll.autoScrollDown();
				}
				else {
					//stop plz
					trophy_scroll.autoScrollStop();
				}
			}
		}
		
		private function resort(ignore_slot:TrophyCaseSlot):void {
			//clean up any mess
			var i:int;
			var child:DisplayObject;
			var trophy_slot:TrophyCaseSlot;
			
			for(i = 0; i < trophy_display_sp.numChildren; i++){
				child = trophy_display_sp.getChildAt(i);
				if(child is TrophyCaseSlot){
					trophy_slot = child as TrophyCaseSlot;
					if(!trophy_slot.itemstack && trophy_slot != ignore_slot) trophy_slot.isEmpty = true;
				}
			}
			
			for(i = 0; i < trophy_private_sp.numChildren; i++){
				child = trophy_private_sp.getChildAt(i);
				if(child is TrophyCaseSlot){
					trophy_slot = child as TrophyCaseSlot;
					if(!trophy_slot.itemstack && trophy_slot != ignore_slot) trophy_slot.isEmpty = true;
				}
			}
		}
		
		private function findDropTarget():void {
			//figure out where the dragVO is and return the relevent slot
			var i:int = 0;
			var trophy_slot:TrophyCaseSlot;
			var child:DisplayObject;
			var good_slot:TrophyCaseSlot = null;
			var holder:Sprite;
						
			//figure out if we are in the display bag or the private bag
			if(trophy_display_sp.hitTestPoint(StageBeacon.stage.mouseX, StageBeacon.stage.mouseY)){
				holder = trophy_display_sp;
				dragVO.receptive_location_itemstacks.tsid = trophy_case.itemstack_tsid; //sneak the tsid of the pack in here
			}else if(trophy_scroll.hitTestPoint(StageBeacon.stage.mouseX, StageBeacon.stage.mouseY)){
				holder = trophy_private_sp;
				dragVO.receptive_location_itemstacks.tsid = trophy_case.private_tsid;
			}else{
				//hitting nothing
				resort(mouse_down_slot);
				mouse_move_slot = null;
				return;
			}
			
			//do some detection now that we have things to detect
			for (i; i < holder.numChildren; i++) {
				child = holder.getChildAt(i);
				
				if(child is TrophyCaseSlot){
					trophy_slot = child as TrophyCaseSlot;
					trophy_slot.unhighlightOnDragOut();
					
					if(trophy_slot.hitTestPoint(StageBeacon.stage.mouseX, StageBeacon.stage.mouseY)){ 
						if (trophy_slot.isEmpty) {
							trophy_slot.highlightEmpty();
							good_slot = trophy_slot;
							resort(good_slot);
							break;
							
						} else if (trophy_slot.item_class == dragVO.dragged_itemstack.class_tsid) {
							if (dragVO.dragged_itemstack.count < dragVO.dragged_itemstack.item.stackmax) {
								trophy_slot.highlightOnDragOver();
								good_slot = trophy_slot;
								resort(good_slot);
								break;
							}
						}
					}
				}
			}
			
			//if we didn't highlight a slot, make sure we don't drop it in a crazy place
			mouse_move_slot = good_slot;
		}
		
		private function getSlot(slot:int, type:String):TrophyCaseSlot {
			var trophy_sp:Sprite = (type == TYPE_DISPLAY) ? trophy_display_sp : trophy_private_sp;
			return trophy_sp.getChildByName(SLOT_NAME+slot) as TrophyCaseSlot;
		}
		
		private function getSlotByItemstackTsid(tsid:String, type:String):TrophyCaseSlot {
			var trophy_sp:Sprite = (type == TYPE_DISPLAY) ? trophy_display_sp : trophy_private_sp;
			var i:int = 0;
			var total:int = trophy_sp.numChildren;
			var trophy_slot:TrophyCaseSlot;
			var child:DisplayObject;
			
			for(i; i < total; i++){
				child = trophy_sp.getChildAt(i);
				if(child is TrophyCaseSlot){
					trophy_slot = child as TrophyCaseSlot;
					if(trophy_slot.itemstack && trophy_slot.itemstack.tsid == tsid) return trophy_slot;
				}
			}
			
			return null;
		}
		
		public function onPcItemstackUpdates(tsids:Array):void {
			if (!trophy_case) return; // no cabinet means we're not in use
			
			var i:int;
			var trophy_slot:TrophyCaseSlot;
			var tsid:String;
			var itemstack:Itemstack;
			var type:String = TYPE_PRIVATE;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if (itemstack.container_tsid != trophy_case.itemstack_tsid && itemstack.container_tsid != trophy_case.private_tsid) { //irrelevant to this cabinet
					continue;
				}
				
				//if(itemstack.container_tsid == trophy_case.private_tsid) type = TYPE_PRIVATE;
				
				// get the slot that holds this itemstack
				trophy_slot = getSlotByItemstackTsid(tsid, type);
				
				if (trophy_slot) { // good!
					if (trophy_slot.slot != itemstack.slot) { // the itemstack has been moved
						trophy_slot.update(null); // empty the old slot for the itemstack
					}
					
					trophy_slot = getSlot(itemstack.slot, type);
					if (trophy_slot.itemstack && trophy_slot.itemstack.tsid != itemstack.tsid) { // this is bad and should never happen
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('there is already another stack in slot '+itemstack.slot);
						}
					} else {
						trophy_slot.update(itemstack);
					}
					
				} else { // no slot? this is bad and should never happen
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('UPDATE trophy slot not exists for stack '+tsid);
					}
				}
			}
		}
		
		public function onPcItemstackAdds(tsids:Array):void {
			if (!trophy_case) return; // no cabinet means we're not in use
			
			var i:int;
			var trophy_slot:TrophyCaseSlot;
			var tsid:String;
			var itemstack:Itemstack;
			var type:String = TYPE_PRIVATE;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if (itemstack.container_tsid != trophy_case.itemstack_tsid && itemstack.container_tsid != trophy_case.private_tsid) { //irrelevant to this cabinet
					CONFIG::debugging {
						Console.warn('Moving on...', itemstack.container_tsid, trophy_case.itemstack_tsid, trophy_case.private_tsid);
					}
					continue;
				}
				
				trophy_slot = getSlotByItemstackTsid(tsid, type);
				if (trophy_slot) {
					//we shouldn't get this on an add, but clear out the slot it came from
					trophy_slot.update(null);
					CONFIG::debugging {
						Console.warn('PACK ADD trophy slot already exists for stack '+tsid, trophy_slot.slot);
					}
				}
				
				// make sure the is not already a stack in the slot we're adding to
				trophy_slot = getSlot(itemstack.slot, type);
				if (trophy_slot.itemstack) { // this is bad and shoould never happen
					CONFIG::debugging {
						Console.error('PACK ADD there is already a stack in slot '+itemstack.slot);
					}
					continue;
				}
				
				if (trophy_slot) { // good!
					trophy_slot.update(itemstack);
				}else{ //ruh roh
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('PACK ADD Could not get the slot to place the item into');
					}
				}
			}
		}
		public function onPcItemstackDels(tsids:Array):void {
			if (!trophy_case) return; // no cabinet means we're not in use
			
			var i:int;
			var trophy_slot:TrophyCaseSlot;
			var tsid:String;
			var itemstack:Itemstack;
			var type:String = TYPE_PRIVATE;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if (itemstack.container_tsid != trophy_case.itemstack_tsid && itemstack.container_tsid != trophy_case.private_tsid) { //irrelevant to this cabinet
					CONFIG::debugging {
						Console.warn(itemstack.container_tsid +' != '+trophy_case.itemstack_tsid)
					}
					continue;
				}
				
				trophy_slot = getSlotByItemstackTsid(tsid, type);
				
				if (!trophy_slot) { // this is bad, but we don't have a slot with this stack, so we can kind of ignore
					CONFIG::debugging {
						Console.warn('PACK DELETE trophy slot not exists for stack '+tsid);
					}
					continue;
				}
				
				trophy_slot.update(null);
			}
		}
		
		public function onLocItemstackAdds(tsids:Array):void {
			if (!trophy_case) return; // no cabinet means we're not in use 
			
			var i:int;
			var trophy_slot:TrophyCaseSlot;
			var tsid:String;
			var itemstack:Itemstack;
			var type:String = TYPE_DISPLAY;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);

				// I am commenting some stuff out out, because it is a failure in messaging if we get here for a stack that is not in the display
				
				if (itemstack.container_tsid != trophy_case.itemstack_tsid/* && itemstack.container_tsid != trophy_case.private_tsid*/) { //irrelevant to this cabinet
					continue;
				}
				
				//if(itemstack.container_tsid == trophy_case.private_tsid) type = TYPE_PRIVATE;
				
				// make sure there is not already a slot filled with this stack
				trophy_slot = getSlotByItemstackTsid(tsid, type);
				if (trophy_slot) {
					CONFIG::debugging {
						Console.warn('trophy slot already exists for stack '+tsid);
					}
					continue;
				}
				
				// make sure the is not already a stack in the slot we're adding to
				trophy_slot = getSlot(itemstack.slot, type);
				if (trophy_slot.itemstack) { // this is bad and shoould never happen
					CONFIG::debugging {
						Console.error('there is already a stack in slot '+itemstack.slot);
					}
					continue;
				}
				
				trophy_slot.update(itemstack);
			}
		}
		
		public function onLocItemstackDels(tsids:Array):void {
			if (!trophy_case) return; // no cabinet means we're not in use
			
			var i:int;
			var trophy_slot:TrophyCaseSlot;
			var tsid:String;
			var itemstack:Itemstack;
			var type:String = TYPE_DISPLAY;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				// I am commenting some stuff out out, because it is a failure in messaging if we get here for a stack that is not in the display
				
				if (itemstack.container_tsid != trophy_case.itemstack_tsid/* && itemstack.container_tsid != trophy_case.private_tsid*/) { //irrelevant to this cabinet
					continue;
				}
				
				//if(itemstack.container_tsid == trophy_case.private_tsid) type = TYPE_PRIVATE;
				
				trophy_slot = getSlotByItemstackTsid(tsid, type);
				
				if (!trophy_slot) { // this is bad, but we don't have a slot with this stack, so we can kind of ignore
					CONFIG::debugging {
						Console.warn('DELETE trophy slot not exists for stack '+tsid);
					}
					continue;
				}
				
				trophy_slot.update(null);
			}
		}
		
		public function onLocItemstackUpdates(tsids:Array):void {
			if (!trophy_case) return; // no case means we're not in use
			
			var i:int;
			var trophy_slot:TrophyCaseSlot;
			var tsid:String;
			var itemstack:Itemstack;
			var type:String = TYPE_DISPLAY;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				// I am commenting some stuff out out, because it is a failure in messaging if we get here for a stack that is not in the display
				
				if (itemstack.container_tsid != trophy_case.itemstack_tsid/* && itemstack.container_tsid != trophy_case.private_tsid*/) { //irrelevant to this cabinet
					continue;
				}
				
				//if(itemstack.container_tsid == trophy_case.private_tsid) type = TYPE_PRIVATE;
				
				// get the slot that holds this itemstack
				trophy_slot = getSlotByItemstackTsid(tsid, type);
				
				if (trophy_slot) { // good!
					if (trophy_slot.slot != itemstack.slot) { // the itemstack has been moved
						trophy_slot.update(null); // empty the old slot for the itemstack
					}
					
					trophy_slot = getSlot(itemstack.slot, type);
					if (trophy_slot.itemstack && trophy_slot.itemstack.tsid != itemstack.tsid) { // this is bad and should never happen
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('there is already another stack in slot '+itemstack.slot);
						}
					} else {
						trophy_slot.update(itemstack);
					}
					
				} else { // no slot? Must be a pack to bag transition
					getSlot(itemstack.slot, type).update(itemstack);
				}
				
			}
		}
		
		private function cleanSWF():void {
			if (trophy_mc && item_class) {
				// add the loaded item swf to the pool so it can be reused
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(trophy_case.itemstack_tsid);
				var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(itemstack.swf_url);
				if (swf_data) {
					swf_data.addReusableMC(trophy_mc);
				}
				if (trophy_mc.parent) {
					try {
						trophy_mc.parent.removeChild(trophy_mc);
					} catch (e:Error) {
						CONFIG::debugging {
							Console.error(e);
						}
					}
				}
				trophy_mc.gotoAndStop(1, '1'); // WE MUST DO THIS HERE because for some fucking reason just doing it in onFreshMCReady does not work
				trophy_mc = null;
			}
		}
		
		private function clean():void {
			cleanSWF();
			
			//just clean up stuff before using it again
			if (trophy_display_sp) SpriteUtil.clean(trophy_display_sp);
			SpriteUtil.clean(holder);
			SpriteUtil.clean(blocker);
			
			trophy_case = null;
			trophy_private_sp = null;
			trophy_scroll = null;
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