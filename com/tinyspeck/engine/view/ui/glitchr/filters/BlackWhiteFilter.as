package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Shader;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class BlackWhiteFilter extends GlitchrFilter {
	
		public function BlackWhiteFilter() {
			super("bw_fitler");
		}
		
		override protected function init():void {
			
			// black and white color shader
			var bwColorShader:Shader = new Shader(new GlitchrShaders.ChannelColorizerShader() as ByteArray);
			bwColorShader.data.r.value = [128, 128, 128, 0];
			bwColorShader.data.g.value = [128, 128, 128, 0];
			bwColorShader.data.b.value = [255, 255, 255, 0];
			bwColorShader.data.normalization.value = [0.50];
			var bwColorFilter:ShaderFilter = new ShaderFilter(bwColorShader);
			
			// noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.07];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);
			
			// black inner glow
			var vignetteGlow:GlowFilter = new GlowFilter(0, 0.8, 180, 180, 1.5, BitmapFilterQuality.HIGH, true);
			
			_components.push(bwColorFilter);
			_components.push(vignetteGlow);
			_components.push(noiseFilter);

		}
	}
}