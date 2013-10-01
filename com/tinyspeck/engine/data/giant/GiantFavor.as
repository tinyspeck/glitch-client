package com.tinyspeck.engine.data.giant
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.SortTools;

	public class GiantFavor extends AbstractTSDataEntity
	{
		public var name:String;
		public var current:uint;
		public var max:uint;
		public var cur_daily_favor:uint;
		public var max_daily_favor:uint;
		
		public function GiantFavor(giant_tsid:String){
			super(giant_tsid);
			this.name = giant_tsid != 'ti' ? giant_tsid : 'tii';
		}
		
		public static function parseMultiple(ob:Object):Vector.<GiantFavor> {
			const V:Vector.<GiantFavor> = new Vector.<GiantFavor>();
			var k:String;
			
			for(k in ob){
				if('name' in ob[k]){
					V.push(fromAnonymous(ob[k], ob[k].name));
				}
			}
			
			//sort them
			SortTools.vectorSortOn(V, ['percent', 'name'], [Array.NUMERIC | Array.DESCENDING, Array.CASEINSENSITIVE]);
			
			return V;
		}
		
		public static function fromAnonymous(ob:Object, giant_tsid:String):GiantFavor {
			const favor:GiantFavor = new GiantFavor(giant_tsid);
			return updateFromAnonymous(ob, favor);
		}
		
		public static function updateFromAnonymous(ob:Object, favor:GiantFavor):GiantFavor {
			var k:String;
			for(k in ob){
				if(k == 'name' && ob[k] == 'ti'){
					favor.name = 'tii';
				}
				else if(k in favor){
					favor[k] = ob[k];
				}
				else {
					resolveError(favor, ob, k);
				}
			}
			
			return favor;
		}
		
		public function get label():String {
			//shortcut method
			return Giants.getLabel(name);
		}
		
		public function get percent():Number {
			//take the current divided by max and taa daa
			return current/max;
		}
	}
}