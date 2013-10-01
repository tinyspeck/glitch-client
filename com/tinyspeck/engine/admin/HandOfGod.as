package com.tinyspeck.engine.admin
{
	import com.tinyspeck.bridge.CartesianMouseEvent;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.admin.locodeco.LocoDecoConstants;
	import com.tinyspeck.engine.admin.locodeco.components.MoveableControlPoints;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingItemstackModifyVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackAddDelConsumer;
	
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	public final class HandOfGod implements IFocusableComponent, ILocItemstackAddDelConsumer, IMoveListener
	{
		public static const instance:HandOfGod = new HandOfGod();
		private static const KEY_REPEAT_DELAY:int = 250; // ms
		
		private var initialized:Boolean;
		private var has_focus:Boolean;
		private var stage:Stage;
		private var model:TSModelLocator;
		private var gameRenderer:LocationRenderer;
		private var controlPoints:MoveableControlPoints;
		
		private var selection:LocationItemstackView;
		private var lastHighlight:LocationItemstackView;
		
		/** While the mouse is down, this specifies whether it originated over the viewport */
		private var mouseDownOriginatedInViewport:Boolean;
		
		// keyboard
		private var keyboard:KeyBeacon;
		/** True when onKeyDown has executed, false when keyUpHandler runs */
		private var keyDown:Boolean;
		/** When the last keypress actually did something (sometimes after pressed) */
		private var firstKeyEventAt:Number = NaN;
		
		public function HandOfGod():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init():void {
			if (initialized) return;
			initialized = true;
			
			model = TSModelLocator.instance;
			stage = StageBeacon.stage;
			gameRenderer = TSFrontController.instance.getMainView().gameRenderer;
			keyboard = KeyBeacon.instance;
			
			controlPoints = new MoveableControlPoints();
			controlPoints.stage = stage;
			
			model.stateModel.registerCBProp(onHandOfGodChange, 'hand_of_god');
			TSFrontController.instance.registerMoveListener(this);
			registerSelfAsFocusableComponent();
		}
		
		public function start():Boolean {
			if (TSFrontController.instance.requestFocus(this)) {
				// I think we want to show the avatar, for scale comparison
				// gameRenderer.locationView.middleGroundRenderer.hidePCs();
				return true;
			}
			
			return false;
		}
		
		public function end():void {
			TSFrontController.instance.releaseFocus(this);
			gameRenderer.locationView.middleGroundRenderer.showPCs();
		}
		
		/** Returns the increment/decrement for rotation and positioning */
		private function getIncrement():int {
			var xcrement:int = LocoDecoConstants.DEFAULT_INCREMENT;
			if (keyboard.pressed(Keyboard.SHIFT)) {
				xcrement = LocoDecoConstants.SHIFT_INCREMENT;
			} else if (keyboard.pressed(Keyboard.Z)) {
				xcrement = 1;
			}
			return xcrement;
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// Handlers //////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		private function startListeningForControlEvts():void {
			StageBeacon.enter_frame_sig.add(onEnterFrame);
			
			// track the mouse for deco selection
			StageBeacon.mouse_up_sig.add(onMouseUp);
			StageBeacon.mouse_down_sig.add(onMouseDown);
			StageBeacon.mouse_move_sig.add(onMouseMove);
			StageBeacon.cartesian_mouse_wheel.add(onMouseWheel);
			
			// keybindings!
			StageBeacon.key_down_sig.add(onKeyDown);
			StageBeacon.key_up_sig.add(onKeyUp);
			
			keyboard.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterKey);
			// higher priority so HoG always gets the escape event before super search and stamping
			// so HoG can decide to not close if one of those two are open first (escape closes SS and stops S)
			keyboard.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey, false, 1);
			keyboard.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DELETE, onDeleteKey);
			
			TSFrontController.instance.startListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function stopListeningForControlEvts():void {
			StageBeacon.enter_frame_sig.remove(onEnterFrame);
			
			// stop tracking mouse
			StageBeacon.mouse_up_sig.remove(onMouseUp);
			StageBeacon.mouse_down_sig.remove(onMouseDown);
			StageBeacon.mouse_move_sig.remove(onMouseMove);
			StageBeacon.cartesian_mouse_wheel.remove(onMouseWheel);
			
			// kill keybindings
			StageBeacon.key_down_sig.remove(onKeyDown);
			StageBeacon.key_up_sig.remove(onKeyUp);
			
			keyboard.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterKey);
			keyboard.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey);
			keyboard.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DELETE, onDeleteKey);
			
			TSFrontController.instance.stopListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function zoomKeyHandler(e:KeyboardEvent):void {
			// it's important that we don't add shared listeners directly to TSFC
			// because where one class has started listening, another might
			// remove the same listener by accident, so the first class fails
			TSFrontController.instance.zoomKeyHandler(e);
		}
		
		private function onKeyDown(e:KeyboardEvent):void {;
			if (selection) {
				checkForItemScaleKeys(e.keyCode);
			}
			
			// key repeat buster
			if (keyDown) return;
			keyDown = (e.keyCode != Keyboard.CONTROL) && (e.keyCode != Keyboard.SHIFT) && (e.keyCode != Keyboard.ALTERNATE) && (e.keyCode != Keyboard.COMMAND)
		}
		
		private function onKeyUp(e:KeyboardEvent):void {
			// reset repeat delay whenever all the arrow keys are depressed
			if (!keyboard.anyArrowKeysPressed()) {
				keyDown = false;
				firstKeyEventAt = NaN;
			}
		}
		
		private function onEnterKey(event:Event):void {
			// commit changes
			if (selection) {
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(selection.tsid);
				if (itemstack) {
					itemstack.x = selection.x;
					itemstack.y = selection.y;
					TSFrontController.instance.genericSend(
						new NetOutgoingItemstackModifyVO(itemstack.tsid, itemstack.x, itemstack.y),
						function (rm:NetResponseMessageVO):void { SoundMaster.instance.playSound('CLICK_SUCCESS') },
						function (rm:NetResponseMessageVO):void { SoundMaster.instance.playSound('CLICK_FAILURE') }
					);
				}
				deselect(selection);
			}
		}
		
		private function onEscapeKey(event:Event):void {
			// abort if super search is open (escape closes it)
			if (TSFrontController.instance.getMainView().superSearchVisible) {
				return;
			}
			
			// abort if we are currently stamping itemstacks (escape stops it)
			if (model.stateModel.is_stamping_itemstacks) {
				return;
			}
			
			// undo uncommitted changes
			if (selection) {
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(selection.tsid);
				if (itemstack) {
					selection.x = itemstack.x;
					selection.y = itemstack.y;
					SoundMaster.instance.playSound('CLICK_SUCCESS');
				}
				deselect(selection);
				return;
			}
			
			// close HoG
			TSFrontController.instance.stopHandOfGodMode();
		}
		
		private function onDeleteKey(event:Event):void {
			if (selection) destroySelection(selection);
		}
		
		private function editProps(itemstack:LocationItemstackView):void {
			if (itemstack) {
				TSFrontController.instance.doVerb(itemstack.tsid, Item.CLIENT_EDIT_PROPS);
				SoundMaster.instance.playSound('CLICK_SUCCESS')
			}
		}
		
		private function destroySelection(itemstack:LocationItemstackView):void {
			if (itemstack) {
				TSFrontController.instance.doVerb(itemstack.tsid, Item.CLIENT_DESTROY);
				SoundMaster.instance.playSound('CLICK_SUCCESS')
			}
		}
		
		private function onHandOfGodChange(enabled:Boolean):void {
			deselectAll();
		}
		
		private function onEnterFrame(ms_elapsed:int):void {
			const lm:LayoutModel = model.layoutModel;
			const xcrement:int = getIncrement();
			const inc:int = 5*getIncrement();
			
			var old_x:int;
			var old_y:int;
			var new_x:int;
			var new_y:int;
			
			// if the mouse is dragging across the edges of the VP, scroll it
			if (StageBeacon.mouseIsDown && mouseDownOriginatedInViewport && selection) {
				var moving:Boolean;
				
				// pan the world
				old_x = new_x = model.layoutModel.loc_cur_x;
				old_y = new_y = model.layoutModel.loc_cur_y;
				
				if (StageBeacon.stage_mouse_pt.x >= (lm.gutter_w + lm.loc_vp_w)) {
					// pan right
					new_x += inc;
					moving = true;
				} else if (StageBeacon.stage_mouse_pt.x < lm.gutter_w) {
					// pan left
					new_x -= inc;
					moving = true;
				}
				
				// allow diagonal movement by separating the IF blocks
				if (StageBeacon.stage_mouse_pt.y < lm.header_h) {
					// pan up
					new_y -= inc;
					moving = true;
				} else if (StageBeacon.stage_mouse_pt.y >= (lm.header_h + lm.loc_vp_h)) {
					// pan down
					new_y += inc;
					moving = true;
				}
				
				if (moving) {
					// pan the renderer
					gameRenderer.moveTo(new_x, new_y);
					// reset the move's start position
					controlPoints.restartMove();
				}
				return;
			}
			
			// return if no keys are pressed, or the key repeat interval hasn't elapsed
			if (!keyDown || (!isNaN(firstKeyEventAt) && ((getTimer() - firstKeyEventAt) < KEY_REPEAT_DELAY))) return;
			
			var repeatableKeyEventOccurred:Boolean;
			if (selection) {
				// move the selected deco(s)
				if (keyboard.pressed(Keyboard.RIGHT)) {
					selection.x += xcrement;
					repeatableKeyEventOccurred = true;
				} else if (keyboard.pressed(Keyboard.LEFT)) {
					selection.x -= xcrement;
					repeatableKeyEventOccurred = true;
				}
				
				// allow diagonal movement by separating the IF blocks
				if (keyboard.pressed(Keyboard.UP)) {
					selection.y -= xcrement;
					repeatableKeyEventOccurred = true;
				} else if (keyboard.pressed(Keyboard.DOWN)) {
					selection.y += xcrement;
					repeatableKeyEventOccurred = true;
				}
			} else {
				// pan the world
				new_x = lm.loc_cur_x;
				new_y = lm.loc_cur_y;
				
				if (keyboard.pressed(Keyboard.RIGHT)) {
					new_x += inc;
					repeatableKeyEventOccurred = true;
				} else if (keyboard.pressed(Keyboard.LEFT)) {
					new_x -= inc;
					repeatableKeyEventOccurred = true;
				}
				
				// allow diagonal movement by separating the IF blocks
				if (keyboard.pressed(Keyboard.UP)) {
					new_y -= inc;
					repeatableKeyEventOccurred = true;
				} else if (keyboard.pressed(Keyboard.DOWN)) {
					new_y += inc;
					repeatableKeyEventOccurred = true;
				}
				
				gameRenderer.moveTo(new_x, new_y);
			}
			
			// if a valid key was pressed, then we start counting the interval
			if (repeatableKeyEventOccurred && isNaN(firstKeyEventAt)) firstKeyEventAt = getTimer();
		}
		
		/** Pans the viewport using a 2D mousewheel */
		private function onMouseWheel(e:CartesianMouseEvent):void {
			if (!gameRenderer.contains(e.target as DisplayObject)) {
				// however bug [2060]: you may be trying to draw geometry over
				// a location with no gradient, so detect that before giving up
				if ((e.target != TSFrontController.instance.getMainView()) || !gameRenderer.hitTestPoint(e.stageX, e.stageY)) {
					return;
				}
			}
			
			// Webkit may give you TWO non-zero values as it allows simultaneous scrolling
			const new_x:int = model.layoutModel.loc_cur_x-int(e.xDelta*10);
			const new_y:int = model.layoutModel.loc_cur_y-int(e.yDelta*10);
			gameRenderer.moveTo(new_x, new_y);
		}
		
		private function onMouseDown(e:MouseEvent):void {
			// only allow clicking on the renderer, skip dialogs above it
			if (!gameRenderer.contains(e.target as DisplayObject)) {
				if ((e.target != TSFrontController.instance.getMainView()) || !gameRenderer.hitTestPoint(e.stageX, e.stageY)) {
					mouseDownOriginatedInViewport = false;
					return;
				}
			}
			
			mouseDownOriginatedInViewport = true;
			
			// you're probably starting a drag
			if (controlPoints.contains(e.target as DisplayObject)) {
				// except if the shift key is down, then you're deselecting it
				if (!e.shiftKey) return;
			}
			
			const newSelection:LocationItemstackView = chooseMostLikelyItemstackForSelection(gameRenderer.getItemstacksUnderCursor());
			
			// if there isn't a new selection, we have nothing to do here
			if (!newSelection) return;
			
			// if shift-clicking the already-selected deco, deselect
			if ((selection == newSelection) && e.shiftKey) {
				deselect(selection);
			} else {
				// basic single selection; start a move immediately
				select(newSelection, true);
			}
		}
		
		private function onMouseMove(e:MouseEvent):void {
			if (StageBeacon.mouseIsDown && controlPoints.contains(e.target as DisplayObject)) {
				// temporarily disable highlighting and hide the control points
				if (selection) {
					controlPoints.visible = false;
					selection.unglow();
					return;
				}
			}
			
			// if we're hovering over the map or other UI,
			// remove existing highlights and don't highlight anything new
			if (!gameRenderer.contains(e.target as DisplayObject)) {
				if (lastHighlight && (lastHighlight != selection)) {
					lastHighlight.enableGSMoveUpdates();
					lastHighlight.unglow();
					lastHighlight = null;
					gameRenderer.buttonMode = false;
					gameRenderer.useHandCursor = false;
				}
				return;
			}
			
			// find the object that you are most likely selecting
			const newHighlight:LocationItemstackView = chooseMostLikelyItemstackForSelection(gameRenderer.getItemstacksUnderCursor());
			
			// if the new highlight is already highlighted, we're done
			if (newHighlight == lastHighlight) return;
			
			// if there is a new highlight and it's our selection, we're done
			if (newHighlight && (newHighlight == selection)) return;
			
			// at this point we can be sure that there is a new highlight
			// and it is not over the existing highlight or selection
			if (lastHighlight && (lastHighlight != selection)) {
				lastHighlight.enableGSMoveUpdates();
				lastHighlight.unglow();
				lastHighlight = null;
			}
			
			// draw the new highlight
			lastHighlight = newHighlight;
			if (newHighlight) {
				// disallow itemstack from moving when selected
				newHighlight.disableGSMoveUpdates();
				newHighlight.glow();
				
				// make it apparent that you can click the itemstack
				gameRenderer.buttonMode = true;
				gameRenderer.useHandCursor = true;
			} else {
				gameRenderer.buttonMode = false;
				gameRenderer.useHandCursor = false;
			}
		}
		
		private var changed_item_scalesV:Vector.<Item> = new Vector.<Item>();
		private function onMouseUp(e:MouseEvent):void {
			if (selection) {
				// when clicking an itemstack, highlighting is disabled
				controlPoints.visible = true;
				selection.glow();
				
				if (keyboard.pressed(Keyboard.P)) {
					// P click open edit props page
					editProps(selection);
				} else if (keyboard.pressed(Keyboard.K)) {
					// K click destroys the itemstack
					destroySelection(selection);
				}
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// Changing Item Scales //////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		private function checkForItemScaleKeys(key_code:uint):void {
			if (key_code == (Keyboard.EQUAL) || key_code == (Keyboard.MINUS) || key_code == (Keyboard.NUMBER_0) || key_code == (Keyboard.NUMBER_1)) {
				const item:Item = selection.item;
				const was_scale:Number = item.adjusted_scale;
				
				if (item.is_furniture || item.is_special_furniture) {
					return;
				}
				
				if (key_code == (Keyboard.NUMBER_0)) {
					item.adjusted_scale = item.adjusted_scale_as_loaded;
				} else if (key_code == (Keyboard.NUMBER_1)) {
					item.adjusted_scale = 1;
				} else {
					const inc:Number = (key_code == (Keyboard.MINUS)) ? -.1 : .1;
					item.adjusted_scale = MathUtil.clamp(.1, 2, item.adjusted_scale+inc);
				}
				
				// keep it to the hundredths and fix precisions
				var fix:Number = Math.round(item.adjusted_scale*100);
				item.adjusted_scale = fix/100;
				
				CONFIG::debugging {
					Console.info(item.tsid+' '+item.adjusted_scale_as_loaded+' -> '+item.adjusted_scale);
				}
				
				if (item.adjusted_scale != was_scale) {
					gameRenderer.bruteForceReloadLIVs(item.tsid);
				}
				
				if (item.adjusted_scale != item.adjusted_scale_as_loaded) {
					// add it it if needed!
					if (changed_item_scalesV.indexOf(item) == -1) {
						changed_item_scalesV.push(item);
					}
				} else {
					// remove it if needed!
					if (changed_item_scalesV.indexOf(item) != -1) {
						changed_item_scalesV.splice(changed_item_scalesV.indexOf(item), 1);
					}
				}
			}
		}
		
		public function promptForItemScaleChanged():Boolean {
			if (!changed_item_scalesV.length) return false;
			
			var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.title = 'You Changed Some Item Scales!';
			
			var txt:String = '';
			
			var item:Item;
			for (var i:int;i<changed_item_scalesV.length;i++) {
				item = changed_item_scalesV[i];
				txt+= '<b>'+item.tsid+'</b> '+item.adjusted_scale_as_loaded+' -> '+item.adjusted_scale+'<br>';
			}
			
			txt+= '<br>Do you want to save these changes?'
			
			cdVO.txt = txt;
			cdVO.choices = [
				{value: false, label: 'NO!!'},
				{value: true, label: 'Yes Please!'}
			];
			
			cdVO.callback = onPromptForItemScaleChangedResponse;
			TSFrontController.instance.confirm(cdVO);
			
			return true;
		}
		
		private function onPromptForItemScaleChangedResponse(value:*):void {
			if (value !== true) {
				TSFrontController.instance.stopHandOfGodMode(false);
				return;
			}
			saveItemScale();
		}
		
		private function saveItemScale():void {
			var idsA:Array = [];
			var scalesA:Array = [];
			for (var i:int;i<changed_item_scalesV.length;i++) {
				idsA.push(changed_item_scalesV[i].tsid);
				scalesA.push(changed_item_scalesV[i].adjusted_scale);
			}
			
			if (!idsA.length) {
				return;
			}
			
			CONFIG::debugging {
				Console.info(idsA.join(','));
				Console.info(scalesA.join(','));
			}
			
			API.changeItemScale(idsA.join(','), scalesA.join(','), onChangeItemScaleResponse);
		}
		
		private function onChangeItemScaleResponse(success:Boolean, rsp:Object):void {
			var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			if (success) {
				cdVO.title = 'Saving Was a Grand Success!';
				cdVO.txt = 'You will need to <b><a target="_publisher" href="'+model.flashVarModel.root_url+'god/item_publisher.php">republish items</a></b> now!';
				cdVO.choices = [
					{value: true, label: 'Thanks!'}
				];

				for (var i:int;i<changed_item_scalesV.length;i++) {
					changed_item_scalesV[i].adjusted_scale_as_loaded = changed_item_scalesV[i].adjusted_scale;
				}
				
				changed_item_scalesV.length = 0;
				
				TSFrontController.instance.stopHandOfGodMode(false);
			} else {
				cdVO.title = 'Saving of Item Scales Failed';
				cdVO.txt = (rsp && rsp.error) ? rsp.error : 'unknown';
				cdVO.txt+= '<br><br>Try again?';
				cdVO.choices = [
					{value: false, label: 'I Give Up'},
					{value: true, label: 'Yes, Try Again'}
				];
				cdVO.callback = onPromptForItemScaleChangedResponse;
			}
			
			TSFrontController.instance.confirm(cdVO);
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// SELECTION /////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		private function chooseMostLikelyItemstackForSelection(itemstacks:Vector.<LocationItemstackView>):LocationItemstackView {
			var itemstack:LocationItemstackView;
			var mostLikely:LocationItemstackView = null;
			// last item in the vector is above previous items
			for (var i:int=itemstacks.length-1; i != -1; --i) {
				itemstack = itemstacks[i];
				if (selection == itemstack) {
					// no matter what, the existing selection wins out
					mostLikely = itemstack;
					break;
				} else if (mostLikely) {
					// do nothing, we already selected a candidate
				} else {
					mostLikely = itemstack;
				}
			}
			return mostLikely;
		}
		
		public function select(itemstack:LocationItemstackView, startMove:Boolean = false):void {
			// always deselect existing selections
			deselectAll();
			
			selection = itemstack;
			selection.glow();
			gameRenderer.registerControlPoint(controlPoints);
			controlPoints.target = selection;
			
			// disallow itemstack from moving when selected
			selection.disableGSMoveUpdates();
			
			// this will allow you to mouse down on a new itemstack and start dragging immediately
			if (StageBeacon.mouseIsDown && startMove) {
				controlPoints.startMove();
			}
		}
		
		private function deselect(itemstack:LocationItemstackView):void {
			if (selection && (itemstack == selection)) {
				gameRenderer.unregisterControlPoint(controlPoints);
				controlPoints.target = null;
				selection.enableGSMoveUpdates();
				selection.unglow();
				selection = null;
			}
		}
		
		private function deselectAll():void {
			if (selection) deselect(selection);
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// FOCUS /////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			//
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function blur():void {
			has_focus = false;
			stopListeningForControlEvts();
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			has_focus = true;
			startListeningForControlEvts();
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// ILocItemstackAddDelConsumer ///////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function onLocItemstackAdds(tsids:Array):void {
			// don't care
		}
		
		public function onLocItemstackDels(tsids:Array):void {
			// if our current selection was deleted
			if (selection && (tsids.indexOf(selection.tsid) != -1)) {
				deselect(selection);
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// IMoveListener /////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function moveLocationHasChanged():void {
			//
		}
		
		public function moveLocationAssetsAreReady():void {
			//
		}
		
		public function moveMoveStarted():void {
			deselectAll();
		}
		
		public function moveMoveEnded():void {
			//
		}
	}
}
