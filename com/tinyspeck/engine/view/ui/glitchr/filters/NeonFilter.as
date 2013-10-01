package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.filters.ConvolutionFilter;
	
	public class NeonFilter extends GlitchrFilter {
	
		public function NeonFilter() {
			super("neon_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			var neonFilter:ConvolutionFilter = new ConvolutionFilter(3,3,new Array(0,20,0,20,-80,20,0,20,0),10);
			_components.push(neonFilter);
		}
	}
}