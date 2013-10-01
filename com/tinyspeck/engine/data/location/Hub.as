package com.tinyspeck.engine.data.location {
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.map.MapData;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	public class Hub extends AbstractTSDataEntity {
		public static const HELL_TSID:String = '40'; //hardcoding this in for now until myles passes something from the server
		
		public var tsid:String;
		public var label:String;
		public var map_data:MapData;
		public var street_tsids:Vector.<String> = new Vector.<String>();
		public var has_available_streets:Boolean; //server sends this, client doesn't use it for anything... yet
		
		public function Hub(hashName:String) {
			this.tsid = hashName;
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, tsid:String, add_to_search:Boolean = false):Hub {
			var hub:Hub = new Hub(tsid);
			hub = updateFromAnonymous(object, hub, add_to_search);
			
			return hub;
		}
		
		public static function updateFromAnonymous(object:Object, hub:Hub, add_to_search:Boolean = false):Hub {
			var j:String;
			var k:String;
			
			for(j in object){
				//handle the streets
				if(j == 'streets'){
					for(k in object[j]){
						//look through the world to see if we already know about this location
						var location:Location = TSModelLocator.instance.worldModel.getLocationByTsid(k);
						if(!location){
							//build one for the world
							location = new Location(k);
							TSModelLocator.instance.worldModel.locations[k] = location;
						}
						
						//update the name/hub
						location.label = object[j][k];
						location.hub_id = hub.tsid;
												
						//add it to the street tsids if not already there
						if(hub.street_tsids.indexOf(location.tsid) == -1){
							hub.street_tsids.push(location.tsid);
						}
						
						//if we are adding to the search, let's add it!
						if(add_to_search) TSModelLocator.instance.worldModel.search_locations[k] = location.label;
					}
				}
				else if(j == 'name'){
					hub.label = object[j];
				}
				else if(j in hub){
					hub[j] = object[j];
				}
				else {
					resolveError(hub,object,j);
				}
			}
			
			return hub;
		}
		
		public static function updateFromMapDataAll(mapData:Object):void {
			if(mapData.all){
				var hub:Hub;
				var m:String;
				var model:TSModelLocator = TSModelLocator.instance;
				
				for(m in mapData.all){
					hub = model.worldModel.getHubByTsid(m);
					if(!hub){
						hub = Hub.fromAnonymous(mapData.all[m], m, true);
					}
					else {
						hub = Hub.updateFromAnonymous(mapData.all[m], hub, true);
					}
					
					//place it in the world
					model.worldModel.hubs[m] = hub;
					
					//allow the searching of hub names as well
					if(hub){
						model.worldModel.search_locations[m] = hub.label;
					}
				}
				
				//make sure this doesn't make it to the map_data
				delete mapData.all;
			}
		}
	}
}