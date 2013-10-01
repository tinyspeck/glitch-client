package com.tinyspeck.engine.util.geom
{
	import flash.geom.Rectangle;

	public class LineClip
	{
		// bit flags for outcodes
		private static const LEFT:int = 1;
		private static const RIGHT:int = 2;
		private static const BOTTOM:int = 4;
		private static const TOP:int = 8;
						
		/**
		 * Clips a line to a rectangle using the Cohen-Sutherland algorithm.
		 * Currently, lines completely outside the rectangle are NOT changed--need to fix.
		 * http://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
		 */
		public static function cohenSutherland(line:Line, rect:Rectangle):void {
			var x1:Number = line.x1;
			var y1:Number = line.y1;
			var x2:Number = line.x2;
			var y2:Number = line.y2;
			
			var xmax:Number = rect.right;
			var xmin:Number = rect.left;
			var ymax:Number = rect.bottom;
			var ymin:Number = rect.top;
			
			//Outcodes for P0, P1, and whatever point lies outside the clip rectangle
			var outcodeOut:int;
			var hhh:int = 0;
			var accept:Boolean = false;
			var done:Boolean = false;
								
			//compute outcodes
			var outcode0:int = computeOutcode(x1, y1, xmin, ymin, xmax, ymax);
			var outcode1:int = computeOutcode(x2, y2, xmin, ymin, xmax, ymax);
					
			while (!done && hhh < 5000) {
				if ((outcode0 | outcode1) == 0) {
					accept = true;
					done = true;
				} else if ((outcode0 & outcode1) > 0) {
					done = true;
				} else {
					//failed both tests, so calculate the line segment to clip
					//from an outside point to an intersection with clip edge
					var x:int = 0;
					var y:int = 0;
					//At least one endpoint is outside the clip rectangle; pick it.
					outcodeOut = outcode0 != 0 ? outcode0: outcode1;
					//Now find the intersection point;
					//use formulas y = y0 + slope * (x - x0), x = x0 + (1/slope)* (y - y0)
					if ((outcodeOut & TOP) > 0){
						x = x1 + (x2 - x1) * (ymax - y1)/(y2 - y1);
						y = ymax;
					} else if ((outcodeOut & BOTTOM) > 0) {
						x = x1 + (x2 - x1) * (ymin - y1)/(y2 - y1);
						y = ymin;
					} else if ((outcodeOut & RIGHT) > 0) {
						y = y1 + (y2 - y1) * (xmax - x1)/(x2 - x1);
						x = xmax;
					} else if ((outcodeOut & LEFT) > 0) {
						y = y1 + (y2 - y1) * (xmin - x1)/(x2 - x1);
						x = xmin;
					}
					//Now we move outside point to intersection point to clip
					//and get ready for next pass.
					if (outcodeOut == outcode0) {
						x1 = x;
						y1 = y;
						outcode0 = computeOutcode(x1, y1, xmin, ymin, xmax, ymax);
					} else {
						x2 = x;
						y2 = y;
						outcode1 = computeOutcode(x2, y2, xmin, ymin, xmax, ymax);
					}
				}
				hhh ++;
			}
			if (accept) {
				line.x1 = x1;
				line.y1 = y1;
				line.x2 = x2;
				line.y2 = y2;
			}
			//TODO: if not accepted, set line coordinates to 0.
		}
		
		private static function computeOutcode(x:Number, y:Number, xmin:Number, ymin:Number, xmax:Number, ymax:Number):int
		{
			var code:int = 0;
			if (y > ymax) {
				code |= TOP;
			} else if (y < ymin) {
				code |= BOTTOM;
			}
			if (x > xmax) {
				code |= RIGHT;
			} else if (x < xmin) {
				code |= LEFT;
			}
			return code;
		}
	}
}