
package com.tinyspeck.engine.loader {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	
	public class AvatarConfigRecord {
		
		public var ava_swf:AvatarSwf;
		public var ac:AvatarConfig;
		public var swf_urlsA:Array = [];
		public var ready:Boolean;
		public var callbacks:Array = [];
		public var article_classes_per_swf:Object = {};
		
		public function AvatarConfigRecord(ac:AvatarConfig) {
			this.ac = ac;
		}
		
		public function addCallback(callback:Function):void {
			if (ready) {
				CONFIG::debugging {
					Console.error('ACR ALRDY RDY!');
				}
				return;
			}
			if (callback == null) return;
			if (callbacks.indexOf(callback) > -1) return;
			callbacks.push(callback);
		}
		
		
		public function doCallbacks():void {
			if (!ready) {
				CONFIG::debugging {
					Console.error('ACR NOT RDY!');
				}
				return;
			}

			CONFIG::debugging {
				Console.priwarn(89, 'doing '+callbacks.length+' callbacks');
			}
			for (var i:int;i<callbacks.length;i++) {
				callbacks[int(i)](this.ac);
			}
		}
	}
}