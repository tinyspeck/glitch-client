package com.tinyspeck.engine.data.location
{
	public class Cap extends Deco
	{
		public function Cap(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Cap
		{
			var cap:Cap = new Cap(hashName);
			for(var j:String in object){
				if(j in cap){
					cap[j] = object[j];
				}else{
					resolveError(cap,object,j);
				}
			}
			return cap;
		}
	}
}