package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Shader;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class BerylFilter extends GlitchrFilter {
		
		public function BerylFilter() {
			super("beryl_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			// teal color shader
			var tealColorShader:Shader = new Shader(new GlitchrShaders.ChannelColorizerShader() as ByteArray);
			tealColorShader.data.r.value = [230, 40, 30, 0];
			tealColorShader.data.g.value = [0, 230, 35, 0];
			tealColorShader.data.b.value = [0, 35, 230, 0];
			var tealColorFilter:ShaderFilter = new ShaderFilter(tealColorShader);
			
			// noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.07];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);
			
			// black inner glow
			var vignetteGlow:GlowFilter = new GlowFilter(0, 0.7, 180, 180, 1.5, BitmapFilterQuality.HIGH, true);
			
			_components.push(tealColorFilter);
			_components.push(noiseFilter);
			_components.push(vignetteGlow);
		}
	}
}