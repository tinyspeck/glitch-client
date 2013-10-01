package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class ShiftFilter extends GlitchrFilter {
		
		public function ShiftFilter() {
			super("shift_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			// contrast boost
			var contrastMat:Array =	[1.5, 0.0, 0.0, 0.0, -40,
									 0.0, 1.5, 0.0, 0.0, -40,
									 0.0, 0.0, 1.5, 0.0, -40, 
									 0.0, 0.0, 0.0, 1.0, 0];
			var contrastFilter:ColorMatrixFilter = new ColorMatrixFilter(contrastMat);
			
			// red green color shift
			var colorShiftShader:Shader = new Shader(new GlitchrShaders.ColorSeparatorShader() as ByteArray);
			colorShiftShader.data.or.value = [ -5, 10];
			colorShiftShader.data.og.value = [ 3, -4];
			colorShiftShader.data.oa.value = [-1.2, 1.0];
			var colorShiftFilter:ShaderFilter = new ShaderFilter(colorShiftShader);
			
			//noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.07];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);
			
			// Inner glow
			var innerGlow:GlowFilter = new GlowFilter(0, 0.7, 180, 180, 1.5, BitmapFilterQuality.HIGH, true);
			
			_components.push(contrastFilter);
			_components.push(colorShiftFilter);
			_components.push(noiseFilter);
			_components.push(innerGlow);
			
			setupOverlay();
		}
		
		private function setupOverlay():void {
			// disable streaks overlay for now.
//			_overlayBitmaps.push(new GlitchrOverlays.StreaksOverlayBitmap() as Bitmap);
		}
	}
}