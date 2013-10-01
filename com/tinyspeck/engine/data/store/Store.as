package com.tinyspeck.engine.data.store
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;

	public class Store extends AbstractTSDataEntity
	{
		public var name:String;
		public var buy_multiplier:Number;
		public var items:Vector.<StoreItem> = new Vector.<StoreItem>();
		public var tsid:String;
		public var single_stack_tsid:String;
		public var is_single_furniture:Boolean;
		public var single_furniture_upgrades:Vector.<FurnUpgrade> = new Vector.<FurnUpgrade>();
		
		public function Store(hashName:String){
			super(hashName);
			tsid = hashName;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Store {
			var store:Store = new Store(hashName);
			var store_item:StoreItem;
			var val:*;
			var j:String;
			var count:int;
			
			for(j in object){
				val = object[j];
				
				if(j == 'items'){
					count = 0;
					while(val && val[count]){
						store_item = StoreItem.fromAnonymous(val[count], 'item'+count);
						store.items.push(store_item);
						count++;
					}	
				}
				else if(j == 'single_furniture_upgrades'){
					store.single_furniture_upgrades = FurnUpgrade.parseMultiple(val, store.single_furniture_upgrades)
				}
				else if(j in store){
					store[j] = val;
				}
				else{
					resolveError(store,object,j);
				}
			}
			
			return store;
		}
		
		public static function updateFromAnonymous(object:Object, store:Store):Store {
			store = fromAnonymous(object, store.hashName);
			
			return store;
		}
		
		public function getStoreItemByItemClass(class_tsid:String):StoreItem {
			if (!items || !items.length) return null;
			
			var store_item:StoreItem;
			for each (store_item in items) {
				if (store_item.class_tsid == class_tsid) {
					return store_item;
				}
			}
			
			return null;
		}
	}
}