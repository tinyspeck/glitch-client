package com.tinyspeck.engine.pack {
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.itemstack.PackItemstackView;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	public class PackContainerView extends TSSpriteWithModel {
		private static const BG_PADD:uint = 4; //how much padding around the pack icons the bg gets (this does not include the 1px border)
		
		private static var border_glowA:Array;
		
		public var open_container_tsid:String;
		public var pack_slotsA:Array = [];
		
		private var pis_viewsA:Array = [];
		
		private var dragged_pis_view:PackItemstackView;
		private var dragVO:DragVO = DragVO.vo;
		
		private var slots_holder:Sprite = new Sprite();
		
		private var label:String;
		
		private var slots:int;
		private var box_margin_w:uint = 2;
		private var box_padd_wh:uint = 5;
		private var bg_color:uint = 0xc6d2d3;
		
		private var draw_background:Boolean;
		private var inited:Boolean;
 		
		public function PackContainerView(slots:int, label:String):void {
			super();
			
			this.label = label;
			this.slots = slots;
			_h = 67; // hrmmm
		}
		
		public function init(draw_background:Boolean = false):void {
			inited = true;
			this.draw_background = draw_background;
			
			var i:int;
			
			addChild(slots_holder);
			
			for (i=0;i<slots;i++) {
				var pack_slot:PackSlot = new PackSlot(i);
				pack_slotsA.push(pack_slot);
				slots_holder.addChild(pack_slot);
			}
			
			this.addEventListener(MouseEvent.CLICK, _clickHandler, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_DOWN, _mouseDownHandler, false, 0, true);
			
			box_margin_w = 4;
			
			//get the bg
			bg_color = CSSManager.instance.getUintColorValueFromStyle('pack_container', 'backgroundColor', bg_color);
			
			//set the border filter if it's not set
			if(!border_glowA){
				const border_color:uint = CSSManager.instance.getUintColorValueFromStyle('pack_container', 'borderColor', 0xb2bfc0);
				border_glowA = StaticFilters.copyFilterArrayFromObject({color:border_color, strength:8}, StaticFilters.black_GlowA);
			}
			
			if(draw_background) filters = border_glowA;
			
			refresh();
		}
		
		internal function addPISViews(contents_tsidsA:Array):void {
			var i:int;
			if (contents_tsidsA) {
				for (i=0;i<contents_tsidsA.length;i++) {
					if (!model.flashVarModel.no_render_stacks) {
						var tsid:String = contents_tsidsA[int(i)];
						var itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
						var packItemstackView:PackItemstackView = new PackItemstackView(itemstack.tsid, model.layoutModel.pack_itemicon_wh);
						pis_viewsA.push(packItemstackView);
					} else {
						PackDisplayManager.instance.onPISViewLoaded();
					}
				}
				contents_tsidsA.length = 0;
				contents_tsidsA = null;
			}
			refresh();
		}
		
		public function refreshLabel():void {
			var empty_c:int = 0;
			var pack_slot:PackSlot;
			var i:int;
			
			for (i=0;i<pack_slotsA.length;i++) {
				pack_slot = pack_slotsA[int(i)] as PackSlot;
				if (!pack_slot.is_full) empty_c++;
			}
		}
		
		public function translateSlotCenterToGlobal(slot:int):Point {
			return this.localToGlobal(getCenterPtForSlot(slot));
		}
		
		private function getCenterPtForSlot(i:int):Point {
			var pack_slot:PackSlot = getPackSlotForSlot(i);
			if (!pack_slot) {
				CONFIG::debugging {
					Console.error(i+' has no PackSlot!');
				}
				return new Point();
			}
			var pt:Point = new Point(pack_slot.x, pack_slot.y);
			
			if (pack_slot.holds_container) {
				pt.x+= pack_slot.pis_view.x+(model.layoutModel.pack_itemicon_wh/2);
			} else {
				pt.x+= box_padd_wh+(model.layoutModel.pack_itemicon_wh/2);
			}
			
			pt.y+= box_padd_wh+(model.layoutModel.pack_itemicon_wh/2);
			
			return pt;
		}
		
		public function getPackSlotForSlot(slot:int):PackSlot {
			return pack_slotsA[slot] as PackSlot;
		}
		
		public function getPackSlotByTsid(tsid:String):PackSlot {
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
			if (!itemstack) return null;
			return getPackSlotForSlot(itemstack.slot);
		}
		
		public function markSlotOpenForTsid(tsid:String):void {
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
			var pack_slot:PackSlot = getPackSlotForSlot(itemstack.slot);
			if(pack_slot) {
				pack_slot.is_open = true;
				open_container_tsid = tsid;
			}
			else {
				CONFIG::debugging {
					Console.warn('Could not find pack slot to open for tsid: '+tsid);
				}
			}
		}
		
		public function markSlotClosedForTsid(tsid:String):void {
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
			if (!itemstack) return;
			var pack_slot:PackSlot = getPackSlotForSlot(itemstack.slot);
			if (!pack_slot) return;
			open_container_tsid = '';
			pack_slot.is_open = false;
		}
		
		private function placePackItemstackViewsAndSlots():void {
			var i:int;
			var pack_slot:PackSlot;
			var pis_view:PackItemstackView;
			
			pis_viewsA.sortOn('slot', [Array.NUMERIC]);
			for (i=0;i<pis_viewsA.length;i++) {
				pis_view = PackItemstackView(pis_viewsA[int(i)]);
				pack_slot = getPackSlotForSlot(pis_view.slot);
				if (pack_slot) {
					if (pack_slot.pis_view != pis_view) {
						pack_slot.addStack(pis_view);
					}	
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('no pack_slot for stack:'+pis_view.tsid+' in slot:'+pis_view.slot+' (in '+this.label+' with '+this.slots+' slots)');
					}
				}
			}
			
			var use_x:int = 0;
			for (i=0;i<pack_slotsA.length;i++) {
				pack_slot = pack_slotsA[int(i)] as PackSlot;
				pack_slot.x = use_x;
				use_x+= (model.layoutModel.pack_slot_w+box_margin_w);
			}
			
			//draw the background if we need to
			if(draw_background){
				var g:Graphics = graphics;
				g.clear();
				g.beginFill(bg_color);
				g.drawRoundRect(-BG_PADD, -BG_PADD, use_x-box_margin_w+BG_PADD*2-1, model.layoutModel.pack_slot_h+BG_PADD*2-1, 10);
			}
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
			refresh();
		}
		
		private function getPackSlotForDraggedPISView():PackSlot {
			if (!dragged_pis_view) return null;
			try {
				return dragged_pis_view.parent.parent as PackSlot; // omy dumb, we might need to find a better way to find the slot from the pisv
			} catch(err:Error) {
				BootError.handleError('need to investigate why this is firing', err, ['dragged_pis_view_lacking_parent_parent'], true);
			}
			return null;
		}
		
		private function _mouseUpHandler(e:MouseEvent):void {
			endDrag();
		}
		
		private function endDrag():void {
			if (getPackSlotForDraggedPISView()) getPackSlotForDraggedPISView().alpha = 1;
			
			if (Cursor.instance.is_dragging) {
				PackDisplayManager.instance.dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE));
				Cursor.instance.endDrag();
			}
			
			dragged_pis_view = null;
			
			StageBeacon.mouse_move_sig.remove(_mouseMoveHandler);
			StageBeacon.mouse_up_sig.remove(_mouseUpHandler);
		}
		
		private function _mouseMoveHandler(e:MouseEvent):void {
			var distance:Number = Point.distance(StageBeacon.last_mouse_down_pt, StageBeacon.stage_mouse_pt);
			
			//Console.warn('distance:'+distance)
			
			if (distance> StateModel.DRAG_DIST_REQUIRED) {
				startDraggingAPISView(dragged_pis_view);
			}
		}
		
		private function startDraggingAPISView(pis_view:PackItemstackView):void {
			// make sure we set these, in case we started the dragging from somewhere other than _mouseMoveHandler (like invoke dragging)
			dragged_pis_view = pis_view;
			StageBeacon.mouse_up_sig.add(_mouseUpHandler);
			
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(dragged_pis_view.tsid);
			
			var state:Object = dragged_pis_view.ss_state || null;
			
			var wh:int = model.layoutModel.pack_itemicon_wh;
			
			// since we're dragging into location, use location states
			/*if (state == 'iconic') {
				state = itemstack.count.toString();
				wh = 0;
			} else if (state == 'broken_iconic') {
				state = 'broken';
				wh = 0;
			}*/
			
			// ROLING BACK THE ABOVE!
			/*
			
			6:34 PM <kevin> eric, after that bug was closed with the swfs that expand quite a bit after you drag them around in the pack, it seems there's some more complains about them in the forum.
			6:34 PM <eric> links please
			6:34 PM <kevin> http://www.glitch.com/forum/bugs/24887/
			6:35 PM <eric> kev, the issue here is not related to the bug
			6:36 PM <eric> err, maybe it is
			6:36 PM <eric> I am actually not sure what bug you were referencing, but
			6:36 PM <eric> this is what is:
			6:36 PM <kevin> http://bugs.tinyspeck.com/9507
			6:36 PM <eric> 11:13 AM <eric> bug http://bugs.tinyspeck.com/9507 - When dragging some items from your inventory the swf is too large 
			6:36 PM <eric> 11:23 AM <eric> ^ that involves a change to the way a stack dragged from your pack appears... we now show it as the stack would appear in location instead of how it appears in your pack.
			6:37 PM <kevin> yeah, I didnt quite understand what that meant
			6:37 PM <kevin> ok
			6:37 PM <kevin> So, if you drop the bundle of grain
			6:37 PM <kevin> it will look the same as you drag it around your pack as it does on the gound
			6:37 PM <eric> and here is some more discussion:
			6:37 PM <eric> 12:16 PM <stewart> http://www.glitch.com/forum/ideas/24881/  — we swtiched away from using iconic view when dragging in-inventory? 
			6:37 PM <eric> 12:17 PM <scott> yah eric changed that to show what it will look like
			6:37 PM <eric> 12:21 PM <eric> yeah, the downside of the way it was, was that when you were dragging an item from your pack, it showed the iconic view, and some of the iconic views are not meant for this (too big, oriented differently) so it looked wrong. The downside of this new way is that the location views when organizing your pack is not as nice. The best solution would be to use the iconic view until you d
			6:37 PM <eric> rag it over the 
			6:37 PM <eric> 12:21 PM <eric> viewport, but that is more work.
			6:38 PM <kevin> ok, yeah, thats it, thanks. 
			6:38 PM <eric> So, I think I will revert the change
			6:39 PM <eric> and then find another way to fix this http://bugs.tinyspeck.com/9507
			6:39 PM <eric> who agrees that is the correct thing to do?
			6:39 PM <kevin> thanks for the detail
			6:40 PM <kevin> I agree
			6:40 PM <Kristi> I get what you are saying and I agree
			6:40 PM <michael> thirded
			
			*/
			
			var iiv:ItemIconView;
			iiv = new ItemIconView(itemstack.class_tsid, wh, state, 'center', false, false)
			
			Cursor.instance.startDragWith(iiv, false, endDrag);
			
			StageBeacon.mouse_move_sig.remove(_mouseMoveHandler);
			dragVO.clear();
			dragVO.dragged_itemstack = itemstack;
			if (getPackSlotForDraggedPISView()) getPackSlotForDraggedPISView().alpha = .5;
			PackDisplayManager.instance.dispatchEvent(new TSEvent(TSEvent.DRAG_STARTED, dragVO));
		}
		
		private function _mouseDownHandler(e:MouseEvent):void {
			TSFrontController.instance.goNotAFK();
			if (model.stateModel.menus_prohibited) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			var element:DisplayObject = e.target as DisplayObject;
			
			while (element != this) {
				if (element is PackItemstackView) {
					var pis_view:PackItemstackView = element as PackItemstackView;
					TipDisplayManager.instance.goAway();
					
					dragged_pis_view = pis_view;
					
					StageBeacon.mouse_move_sig.add(_mouseMoveHandler);
					StageBeacon.mouse_up_sig.add(_mouseUpHandler);
					
					break;
				}
				
				element = element.parent;
			}
			
			StageBeacon.stage.focus = StageBeacon.stage;//TODO : As this happens a lot, let's make a focus manager.
		}
		
		private function _clickHandler(e:MouseEvent):void {
			if (model.stateModel.menus_prohibited) {
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			var element:DisplayObject = e.target as DisplayObject;
			var focus_stage:Boolean = true;
			
			while (element != this) {
				if (element.name == 'opener') {
					
					PackDisplayManager.instance.setFocusedSlot(this.name, PackSlot(element.parent.parent).slot);
					PackDisplayManager.instance.toggleContainer(PackSlot(element.parent.parent).pis_view.tsid);
					TipDisplayManager.instance.goAway();
					break;
					
				} else if (element.name == 'container_toggler') {
					PackDisplayManager.instance.setFocusedSlot(this.name, PackSlot(element.parent.parent.parent).slot);
					PackDisplayManager.instance.toggleContainer(PackItemstackView(element.parent).tsid);
					TipDisplayManager.instance.goAway();
					break;
					
				} else if (element is PackItemstackView) {
					var pis_view:PackItemstackView = element as PackItemstackView;
					
					var itemstack:Itemstack = model.worldModel.getItemstackByTsid(pis_view.tsid);
					
					PackDisplayManager.instance.setFocusedSlot(this.name, PackSlot(element.parent.parent).slot);
					if(KeyBeacon.instance.pressed(Keyboard.CONTROL)) {
						//link the item in chat
						var chat_area:ChatArea = RightSideManager.instance.right_view.getChatToFocus();
						var item:Item = model.worldModel.getItemByTsid(itemstack.class_tsid);
						chat_area.input_field.setLinkText(item.label, TSLinkedTextField.LINK_ITEM+'|'+item.tsid);
						chat_area.focus();
						focus_stage = false;
					} else if (CONFIG::god) {
						; // satisfy compiler
						CONFIG::god {
							if (KeyBeacon.instance.pressed(Keyboard.K)) {
								TSFrontController.instance.doVerb(PackItemstackView(element).tsid, Item.CLIENT_DESTROY);
							} else if (KeyBeacon.instance.pressed(Keyboard.P)) {
								TSFrontController.instance.doVerb(PackItemstackView(element).tsid, Item.CLIENT_EDIT_PROPS);
							} else {
								TSFrontController.instance.startInteractionWith(TSSprite(element), true);
							}
						}
					} else {
						TSFrontController.instance.startInteractionWith(TSSprite(element), true);
					}
					
					break;
				}
				
				element = element.parent;
			}
			
			if(focus_stage) StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		public function getItemstackViewByTsid(tsid:String):PackItemstackView {
			var m:int;
			var len:int = pis_viewsA.length;
			for (m=0; m<len;m++) {
				if (pis_viewsA[m].tsid == tsid) {
					return pis_viewsA[m];
				}
			}
			return null;
		}
		
		private function _playSoundAfterItemstackChanges(itemstack:Itemstack):void {
			if (model.worldModel.getItemstackByTsid(itemstack.tsid).tsid == 'coin') {
			}
		}
		
		public function removeItemstackSpriteByTsid(itemstack_tsid:String):void {
			var len:int = pis_viewsA.length;
			var found_it:Boolean = false;
			for (var i:int=0; i<len;i++) {
				if (pis_viewsA[int(i)].tsid == itemstack_tsid) {
					//Console.warn('removin!')
					PackSlot(pis_viewsA[int(i)].parent.parent).removeStack(); // omy dumb
					pis_viewsA.splice(i, 1);
					found_it = true;
					break;
				}
			}
			
			CONFIG::debugging {
				if (!found_it) Console.error(itemstack_tsid+' not found');
			}
			
			// we no longer refresh in here, you must call it after removing (so you can control when it happens after a batch)
			//refresh();
		}

		// this removes it, but does not dispose the pis_view, because we want to reuse it
		public function moveItemstackSpriteByTsid(itemstack_tsid:String):void {
			var pis_view:PackItemstackView = getItemstackViewByTsid(itemstack_tsid);
			if (pis_view) {
				pis_view = PackSlot(pis_view.parent.parent).removeStack(false);
				if (!pis_view) {
					throw new Error('moveItemstackSpriteByTsidWTF2');
				}
			} else {
				throw new Error('moveItemstackSpriteByTsidWTF');
			}
		}
		
		public function addItemstackSpriteByTsid(itemstack_tsid:String):void {
			pis_viewsA.push(new PackItemstackView(itemstack_tsid, model.layoutModel.pack_itemicon_wh));
			// we no longer refresh in here, you must call it after adding (so you can control when it happens after a batch)
			//refresh()
		}
		
		public function refresh():void {
			if (!inited) return;
			placePackItemstackViewsAndSlots();
		}
		
		public override function get h():int {
			return _h;
		}
	}
}