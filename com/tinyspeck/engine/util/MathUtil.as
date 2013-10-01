package com.tinyspeck.engine.util
{
import flash.geom.Point;

	public class MathUtil
	{
		public static const DEG_TO_RAD:Number = (Math.PI / 180);
		public static const RAD_TO_DEG:Number = (180 / Math.PI);
		
		/** Returns angle in radians of vector A and B */
		public static function angle(ax:Number, ay:Number, bx:Number, by:Number):Number {
			const dot:Number = ((ax*bx)+(ay*by));
			const lenA:Number = Math.sqrt(ax*ax+ay*ay);
			const lenB:Number = Math.sqrt(bx*bx+by*by);
			return Math.acos(dot / (lenA * lenB));
		}
		
		/** Reflect vector A against B */
		public static function reflectVector(ax:Number, ay:Number, bx:Number, by:Number, out:Point):void {
			// normalize B
			const lenB:Number = Math.sqrt(bx*bx+by*by);
			bx /= lenB;
			by /= lenB;
			
			const dot:Number = ((ax*bx)+(ay*by));
			out.x = (ax - 2 * dot * bx);
			out.y = (ay - 2 * dot * by);
		}
		
		public static function randomInt(min:int, max:int):int {
			return Math.floor(Math.random() * (1+max-min))+min;
		}
		
		public static function chance(n:int):Boolean { //1-100
			return (randomInt(1,100) <= n);
		}
		
		public static function clamp(min:Number, max:Number, value:Number):Number {
			return Math.max(min,Math.min(max,value));
		}
		
		public static function rotatePointByDegrees(pt:Point, origin:Point, degrees:Number):Point {
			return rotatePointByRadians(pt, origin, degrees*DEG_TO_RAD);
		}
		
		public static function rotatePointByRadians(pt:Point, origin:Point, radians:Number):Point {
			const cosRadians:Number = Math.cos(radians);
			const sinRadians:Number = Math.sin(radians);
			
			// translate the point to the origin
			pt.x += -(origin.x);
			pt.y += -(origin.y);
			
			// rotate
			const rotatedPt:Point = new Point();
			rotatedPt.x = (pt.x*cosRadians) - (pt.y*sinRadians);
			rotatedPt.y = (pt.x*sinRadians) + (pt.y*cosRadians);
			
			// translate from the origin back
			rotatedPt.x += origin.x;
			rotatedPt.y += origin.y;
			
			return rotatedPt;
		}
		
		public static function isNumeric(num:String):Boolean {
			return !isNaN(parseInt(num));
		}
		
		/** Not optimal: If you need this a lot, see @ColliderLine.distanceFromInfinite() */
		public static function distanceFromPointToInfiniteLine(pointX:Number, pointY:Number, lineX0:Number, lineY0:Number, lineX1:Number, lineY1:Number):Number {
			// vertical line
			if (lineX0 == lineX1) return Math.abs(pointX - lineX0);
			
			// horizontal line
			if (lineY0 == lineY1) return Math.abs(pointY - lineY0);
			
			// oblique line
			const dX:Number = (lineX1 - lineX0);
			const dY:Number = (lineY1 - lineY0);
			return Math.abs((dX*(lineY0 - pointY) - dY*(lineX0 - pointX)) / Math.sqrt(dX*dX + dY*dY));
		}
		
		public static function distanceFromPointToFiniteLine(pointX:Number, pointY:Number, lineX0:Number, lineY0:Number, lineX1:Number, lineY1:Number):Number {
			const dX:Number = (lineX1 - lineX0);
			const dY:Number = (lineY1 - lineY0);
			
			const lineLength:Number = Math.sqrt(dX*dX + dY*dY);
			
			const numer:Number = (dX*(pointX - lineX0) + dY*(pointY - lineY0));
			const denom:Number = (lineLength*lineLength);
			const u:Number = (numer / denom);
			
			// point is not on line
			if ((u < 0.00001) || (u > 1)) {
				// return the distance to the closest endpoint
				const dist0:Number = Math.sqrt((pointX - lineX0)*(pointX - lineX0) + (pointY - lineY0)*(pointY - lineY0));
				const dist1:Number = Math.sqrt((pointX - lineX1)*(pointX - lineX1) + (pointY - lineY1)*(pointY - lineY1));
				return ((dist0 < dist1) ? dist0 : dist1);
			}
			
			// point falls on the line, return the distance to the intersection
			const intersectionX:Number = (lineX0 + u*dX);
			const intersectionY:Number = (lineY0 + u*dY);
			return Math.sqrt(((intersectionX - pointX)*(intersectionX - pointX)) + ((intersectionY - pointY)*(intersectionY - pointY)));
		}
		
		public static function distance(x1:int, y1:int, x2:int, y2:int):Number {
			return Math.sqrt(((x2 - x1)*(x2 - x1)) + ((y2 - y1)*(y2 - y1)));
		}
	}
}