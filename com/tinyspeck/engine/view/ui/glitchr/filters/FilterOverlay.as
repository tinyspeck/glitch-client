package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	public class FilterOverlay extends Bitmap {
		
		public var lockAlpha:Boolean = false;
		
		public function FilterOverlay(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=false) {
			super(bitmapData, pixelSnapping, smoothing);
		}
	}
}