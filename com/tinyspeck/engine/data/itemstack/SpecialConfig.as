package com.tinyspeck.engine.data.itemstack {
	
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	
	public class SpecialConfig extends AbstractTSDataEntity {
		
		public static const TYPE_SDB_ITEM_CLASS:String = 'sdb_item_class';
		public static const TYPE_SDB_COLLECT:String = 'sdb_collect';
		public static const TYPE_SDB_COST:String = 'sdb_cost';
		public static const TYPE_TOWER_SIGN:String = 'tower_sign';
		public static const TYPE_TOWER_SCAFFOLDING:String = 'tower_scaffolding';
		public static const TYPE_TOWER_EDIT:String = 'tower_edit';
		public static const TYPE_FURN_PRICE_TAG:String = 'furn_price_tag';
		public static const TYPE_SNAP_FRAME:String = 'snap_frame';
		
		public static var sig_exclusions:Array = ['item_count'];
		
		public var sig:String;
		public var is_dirty:Boolean;
		
		public var item_class:String;
		public var swf_url:String;
		public var img_url:String;
		public var furniture:Object;
		public var item_count:int = -1;
		public var state:String;
		public var uid:String;
		public var delta_y:int;
		public var delta_x:int;
		public var width:int;
		public var height:int;
		public var center_view:Boolean;
		public var under_itemstack:Boolean;
		public var fade_in_sec:Number;
		public var fade_out_sec:Number;
		public var type:String;
		public var sale_price:Number = NaN;
		public var income:int = 0;
		public var is_selling:Boolean;
		public var h_flipped:Boolean;
		public var for_pc_tsid:String;
		public var label:String;
		public var no_display:Boolean;
		public var opacity:Object;
		
		// this will turn the special display on and off when the stack enters and exits these states
		public var state_triggers:Array;
		
		public function SpecialConfig(hashName:String) {
			super(hashName);
		}
		
		private function reset():void {
			sig = null;
			is_dirty = false;
			item_class = null;
			img_url = null;
			swf_url = null;
			item_count = -1;
			state = null;
			uid = null;
			delta_y = 0;
			delta_x = 0;
			width = 0;
			height = 0;
			center_view = false;
			under_itemstack = false;
			sig = null;
			type = null;
			sale_price = NaN;
			income = 0;
			is_selling = false;
			h_flipped = false;
			for_pc_tsid = null;
			label = null;
			no_display = false;
			opacity = null;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):SpecialConfig {
			var sconfig:SpecialConfig = new SpecialConfig(hashName);
			return SpecialConfig.updateFromAnonymous(object, sconfig);
		}
		
		public static function updateFromAnonymous(object:Object, sconfig:SpecialConfig):SpecialConfig {
			if (object) { 
				for (var j:String in object) {
					
					if (j in sconfig){
						sconfig[j] = object[j];
					} else { 
						resolveError(sconfig, object, j);
					}
				}
			}
			
			return sconfig;
		}
		
		public static function resetAndUpdateFromAnonymous(object:Object, sconfig:SpecialConfig):SpecialConfig {
			sconfig.reset();
			return updateFromAnonymous(object, sconfig);
		}
	}
}