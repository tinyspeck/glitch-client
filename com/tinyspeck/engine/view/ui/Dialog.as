package com.tinyspeck.engine.view.ui {
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.chat.InputField;
	
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.getQualifiedClassName;
	
	public class Dialog extends Sprite implements IFocusableComponent, IRefreshListener {
		protected var window_border:WindowBorder;
		protected var _close_bt:Button;
		protected var _close_bt_wh:int = 30;
		protected var _border_w:int = 2;
		protected var _outer_border_w:uint = 6;
		protected var _border_color:uint;
		protected var _border_alpha:Number = .15;
		protected var _close_bt_padd_right:int = 16;
		protected var _close_bt_padd_top:int = 16;
		protected var _base_padd:int = 10;
		protected var has_focus:Boolean;
		protected var transitioning:Boolean = false;
		protected var dest_x:int;
		protected var dest_y:int;
		protected var last_x:int;
		protected var last_y:int;
		protected var pointer:String;
		protected var no_border:Boolean = false;
		protected var bg_c:Number = 0xffffff;
		protected var bg_alpha:Number = 1;
		protected var _w:int;
		protected var _h:int;
		protected var _draggable:Boolean = false;
		protected var model:TSModelLocator;
		protected var gripper:DisplayObject;
		protected var gripper_padding:int = 6;
		protected var close_on_move:Boolean = true; // extenders can set to false if they need to stay open during a move
		protected var close_on_editing:Boolean = true; // extenders can set to false if they need to stay open during loco deco editing
		protected var corner_rad:int = 8;
		protected var outter_glow:GlowFilter = new GlowFilter();
		protected var is_dragging:Boolean;
		
		private var checked_start:Boolean;
		private var requires_focus:Boolean;
		
		public function Dialog():void {
			model = TSModelLocator.instance;
			
			_w = 500;
			_h = 300; //dynamic
			
			registerSelfAsFocusableComponent();
		}		
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur')
			}
			has_focus = false;
			
			// EC: WTF IS THIS FOR? WE NEVER ASSIGN closeFromUserInput as an ESC LISTENER THAT I CAN SEE
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, closeFromUserInput);
			stopListeningToNavKeys();
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus')
			}
			has_focus = true;
			startListeningToNavKeys();
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			//
		}
		
		protected function startListeningToNavKeys():void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_, allKeyHandler);
		}
		
		protected function stopListeningToNavKeys():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_, allKeyHandler);
		}
		
		protected function upArrowKeyHandler(e:KeyboardEvent):void {
			
		}
		
		protected function rightArrowKeyHandler(e:KeyboardEvent):void {
			
		}
		
		protected function downArrowKeyHandler(e:KeyboardEvent):void {
			
		}
		
		protected function leftArrowKeyHandler(e:KeyboardEvent):void {
			
		}
		
		public function escKeyHandler(e:KeyboardEvent):void {
			closeFromUserInput(e);
		}
		
		protected function enterKeyHandler(e:KeyboardEvent):void {
			
		}
		
		protected function allKeyHandler(e:KeyboardEvent):void {
			
		}
		
		protected function _construct():void {
			window_border = new WindowBorder(_w, _h, _border_w, bg_alpha, pointer, no_border, bg_c);
			window_border.corner_rad = corner_rad; //make the edges a little tighter for dialogs
			addChild(window_border);
			
			window_border.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownInHeaderHandler, false, 0, true);
			
			// close button
			_close_bt = makeCloseBt();
			addChild(_close_bt);
			
			// we were doing this when the window got focus, but we're not now, because we want it to work if the window has focus or not
			if (_close_bt) _close_bt.addEventListener(MouseEvent.CLICK, closeFromUserInput, false, 0, true);
			
			//setup the gripper
			gripper = new AssetManager.instance.assets.dialog_gripper();
			
			gripper.y = gripper_padding;
			gripper.visible = _draggable;
			
			if(_draggable){				
				window_border.addEventListener(MouseEvent.ROLL_OVER, showHandCursor, false, 0, true);
				window_border.addEventListener(MouseEvent.ROLL_OUT, resetCursor, false, 0, true);
			}
			
			addChild(gripper);
		}
		
		private static function showHandCursor(e:Event):void {
			Mouse.cursor = MouseCursor.HAND;
		}
		
		private static function resetCursor(e:Event):void {
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		protected function makeCloseBt():Button {
			var nudge:int = 2 - (_close_bt_wh % 2);
			var leg:int = nudge+(_close_bt_wh-10)/2;
			var sp:Sprite = new Sprite();
			var g:Graphics = sp.graphics;
			g.lineStyle(3, 0xc33823, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			g.moveTo(nudge, nudge);
			g.lineTo(leg, leg);
			g.moveTo(nudge, leg);
			g.lineTo(leg, nudge);

			return new Button({
				graphic: sp,
				name: '_close_bt',
				c: 0xffffff,
				high_c: 0xffffff,
				disabled_c: 0xffffff,
				shad_c: 0xffffff,
				inner_shad_c: 0xe5aaa1,
				h: _close_bt_wh,
				w: _close_bt_wh
			});
		}
		
		protected function makeBackBt():Button {
			var back_DO:DisplayObject = new AssetManager.instance.assets.back_circle();
			var back_bt:Button = new Button({
				label: '',
				name: 'back',
				graphic: back_DO,
				graphic_hover: new AssetManager.instance.assets.back_circle_hover(),
				graphic_disabled: new AssetManager.instance.assets.back_circle_disabled(),
				w: back_DO.width,
				h: back_DO.height,
				draw_alpha: 0
			});
			back_bt.x = -back_DO.width/2 + 1;
			back_bt.y = 12;
			
			return back_bt;
		}
		
		protected function closeFromUserInput(e:Event=null):void {
			if (_close_bt.disabled) return;
			end(true);
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		public function end(release:Boolean):void {
			if (parent) {
				dispatchEvent(new TSEvent(TSEvent.CLOSE, this));
				parent.removeChild(this);
			}
			if (release) TSFrontController.instance.releaseFocus(this);
			
			//remove it from the refresh list
			TSFrontController.instance.unRegisterRefreshListener(this);
		}
		
		protected var focus_details:Object;
		public function canStart(requires_focus:Boolean):Boolean {
			checked_start = true;
			this.requires_focus = requires_focus;
			
			if (model.moveModel.moving && close_on_move) {
				Benchmark.addCheck('not starting '+getQualifiedClassName(this)+' because we are moving');
				CONFIG::debugging {
					//if (parent) {
					Console.warn('not starting '+getQualifiedClassName(this)+' because we are moving');
					//}
				}
				return false;
			} else if (model.stateModel.editing && close_on_editing) {
				Benchmark.addCheck('not starting '+getQualifiedClassName(this)+' because we are editing');
				CONFIG::debugging {
					//if (parent) {
					Console.warn('not starting '+getQualifiedClassName(this)+' because we are editing');
					//}
				}
				return false;
			}
			
			//if this dialog needs focus, try and get it
			if(requires_focus){
				if (model.stateModel.focused_component is InputField) {
					// in this case we don't really want to steal focus from the input field
					// so we just tuck the dialog in focus history, to keep focus
					// from falling back to tsmainview
					TSFrontController.instance.putInFocusStack(this);
					return true;
				} else {
					if (TSFrontController.instance.requestFocus(this, focus_details)) {
						return true;
					}
				}
				
				CONFIG::debugging {
					Console.warn('could not take focus');
				}
				return false;
			}
			
			return true;
		}
		
		public function start():void {
			if (parent) end(false);
			
			//if we haven't checked to see if we can start, do that now!
			if (!checked_start && !canStart(requires_focus)){
				checked_start = false;
				return;
			}
			
			TSFrontController.instance.getMainView().addView(this);
			TipDisplayManager.instance.goAway();
			
			dispatchEvent(new TSEvent(TSEvent.STARTED));
			
			invalidate(true);
			
			//add it to the refresh list
			TSFrontController.instance.registerRefreshListener(this);
		}
		
		public function refresh():void {
			invalidate();
			if(!transitioning) {
				checkBounds();
			}
		}
		
		protected function invalidate(force:Boolean = false):void {
			if (force) {
				onInvalidate();
			} else {
				addEventListener(Event.EXIT_FRAME, onInvalidate, false, 0, true);
			}
		}
		
		protected function onInvalidate(event:Event = null):void {
			removeEventListener(Event.EXIT_FRAME, onInvalidate);
			
			//if no parent then bail out now
			if(!parent) return;
			
			if (model.moveModel.moving && close_on_move) {
				if (parent) {
					CONFIG::debugging {
						Console.warn('closing '+getQualifiedClassName(this)+' because we are moving')
					}
					forcedToEndDueToMoving();
				}
				return;
			} else if (model.stateModel.editing && close_on_editing) {
				if (parent) {
					CONFIG::debugging {
						Console.warn('closing '+getQualifiedClassName(this)+' because we are editing')
					}
					forcedToEndDueToEditing();
				}
				return;
			}
			
			_jigger();
			_draw();
			_place();
		}
		
		protected function forcedToEndDueToMoving():void {
			end(true);
		}
		
		protected function forcedToEndDueToEditing():void {
			end(true);
		}
		
		protected function _place():void {
			if (last_x || last_y) {
				dest_x = last_x;
				dest_y = last_y;
			} else {
				dest_x = Math.round((model.layoutModel.loc_vp_w-_w)/2) + model.layoutModel.gutter_w;
				dest_y = Math.round((model.layoutModel.loc_vp_h-_h)/2) + model.layoutModel.header_h;
				
				dest_x = Math.max(dest_x, 0);
				dest_y = Math.max(dest_y, 0);
			}
			
			if (!transitioning) {
				x = dest_x;
				y = dest_y;
			}
		}
		
		protected function _jigger():void {
			_close_bt.x = _w - _close_bt.width - _close_bt_padd_right;
			_close_bt.y = _close_bt_padd_top;
			
			gripper.x = int(_w/2 - gripper.width/2);
		}
		
		protected function _draw():void {
			window_border.setSize(_w, _h, pointer);
			
			//put a semi-trans border on it
			if(_outer_border_w > 0 && !no_border){
				outter_glow.blurX = outter_glow.blurY = _outer_border_w*2;
				outter_glow.strength = 100;
				outter_glow.color = _border_color;
				outter_glow.alpha = _border_alpha;
				filters = [outter_glow];
			}
			else {
				filters = null;
			}
		}
		
		protected function mouseDownInHeaderHandler(event:MouseEvent):void {
			// move it to top of stack
			if (parent) TSFrontController.instance.getMainView().addView(this);
			
			if (_draggable) {
				startDragging(event);
			}
		}
		
		protected function startDragging(event:MouseEvent):void {
			if (event.target is Button) return;
			is_dragging = true;
			startDrag();
			StageBeacon.mouse_up_sig.add(endDragging);
			StageBeacon.mouse_move_sig.add(moveDragging);
		}
		
		protected function moveDragging(event:MouseEvent):void {
			checkBounds();
		}
		
		protected function endDragging(event:MouseEvent):void {
			//make sure that the dialog stays grabbable					
			is_dragging = false;
			stopDrag();
			StageBeacon.mouse_up_sig.remove(endDragging);
			StageBeacon.mouse_move_sig.remove(moveDragging);
			
			checkBounds();
		}
		
		protected function checkBounds():void {
			const viewable_px:uint = 65; // we want to make sure at least this many pixels of the dialog are on screen at all times
			const min_allowed_x:int = -_w + viewable_px;
			const max_allowed_x:int = model.layoutModel.gutter_w*2 + model.layoutModel.overall_w - viewable_px;
			const min_allowed_y:int = 0;
			const max_allowed_y:int = StageBeacon.stage.stageHeight - viewable_px;
			
			if(x < min_allowed_x) x = min_allowed_x;
			if(x > max_allowed_x) x = max_allowed_x;
			
			if(y < min_allowed_y) y = min_allowed_y;
			if(y > max_allowed_y) y = max_allowed_y;
				
			// only remember this if we're open!			
			if (_draggable && parent) {
				last_y = y;
				last_x = x;
			}
		}
	}
}