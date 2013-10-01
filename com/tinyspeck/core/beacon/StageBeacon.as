package com.tinyspeck.core.beacon {
	CONFIG const event_debug:Boolean = false;
	CONFIG const focus_debug:Boolean = false;

	import com.tinyspeck.bridge.CartesianMouseEvent;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.bridge.PrefsModel;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.util.BoundedAverageValueTracker;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import org.osflash.signals.PrioritySignal;
	import org.osflash.signals.Signal;

	/**
	 * Use this class instead of adding listeners to the Stage so we can
	 * accurately time and dispatch the gameloop, and for performance.
	 */
	public class StageBeacon {
		/** pre_throttled_sig is sent this many MS before throttled_sig */
		public static const PRE_THROTTLE_DELAY:Number = 1000;
		
		public static const MAX_MS_PER_LOOP:int = 125;
		
		/** Sends no arguments; occurs on ACTIVATE */
		public static const activate_sig:Signal = new Signal();
		
		/** Sends no arguments; occurs on DEACTIVATE */
		public static const deactivate_sig:Signal = new Signal();
		
		/** Sends a (Boolean) with the current state of browser focus */
		public static const flash_focus_changed_sig:Signal = new Signal(Boolean);
		
		/** Sends no arguments; occurs PRE_THROTTLE_MS before we throttle the SWF */
		public static const pre_throttle_sig:Signal = new Signal();
		
		/** Sends no arguments; occurs when we throttle the SWF manually */
		public static const throttled_sig:Signal = new Signal();
		
		/** Sends no arguments; synonymous with activate_sig */
		public static const unthrottled_sig:Signal = new Signal();
		
		/**
		 * Sends an (int) of time elapsed in ms since last gameloop.
		 * 
		 * The game_loop runs independently of enter_frame and render,
		 * and usually much more often, so we simulate physics and keystrokes
		 * between frames.
		 */
		public static const game_loop_sig:Signal = new Signal(int);
		
		/** Sends no arguments; occurs immediately after the game_loop */
		public static const game_loop_end_sig:Signal = new Signal();
		
		/** Sends an (int) of the time elapsed in ms since last ENTER_FRAME */
		public static const enter_frame_sig:PrioritySignal = new PrioritySignal(int);
		
		/**
		 * Sends no arguments; occurs after each frame is fully constructed,
		 * just before rendering takes places, and usually occurs less
		 * frequently than the game_loop.
		 */
		public static const render_sig:Signal = new Signal();
		
		/** Sends a (FocusEvent) on focus in */
		public static const focus_in_sig:Signal = new Signal(FocusEvent);
		
		/** Sends a (FocusEvent) on focus out */
		public static const focus_out_sig:Signal = new Signal(FocusEvent);
		
		/** Sends a (MouseEvent) on mouse move */
		public static const mouse_move_sig:Signal = new Signal(MouseEvent);
		
		/** Sends a (MouseEvent) on mouse down */
		public static const mouse_down_sig:Signal = new Signal(MouseEvent);
		
		/** Sends a (MouseEvent) on mouse up */
		public static const mouse_up_sig:Signal = new Signal(MouseEvent);
		
		/** Sends a (MouseEvent) of the last mouse click */
		public static const mouse_click_sig:Signal = new Signal(MouseEvent);
		
		/** Sends a (Event) when the mouse leaves the stage */
		public static const mouse_leave_sig:Signal = new Signal(Event);
		
		/** Sends a (MouseEvent) when the mouse rolls over the stage */
		public static const mouse_roll_over_sig:Signal = new Signal(MouseEvent);
		
		/** Sends a (MouseEvent) when the mouse rolls over the stage */
		public static const mouse_roll_out_sig:Signal = new Signal(MouseEvent);
		
		/** Sends a (CartesianMouseEvent) when the mouse scrolls in 2D */
		public static const cartesian_mouse_wheel:Signal = new Signal(CartesianMouseEvent);
		
		/** Sends no arguments; occurs when the stage resizes */
		public static const resize_sig:Signal = new Signal();
		
		/** Sends a (KeyboardEvent) on KeyboardEvent.KEY_DOWN */
		public static const key_down_sig:Signal = new Signal(KeyboardEvent);
		
		/** Sends a (KeyboardEvent) on KeyboardEvent.KEY_UP */
		public static const key_up_sig:Signal = new Signal(KeyboardEvent);
		
		/** The current location of the mouse as a Point */
		public static const stage_mouse_pt:Point = new Point();
		
		/** The last location of the mouse when down as a Point */
		public static const last_mouse_down_pt:Point = new Point();
		
		public static const game_parent:Sprite = new Sprite();
		
		/** Set externally by MoveModel; avoids Engine dependency of MoveModel */
		public static var isMoving:Boolean = false;
		
		/** Set externally by NetModel; avoids Engine dependency of NetModel */
		public static var isLoggedIn:Boolean = false;
		
		// internal state
		private static var _stage:Stage;
		private static var _swf_is_pre_throttled:Boolean;
		private static var _swf_is_throttled:Boolean;
		private static var _swf_is_activated:Boolean;
		private static var _mouseIsDown:Boolean;

		/**
		 * GameLoop should run as often as possible between frames
		 * to catch user input and network traffic.
		 * 
		 * Note: A delay lower than 20 milliseconds is not recommended.
		 * Timer frequency is limited to 60 frames per second, meaning a delay
		 * lower than 16.6 milliseconds causes runtime problems.
		 */
		private static const gameloop_timer:Timer = new Timer(20);

		private static var gameloop_timestep:int;
		private static var gameloop_accumulator:int;
		private static var gameloop_start_time:int;
		private static var enter_frame_start_time:int;
		private static var inactivity_start_time:Number = NaN;
		
		private static const averageFrameTimeTracker:BoundedAverageValueTracker = new BoundedAverageValueTracker(30);
		
		private static var flashVarModel:FlashVarModel;
		private static var prefsModel:PrefsModel;
		
		private static var _last_mouse_move:int;
		private static var _flash_has_focus:Boolean;
		
		CONFIG::event_debug private static var gameloop_count:int = 0;
		CONFIG::event_debug private static var enter_frame_count:int = 0;
		CONFIG::event_debug private static var render_count:int = 0;
		
		public static function init(stage:Stage, fvm:FlashVarModel, pm:PrefsModel=null):void {
			flashVarModel = fvm;
			prefsModel = pm;
			_stage = stage;
			
			game_parent.name = 'game_parent';
			game_parent.tabChildren = false;
			game_parent.tabEnabled = false;
			
			gameloop_timestep = Math.round(1000 / TSEngineConstants.TARGET_PHYSICS_FRAMERATE);
			gameloop_timer.delay = gameloop_timestep;
			gameloop_timer.addEventListener(TimerEvent.TIMER, onGameloopTimer);
			gameloop_timer.start();
			
			stage.addEventListener(Event.ACTIVATE, onActivate);
			stage.addEventListener(Event.DEACTIVATE, onDeactivate);
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(Event.RENDER, onRender);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			stage.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
			stage.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);
			stage.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			stage.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			stage.addEventListener(MouseEvent.CLICK, onClick, true, 333);
			
			stage.addEventListener(CartesianMouseEvent.CARTESIAN_MOUSE_WHEEL, onCartesianMouseWheel);
			
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
			stage.addEventListener(MouseEvent.MOUSE_UP, onCaptureMouseUp, true);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onCaptureMouseDown, true);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onCaptureKeyDown, true);
			
			if (fvm.use_set_timeout_controller) {
				SetTimeoutController.init();
			}
			
			gameloop_start_time = getTimer();
			enter_frame_start_time = getTimer();
		}
		
		public static function get stage():Stage {
			return _stage;
		}
		
		public static function get mouseIsDown():Boolean {
			return _mouseIsDown;
		}
		
		/** True when the SWF is active in the browser after ACTIVATED, false after DEACTIVATE */
		public static function get swf_is_activated():Boolean {
			return _swf_is_activated;
		}

		/** True while the SWF framerate is throttled for power saving */
		public static function get swf_is_throttled():Boolean {
			return _swf_is_throttled;
		}

		/** True while the SWF is being pre-throttled for power saving */
		public static function get swf_is_pre_throttled():Boolean {
			return _swf_is_pre_throttled;
		}
		
		/** Whether the SWF is browser-active in all measurable ways except being logged in */
		public static function isActivelyPlaying():Boolean {
			// UNFORTUNATE HACK:
			// I get the impression Chrome is not sending an ACTIVATED message
			// to the game when it is clicked, so I need to consider the game
			// is being played when ACTIVATED was received OR when JS thinks
			// it has focus even if it does not, rather than if both are true
			// (as works in FireFox)
			return (
				// the SWF has focus
				(flash_has_focus || swf_is_activated)
				// we're logged in and not in a move (loading)
				&& isLoggedIn && !isMoving
				// the SWF is not already being throttled
				&& !swf_is_throttled && !swf_is_pre_throttled
			);
		}

		public static function get flash_has_focus():Boolean {
			return _flash_has_focus;
		}
		
		public static function set flash_has_focus(value:Boolean):void {
			CONFIG::debugging {
				Console.log(99, 'flash_has_focus ' + value);
			}
			
			if (_flash_has_focus != value) {
				// important to change this before dispatching the Signal
				// in case functions read the getter during the dispatch
				_flash_has_focus = value;
				
				Benchmark.addCheck('SM.flash_has_focus '+value);
				
				flash_focus_changed_sig.dispatch(value);
			}

			if (canThrottle()) {
				if (_flash_has_focus) {
					maybeUnthrottle();
				} else {
					maybeThrottle();
				}
			}
		}
		
		private static function canThrottle():Boolean {
			return flashVarModel.throttle_swf && (!prefsModel || prefsModel.do_power_saving_mode);
		}
		
		private static function onGameloopTimer(event:TimerEvent):void {
			// simulate time between this and previous gameloop
			const newTime:int = getTimer();
			// look, if it is longer than 10 seconds, then something is just royally fucked, maybe computer woke up from sleep?
			const ms_elapsed:int = Math.min(10000, (newTime - gameloop_start_time));
			gameloop_accumulator += ms_elapsed;
			gameloop_start_time = newTime;
			
			if (flashVarModel.irregular_gl) {
				gameloop_timer.delay = int(gameloop_timestep+MathUtil.randomInt(-gameloop_timestep*.5, gameloop_timestep*2));
			}

			if (flashVarModel.lie_about_gl) {
				// our physics engine works best when simulating small timeslices
				while (gameloop_accumulator >= gameloop_timestep) {
					dispatchGameLoop(gameloop_timestep);
					gameloop_accumulator -= gameloop_timestep;
				}
			} else {
				// EC: doing this Math.min is necessary to keep you from going through walls and plats
				// when there is a hiccough. It accomplishes the same thing as the above when we
				// lie about how many ms have elapsed, but is better maybe because 1) you do not end up
				// being moved halfway across a location after a long hiccough, and 2) not lieing about
				// elapsed ms makes everything smoother
				
				if (ms_elapsed > MAX_MS_PER_LOOP) {
					/*CONFIG::debugging {
						Console.warn(ms_elapsed+'ms hiccough; treating it like a '+max_ms_per_loop+'ms interval instead');
					}*/
					dispatchGameLoop(MAX_MS_PER_LOOP);
				} else {
					dispatchGameLoop(ms_elapsed);
				}
			}
			
			// causes skipping when rendering less than the timestep:
			// simulate the rest of the accumulated time if there's enough
			//if (gameloop_accumulator > (gameloop_timestep/2)) {
			//	dispatchGameLoop(gameloop_accumulator);
			//	gameloop_accumulator = 0;
			//}
			
			CONFIG::event_debug {
				trace('ACCUMULATOR:', gameloop_accumulator);
			}
			
			
			if (flashVarModel.sleep_ms) {
				var init:int = getTimer();
				while(true) {
					if(getTimer() - init >= flashVarModel.sleep_ms) {
						break;
					}
				}
			}
		}
		
		/**
		 * Use this to delay a callback by a combination of frames and a delay.
		 * @see setTimeout
		 */
		public static function waitFor(ms_to_wait:uint, frames_to_wait:uint, callback:Function, ...args):void {
			if (!flashVarModel.use_set_timeout_controller) throw new Error();
			
			SetTimeoutController.setTimeout(callback, ms_to_wait, frames_to_wait, args);
		}
		
		/**
		 * Use this instead of to get a callback on the next fully rendered
		 * frame, e.g. when waiting for new display objects to be placed on
		 * the stage for measurement, etc.
		 * 
		 * This is equivalent to StageBeacon.setTimeout(f, 0, ...)
		 * 
		 * @see setTimeout
		 */
		public static function waitForNextFrame(callback:Function, ...args):void {
			if (flashVarModel.use_set_timeout_controller) {
				SetTimeoutController.setTimeout(callback, 0, 1, args);
			} else {
				if (args.length) {
					render_sig.addOnce(function():void {
						callback.apply(null, args);
					});
				} else {
					render_sig.addOnce(callback);
				}
			}
		}
		
		/**
		 * Use this instead of e.g. setTimeout(f, time, ... args) to get a
		 * callback to run at the time specified, which may be before the next
		 * frame is rendered.
		 * 
		 * Returns id of callback in case you want to clearTimeout again later
		 * (guaranteed to be greater than 0).
		 * 
		 * @see waitForNextFrame
		 */
		public static function setTimeout(callback:Function, delay:Number, ...args):uint {
			CONFIG::debugging {
				if (!flashVarModel) {
					Console.error('You are using SteageBeacon before it has been inited');
				}
			}
			
			if (flashVarModel && flashVarModel.use_set_timeout_controller) {
				return SetTimeoutController.setTimeout(callback, delay, 0, args);
			} else {
				return flash.utils.setTimeout(function():void{
					callback.apply(null, args);
				}, delay);
			}
		}
		
		public static function clearTimeout(id:uint):void {
			CONFIG::debugging {
				if (!flashVarModel) {
					Console.error('You are using SteageBeacon before it has been inited');
				}
			}
			
			if (flashVarModel && flashVarModel.use_set_timeout_controller) {
				SetTimeoutController.clearTimeout(id);
			} else {
				flash.utils.clearTimeout(id);
			}
		}
		
		/**
		 * Use this instead of e.g. setTimeout(f, time, ... args) to get a
		 * callback to run at the time specified, which may be before the next
		 * frame is rendered.
		 * 
		 * Returns id of callback in case you want to clearTimeout again later
		 * (guaranteed to be greater than 0).
		 * 
		 * @see waitForNextFrame
		 */
		public static function setInterval(callback:Function, delay:Number, ...args):uint {
			CONFIG::debugging {
				if (!flashVarModel) {
					Console.error('You are using SteageBeacon before it has been inited');
				}
			}
			
			if (flashVarModel && flashVarModel.use_set_timeout_controller) {
				return SetTimeoutController.setInterval(callback, delay, 0, args);
			} else {
				return flash.utils.setInterval(function():void{
					callback.apply(null, args);
				}, delay);
			}
		}
		
		public static function clearInterval(id:uint):void {
			CONFIG::debugging {
				if (!flashVarModel) {
					Console.error('You are using SteageBeacon before it has been inited');
				}
			}
			
			if (flashVarModel && flashVarModel.use_set_timeout_controller) {
				SetTimeoutController.clearInterval(id);
			} else {
				flash.utils.clearInterval(id);
			}
		}
		
		private static function onFocusIn(event:FocusEvent):void {
			focus_in_sig.dispatch(event);
		}
		
		private static function onFocusOut(event:FocusEvent):void {
			focus_out_sig.dispatch(event);
		}
		
		public static function get last_mouse_move():int {
			return _last_mouse_move;
		}
		
		private static function onMouseLeave(e:Event):void {
			mouse_leave_sig.dispatch(e);
		}
		
		private static function onMouseRollOver(e:MouseEvent):void {
			mouse_roll_over_sig.dispatch(e);
		}
		
		private static function onMouseRollOut(e:MouseEvent):void {
			mouse_roll_out_sig.dispatch(e);
		}
		
		private static function onMouseUp(e:MouseEvent):void {
			mouse_up_sig.dispatch(e);
			e.updateAfterEvent();
		}
		
		private static function onCaptureMouseUp(e:MouseEvent):void {
			stage_mouse_pt.x = stage.mouseX;
			stage_mouse_pt.y = stage.mouseY;
			
			_mouseIsDown = false;
		}
		
		private static function onCaptureMouseDown(e:MouseEvent):void {
			CONFIG::event_debug {
				Console.info(e.target+' '+StringUtil.DOPath(e.target as DisplayObject));
			}
			
			stage_mouse_pt.x = stage.mouseX;
			stage_mouse_pt.y = stage.mouseY;
			
			last_mouse_down_pt.x = stage.mouseX;
			last_mouse_down_pt.y = stage.mouseY;
			
			_mouseIsDown = true;
			
			if (flashVarModel.better_focus_handling) {
				CONFIG::focus_debug {
					trace('********************** CAPTURE_MOUSE_DOWN ************************');
				}
				flash_has_focus = true;
			}
		}
		
		private static function onMouseDown(e:MouseEvent):void {
			mouse_down_sig.dispatch(e);
			e.updateAfterEvent();
		}
		
		private static function onClick(event:MouseEvent):void {
			if (flashVarModel.better_focus_handling) {
				mouse_click_sig.dispatch(event);
			} else {
				Benchmark.addCheck('SB.onClick');
				CONFIG::focus_debug {
					trace('********************** CLICK ************************');
				}
				mouse_click_sig.dispatch(event);
				flash_has_focus = true;
			}
		}
		
		private static function onMouseMove(event:MouseEvent):void {
			_last_mouse_move = getTimer();
			
			stage_mouse_pt.x = event.stageX;
			stage_mouse_pt.y = event.stageY;
			
			mouse_move_sig.dispatch(event);
			
			// I've found dragging to be extremely smooth without this at 30fps
			// and <10fps with it:
			//if (_mouseIsDown) {
			//	// during drags; very expensive otherwise (30% FPS cost)
			//	event.updateAfterEvent();
			//}
		}
		
		private static function onCartesianMouseWheel(event:CartesianMouseEvent):void {
			cartesian_mouse_wheel.dispatch(event);
		}
		
		private static function onCaptureKeyDown(event:KeyboardEvent):void {
			if (flashVarModel.better_focus_handling) {
				flash_has_focus = true;
			}
		}
		
		private static function onKeyDown(event:KeyboardEvent):void {
			if (flashVarModel.alt_keyboard_support) {
				//Benchmark.addCheck('ON KEY DOWN ' + event + ' char:' + event.charCode + ' key:' + event.keyCode + '->' + getKeyCode(event));
				event.keyCode = getKeyCode(event);
			}
			key_down_sig.dispatch(event);
		}
		
		private static function onKeyUp(event:KeyboardEvent):void {
			if (flashVarModel.alt_keyboard_support) {
				event.keyCode = getKeyCode(event);
			}
			key_up_sig.dispatch(event);
		}
		
		private static function onEnterFrame(event:Event):void {
			const newTime:int = getTimer();
			// Calculate rendertime between this and previous frame;
			const render_time:int = (newTime - enter_frame_start_time);
			// to maximally account for all milliseconds passed per second,
			// time should be calculated from the *start* of the prevous
			// enterframe to the *start* of the current enterframe
			// (otherwise time elapsed from handlers below is 'lost' per second)
			enter_frame_start_time = newTime;
			
			if (flashVarModel.avg_enter_frame_ms || !flashVarModel.new_physics) {
				// frametime is assumed to be 8fps or higher each frame
				// (to prevent super speedups after really slow frames, like when
				//  loading a new location)
				averageFrameTimeTracker.push(Math.min(125, render_time));
				enter_frame_sig.dispatch(Math.round(averageFrameTimeTracker.averageValue));
			} else {
				if (render_time > MAX_MS_PER_LOOP) {
					/*CONFIG::debugging {
						Console.warn(render_time+'ms hiccough; treating it like a '+max_ms_per_loop+'ms interval instead');
					}*/
					enter_frame_sig.dispatch(MAX_MS_PER_LOOP);
				} else {
					enter_frame_sig.dispatch(render_time);
				}
			}
			
			if (flashVarModel.new_physics) {
				;
				CONFIG::event_debug {
					const loopTime:int = (getTimer() - enter_frame_start_time);
					trace('ENTER_FRAME[' + ++enter_frame_count + ']: rendered ' + render_time + 'ms over ' + loopTime + 'ms');
				}
			} else {
				game_loop_end_sig.dispatch();
				// cause a RENDER event to be sent at the end of the frame
				stage.invalidate();
			}
			
			// throttle the game after a timeout
			if (canThrottle()) {
				// we might need to stop throttling if we've logged out or started moving locations
				if (!isLoggedIn || isMoving) {
					maybeUnthrottle();
				} else {
					maybeThrottleSWF();
				}
			}
		}
		
		private static function onRender(event:Event):void {
			CONFIG::event_debug {
				trace('RENDER[' + ++render_count + ']');
			}
			
			render_sig.dispatch();
		}

		private static function onResize(event:Event):void {
			resize_sig.dispatch();
		}
		
		private static function dispatchGameLoop(ms_elapsed:int):void {
			if (flashVarModel.new_physics) {
				CONFIG::event_debug const start:int = getTimer();
				
				game_loop_sig.dispatch(ms_elapsed);
				game_loop_end_sig.dispatch();
				
				CONFIG::event_debug {
					const loopTime:int = (getTimer() - start);
					trace('   GAMELOOP[' + ++gameloop_count + ']: simulated ' + ms_elapsed + 'ms over ' + loopTime + 'ms');
				}
				
				// cause a RENDER event to be sent at the end of the frame
				stage.invalidate();
			} else {
				game_loop_sig.dispatch(ms_elapsed);
			}
		}
		
		/** When the SWF gets browser focus */
		private static function onActivate(event:Event):void {
			_swf_is_activated = true;
			
			CONFIG::focus_debug {
				trace('*********************** ACTIVATE *************************');
			}
			
			if (flashVarModel.better_focus_handling) {
				// critical to do this before dispatching the handler so that
				// the activate handlers know that we have focus
				flash_has_focus = true;
			}
			
			if (canThrottle()) {
				maybeUnthrottle();
			}
			
			activate_sig.dispatch();
		}
		
		/** When the SWF loses browser focus */
		private static function onDeactivate(event:Event):void {
			_swf_is_activated = false;
			
			CONFIG::focus_debug {
				trace('********************** DEACTIVATE ************************');
			}
			
			if (flashVarModel.better_focus_handling) {
				// critical to do this before dispatching the handler so that
				// the deactivate handlers know that we have focus
				flash_has_focus = false;
			}
			
			if (canThrottle()) {
				maybeThrottle();
			}
			
			deactivate_sig.dispatch();
		}
		
		private static function maybeThrottle():void {
			// if the inactivity timer has not been started,
			// and the game is effectively inactive, then start the timer
			if (isNaN(inactivity_start_time) && !isActivelyPlaying()) {
				// note the time in the ship's log so we may
				// throttle the framerate after a delay
				inactivity_start_time = getTimer();
			}
		}
		
		private static function maybeUnthrottle():void {
			// if throttling of any kind is going on, or the inactivity timer was started, unthrottle
			if (swf_is_throttled || swf_is_pre_throttled || !isNaN(inactivity_start_time)) {
				unthrottle();
			}
		}
		
		private static function unthrottle():void {
			CONFIG::focus_debug {
				trace('********************** UNTHROTTLE ************************');
			}
			_swf_is_throttled = false;
			// and in case the user returned while pre-throttling, but before throttling:
			_swf_is_pre_throttled = false;
			inactivity_start_time = NaN;
			
			// speed up the SWF to full speed
			stage.frameRate = flashVarModel.fps;
			gameloop_timer.delay = gameloop_timestep;
			
			unthrottled_sig.dispatch();
		}
		
		private static function preThrottle():void {
			CONFIG::focus_debug {
				trace('********************* PRE-THROTTLE ***********************');
			}
			_swf_is_pre_throttled = true;
			
			pre_throttle_sig.dispatch();
		}
		
		private static function throttle():void {
			CONFIG::focus_debug {
				trace('*********************** THROTTLE *************************');
			}
			_swf_is_pre_throttled = false;
			_swf_is_throttled = true;
			
			// slow down the SWF
			stage.frameRate = flashVarModel.throttle_fps;
			gameloop_timer.delay = int(1000/flashVarModel.throttle_fps);
			throttled_sig.dispatch();
		}
		
		private static function maybeThrottleSWF():void {
			CONFIG::perf {
				// no throttling during perf testing
				return;
			}
			
			// if the inactivity timer has started
			if (!isNaN(inactivity_start_time)) {
				// and not yet pre-throttled
				if (!swf_is_pre_throttled) {
					// and the pre-throttle timer has elapsed
					if (enter_frame_start_time > (inactivity_start_time + flashVarModel.throttle_delay - PRE_THROTTLE_DELAY)) {
						// start pre-throttling
						preThrottle();
					}
					
				// else if pre-throttling has begun
				} else {
					// and the throttle timer has elapsed
					if (enter_frame_start_time > (inactivity_start_time + flashVarModel.throttle_delay)) {
						// start throttling
						throttle();
					}
				}
			}
		}
		
		private static function getKeyCode(e:KeyboardEvent):uint {
			// determine the QWERTY keyCode from the charCode
			// to support non-QWERTY keyboard layouts
			if (e.charCode in charCode_to_qwerty_keyCode) {
				return charCode_to_qwerty_keyCode[e.charCode];
			} else if (e.shiftKey && e.charCode == 223) {
				// on Windows, the German ß key with shift pressed is ASCII '?'
				// but Windows reports it still with the same character code 223
				// so we need to manually map it
				return 191;
			}
			
			// fall back to the keyCode
			return e.keyCode;
		}
		
		/** To support the use of non-QWERTY keyboards */
		private static const charCode_to_qwerty_keyCode:Object = {
			32:32,   // [space]
			48:48,   // 0
			41:48,   // )
			49:49,   // 1
			33:49,   // !
			50:50,   // 2
			64:50,   // @
			51:51,   // 3
			35:51,   // #
			52:52,   // 4
			36:52,   // $
			53:53,   // 5
			37:53,   // %
			54:54,   // 6
			94:54,   // ^
			55:55,   // 7
			38:55,   // &
			56:56,   // 8
			42:56,   // *
			57:57,   // 9
			40:57,   // (
			97:65,   // a
			98:66,   // b
			99:67,   // c
			100:68,  // d
			101:69,  // e
			102:70,  // f
			103:71,  // g
			104:72,  // h
			105:73,  // i
			106:74,  // j
			107:75,  // k
			108:76,  // l
			109:77,  // m
			110:78,  // n
			111:79,  // o
			112:80,  // p
			113:81,  // q
			114:82,  // r
			115:83,  // s
			116:84,  // t
			117:85,  // u
			118:86,  // v
			119:87,  // w
			120:88,  // x
			121:89,  // y
			122:90,  // z
			65:65,   // A
			66:66,   // B
			67:67,   // C
			68:68,   // D
			69:69,   // E
			70:70,   // F
			71:71,   // G
			72:72,   // H
			73:73,   // I
			74:74,   // J
			75:75,   // K
			76:76,   // L
			77:77,   // M
			78:78,   // N
			79:79,   // O
			80:80,   // P
			81:81,   // Q
			82:82,   // R
			83:83,   // S
			84:84,   // T
			85:85,   // U
			86:86,   // V
			87:87,   // W
			88:88,   // X
			89:89,   // Y
			90:90,   // Z
			45:189,  // -
			95:189,  // _
			46:190,  // .
			62:190,  // >
			47:191,  // /
			63:191,  // ?
			58:186,  // :
			59:186,  // ;
			43:187,  // +
			61:187,  // =
			44:188,  // ,
			60:188,  // <
			96:192,  // `
			126:192, // ~
			91:219,  // [
			123:219, // {
			93:221,  // ]
			125:221, // }
			92:220,  // \
			124:220, // |
			39:222,  // '
			34:222   // "
		};
	}
}
