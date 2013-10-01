package com.tinyspeck.engine.data.transit
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class TransitLine extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var bg:String;
		public var fg:String;
		public var name:String;
		public var locations:Vector.<TransitLocation>;
		
		public function TransitLine(hashName:String){
			super(hashName);
			this.tsid = hashName;
		}
		
		public static function fromAnonymous(object:Object, tsid:String):TransitLine {
			var line:TransitLine = new TransitLine(tsid);
			var j:String;
			var count:int;
			var location:TransitLocation;
			var val:*;
			
			for(j in object){
				if(j == 'locations'){
					count = 0;
					line.locations = new Vector.<TransitLocation>();
					while(object[j][count]){
						val = object[j][count];
						if(val && val.tsid){
							location = TransitLocation.fromAnonymous(val, val.tsid);
							line.locations.push(location);
						}
						count++;
					}
				}
				else if(j in line){	
					line[j] = object[j];
				}
				else{
					resolveError(line,object,j);
				}
			}
			
			return line;
		}
		
		public function getLocationByTsid(tsid:String):TransitLocation {
			if(!locations) return null;
			
			var i:int;
			for(i; i < locations.length; i++){
				if(locations[int(i)].tsid == tsid) return locations[int(i)];
			}
			
			return null;
		}
		
		public function getLocationByStationTsid(tsid:String):TransitLocation {
			if(!locations) return null;
			
			var i:int;
			for(i; i < locations.length; i++){
				if(locations[int(i)].station_tsid == tsid) return locations[int(i)];
			}
			
			return null;
		}
		
		public function getNextLocationByTsid(tsid:String):TransitLocation {
			if(!locations) return null;
			
			var i:int;
			for(i; i < locations.length; i++){
				if(locations[int(i)].tsid == tsid){
					//do we have the next one?
					if(i != locations.length-1){
						return locations[i+1];
					}
					//go back to the start
					else {
						return locations[0];
					}
				}
			}
			
			return null;
		}
	}
}