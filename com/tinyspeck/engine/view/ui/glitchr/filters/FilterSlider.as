package com.tinyspeck.engine.view.ui.glitchr.filters {
	import com.tinyspeck.engine.view.ui.TSSlider;
	
	import flash.display.DisplayObjectContainer;
	
	public class FilterSlider extends TSSlider {
	
		private static const BORDER:Number = 6;
		private static const BORDER_CORNER:Number = 20;
		private static const TRIANGLE_EDGE:Number = 12;
		private static const FILL_COLOR:uint = 0x00b4cf;
		
		public function FilterSlider(orientation:String=TSSlider.HORIZONTAL, parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0, defaultHandler:Function=null) {
			super(orientation, parent, xpos, ypos, defaultHandler);
			
			setupBackground();
			fillLevelColorTo = FILL_COLOR;
			fillLevelColorFrom = FILL_COLOR;
		}
		
		private function setupBackground():void {
			graphics.beginFill(0xffffff);
			graphics.drawRoundRect(-BORDER, -BORDER, width + BORDER*2, height + BORDER*2, BORDER_CORNER, BORDER_CORNER);
			
			var triangleVertices:Vector.<Number> = new Vector.<Number>();
			var topLeftX:Number = width/2 - TRIANGLE_EDGE/2;
			var topLeftY:Number = height + BORDER;
			var topRightX:Number = width/2 + TRIANGLE_EDGE/2;
			var topRightY:Number = height + BORDER;
			var bottomX:Number = width/2;
			var bottomY:Number = height + TRIANGLE_EDGE/2 + BORDER;
			triangleVertices.push(topLeftX, topLeftY, topRightX, topRightY, bottomX, bottomY);
			graphics.drawTriangles(triangleVertices);
		}
	}
}