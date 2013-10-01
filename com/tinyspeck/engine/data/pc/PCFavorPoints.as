package com.tinyspeck.engine.data.pc
{
	import com.tinyspeck.engine.data.giant.GiantFavor;

	public class PCFavorPoints extends AbstractPCEntity
	{		
		public const all_favor:Vector.<GiantFavor> = new Vector.<GiantFavor>();
		
		public function PCFavorPoints(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):PCFavorPoints
		{
			const pc_fp:PCFavorPoints = new PCFavorPoints('favor_points');
			var j:String;
			var favor:GiantFavor;
			
			for(j in object){
				favor = pc_fp.getFavorByName(j);
				if(!favor){
					favor = GiantFavor.fromAnonymous(object[j], j);
					pc_fp.all_favor.push(favor);
				}
				else {
					favor = GiantFavor.updateFromAnonymous(object[j], favor);
				}
			}
			
			return pc_fp;
		}
		
		public function getFavorByName(giant_tsid:String):GiantFavor {
			const total:int = all_favor.length;
			var favor:GiantFavor;
			var i:int;
			
			if(giant_tsid == 'ti') giant_tsid = 'tii';
			for(i; i < total; i++){
				favor = all_favor[int(i)];
				if(favor.name == giant_tsid) return favor;
			}
			
			return null;
		}
		
		/**
		 * This should only be run from a new day message 
		 */		
		public function resetCurrentDailyFavor():void {
			const total:int = all_favor.length;
			var i:int;
			
			for(i; i < total; i++){
				all_favor[int(i)].cur_daily_favor = 0;
			}
		}
	}
}