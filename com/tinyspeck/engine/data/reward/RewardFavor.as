package com.tinyspeck.engine.data.reward
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class RewardFavor extends AbstractTSDataEntity
	{				
		public var giant:String;
		public var points:int;
		
		public function RewardFavor(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):RewardFavor {
			var favor:RewardFavor = new RewardFavor(hashName);
			var val:*;
			
			for(var i:String in object){
				val = object[i];
				if(i in favor){
					favor[i] = val;
				}
				else{
					resolveError(favor,object,i);
				}
			}
			
			if (favor.giant == 'ti') favor.giant = 'tii';
			
			return favor;
		}
		
		public static function updateFromAnonymous(object:Object, favor:RewardFavor):RewardFavor 
		{
			favor = fromAnonymous(object, favor.hashName);
			
			return favor;
		}
	}
}