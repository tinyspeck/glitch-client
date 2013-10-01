package com.tinyspeck.engine.data.transit
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class TransitLocation extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var name:String;
		public var x:int;  //X/Y is used for drawing the location on the map
		public var y:int;
		public var station_tsid:String; //the street the station is on
		
		public function TransitLocation(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, tsid:String):TransitLocation {
			var location:TransitLocation = new TransitLocation(tsid);
			var j:String;
			
			for(j in object){
				if(j in location){	
					location[j] = object[j];
				}
				else{
					resolveError(location,object,j);
				}
			}
			
			return location;
		}
	}
}