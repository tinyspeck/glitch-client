package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Shader;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class FireFlyFilter extends GlitchrFilter {
		
		public function FireFlyFilter() {
			super("fire_fly_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			// warm color shader
			var warmColorShader:Shader = new Shader(new GlitchrShaders.ChannelColorizerShader() as ByteArray);
			warmColorShader.data.r.value = [220, 80, 0, 0];
			warmColorShader.data.g.value = [60, 220, 0, 0];
			warmColorShader.data.b.value = [60, 0, 220, 0];
			var warmColorFilter:ShaderFilter = new ShaderFilter(warmColorShader);
			
			// noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.07];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);
			
			// black inner glow
			var vignetteGlow:GlowFilter = new GlowFilter(0, 0.7, 180, 180, 1.5, BitmapFilterQuality.HIGH, true);
			
			_components.push(warmColorFilter);
			_components.push(noiseFilter);
			_components.push(vignetteGlow);
		}
	}
}