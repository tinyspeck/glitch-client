package com.tinyspeck.engine.view.ui.glitchr.filters {

	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;

	public class MemphisFilter extends GlitchrFilter {
		
		public function MemphisFilter() {
			super("memphis_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			var vignetteGlow:GlowFilter = new GlowFilter(0, 0.5, 64, 64, 1, BitmapFilterQuality.HIGH, true);
			
			var curvesShader:Shader = new Shader(new GlitchrShaders.CurvesShader() as ByteArray);
			curvesShader.data.saturation.value = [1.0];
			curvesShader.data.redLow.value = [54, 13];
			curvesShader.data.redHigh.value = [200, 255];
			curvesShader.data.greenLow.value = [46, 0];
			curvesShader.data.greenHigh.value = [220, 255];
			curvesShader.data.blueLow.value = [0, 59];
			curvesShader.data.blueHigh.value = [255, 255];
			var curvesFilter:ShaderFilter = new ShaderFilter(curvesShader);
			
			_components.push(vignetteGlow);
			_components.push(curvesFilter);
			
			setupOverlay();
		}
		
		private function setupOverlay():void {
			var washSprite:Sprite = new Sprite();
			washSprite.graphics.beginFill(0xffffff, 0.25);
			washSprite.graphics.drawCircle(6, 6, 3);
			washSprite.graphics.endFill();
			
			var washBMD:BitmapData = new BitmapData(8, 8, true, 0);
			washBMD.draw(washSprite);
			var washOverlay:FilterOverlay = new FilterOverlay(washBMD, "auto", true);
			
			_overlays.push(washOverlay);
		}
	}
}