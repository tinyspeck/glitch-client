package com.tinyspeck.engine.util.geom
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class GeomUtil
	{
		public static function rectangleIntersects(rectangleA : Rectangle, rectangleB :Rectangle) : Boolean
		{
			if( (!((rectangleA.right<rectangleB.left)||(rectangleA.left>rectangleB.right))) && (!((rectangleA.bottom<rectangleB.top)||(rectangleA.top>rectangleB.bottom)))){
				return true;
			}
			return false;
		}
		
		/**
		 * round the valus of a rectang;e
		 * 
		 */
		public static function roundRectValues(rect:Rectangle):Rectangle {
			rect.x = Math.round(rect.x);
			rect.y = Math.round(rect.y);
			rect.width = Math.round(rect.width);
			rect.height = Math.round(rect.height);
			
			return rect;
		}
		
		/**
		 * Finds a pt between two points a certain distance form the first pt
		 * 
		 */
		public static function getPtBetweenTwoPts(pt1:Point, pt2:Point, distance_from_pt1:Number):Point {
			return Point.interpolate(pt2, pt1, distance_from_pt1/Point.distance(pt1, pt2));
		}
		
		/**
		 * Finds a the third pt of a trinagle when given the first two points, and the angle and distance from the first point and the desired pt
		 * 
		 */
		public static function getTrianglePtCFromPtsABAndDistAtoCAndAngleAtoC(ptA:Point, ptB:Point, distAtoC:Number, angleAtoC:Number):Point {
			
			var distAtoB:Number = Point.distance(ptA,ptB);
			var nRotation:Number = -Math.atan2(ptB.y-ptA.y, ptB.x-ptA.x); // radians
			
			// Convert the angle between the sides from degrees to radians.
			angleAtoC = angleAtoC * Math.PI / 180; // radians
			
			// Calculate the coordinates of points b and c.
			var nBx:Number = Math.cos(angleAtoC - nRotation) * distAtoC;
			var nBy:Number = Math.sin(angleAtoC - nRotation) * distAtoC;
			var nCx:Number = Math.cos(-nRotation) * distAtoB;
			var nCy:Number = Math.sin(-nRotation) * distAtoB;
			
			// Calculate the centroid's coordinates.
			var nCentroidX:Number = 0;
			var nCentroidY:Number = 0;
			
			return new Point(nBx - nCentroidX + ptA.x, nBy - nCentroidY + ptA.y);
		}
		
		/**
		 * Fast rectangle rectangle intersection.
		 * Make sure the rectangles intersect before running this.
		 * 
		 */
		public static function rectangleIntersectionTo(rectangleA:Rectangle, rectangleB:Rectangle, target:Rectangle):Rectangle
		{
			target.left = (rectangleA.left>rectangleB.left) ? rectangleA.left : rectangleB.left;
			target.right = (rectangleA.right<rectangleB.right) ? rectangleA.right : rectangleB.right;
			target.top = (rectangleA.top>rectangleB.top) ? rectangleA.top : rectangleB.top;
			target.bottom = (rectangleA.bottom<rectangleB.bottom) ? rectangleA.bottom : rectangleB.bottom;
			
			return target;
		}
		
		/**
		 * copy + paste + mod.
		 * http://keith-hair.net/blog/2008/08/04/find-intersection-point-of-two-lines-in-as3/
		 */
		public static function segmentIntersectSegment (a:Point,b:Point,e:Point,f:Point,targetPoint:Point):Point
		{
			var a1:Number;
			var a2:Number;
			var b1:Number;
			var b2:Number;
			var c1:Number;
			var c2:Number;
			a1= b.y-a.y;
			b1= a.x-b.x;
			c1= b.x*a.y - a.x*b.y;
			a2= f.y-e.y;
			b2= e.x-f.x;
			c2= f.x*e.y - e.x*f.y;
			var denom:Number=a1*b2 - a2*b1;
			if (denom == 0) {
				return null;
			}
			targetPoint.x=(b1*c2 - b2*c1)/denom;
			targetPoint.y=(a2*c1 - a1*c2)/denom;
			if ( a.x == b.x ){
				targetPoint.x = a.x;
			}else if (e.x == f.x){
				targetPoint.x = e.x;
			}
			if ( a.y == b.y ){
				targetPoint.y = a.y;
			}else if ( e.y == f.y ){
				targetPoint.y = e.y;
			}		
			if ( ( a.x < b.x ) ? targetPoint.x < a.x || targetPoint.x > b.x : targetPoint.x > a.x || targetPoint.x < b.x ){
				return null;
			}	
			if ( ( a.y < b.y ) ? targetPoint.y < a.y || targetPoint.y > b.y : targetPoint.y > a.y || targetPoint.y < b.y ){
				return null;
			}
			if ( ( e.x < f.x ) ? targetPoint.x < e.x || targetPoint.x > f.x : targetPoint.x > e.x || targetPoint.x < f.x ){
				return null;
			}
			if ( ( e.y < f.y ) ? targetPoint.y < e.y || targetPoint.y > f.y : targetPoint.y > e.y || targetPoint.y < f.y ){
				return null;
			}
			return targetPoint;
		}
		
		public static function lineIntersectLine (a : Point, b : Point,e : Point, f : Point, ret:Point, abIsSeg : Boolean = false, efIsSeg : Boolean = false) : Point
		{
			var a1:Number;
			var a2:Number;
			var b1:Number;
			var b2:Number;
			var c1:Number;
			var c2:Number;
			
			a1= b.y-a.y;
			b1= a.x-b.x;
			c1= b.x*a.y - a.x*b.y;
			a2= f.y-e.y;
			b2= e.x-f.x;
			c2= f.x*e.y - e.x*f.y;
			
			var denom:Number=a1*b2 - a2*b1;
			if (denom == 0) {
				return null;
			}
			ret=new Point();
			ret.x=(b1*c2 - b2*c1)/denom;
			ret.y=(a2*c1 - a1*c2)/denom;
				
			if ( a.x == b.x )
				ret.x = a.x;
			else if ( e.x == f.x )
				ret.x = e.x;
			if ( a.y == b.y )
				ret.y = a.y;
			else if ( e.y == f.y )
				ret.y = e.y;
			
			//      Constrain to segment.
			
			if ( abIsSeg )
			{
				if ( ( a.x < b.x ) ? ret.x < a.x || ret.x > b.x : ret.x > a.x || ret.x < b.x )
					return null;
				if ( ( a.y < b.y ) ? ret.y < a.y || ret.y > b.y : ret.y > a.y || ret.y < b.y )
					return null;
			}
			if ( efIsSeg )
			{
				if ( ( e.x < f.x ) ? ret.x < e.x || ret.x > f.x : ret.x > e.x || ret.x < f.x )
					return null;
				if ( ( e.y < f.y ) ? ret.y < e.y || ret.y > f.y : ret.y > e.y || ret.y < f.y )
					return null;
			}
			return ret;
		}
	}
}