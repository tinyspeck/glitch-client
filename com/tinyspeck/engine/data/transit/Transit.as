package com.tinyspeck.engine.data.transit
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.model.TSModelLocator;

	public class Transit extends AbstractTSDataEntity
	{
		public static const SUBWAY:String = 'subway';
		
		public var tsid:String;
		public var name:String;
		public var lines:Vector.<TransitLine>;
		
		public function Transit(hashName:String){
			super(hashName);
			this.tsid = hashName;
		}
		
		public static function updateFromMapDataTransit(mapData:Object):void {
			if(mapData.transit){
				var transit:Transit;
				var model:TSModelLocator = TSModelLocator.instance;
				var count:int;
				var val:*;
				
				while(mapData.transit[count]){
					val = mapData.transit[count];
					if(val && val.tsid){
						transit = model.worldModel.getTransitByTsid(val.tsid);
						if(!transit){
							transit = fromAnonymous(val, val.tsid);
							model.worldModel.transits.push(transit);
						}
						else {
							transit = updateFromAnonymous(val, transit);
						}
					}
					count++;
				}
				
				//make sure this doesn't make it to the map_data
				delete mapData.transit;
			}
		}
		
		public static function fromAnonymous(object:Object, tsid:String):Transit {
			var transit:Transit = new Transit(tsid);
						
			return updateFromAnonymous(object, transit);
		}
		
		public static function updateFromAnonymous(object:Object, transit:Transit):Transit {
			var j:String;
			var count:int;
			var line:TransitLine;
			var val:*;
			
			for(j in object){
				if(j == 'lines'){
					count = 0;
					transit.lines = new Vector.<TransitLine>();
					while(object[j][count]){
						val = object[j][count];
						if(val && val.tsid){
							line = TransitLine.fromAnonymous(val, val.tsid);
							transit.lines.push(line);
						}
						count++;
					}
				}
				else if(j in transit){	
					transit[j] = object[j];
				}
				else{
					resolveError(transit,object,j);
				}
			}
			
			return transit;
		}
		
		public function getLineByTsid(tsid:String):TransitLine {
			if(!lines) return null;
			
			var i:int;
			
			for(i; i < lines.length; i++){
				if(lines[int(i)].tsid == tsid) return lines[int(i)];
			}
			
			return null;
		}
		
		public function getLineByCurrentAndNext(current_tsid:String, next_tsid:String):TransitLine {
			if(!lines) return null;
			
			var i:int;
			
			for(i; i < lines.length; i++){
				if(lines[int(i)].getNextLocationByTsid(current_tsid).tsid == next_tsid) return lines[int(i)];
			}
			
			return null;
		}
	}
}