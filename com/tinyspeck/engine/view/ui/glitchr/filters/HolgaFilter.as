package com.tinyspeck.engine.view.ui.glitchr.filters {
	
	import flash.display.Shader;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class HolgaFilter extends GlitchrFilter {
		
		public function HolgaFilter() {
			super("holga_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			// slight increase in contrast and brightness
			var holgaColor:Array =	[1.5, 0.0, 0.0, 0.0, -40,
									0.0, 1.5, 0.0, 0.0, -40,
									0.0, 0.0, 1.5, 0.0, -40, 
									0.0, 0.0, 0.0, 1.0, 0];
			var holgaColorMatFilter:ColorMatrixFilter = new ColorMatrixFilter(holgaColor);
			
			// inner glow
			var holgaInnerGlow:GlowFilter = new GlowFilter(0, 1, 245, 245, 1.5, BitmapFilterQuality.HIGH, true);
			
			// noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.07];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);
			
			_components.push(holgaColorMatFilter);
			_components.push(holgaInnerGlow);
			_components.push(noiseFilter);
		}
	}
}