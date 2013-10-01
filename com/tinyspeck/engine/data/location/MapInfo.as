package com.tinyspeck.engine.data.location
{	
	public class MapInfo extends AbstractLocationEntity
	{
		public var mote_id:String;
		public var mote_name:String;
		public var hub_id:String;
		public var hub_name:String;
		public var showStreet:String;
		public var showPos:Number;
		public var image_full:MapInfoImage;
		public var type:String;
		
		public function MapInfo()
		{
			super('mapInfo');
		}
		
		public static function fromAnonymous(object:Object):MapInfo
		{
			const mapInfo:MapInfo = new MapInfo();
			var j:String;
			
			for(j in object){
				if(j == 'image_full'){
					mapInfo.image_full = MapInfoImage.fromAnonymous(object[j]);
				}
				else if(j in mapInfo){	
					mapInfo[j] = object[j];
				}
				else{
					resolveError(mapInfo,object,j, true);
				}
			}
			return mapInfo;
		}
	}
}