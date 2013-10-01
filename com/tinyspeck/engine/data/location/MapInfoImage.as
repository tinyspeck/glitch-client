package com.tinyspeck.engine.data.location
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class MapInfoImage extends AbstractTSDataEntity
	{
		public var url:String;
		public var w:int;
		public var h:int;
		
		public function MapInfoImage(){
			super('mapInfo_image');
		}
		
		public static function fromAnonymous(object:Object):MapInfoImage {
			const image:MapInfoImage = new MapInfoImage();
			var j:String;
			
			for(j in object){
				if(j in image){
					image[j] = object[j];
				}
				else {
					resolveError(image, object, j);
				}
			}
			return image;
		}
	}
}