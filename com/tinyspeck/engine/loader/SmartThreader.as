package com.tinyspeck.engine.loader {
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	
	public class SmartThreader {
		
		private static const notable_logsV:Vector.<String> = new Vector.<String>();
		private static const waitingV:Vector.<SmartLoaderBase> = new Vector.<SmartLoaderBase>();
		private static const loadingV:Vector.<SmartLoaderBase> = new Vector.<SmartLoaderBase>();
		CONFIG::god private static const doneV:Vector.<SmartLoaderBase> = new Vector.<SmartLoaderBase>();
		private static const max:int = 3;
		private static var loaded_cnt:int;
		
		public function SmartThreader() {}
		
		internal static function addToQ(sl:SmartLoaderBase):void {
			if (waitingV.indexOf(sl) > -1) {
				throw new Error('ALREADY IN waitingV');
			}
			
			if (loadingV.indexOf(sl) > -1) {
				throw new Error('ALREADY IN loadingV');
			}
			
			waitingV.push(sl);
			maybeLoadFromQ();
		}
		
		internal static function loadDone(sl:SmartLoaderBase):void {
			CONFIG::god {
				if (doneV.indexOf(sl) > -1) {
					Console.error(sl.eventLog)
					throw new Error('ALREADY IN doneV '+sl);
				}
			}
			
			var was_in_waitingV:Boolean;
			var index:int;
			
			// in case this gets called on a loader that has not yet actually had its loading started...
			index = waitingV.indexOf(sl);
			if (index != -1) {
				was_in_waitingV = true;
				waitingV.splice(index, 1);
			}
			
			index = loadingV.indexOf(sl);
			if (index == -1) {
				// if was_in_waitingV=true, then this is ok, we had not started loading it yet 
				if (!was_in_waitingV) {
					BootError.handleError(sl.eventLog||'no eventLog?', new Error('WTF, HOW NOT IN loadingV?? not_in_loading_v loadingV.length:'+loadingV.length), ['loader', 'SmartThreader'], true);
				}
			}
			
			if (sl.retries) {
				notable_logsV.push(sl.eventLog);
				CONFIG::debugging {
					Console.warn(sl.name+' had a notable load\n'+sl.eventLog);
					Console.info(load_report);
				}
			}

			CONFIG::god {
				doneV.push(sl);
			}
			
			loaded_cnt++;
			
			if (index != -1) {
				sl.log('removing from loadingV');
				loadingV.splice(index, 1);
			}
			maybeLoadFromQ();
		}
		
		public static function get currently_loading():int {
			return loadingV.length;
		}
		
		private static function maybeLoadFromQ():void {
			if (!waitingV.length) return;
			if (loadingV.length >= max) return;
			
			var sl:SmartLoaderBase = waitingV.shift();
			sl.log('adding to loadingV');
			loadingV.push(sl);
			sl.actuallyLoad();
		}
		
		public static function get load_report():String {
			var str:String = 'SmartThreader report:\n';
			str+= 'total loaded: '+loaded_cnt+'\n';
			str+= 'loading now: '+loadingV.length+'\n';
			str+= 'waiting to load: '+waitingV.length+'\n';
			
			var notable_current_logsV:Vector.<String> = new Vector.<String>();
			if (loadingV.length) {
				for (var i:int;i<loadingV.length;i++) {
					if (loadingV[i].retries > 0) {
						notable_current_logsV.push(loadingV[i].eventLog); 
					}
				}
			}
			
			str+= 'notable current loads: ';
			if (!notable_current_logsV.length) {
				str+= 'none\n';
			} else {
				str+= '\n--------------------------------------\n'+notable_current_logsV.join('\n--------------------------------------\n');
				str+= '\n';
			}
			
			str+= 'notable finished loads: ';
			if (!notable_logsV.length) {
				str+= 'none\n';
			} else {
				str+= '\n--------------------------------------\n'+notable_logsV.join('\n--------------------------------------\n');
			}
			
			return str;
		}
		
	}
	
}