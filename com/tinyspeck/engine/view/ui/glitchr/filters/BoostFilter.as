package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.filters.BitmapFilterQuality;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	
	public class BoostFilter extends GlitchrFilter {
		
		public function BoostFilter() {
			super("boost_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			var innerGlowFilter:GlowFilter = new GlowFilter(0, 0.8, 128, 128, 1, BitmapFilterQuality.HIGH, true);
			var highContrastMat:Array =	[1.5, 0.0, 0.0, 0.0, -36,
										 0.0, 1.5, 0.0, 0.0, -36,
										 0.0, 0.0, 1.5, 0.0, -36, 
										 0.0, 0.0, 0.0, 1.0, 0];
			
			var highContrastFilter:ColorMatrixFilter = new ColorMatrixFilter(highContrastMat);
			_components.push(innerGlowFilter);
			_components.push(highContrastFilter);
		}
	}
}