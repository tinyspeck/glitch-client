package com.tinyspeck.engine.data.map
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class MapPathSegment extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var to:int;
		public var from:int;
		
		public function MapPathSegment(tsid:String){
			super(tsid);
			this.tsid = tsid;
		}
		
		public static function fromAnonymous(object:Object):MapPathSegment {
			var segment:MapPathSegment = new MapPathSegment(object.tsid);
			var j:String;
			
			for(j in object){
				if(j in segment){	
					segment[j] = object[j];
				}else{
					resolveError(segment,object,j, true);
				}
			}
			
			return segment;
		}
	}
}