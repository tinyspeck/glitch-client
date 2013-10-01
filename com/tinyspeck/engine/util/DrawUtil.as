package com.tinyspeck.engine.util
{
	import at.leichtgewicht.draw.BezierCurve;
	
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.SpreadMethod;
	import flash.geom.Matrix;
	import flash.geom.Point;

	public class DrawUtil
	{
		private static var HDASH:BitmapData;
		private static var VDASH:BitmapData;
		{ // static init
			HDASH = new BitmapData(6, 1);
			HDASH.setPixel32(1, 0, 0);
			HDASH.setPixel32(2, 0, 0);
			HDASH.setPixel32(3, 0, 0);
			
			VDASH = new BitmapData(1, 6);
			VDASH.setPixel32(0, 1, 0);
			VDASH.setPixel32(0, 2, 0);
			VDASH.setPixel32(0, 3, 0);
		}
		
		// O"bject instead of :Location to avoid loading the whole fracking client codebase in auxilliary swfs that use this class
		public static function drawBGForLoc(loc:Object, g:Graphics, w:int, h:int):void
		{
			var colorsA:Array = [0xffffff, 0xffffff]; // default
			
			if (loc.hasGradient()) {
				colorsA = [
					ColorUtil.colorStrToNum(loc.gradient.top),
					ColorUtil.colorStrToNum(loc.gradient.bottom)
				];
			}
			
			g.clear();
			drawVerticalGradientBG(g, w, h, 0, colorsA);
		}
		
		public static function drawVerticalGradientBG(g:Graphics, w:int, h:int, corner:int, colorsA:Array, alphasA:Array = null, ratios:Array = null):void
		{
			var alphas:Array = alphasA || [1, 1];
			var ratiosA:Array = ratios || [0, 255];
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(w, h, Math.PI/2, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, colorsA, alphas, ratiosA, matrix, SpreadMethod.PAD);
			g.drawRoundRect(0, 0, w, h, corner);
			g.endFill();
		}
		
		public static function toRadians(a:Number):Number {
			return (a) / (180/Math.PI);
		}
		
		public static function drawArc(g:Graphics, centerX:Number, centerY:Number, startAngle:Number, endAngle:Number, radius:Number, direction:Number):void {
			/* 
			centerX  -- the center X coordinate of the circle the arc is located on
			centerY  -- the center Y coordinate of the circle the arc is located on
			startAngle  -- the starting angle to draw the arc from
			endAngle    -- the ending angle for the arc
			radius    -- the radius of the circle the arc is located on
			direction   -- toggle for going clockwise/counter-clockwise
			*/
			
			startAngle = toRadians(startAngle);
			endAngle = toRadians(endAngle);
			
			var difference:Number = Math.abs(endAngle - startAngle);
			/* How "far" around we actually have to draw */
			
			var divisions:Number = Math.floor(difference / (Math.PI / 4))+1;
			/* The number of arcs we are going to use to simulate our simulated arc */
			
			var span:Number    = direction * difference / (2 * divisions);
			var controlRadius:Number    = radius / Math.cos(span);
			
			g.moveTo(centerX + (Math.cos(startAngle)*radius), centerY + Math.sin(startAngle)*radius);
			var controlPoint:Point;
			var anchorPoint:Point;
			for(var i:Number=0; i<divisions; ++i)
			{
				endAngle    = startAngle + span;
				startAngle  = endAngle + span;
				
				controlPoint = new Point(centerX+Math.cos(endAngle)*controlRadius, centerY+Math.sin(endAngle)*controlRadius);
				anchorPoint = new Point(centerX+Math.cos(startAngle)*radius, centerY+Math.sin(startAngle)*radius);
				g.curveTo(
					controlPoint.x,
					controlPoint.y,
					anchorPoint.x,
					anchorPoint.y
				);
			}
		}
		
		public static function drawRing(g:Graphics, inner_radius:Number, outer_radius:Number, start_angle:Number = 0, perc:Number = 1):void {
			//how much of the ring are we drawing?
			const size:Number = perc * (2 * Math.PI);
			
			//convert it
			start_angle = toRadians(start_angle);
			
			//create the points
			const startX: Number = Math.cos(start_angle) * inner_radius;
			const startY: Number = Math.sin(start_angle) * inner_radius;
			const endX: Number = Math.cos(start_angle + size) * outer_radius;
			const endY: Number = Math.sin(start_angle + size) * outer_radius;
			
			//draw it
			g.moveTo(startX, startY);
			BezierCurve.draw(g, inner_radius, size, start_angle, 20);
			g.lineTo(endX, endY);
			BezierCurve.draw(g, outer_radius, size, start_angle, 20, null, false);
			g.lineTo(startX, startY);
		}
		
		public static function drawHighlightBlocker(g:Graphics, radius:int):void {
			const BG_MATRIX:Matrix = new Matrix();
			const BG_COLORS:Array = [0,0,0];
			const BG_ALPHAS:Array = [.2,.8,1];
			const BG_RATIOS:Array = [0,40,255];
			BG_MATRIX.createGradientBox(radius*2, radius*2, 0, -radius, -radius);
			g.beginGradientFill(GradientType.RADIAL, BG_COLORS, BG_ALPHAS, BG_RATIOS, BG_MATRIX);
			g.drawCircle(0, 0, radius);
		}
		
		public static function roundRectForDrawPath(x:Number, y:Number, w:Number, h:Number, r:Number):Array {
			var commands:Vector.<int> = new Vector.<int>();
			commands.push(1,2,3,2,3,2,3,2,3); //1 = moveTo, 2 = lineTo, 3 = curveTo
			
			var data:Vector.<Number> = new Vector.<Number>();
			data.push(x+r, y); //move to x/y
			data.push(x+w-r, y); //top line
			data.push(x+w,y, x+w,y+r); //top right
			data.push(x+w, y+h-r); //right
			data.push(x+w,y+h, x+w-r,y+h); //bottom right
			data.push(x+r, y+h); //bottom
			data.push(x,y+h, x,y+h-r); //bottom left
			data.push(x, y+r); //left
			data.push(x,y, x+r,y); //top left
			
			return new Array(commands, data);
		}
		
		public static function drawDashedRect(g:Graphics, w:int, h:int):void {
			g.lineStyle(0);
			
			g.lineBitmapStyle(HDASH);
			g.moveTo(0, 0);
			g.lineTo(w, 0);
			g.moveTo(0, h);
			g.lineTo(w, h);
			
			g.lineStyle(0);
			g.lineBitmapStyle(VDASH);
			g.lineTo(w, 0);
			g.moveTo(0, 0);
			g.lineTo(0, h);
			
			g.lineStyle(0);
		}
		
		public static function drawStar(radius:Number, g:Graphics, xOffset:int=0, yOffset:int=0):void {
			var inner_rad:Number = 0.382 * radius;
			var i:int = 1;
			var inter:int;
			var rad:Number;
			var a:Number;
			var p:Point;
			
			g.moveTo(xOffset, yOffset - radius);
			for (i; i <= 10; i++)
			{
				inter = i % 2;
				rad = (inter) ? inner_rad : radius;
				
				a = -Math.PI / 2 + i * Math.PI / 5;
				p = new Point( Math.cos(a), Math.sin(a));
				p.normalize(rad);
				g.lineTo(p.x + xOffset, p.y + yOffset);
			}
		}
		
		public static function pointIntersection(p1:Point, p2:Point, p3:Point, p4:Point):Point {
			var x1:Number = p1.x, x2:Number = p2.x, x3:Number = p3.x, x4:Number = p4.x;
			var y1:Number = p1.y, y2:Number = p2.y, y3:Number = p3.y, y4:Number = p4.y;
			var z1:Number = (x1 -x2), z2:Number = (x3 - x4), z3:Number = (y1 - y2), z4:Number = (y3 - y4);
			var d:Number = z1 * z4 - z3 * z2;
			
			// If d is zero, there is no intersection
			if (d == 0) return null;
			
			// Get the x and y
			var pre:Number = (x1*y2 - y1*x2), post:Number = (x3*y4 - y3*x4);
			var x:Number = ( pre * z2 - z1 * post ) / d;
			var y:Number = ( pre * z4 - z3 * post ) / d;
			
			// Check if the x and y coordinates are within both lines
			if ( x < Math.min(x1, x2) || x > Math.max(x1, x2) ||
				x < Math.min(x3, x4) || x > Math.max(x3, x4) ) return null;
			if ( y < Math.min(y1, y2) || y > Math.max(y1, y2) ||
				y < Math.min(y3, y4) || y > Math.max(y3, y4) ) return null;
			
			// Return the point of intersection
			return new Point(x, y);
		}
		
		/**
		 * Makes a candy cane pattern in some bitmapdata 
		 * @param h - height of the pattern
		 * @param stripe_w - how fat you want the stripe
		 * @param alpha - alpha of the stripe
		 * @param extra_padding - space between stripes, default is the same width as the stripe
		 * @return BitmapData of the stripe to use in bitmapFill or other such rad things
		 */		
		public static function drawCandyCanePattern(h:uint, stripe_w:uint, alpha:Number = .1, color:uint = 0xffffff, extra_padding:int = 0):BitmapData {
			const draw_w:uint = stripe_w*2 + extra_padding;
			const bmd:BitmapData = new BitmapData(draw_w, h, true, 0);
			const fill_color:uint = uint('0x'+ColorUtil.getHex(alpha * 255)+ColorUtil.colorNumToStr(color));
			
			var row:uint;
			var start_px:uint;
			var stripe_px:uint;
			var x_px:uint;
			
			bmd.lock();
			
			for(row = h; row > 0; row--){
				for(stripe_px = 0; stripe_px < stripe_w; stripe_px++){
					//draw a line starting at the px
					x_px = start_px + stripe_px;
					if(x_px >= draw_w){
						//too much, overflow the px on the left
						x_px -= draw_w;
					}
					bmd.setPixel32(x_px, row, fill_color);
				}
				
				start_px++;
			}
			
			bmd.unlock();
			
			return bmd;
		}
	}
}