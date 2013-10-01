package com.tinyspeck.engine.data.itemstack
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	

	public class ItemstackToolState extends AbstractTSDataEntity
	{
		public var is_broken:Boolean;
		public var points_capacity:int;
		public var points_remaining:int
		
		public function ItemstackToolState(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):ItemstackToolState
		{
			var toolstate:ItemstackToolState = new ItemstackToolState(hashName);
			
			return ItemstackToolState.updateFromAnonymous(object, toolstate);
		}
		
		public static function updateFromAnonymous(object:Object, toolstate:ItemstackToolState):ItemstackToolState
		{
			for(var j:String in object){
				if(j in toolstate){
					toolstate[j] = object[j];
				}else{
					resolveError(toolstate,object,j);
				}
			}
			return toolstate;
		}
	}
}