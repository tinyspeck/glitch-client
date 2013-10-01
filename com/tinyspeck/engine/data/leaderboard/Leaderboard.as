package com.tinyspeck.engine.data.leaderboard
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class Leaderboard extends AbstractTSDataEntity
	{
		public var entries:Vector.<LeaderboardEntry> = new Vector.<LeaderboardEntry>();
		public var my_entry:LeaderboardEntry;
		
		public function Leaderboard(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Leaderboard {
			var lb:Leaderboard = new Leaderboard(hashName);
			var entry:LeaderboardEntry;
			var k:String;
			var count:int;
			
			while(object[count]){
				entry = LeaderboardEntry.fromAnonymous(object[count], object[count].pc.tsid);
				lb.entries.push(entry);
				count++;
			}
			
			//after that's done, parse YOUR position
			if(object.me){
				lb.my_entry = LeaderboardEntry.fromAnonymous(object.me, 'me');
			}
			
			return lb;
		}
		
		public static function updateFromAnonymous(object:Object, leaderboard:Leaderboard):Leaderboard {
			leaderboard = fromAnonymous(object, leaderboard.hashName);
			
			return leaderboard;
		}
	}
}