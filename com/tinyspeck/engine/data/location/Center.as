package com.tinyspeck.engine.data.location
{
	public class Center extends Deco
	{
		public function Center(hashName:String)
		{
			super(hashName);
		}
		
		public static function parseMultiple(object:Object):Vector.<Center>
		{
			var centers:Vector.<Center> = new Vector.<Center>();
			for(var j:String in object){
				centers.push(fromAnonymous(object[j],j));
			}
			return centers;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Center
		{
			var center:Center = new Center(hashName);
			for(var j:String in object){
				if(j in center){
					center[j] = object[j];
				}else{
					resolveError(center,object,j);
				}
			}
			return center;
		}
	}
}