package com.tinyspeck.engine.data.itemstack {
	
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.ObjectUtil;
	
	public class LifespanConfig extends AbstractTSDataEntity {
		
		public var percentage_left:Number = 0;
		public var proto_item_tsid:String;
	
		public function LifespanConfig(hashName:String) {
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):LifespanConfig {
			var lconfig:LifespanConfig = new LifespanConfig(hashName);
			return LifespanConfig.updateFromAnonymous(object, lconfig);
		}
		
		public static function updateFromAnonymous(object:Object, lconfig:LifespanConfig):LifespanConfig {
			for (var j:String in object) {
				
				if (j in lconfig){
					lconfig[j] = object[j];
				} else { 
					resolveError(lconfig, object, j);
				}
			}
			
			return lconfig;
		}
		
	}
}