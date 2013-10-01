package com.tinyspeck.engine.data.map
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class MapData extends AbstractTSDataEntity
	{
		public var color:String;
		public var fg:String;
		public var bg:String;
		public var streets:Vector.<Street> = new Vector.<Street>();
		public var world_map:String;
		
		public function MapData(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):MapData {
			var map_data:MapData = new MapData('map_data');
			
			return updateFromAnonymous(object, map_data);
		}
		
		public static function updateFromAnonymous(object:Object, map_data:MapData):MapData {
			var j:String;
			var count:int;
			var val:*;
			var street:Street;
			var street_index:int;
			var i:int;
			var total:int = map_data.streets.length;
			
			//mark everything as dirty until we can verify they are clean
			for(i = 0; i < total; i++){
				map_data.streets[int(i)].dirty = true;
			}
			
			for(j in object){
				if(j == 'objs'){
					val = object[j];
					count = 0;
					while(val && val[count]){
						street = map_data.getStreetByTsid(val[count]['tsid']);
						if(street){
							street = Street.updateFromAnonymous(val[count], street);
						}
						else {
							street = Street.fromAnonymous(val[count], val[count]['tsid']);
							map_data.streets.push(street);
						}
						street.dirty = false;
						count++;
					}
				}
				else if(j in map_data){	
					map_data[j] = object[j];
				}
				else{
					resolveError(map_data,object,j);
				}
			}
			
			//hunt through the streets and axe any that are dirty, who wants dirty streets anyways AM I RITE?!
			total = map_data.streets.length;
			for(i = total-1; i >= 0; i--){
				street = map_data.streets[int(i)];
				if(street.dirty) {
					CONFIG::debugging {
						Console.warn('FOUND A DIRTY STREET, AXING IT', street.tsid, street.label);
					}
					map_data.streets.splice(i, 1);
				}
			}
			
			return map_data;
		}
		
		public function getStreetByTsid(tsid:String):Street {
			var i:int;
			
			for(i; i < streets.length; i++){
				if(streets[int(i)].tsid == tsid) return streets[int(i)];
			}
			
			return null;
		}
	}
}