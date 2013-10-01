package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	public class GlitchrFilterUtils {
		
		private static const helperMatrix:Matrix = new Matrix();
		
		public static function drawOverlaysToBitmapData(glitchrFilter:GlitchrFilter, destinationBMD:BitmapData, alpha:Number = 1.0):void {

			destinationBMD.lock();
			for each (var overlay:FilterOverlay in glitchrFilter.overlays) {
				var overlayScaleX:Number = destinationBMD.width / overlay.width;
				var overlayScaleY:Number = destinationBMD.height / overlay.height;
				helperMatrix.identity();
				helperMatrix.scale(overlayScaleX, overlayScaleY);
				
				if (!overlay.lockAlpha) {
					var alphaTransform:ColorTransform = new ColorTransform(); // use a colortransform to apply filter alpha
					alphaTransform.alphaMultiplier = alpha;
					destinationBMD.draw(overlay.bitmapData, helperMatrix, alphaTransform, null, null, true);
				} else {
					destinationBMD.draw(overlay.bitmapData, helperMatrix, null, null, null, true);
				}
			}
			destinationBMD.unlock();
		}
	}
}