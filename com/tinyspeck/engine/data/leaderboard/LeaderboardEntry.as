package com.tinyspeck.engine.data.leaderboard
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;

	public class LeaderboardEntry extends AbstractTSDataEntity
	{
		public var position:int;
		public var pc_tsid:String;
		public var contributions:Number;
		
		public function LeaderboardEntry(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):LeaderboardEntry {
			var entry:LeaderboardEntry = new LeaderboardEntry(hashName);
			var k:String;
			
			if(hashName == 'me'){
				entry.pc_tsid = TSModelLocator.instance.worldModel.pc.tsid;
			}
			
			for(k in object){
				if(k == 'pc'){
					if(object[k].tsid){
						//place them in the word if need be
						const world:WorldModel = TSModelLocator.instance.worldModel;
						var pc:PC = world.getPCByTsid(object[k].tsid);
						if(!pc){
							//add them to the world
							pc = PC.fromAnonymous(object[k], object[k].tsid);
							world.pcs[pc.tsid] = pc;
						} else {
							pc = PC.updateFromAnonymous(object[k], pc);
						}
						entry.pc_tsid = pc.tsid;
					} else {
						CONFIG::debugging {
							Console.warn('PC object missing TSID');
						}
					}
				}
				else if(k in entry){
					entry[k] = object[k];
				}
				else {
					resolveError(entry, object, k);
				}
			}
			
			return entry;
		}
		
		public static function updateFromAnonymous(object:Object, entry:LeaderboardEntry):LeaderboardEntry {
			entry = fromAnonymous(object, entry.hashName);
			
			return entry;
		}
	}
}