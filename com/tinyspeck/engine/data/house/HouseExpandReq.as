package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.SortTools;

	public class HouseExpandReq extends AbstractTSDataEntity
	{
		public var class_tsid:String;
		public var count:int;
		
		public function HouseExpandReq(tsid:String){
			super(tsid);
			class_tsid = tsid;
		}
		
		public static function parseMultiple(object:Object):Vector.<HouseExpandReq> {
			const V:Vector.<HouseExpandReq> = new Vector.<HouseExpandReq>();
			var j:String;
			var req:HouseExpandReq;
			
			for(j in object){
				req = new HouseExpandReq(j);
				req.count = int(object[j]);
				V.push(req);
			}
			
			//keep em sorted
			SortTools.vectorSortOn(V, ['class_tsid'], [Array.CASEINSENSITIVE]);
			
			return V;
		}
	}
}