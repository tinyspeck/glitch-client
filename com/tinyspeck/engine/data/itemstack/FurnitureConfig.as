package com.tinyspeck.engine.data.itemstack {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.ObjectUtil;
	
	public class FurnitureConfig extends AbstractTSDataEntity {
		
		public var sig:String;
		public var temp_sig:String;
		public var is_dirty:Boolean;
		
		public var facing_right:Boolean = true;
		public var swf_url:String;
		public var upgrade_id:String;
		public var upgrade_ids:Array;
		private var _config:Object;

		public function get config():Object {
			return _config;
		}

		public function set config(value:Object):void {
			// make sure there is really something there!
			for (var k:String in value) {
				_config = value;
				return;
			}
			
			//if (value) Console.error('WHY? '+hashName+' '+swf_url)
		}

	
		public function FurnitureConfig(hashName:String) {
			super(hashName);
		}
		
		public function reset():void {
			is_dirty = false;
			facing_right = true;
			swf_url = null;
			upgrade_id = null;
			config = null;
			upgrade_ids = null;
		}
		
		public function clone():FurnitureConfig {
			var fconfig:FurnitureConfig = new FurnitureConfig(hashName);
			fconfig.sig = sig;
			fconfig.is_dirty = is_dirty;
			fconfig.facing_right = facing_right;
			fconfig.swf_url = swf_url;
			fconfig.upgrade_id = upgrade_id;
			fconfig.config = (config) ? ObjectUtil.copyOb(config) : null;
			fconfig.upgrade_ids = (upgrade_ids) ? upgrade_ids.concat() : null;
			fconfig.temp_sig = temp_sig;
			return fconfig;
		}
		
		
		public static function fromAnonymous(object:Object, hashName:String):FurnitureConfig {
			var fconfig:FurnitureConfig = new FurnitureConfig(hashName);
			return FurnitureConfig.updateFromAnonymous(object, fconfig);
		}
		
		public static function updateFromAnonymous(object:Object, fconfig:FurnitureConfig):FurnitureConfig {
			for (var j:String in object) {
				
				if (j in fconfig){
					fconfig[j] = object[j];
				} else { 
					resolveError(fconfig, object, j);
				}
			}
			
			return fconfig;
		}
		
		public static function resetAndUpdateFromAnonymous(object:Object, fconfig:FurnitureConfig):FurnitureConfig {
			fconfig.reset();
			return updateFromAnonymous(object, fconfig);
		}
		
	}
}