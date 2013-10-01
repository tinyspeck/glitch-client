package {
	/**
	 * Run this with wmode!=direct in order to preemptively get the
	 * Local Storage Security dialog to pop up and request some MBs
	 * of mems for the game.
	 * 
	 * When we run the game with wmode=direct, the dialog doesn't appear.
	 * 
	 * Pass it '?SWF_lso_needed=1024' to request 1kb.
	 */
	import com.tinyspeck.engine.util.EnvironmentUtil;
	
	import flash.display.Sprite;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	
	public class LocalStorageRequester extends Sprite {
		private static const TS_DATA_LATEST_VERSION:uint = 2;
		
		private var _Q:Array = [];
		private var _count:int = 0;
		private var _default_timer_delay:int = 0;
		private var _timer:Timer = new Timer(_default_timer_delay, 1);
		
		public function LocalStorageRequester() {
			var URLAndQSArgs:Object = EnvironmentUtil.getURLAndQSArgs();
			var url:String = URLAndQSArgs.url;
			var k:String;
			// if they are using the debug player
			if (Capabilities.isDebugger) {
				// and not at a specific SWF_which
				if (!(URLAndQSArgs.args.hasOwnProperty('SWF_which'))) {
					// and not doing performance tests
					if (url.indexOf('game/perf') == -1) {
						// auto-redirect them to SWF_which=DEBUG
						url+= '?SWF_which=DEBUG';
						for (k in URLAndQSArgs.args) {
							if (k == 'SWF_which') continue;
							url+= '&'+k+'='+URLAndQSArgs.args[k];
						}
						// timeout or else there is a load never completed error
						setTimeout(ExternalInterface.call, 1000, 'window.location.replace("'+url+'")');
						return;
					}
				}
			}
			
			// Chrome has this nasty habit of firing:
			//   SecurityError: Error #2000: No active security context.
			// Damned if I know or care why...
			loaderInfo.uncaughtErrorEvents.addEventListener(
				UncaughtErrorEvent.UNCAUGHT_ERROR, function (e:UncaughtErrorEvent):void {
				Console.warn(e.toString() + ': ' + e.error);
				e.preventDefault();
				e.stopImmediatePropagation();
			}, false, int.MAX_VALUE);
			
			_timer.addEventListener(TimerEvent.TIMER, function (e:TimerEvent):void {
				if (_Q.length) call_JS(_Q.shift());
			});
			
			try {
				const fvd:FlashVarData = FlashVarData.createFlashVarData(this);

				const sharedObject:SharedObject = SharedObject.getLocal('TS_DATA', '/');
				
				// handle version control and migration
				if (sharedObject.data['version'] != TS_DATA_LATEST_VERSION) {
					switch (sharedObject.data['version']) {
						default: {
							migrateUndefined(sharedObject);
							break;
						}
						case 1: {
							migrate1To2(sharedObject);
							break;
						}
					}
				}

				// we've done what we can and should be up-to-date
				sharedObject.data.version = TS_DATA_LATEST_VERSION;
				sharedObject.flush();
				
				// how much memory do we need up-to
				var needed:uint = (fvd.getFlashvar('SWF_lso_needed', 'Number') || 100*1024); // 100kb out to be enough for anyone
				// adjust for the amount already in use and ask for 1 byte less
				// (no off-by-ones on my watch, flash rounds up anyway)
				needed = needed - sharedObject.size - 1;
				
				Console.info('Requesting ' + needed + ' bytes of Flash Local Storage');
				if (sharedObject.flush(needed) == SharedObjectFlushStatus.FLUSHED) {
					Console.info('Storage request granted');
					call_JS({meth: 'remove_lso'});
				} else {
					// flush pending, security dialog is raised
					sharedObject.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent):void {
						// dialog has been dismissed
						if (e.info.code == "SharedObject.Flush.Success") {
							Console.info('Storage request granted');
							call_JS({meth: 'remove_lso'});
						} else {
							Console.error('You denied giving Glitch local storage.');
							call_JS({meth: 'lso_request_denied'});
						}
						sharedObject.removeEventListener(NetStatusEvent.NET_STATUS, arguments.callee);
					});
				}
			} catch (e:Error) {
				// security freaks
				Console.error('You permanently disabled your Flash Local Storage, but Glitch wants some. No soup for you!\n\t' + e.toString());
				call_JS({meth: 'lso_request_denied'});
			}
		}
		
		private static function migrateUndefined(sharedObject:SharedObject):void {
			clearSO(sharedObject);
		}
		
		private static function migrate1To2(sharedObject:SharedObject):void {
			for each (var obj:* in sharedObject.data) {
				if (isPCObject(obj)) {
					// clear chat_history
					obj['chat_history'] = null;
					delete obj['chat_history'];
					
					// add is_pc for future migration ease
					obj['is_pc'] = true;
				}
			}
			sharedObject.flush();
		}
		
		private static function isPCObject(obj:*):Boolean {
			// obj is Object will return true for e.g. ByteArray, which is bad
			return ((getQualifiedClassName(obj) == 'Object') &&
				// sfx_volume will be a hint that this is a LocalStorage object
				// since is_pc was introduced introduced in version 2
				(Object(obj).hasOwnProperty('is_pc') || Object(obj).hasOwnProperty('sfx_volume')));
		}
		
		private static function clearSO(sharedObject:SharedObject):void {
			try {
				// for now, clear the fucker out
				Console.info('clearing TS_DATA');
				sharedObject.clear();
				sharedObject.flush();
			} catch (e:Error) {
				// whatever, we tried
			}
		}
		
		/* talk to JS */
		private function call_JS(msg:Object):void {
			//Console.log(4, 'call_JS meth '+(msg.meth || 'NO METH SPECIFIED')+'');
			
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
			
			//Console.log('AS calling JS: '+(msg.meth || 'METH NOT SPECIFIED') +' '+(msg._count));
			
			var received:Boolean = false;
			
			try {
				received = ExternalInterface.call('TS.client.AS_interface.incoming_JS', msg);
			} catch(e:SecurityError) {
				Console.warn('_actually_call_JS Sec. error '+e)
			}
			
			if (received) {
//				Console.log('JS reports received '+msg._count+': '+received);
			} else {
				Console.warn('JS reports received '+msg._count+': '+received);
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

import flash.display.DisplayObject;
import flash.display.LoaderInfo;
import flash.external.ExternalInterface;

class FlashVarData {
	private var data:Object;
	
	public static function createFlashVarData(root:DisplayObject):FlashVarData {
		return new FlashVarData(LoaderInfo(root.loaderInfo));
	}
	
	public function FlashVarData(loaderInfo:LoaderInfo) {
		this.data = loaderInfo.parameters;
		for (var item:String in data) {
			data[item] = String(data[item]);
		}
	}
	
	public function getFlashvar(k:String, t:String = 'String'):* {
		var val:*;
		if (t == 'Number') {
			val = (!isNaN(data[k])) ? parseFloat(data[k]) : null;
		} else if (t == 'String') {
			val = data[k] || '';
		} else {
			val = data[k];
		}
		return val;
	}
}

class Console {
	private static var to_firebug:Boolean = true;
	private static var to_trace:Boolean = true;
	private static var priArray:Array;
	private static var console_name_prefix:String = 'com.tinyspeck.debug::Console';
	private static var ns_prefix:String = 'com.tinyspeck';
	
	private static function deepTrace(obj:*, level:int=0): void {
		var tabs:String = "";
		for (var i:int = 0; i < level; i++) {
			tabs += "  ";
		}
		
		for (var prop:String in obj){
			if(to_trace == true){
				trace(tabs + "\"" + prop + "\":" + obj[prop]);
			}
			deepTrace(obj[prop], level + 1);
		}
	}
	
	public static function priOK(pri:String):Boolean {
		if (!priArray) return true;
		
		if (pri == '0') return true;
		if (priArray.indexOf('all') != -1) return true;
		if (priArray.indexOf(pri) == -1) return false;
		return true;
	}
	
	public static function functionName():String {
		var func:String = '';
		var loc:String = '';
		
		var s:String = new Error().getStackTrace();
		if (!s) return 'no_trace_available';
		var A:Array = s.split('\n');
		//at com.tinyspeck.control::BootController/bootStrap()[/Users/eric/Documents/workspace/clientNew/src/com/tinyspeck/control/BootController.as:50]
		var d:int = 1; // start at second line, because the first contains just "Error at"
		var temp_line:String;
		while(d==1 || temp_line.indexOf(console_name_prefix) > -1) {
			temp_line = A[d];
			d++;
		}
		
		var i:int = temp_line.indexOf('at ');
		var line:String = temp_line.substr(i+3);
		var line_parts:Array = line.split('()');
		func = line_parts[0]+'()';
		func = func.split('/')[func.split('/').length-1];
		loc = line_parts[1].substr(line_parts[1].lastIndexOf('/')+1).replace(']', '');
		
		if (func.indexOf(ns_prefix) > -1) func = func.split('::')[1];
		
		return loc+' '+func;
	}
	
	/**
	 * Writes a message to the console. 
	 * You may pass as many arguments as you'd like, and they will be
	 * joined together in a space-delimited line.
	 * */
	public static function log(pri:*, ...rest):void{
		pri = pri.toString();
		if (pri && !priOK(pri)) return;
		sendWpri('log', pri, rest);
	}
	
	/**
	 * Writes a message to the console with the visual "warning" icon and 
	 * color coding and a hyperlink to the line where it was called.
	 * */
	public static function warn(...rest):void{
		send("warn", rest);
	}
	
	/**
	 * Writes a message to the console with the visual "info" icon and 
	 * color coding and a hyperlink to the line where it was called.
	 * */
	public static function info(...rest):void{
		send("info",rest);
	}
	
	/**
	 * Writes a message to the console with the visual "error" icon and
	 * color coding and a hyperlink to the line where it was called.
	 * */
	public static function error(...rest):void{
		var s:String = new Error().getStackTrace();
		s = s || 'no_trace_available';
		send("error",rest);
		send("log", 'STACK TRACE: '+s);
	}
	/**
	 * makes the call to console
	 * */
	private static function sendWpri(level:String, pri:String = '', ...rest):void{
		var f:String = functionName();
		if (level == 'dir') {
			if (to_trace == true) {
				trace(to_trace);
				trace('Showing tree '+rest.length+' ---> '+f);
				deepTrace(rest);
			}
			if (to_firebug) {
				var msg_type:String = (rest[0] && 'type' in rest[0]) ? ' for type:'+rest[0].type : '';
				ExternalInterface.call("console.log", pri+' '+f+' >>> Showing tree'+msg_type+'');
				try {ExternalInterface.call("console.dir", rest[0]);} catch(e:SecurityError) {error('call to console.dir failed')};
			}
		} else {
			//rest.push(f);
			if (to_trace == true){
				trace(level.toUpperCase()+' '+pri+' '+f+' >>> '+rest[0]);
			} 
			try {
				if (to_firebug) {
					ExternalInterface.call("console."+level, ((level == 'info' || level == 'warn')?'\n':'')+pri+' '+f+' >>> '+rest[0]);
				}
			} catch(e:SecurityError) {}
		}
	}
	
	private static function send(level:String,...rest):void{
		var f:String = functionName();
		if (level == 'dir') {
			if (to_trace == true){
				deepTrace(rest);
			} 
			if (to_firebug) {
				try {
					ExternalInterface.call("console.dir", rest[0]);
				} catch(e:SecurityError) {
					error('call to console.dir failed')
				};
			}
		} else {
			//rest.push(f);
			if (to_trace == true){
				trace(level.toUpperCase()+' '+rest[0]+' ---> '+f);
			}
			try {
				if (to_firebug) {
					ExternalInterface.call("console."+level, ((level == 'info' || level == 'warn')?'\n':'')+f+' >>> '+rest[0]);
				}
			} catch(e:SecurityError) {}
		}
	}
}
