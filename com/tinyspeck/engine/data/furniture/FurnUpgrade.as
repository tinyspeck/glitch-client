package com.tinyspeck.engine.data.furniture {
  	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	
	public class FurnUpgrade extends AbstractTSDataEntity {
		
		public var id:String;
		public var furniture:FurnitureConfig;
		public var credits:uint;
		public var imagination:uint;
		public var label:String;
		public var subscriber_only:Boolean;
		public var is_visible:Boolean;
		public var is_owned:Boolean;
		public var is_new:Boolean;
		public var thumb:String;
		public var thumb_40:String;
		public var thumb_90:String;
		public var thumb_large:String;
		
		public function FurnUpgrade(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):FurnUpgrade {
			const world:WorldModel = TSModelLocator.instance.worldModel;
			var upgrade:FurnUpgrade = new FurnUpgrade(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if (j == 'config') {
					upgrade.furniture = FurnitureConfig.fromAnonymous(val, '');
				} else if (j in upgrade) {
					upgrade[j] = val;
				} else {
					resolveError(upgrade,object,j);
				}
			}
			
			return upgrade;
		}
		
		public static function parseMultiple(object:Object, upgrades:Vector.<FurnUpgrade>):Vector.<FurnUpgrade> {
			upgrades.length = 0;
			var upgrade:FurnUpgrade;
			var k:String;
			
			for(k in object){
				if (!('id' in object[k])) continue;
				upgrade = fromAnonymous(object[k], object[k]['id']);
				if (!upgrade.is_visible) {
					if (!CONFIG::god) {
						continue;
					}/* else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.info('including invisible upgrade '+upgrade.id+' '+upgrade.label+' only because you are admin');
						}
					}*/
				}
				upgrades.push(upgrade);
			}
			
			return upgrades;
		}
	}
}