package com.tinyspeck.engine.port {
	
	import com.tinyspeck.debug.Console;
	
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	
	public class JS_interface_base {
		/* properties */
		private var _Q:Array = [];
		private var _count:int = 0;
		private var _default_timer_delay:int = 0;
		private var _timer:Timer = new Timer(_default_timer_delay, 1);
		
		/* list the methods we want to make available to JS */
		private var methods_open_to_JS:Object;

		/* constructor */
		public function JS_interface_base(methods_open_to_JS:Object) {
			this.methods_open_to_JS = methods_open_to_JS;
		}
		
		/* public method to kick things off, called from Boot after it is added to stage */
		public function init():void {
			ExternalInterface.addCallback('incoming_AS', _incoming_AS);
			_timer.addEventListener(TimerEvent.TIMER, _timerHandler);
		}
		
		/* called by JS */
		private function _incoming_AS(msg:Object):Boolean {
			if (!msg) return true; // not sure I should return true here, but Safari is sometimes passing null and I need to protect. Returning false woudl I think result in the JS trying again.
			CONFIG::debugging {
				Console.log(4, '_incoming_AS:'+msg._count);
			}
			
			if (msg && msg.meth && methods_open_to_JS[msg.meth]) {
				methods_open_to_JS[msg.meth](msg.params || {});
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('unrecognized meth '+(msg.meth || '')+' in _incoming_AS');
				}
			}
	
			CONFIG::debugging {
				if (msg.resent) Console.warn('AS got resent msg._count:'+msg._count);
			}
			
			return true;
		}
		
		/* public method for AS to call JS */
		public function call_JS(msg:Object = null, now:Boolean = false):void {
			msg = msg || {};

			CONFIG::debugging {
				Console.log(4, 'call_JS meth '+(msg.meth || 'NO METH SPECIFIED')+'');
			}
			
			// this is a hack to get around the chrome bug. it duplicates some code that is in client.source.js but loses window focusing
			/*
			2011/08/22 REMOVED THIS BECAUSE I THING CHROME WINDOW OPENING WORKS NOW IN LATEST BUILDS
			if (msg.meth == 'open_window' && EnvironmentUtil.is_chrome && false) {
				CONFIG::debugging {
					Console.warn('SPECIAL CHROME OPENING')
				}
				
				if (msg.params.name == 'prop_editor') {
					ExternalInterface.call('window.open("'+msg.params.url+'","'+msg.params.name+'","status=yes,scrollbars=yes,resizable=yes,width=880,height=600")');
				} else if (msg.params.url) {
					ExternalInterface.call('window.open("'+msg.params.url+'", "'+msg.params.name+'")');
				}
				
				return;
			}*/
			
			if (!_timer.running || now) {
				_actually_call_JS(msg);
			} else {
				if (!msg.del) {
					msg.del = new Date().getTime();
					msg.b4 = _Q.length;
					msg.exp = (_Q.length+1) * _timer.delay;
				}
				
				_Q.push(msg);
			}
		}
		
		/* duh */
		private function _timerHandler(e:TimerEvent):void {
			_drain_Q();
		}
		
		/* called after _actually_call_JS */
		private function _drain_Q():void{
			if (_Q.length) {
				_actually_call_JS(_Q.shift());
			}
		}
		
		/* talk to JS */
		private function _actually_call_JS(msg:Object = null):void {
			msg = msg || {};
			
			// it is not a lost and resent msg
			if (!msg._count && msg._count != 0) {
				if (msg.del) {
					msg.del = (new Date().getTime()) - msg.del;
					msg.diff = (msg.del - msg.exp);
				}
				
				msg._count = _count++;
			} else {
				msg.resent = 1;
			}
			
			CONFIG::debugging {
				Console.log(4, 'AS calling JS: '+(msg.meth || 'METH NOT SPECIFIED') +' '+(msg._count));
			}
			
			var received:Boolean = false;
			
			try {
				received = ExternalInterface.call('TS.client.AS_interface.incoming_JS', msg);
			} catch(e:SecurityError) {
				CONFIG::debugging {
					Console.warn('_actually_call_JS Sec. error '+e)
				}
			}

			CONFIG::debugging {
				if (received) {
					Console.log(4, 'JS reports received '+msg._count+': '+received);
				} else {
					Console.warn('JS reports received '+msg._count+': '+received);
				}
			}
			
			_timer.reset();
			
			if (received) {
				_timer.delay = _default_timer_delay;
			} else {
				_Q.unshift(msg);
				_timer.delay = _default_timer_delay+50;
			}
			
			_timer.start();
		}
	}
}
