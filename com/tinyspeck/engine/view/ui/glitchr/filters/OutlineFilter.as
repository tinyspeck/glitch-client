package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Shader;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class OutlineFilter extends GlitchrFilter {
	
		public function OutlineFilter() {
			super("outline_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			var outlineShader:Shader = new Shader(new GlitchrShaders.OutlineShader() as ByteArray);
			outlineShader.data.difference.value = [1, 0];
			var outlineFilter:ShaderFilter = new ShaderFilter(outlineShader);
			_components.push(outlineFilter);
		}
	}
}