package com.tinyspeck.engine.data.map
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.location.Location;
	
	import flash.geom.Point;

	public class MapPathInfo extends AbstractTSDataEntity
	{
		public var path:Array;
		public var segments:Vector.<MapPathSegment> = new Vector.<MapPathSegment>();
		public var destination_tsid:String;
		public var you_pt:Point = new Point();
		
		public function MapPathInfo(dest_street_tsid:String){
			super(dest_street_tsid);
			destination_tsid = dest_street_tsid;
		}
		
		public static function fromAnonymous(object:Object):MapPathInfo {
			if(object.destination){
				var info:MapPathInfo = new MapPathInfo(object.destination.street_tsid);
				var segment:MapPathSegment;
				var j:String;
				var count:int;
				
				for(j in object){
					if(j == 'destination'){
						//update the world with this new info
						Location.fromAnonymousLocationStub(object[j]);
					}
					else if(j == 'path_new'){
						count = 0;
						while(object[j] && object[j][count]){
							segment = MapPathSegment.fromAnonymous(object[j][count]);
							info.segments.push(segment);
							count++;
						}
					}
					else if(j in info){	
						info[j] = object[j];
					}
					else{
						resolveError(info,object,j, true);
					}
				}
				return info;
			} else {
				CONFIG::debugging {
					Console.warn('Missing destination!');
				}
				return null;
			}
		}
		
		public function getSegmentByTsid(tsid:String):MapPathSegment {
			var i:int;
			
			for(i; i < segments.length; i++){
				if(segments[int(i)].tsid == tsid) return segments[int(i)];
			}
			
			return null;
		}
	}
}