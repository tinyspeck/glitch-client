package com.tinyspeck.engine.data.location
{
	public class PlatformLinePoint extends AbstractPositionableLocationEntity
	{
		public function PlatformLinePoint(hashName:String) {
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PlatformLinePoint {
			var plp:PlatformLinePoint = new PlatformLinePoint(hashName);
			for(var j:String in object){
				if(j in plp){
					plp[j] = object[j];
				}else{
					resolveError(plp,object,j);
				}
			}
			return plp;
		}
		
		public function equals(other:PlatformLinePoint):Boolean {
			return ((x == other.x) && (y == other.y));
		}
	}
}