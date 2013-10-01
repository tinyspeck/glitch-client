package com.tinyspeck.core.data {

	import com.tinyspeck.debug.Console;
	
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;

	public class FlashVarData {
		private var data:Object;
		
		public static function createFlashVarData(root:DisplayObject):FlashVarData {
			return new FlashVarData(LoaderInfo(root.loaderInfo));
		}
		
		public function FlashVarData(loaderInfo:LoaderInfo) {
			var item:String;
			this.data = loaderInfo.parameters;
			CONFIG::debugging {
				Console.info('FlashVarData: '+String(data));
				Console.dir(data);
				for (item in data) {
					Console.info('flashvar: '+item+':'+data[item]);
				}
			}
			for (item in data) {
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
}