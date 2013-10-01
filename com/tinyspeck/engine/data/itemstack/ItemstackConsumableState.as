package com.tinyspeck.engine.data.itemstack
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class ItemstackConsumableState extends AbstractTSDataEntity
	{
		public var count:int;
		public var max:int;
		
		public function ItemstackConsumableState(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):ItemstackConsumableState
		{
			var state:ItemstackConsumableState = new ItemstackConsumableState(hashName);
			
			return updateFromAnonymous(object, state);
		}
		
		public static function updateFromAnonymous(object:Object, state:ItemstackConsumableState):ItemstackConsumableState
		{
			for(var j:String in object){
				if(j in state){
					state[j] = object[j];
				}else{
					resolveError(state,object,j);
				}
			}
			return state;
		}
	}
}