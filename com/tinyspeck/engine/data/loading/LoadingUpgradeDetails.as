package com.tinyspeck.engine.data.loading
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.leaderboard.Leaderboard;

	public class LoadingUpgradeDetails extends AbstractTSDataEntity
	{
		public var upgrade_since_last_visit:Boolean;
		public var mins:int;
		public var leaderboard:Leaderboard;
		
		public function LoadingUpgradeDetails(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):LoadingUpgradeDetails {
			var upgrade_details:LoadingUpgradeDetails = new LoadingUpgradeDetails(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j == 'leaderboard'){
					upgrade_details.leaderboard = Leaderboard.fromAnonymous(val, j);
				}
				else if(j in upgrade_details){
					upgrade_details[j] = val;
				}
				else{
					resolveError(upgrade_details,object,j);
				}
			}
			
			return upgrade_details;
		}
		
		public static function updateFromAnonymous(object:Object, upgrade_details:LoadingUpgradeDetails):LoadingUpgradeDetails {
			upgrade_details = fromAnonymous(object, upgrade_details.hashName);
			
			return upgrade_details;
		}
	}
}