package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Shader;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class DitherFilter extends GlitchrFilter {
		
		public function DitherFilter() {
			super("dither_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			// black and white color shader
			var bwColorShader:Shader = new Shader(new GlitchrShaders.ChannelColorizerShader() as ByteArray);
			bwColorShader.data.r.value = [128, 128, 128, 0];
			bwColorShader.data.g.value = [128, 128, 128, 0];
			bwColorShader.data.b.value = [255, 255, 255, 0];
			bwColorShader.data.normalization.value = [0.50];
			var bwColorFilter:ShaderFilter = new ShaderFilter(bwColorShader);
			
			// dither
			var ditherShader:Shader = new Shader(new GlitchrShaders.DitherShader() as ByteArray);
			var ditherFilter:ShaderFilter = new ShaderFilter(ditherShader);
			
			_components.push(bwColorFilter);
			_components.push(ditherFilter);
		}
	}
}