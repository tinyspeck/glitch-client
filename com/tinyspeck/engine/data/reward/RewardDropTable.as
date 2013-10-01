package com.tinyspeck.engine.data.reward
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class RewardDropTable extends AbstractTSDataEntity
	{				
		public var class_tsid:String;
		public var label:String;
		public var count:int;
		
		public function RewardDropTable(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):RewardDropTable {
			var drop:RewardDropTable = new RewardDropTable(hashName);
			var val:*;
			
			for(var i:String in object){
				val = object[i];
				if(i in drop){
					drop[i] = val;
				}
				else{
					resolveError(drop,object,i);
				}
			}
			
			return drop;
		}
		
		public static function updateFromAnonymous(object:Object, drop:RewardDropTable):RewardDropTable
		{
			drop = fromAnonymous(object, drop.hashName);
			
			return drop;
		}
	}
}