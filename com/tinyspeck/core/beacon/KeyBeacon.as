package com.tinyspeck.core.beacon {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	
	import flash.display.Stage;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	public class KeyBeacon extends EventDispatcher {
		/* singleton boilerplate */
		public static const instance:KeyBeacon = new KeyBeacon();
		
		// Cal needs to be told about any keys added to this! (the new keys need to be added to the verb key map exclusion list in lib_items_publish.php)
		// the above is only true if we ever decide to actually do model.flashVarModel.do_single_interaction_sp_keys
		public static var CLIENT_KEYS:Vector.<uint> = new <uint>[
			Keyboard.I, // info for things
			//Keyboard.O, // Open container
			Keyboard.C, // camera mode
			Keyboard.M, // MAP
			Keyboard.L, // Quest Log
			Keyboard.NUMBER_1, // huh emotion
			Keyboard.NUMBER_2, // grrr emotion
			Keyboard.NUMBER_3, // joy emotion
			Keyboard.NUMBER_4, // afk
			Keyboard.W, // movement
			Keyboard.A, // movement
			Keyboard.S, // movement
			Keyboard.D,  // movement
			Keyboard.TAB,  // focus on chat
			Keyboard.SLASH,  // focus on chat
			
			// below were added after we decided to disable model.flashVarModel.do_single_interaction_sp_keys
			Keyboard.P, // player menu in new chrome
			Keyboard.U // cultivation mode
		];
		
		private static const numA:Vector.<uint> = new <uint>[
			Keyboard.NUMBER_0,
			Keyboard.NUMBER_1,
			Keyboard.NUMBER_2,
			Keyboard.NUMBER_3,
			Keyboard.NUMBER_4,
			Keyboard.NUMBER_5,
			Keyboard.NUMBER_6,
			Keyboard.NUMBER_7,
			Keyboard.NUMBER_8,
			Keyboard.NUMBER_9,
			Keyboard.NUMPAD_0,
			Keyboard.NUMPAD_1,
			Keyboard.NUMPAD_2,
			Keyboard.NUMPAD_3,
			Keyboard.NUMPAD_4,
			Keyboard.NUMPAD_5,
			Keyboard.NUMPAD_6,
			Keyboard.NUMPAD_7,
			Keyboard.NUMPAD_8,
			Keyboard.NUMPAD_9
		];
		
		public static const HIGH_PRIO_KEY_DOWN:String = 'HIGH_PRIO_KEY_DOWN';
		public static const KEY_DOWN_:String = 'KEY_DOWN_';
		public static const KEY_UP_:String = 'KEY_UP_';
		public static const KEY_DOWN_REPEAT_:String = 'KEY_DOWN_REPEAT_';
		public static const CTRL_PLUS_:String = 'CTRL_PLUS_';
		public static const ALT_PLUS_:String = 'ALT_PLUS_';
		public static const SHIFT_PLUS_:String = 'SHIFT_PLUS_';
		
		private const eventsH:Dictionary = new Dictionary();
		private const _downA:Vector.<int> = new Vector.<int>();
		private var _downH:Dictionary = new Dictionary();

		private var stage:Stage;
		private var key_report_tf:TextField;
		
		public function KeyBeacon() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			StageBeacon.flash_focus_changed_sig.add(onFlashFocusChanged);
		}
		
		public function isNumberKeyCode(i:int):Boolean {  
			return (numA.indexOf(i) > -1);
		}
		
		public function setStage(stage:Stage):void {
			this.stage = stage;
			addStageKeyEventHandlers();
			StageBeacon.activate_sig.add(onStageActivate);
			StageBeacon.deactivate_sig.add(onStageDeactivate);
		}
		
		private function onStageActivate():void {
			// wait a little while, because if you focus in browser url window and hit return, focus comes back to 
			// flash and the key event is registered, WTF (at least in FF3 mac)
			StageBeacon.waitForNextFrame(addStageKeyEventHandlers);
			reset('Event.ACTIVATE');
		}
		
		private function onStageDeactivate():void {
			removeStageKeyEventHandlers();
			reset('Event.DEACTIVATE');
		}
		
		private function addStageKeyEventHandlers():void {
			StageBeacon.key_up_sig.add(_keyUpHandler);
			StageBeacon.key_down_sig.add(_keyDownHandler);
		}
		
		private function removeStageKeyEventHandlers():void {
			StageBeacon.key_up_sig.remove(_keyUpHandler);
			StageBeacon.key_down_sig.remove(_keyDownHandler);
		}
		
		public function addKeyReportTF(tf:TextField):void {
			key_report_tf = tf;
			reportKeysDown();
		}
		
		private function reportKeysDown():void {
			if (!key_report_tf) return;
			if (!key_report_tf.visible) return;
			key_report_tf.text = getKeysDownReport();
		}
		
		public function getKeysDownReport():String {
			if (!_downA.length) return '--- no keys down ---';
			
			var str:String = '"';
			for (var i:int;i<_downA.length;i++) {
				if (i) str+= ',';
				str+= code_to_rep_map[_downA[i]] || 'unknown:'+_downA[i];
			}
			str+='" ('+_downA.join(',')+')';
			
			return str;
		}
		
		public function reset(why:String = 'default', except:Array=null):void {
			//Benchmark.addCheck('KB.reset why:'+why);
			CONFIG::debugging {
				Console.log(5, 'reset '+why)
			}
			
			_downH = new Dictionary();
			
			if (except && except.length) {
				// Check to see what keys in except were in _downA, remove any that are not, and then make except the new _downA
				for (var i:int=0; i<except.length; i++) {
					if (_downA.indexOf(except[i]) == -1) { // if the key was not in _downA
						except.splice(_downA.indexOf(except[i]), 1);
						i--; // to accoutn for having removed it from the array
					} else {
						_downH[except[i]] = true;
					}
				}
				
				_downA.length = 0;
				for each (var key:int in except) _downA.push(key);
			} else {
				_downA.length = 0;
			}
			
			reportKeysDown();
		}
		
		public function jsKeyUp(k:int):void {
			if (!StageBeacon.flash_has_focus) {
				_keyUpFire(k);
			}
		}
		
		public function jsKeyDown(k:int):void {
			if (!StageBeacon.flash_has_focus) {
				_keyDownFire(k);
			}
		}
		
		/** True if any key is pressed, including modifiers */
		public function anyKeyPressed():Boolean {
			return (_downA.length > 0);
		}
		
		/** True if any key is pressed that is not a modifier (ctrl, alt, shift, cmd) */
		public function anyNonModifierKeyPressed():Boolean {
			for each (var key:int in _downA) {
				if ((key != Keyboard.CONTROL) && (key != Keyboard.SHIFT) && (key != Keyboard.ALTERNATE) && (key != Keyboard.COMMAND)) return true;
			}
			return false;
		}
		
		/** True if any up/down/left/right keys are pressed */
		public function anyArrowKeysPressed():Boolean {
			return (pressed(Keyboard.UP) || pressed(Keyboard.DOWN) || pressed(Keyboard.LEFT) || pressed(Keyboard.RIGHT));
		}
		
		/** True if any WASD keys are pressed */
		public function anyWASDKeysPressed():Boolean {
			return (pressed(Keyboard.W) || pressed(Keyboard.A) || pressed(Keyboard.S) || pressed(Keyboard.D));
		}
		
		/** True if any up/down/left/right or WASD keys are pressed */
		public function anyWASDorArrowKeysPressed():Boolean {
			return anyWASDKeysPressed() || anyArrowKeysPressed();
		}
		
		public function pressed(k:uint):Boolean {
			return (_downH[int(k)]) ? true : false;
		}
		
		CONFIG::debugging public function whatsPressed():void {
			for (var k:String in _downH) Console.warn(k+' is pressed');
		}
		
		public function pressedLast(k:uint):Boolean {
			return (_downA.length && _downA[0] == k) ? true : false;
		}
		
		public function pressedBefore(k1:uint, k2:uint):Boolean {
			return (_downA.indexOf(k1) > -1 && (_downA.indexOf(k2) == -1 || _downA.indexOf(k1) < _downA.indexOf(k2)));
		}
		
		private function _keyUpHandler(e:KeyboardEvent):void {
			_keyUpFire(e.keyCode);
		}
		
		private function _keyDownHandler(e:KeyboardEvent):void {
			const k:uint = e.keyCode;
			const was_down:Boolean = _downH[int(k)];
			
			if (!was_down && EnvironmentUtil.is_mac && !CONFIG::locodeco && !pressed(Keyboard.SHIFT)) {
				if (k == Keyboard.RIGHT) {
					reset('MAC right');
				} else if (k == Keyboard.LEFT) {
					reset('MAC left');
				} else if (k == Keyboard.A) {
					reset('MAC A');
				} else if (k == Keyboard.D) {
					reset('MAC D');
				}
			}
			
			_keyDownFire(k);
			if (was_down) _keyDownRepeatFire(k);
		}
		
		private function _keyUpFire(k:uint):void {
			CONFIG::debugging {
				Console.log(5, 'KeyBeacon._keyUpFire UP:'+k);
			}
			// if this is cmd/ctrl, go ahead and clear all down keys, because for some fucking bizarre reason, the up event
			// for keys will not fire in some browsers when cmd/ctrl is also down.
			if (k == Keyboard.CONTROL) {
				reset('cmd up');
			} else {
				_downH[int(k)] = false;
				delete _downH[int(k)];
				var i:int = _downA.indexOf(k);
				if (i>-1) _downA.splice(i, 1);
			}
			reportKeysDown();
			var ck:String = KeyBeacon.KEY_UP_+k;
			if (_downH[String(Keyboard.CONTROL)] && k != Keyboard.CONTROL) {
				ck = KeyBeacon.CTRL_PLUS_+ck;
			} else if (_downH[String(Keyboard.ALTERNATE)] && k != Keyboard.ALTERNATE) {
				ck = KeyBeacon.ALT_PLUS_+ck;
			} else if (_downH[String(Keyboard.SHIFT)] && k != Keyboard.SHIFT) {
				ck = KeyBeacon.SHIFT_PLUS_+ck;
			}
			if (hasEventListener(ck)) dispatchEvent(getEvent(ck, k));
			if (hasEventListener(KeyBeacon.KEY_UP_)) dispatchEvent(getEvent(KeyBeacon.KEY_UP_, k));
		}
		
		private function _keyDownFire(k:uint):void {
			const was_down:Boolean = _downH[int(k)];
			const i:int = _downA.indexOf(k);
			if (i>-1) _downA.splice(i, 1);
			_downA.unshift(k);
			CONFIG::debugging {
				Console.log(5, 'KeyBeacon._keyDownFire DOWN:'+k);
			}
			_downH[int(k)] = true;
			
			var ck:String = KeyBeacon.KEY_DOWN_+k;
			if (_downH[String(Keyboard.CONTROL)] && k != Keyboard.CONTROL) {
				ck = KeyBeacon.CTRL_PLUS_+ck;
			} else if (_downH[String(Keyboard.ALTERNATE)] && k != Keyboard.ALTERNATE) {
				ck = KeyBeacon.ALT_PLUS_+ck;
			} else if (_downH[String(Keyboard.SHIFT)] && k != Keyboard.SHIFT) {
				ck = KeyBeacon.SHIFT_PLUS_+ck;
			}
			if (!was_down || _downH[String(Keyboard.CONTROL)]) {
				CONFIG::debugging {
					Console.log(5, 'KeyBeacon._keyDownFire DOWN:'+k+' ck:'+ck);
				}
				if (hasEventListener(KeyBeacon.HIGH_PRIO_KEY_DOWN)) dispatchEvent(getEvent(KeyBeacon.HIGH_PRIO_KEY_DOWN, k));
				if (hasEventListener(ck)) dispatchEvent(getEvent(ck, k));
				if (hasEventListener(KeyBeacon.KEY_DOWN_)) dispatchEvent(getEvent(KeyBeacon.KEY_DOWN_, k));
			}
			reportKeysDown();
		}
		
		private function _keyDownRepeatFire(k:uint):void {
			if (hasEventListener(KeyBeacon.KEY_DOWN_REPEAT_+k)) dispatchEvent(getEvent(KeyBeacon.KEY_DOWN_REPEAT_+k, k));
			if (hasEventListener(KeyBeacon.KEY_DOWN_REPEAT_)) dispatchEvent(getEvent(KeyBeacon.KEY_DOWN_REPEAT_, k));
		}
		
		private function makeEvent(name:String, k:uint):KeyboardEvent {
			eventsH[name] = new KeyboardEvent(name, false, false, 0, k);
			return eventsH[name];
		}
		
		private function getEvent(k:String, kc:uint):KeyboardEvent {
			if (eventsH[k]) KeyboardEvent(eventsH[k]).keyCode = kc;
			return eventsH[k] || makeEvent(k, kc);
		}
		
		private function onFlashFocusChanged(value:Boolean):void {
			reset('flash_has_focus');
		}
		
		public static const code_to_rep_map:Object = {
			0:'opt',
			8:'bckspce',
			9:'tab',
			13:'enter',
			16:'shift',
			17:'ctrl',
			18:'alt',
			19:'pause',
			20:'caps',
			27:'esc',
			32:'space',
			33:'pageup',
			34:'pagedown',
			35:'end',
			36:'home',
			37:'left',
			38:'up',
			39:'right',
			40:'down',
			45:'ins',
			46:'del',
			48:'0',
			49:'1',
			50:'2',
			51:'3',
			52:'4',
			53:'5',
			54:'6',
			55:'7',
			56:'8',
			57:'9',
			65:'A',
			66:'B',
			67:'C',
			68:'D',
			69:'E',
			70:'F',
			71:'G',
			72:'H',
			73:'I',
			74:'J',
			75:'K',
			76:'L',
			77:'M',
			78:'N',
			79:'O',
			80:'P',
			81:'Q',
			82:'R',
			83:'S',
			84:'T',
			85:'U',
			86:'V',
			87:'W',
			88:'X',
			89:'Y',
			90:'Z',
			96:'0N',
			97:'1N',
			98:'2N',
			99:'3N',
			100:'4N',
			101:'5N',
			102:'6N',
			103:'7N',
			104:'8N',
			105:'9N',
			109:'-',
			110:'.',
			111:'/',
			112:'F1',
			113:'F2',
			114:'F3',
			115:'F4',
			116:'F5',
			117:'F6',
			118:'F7',
			119:'F8',
			120:'F9',
			121:'F10',
			122:'F11',
			123:'F12',
			145:'scrlock',
			186:':',
			187:'+',
			188:'<',
			189:'_',
			190:'>',
			191:'?',
			192:'~',
			219:'{',
			220:'|',
			221:'}',
			222:'"'
		};
	}
}
