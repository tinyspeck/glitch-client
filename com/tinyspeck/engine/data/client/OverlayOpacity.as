package com.tinyspeck.engine.data.client
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class OverlayOpacity extends AbstractTSDataEntity
	{
		public var opacity:Number = 1;
		public var opacity_ms:uint;
		public var opacity_end:Number = -1;
		public var opacity_end_delay_ms:int = -1;
		public var opacity_end_ms:int = -1;
		public var uid:String;
		
		public function OverlayOpacity(){
			super('overlay_opacity');
		}
		
		public static function fromAnonymous(object:Object):OverlayOpacity {
			var overlay_opacity:OverlayOpacity = new OverlayOpacity();
			var j:String;
			
			for(j in object){
				if(j in overlay_opacity){
					overlay_opacity[j] = object[j];
				}
				else{
					resolveError(overlay_opacity,object,j);
				}
			}
			
			//check if the end stuff was not set, then go ahead and set them
			if(overlay_opacity.opacity_end == -1) overlay_opacity.opacity_end = overlay_opacity.opacity;
			if(overlay_opacity.opacity_end_delay_ms == -1) overlay_opacity.opacity_end_delay_ms = 0;
			if(overlay_opacity.opacity_end_ms == -1) overlay_opacity.opacity_end_ms = overlay_opacity.opacity_ms;
			
			return overlay_opacity;
		}
	}
}