package com.tinyspeck.engine.data.storage
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.port.TrophyCaseManager;

	public class TrophyCase extends AbstractTSDataEntity
	{
		public var itemstack_tsid:String;
		public var private_tsid:String;
		public var display_cols:uint;
		public var display_rows:uint;
		public var private_cols:uint;
		public var private_rows:uint;
		
		public function TrophyCase(hashName:String)
		{
			super(hashName);
		}
		
		public static function parseMultiple(object:Object):Vector.<TrophyCase>
		{		
			var trophy_cases:Vector.<TrophyCase> = TrophyCaseManager.instance.trophy_cases;
			var trophy_case:TrophyCase;
			
			for(var j:String in object){
				trophy_case = getTrophyCaseByTsid(j);
				if(!trophy_case){
					trophy_cases.push(fromAnonymous(object[j],j));
				}else{
					trophy_cases[trophy_cases.indexOf(trophy_case)] = updateFromAnonymous(object[j], trophy_case);
				}
			}
			return trophy_cases;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):TrophyCase
		{			
			var trophy_case:TrophyCase = new TrophyCase(hashName);
			var val:*;
			var k:String;
			
			for(var j:String in object){
				val = object[j];
				if(j in trophy_case){
					trophy_case[j] = val;
				}else{
					resolveError(trophy_case,object,j);
				}
			}
			return trophy_case;
		}
		
		public static function updateFromAnonymous(object:Object, trophy_case:TrophyCase):TrophyCase 
		{
			trophy_case = fromAnonymous(object, trophy_case.hashName);
			
			return trophy_case;
		}
		
		public static function getTrophyCaseByTsid(tsid:String):TrophyCase 
		{
			var trophy_case:TrophyCase;
			var i:int = 0;
			var trophy_cases:Vector.<TrophyCase> = TrophyCaseManager.instance.trophy_cases;
			var total:int = trophy_cases.length;
			
			for(i; i < total; i++){
				trophy_case = trophy_cases[int(i)];
				if(trophy_case.itemstack_tsid == tsid){
					return trophy_case;
				}
			}
			
			return null;
		}
	}
}