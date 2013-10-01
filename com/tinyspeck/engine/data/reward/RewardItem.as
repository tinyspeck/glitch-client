package com.tinyspeck.engine.data.reward
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class RewardItem extends AbstractTSDataEntity
	{				
		public var class_tsid:String;
		public var label:String;
		public var count:int;
		public var itemstack_tsid:String;
		public var config:Object;
		public var is_broken:Boolean;
		
		public function RewardItem(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):RewardItem {
			var item:RewardItem = new RewardItem(hashName);
			var val:*;
			
			for(var i:String in object){
				val = object[i];
				if(i in item){
					item[i] = val;
				}
				else{
					resolveError(item,object,i);
				}
			}
			
			return item;
		}
		
		public static function updateFromAnonymous(object:Object, item:RewardItem):RewardItem
		{
			item = fromAnonymous(object, item.hashName);
			
			return item;
		}
	}
}