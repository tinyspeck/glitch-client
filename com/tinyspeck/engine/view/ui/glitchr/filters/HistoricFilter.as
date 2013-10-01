package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Shader;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;

	public class HistoricFilter extends GlitchrFilter {
		
		public function HistoricFilter() {
			super("historic_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			// dark inner glow
			var innerGlow:GlowFilter = new GlowFilter(0, 0.7, 180, 180, 1.5, BitmapFilterQuality.HIGH, true);
			
			// sepia shader
			var historicShader:Shader = new Shader(new GlitchrShaders.HistoricShader() as ByteArray);
			historicShader.data.crossfade.value = [2];
			var historicFilter:ShaderFilter = new ShaderFilter(historicShader);
			
			//noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.07];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);

			_components.push(innerGlow);
			_components.push(noiseFilter);
			_components.push(historicFilter);
		}
	}
}