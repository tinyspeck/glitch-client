package com.tinyspeck.engine.data.location
{
	public class QuarterInfo extends AbstractLocationEntity
	{
		public static const STYLE_NORMAL:String = 'normal';
		public static const STYLE_APARTMENT:String = 'apartment';
		
		public var rows:int;
		public var cols:int;
		public var row:int; //what row you're currently on
		public var col:int;
		public var style:String;
		public var label:String;
		
		public function QuarterInfo(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):QuarterInfo {
			var info:QuarterInfo = new QuarterInfo(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				
				if(j in info){
					info[j] = val;
				}
				else{
					resolveError(info,object,j);
				}
			}
			
			return info;
		}
		
		public static function updateFromAnonymous(object:Object, info:QuarterInfo):QuarterInfo {
			info = fromAnonymous(object, info.hashName);
			
			return info;
		}
	}
}