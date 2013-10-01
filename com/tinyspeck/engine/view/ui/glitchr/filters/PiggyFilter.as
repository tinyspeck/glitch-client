package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Shader;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class PiggyFilter extends GlitchrFilter {
		
		public function PiggyFilter() {
			super("piggy_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			// pink color shader
			var pinkColorShader:Shader = new Shader(new GlitchrShaders.ChannelColorizerShader() as ByteArray);
			pinkColorShader.data.r.value = [214, 45, 45, 0];
			pinkColorShader.data.g.value = [55, 219, 20, 0];
			pinkColorShader.data.b.value = [45, 20, 214, 0];
			var pinkColorFilter:ShaderFilter = new ShaderFilter(pinkColorShader);
			
			// noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.07];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);
			
			// black inner glow
			var vignetteGlow:GlowFilter = new GlowFilter(0, 0.7, 180, 180, 1.5, BitmapFilterQuality.HIGH, true);
			
			_components.push(pinkColorFilter);
			_components.push(noiseFilter);
			_components.push(vignetteGlow);
		}
	}
}