package com.tinyspeck.engine.data.store
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class StoreItem extends AbstractTSDataEntity
	{
		public var cost:int;
		public var class_tsid:String;
		private var _count:int;
		public var total_quantity:int;
		public var store_sold:int;
		public var disabled_reason:String;
		
		public function set count(value:int):void { _count = value };
		public function get count():int {
			if (total_quantity) {
				return total_quantity-store_sold;
			}
			return _count;
		}
		
		public function StoreItem(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):StoreItem {
			var item:StoreItem = new StoreItem(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				
				if(j in item){
					item[j] = val;
				}
				else{
					resolveError(item,object,j);
				}
			}
			
			return item;
		}
		
		public static function updateFromAnonymous(object:Object, item:StoreItem):StoreItem {
			item = fromAnonymous(object, item.hashName);
			
			return item;
		}
	}
}