/**
 * http://csalvara.github.com/convex/
 * JONO: Modified from original sources to support vectors.
 * 
 * Just another implementation that may be more stable.
 */
package locodeco.util
{
import flash.geom.Point;

public class GrahamScan2 extends Object
{
	public static function convexHull(points:Vector.<Point>):Vector.<Point> {
		var hull:Vector.<Point> = new Vector.<Point>();
		
		// special cases: 0 or 1 point
		if (points.length == 0)
			return hull;
		if (points.length == 1) {
			hull.push(points[0]);
			return hull;
		}
		
		// find index of leftmost point
		var left_idx:int = 0;
		for (var i:int = 1; i < points.length; i++) {
			if (comparePoints(points[i], points[left_idx]) < 0)
				left_idx = i;
		}
		
		// sort points by angle to leftmost point
		var left:Point = points[left_idx];
		var sorted:Array = new Array();
		for (i = 0; i < points.length; i++) {
			if (i != left_idx)
				sorted.push(points[i]);
		}
		var gr_p:Point = points[!left_idx+0];
		for (i = !left_idx+1; i < points.length; i++) {
			if (i != left_idx) {
				var curr_p:Point = points[i];
				var gr_cmp:Number = (gr_p.y - left.y) * (curr_p.x - left.x);
				var curr_cmp:Number = (curr_p.y - left.y) * (gr_p.x - left.x);
				if (curr_cmp > gr_cmp)
					gr_p = curr_p;
			}
		}
		
		function comp(p1:Point,p2:Point):int {
			var cmp1:Number = (p1.y - left.y) * (p2.x - left.x);
			var cmp2:Number = (p2.y - left.y) * (p1.x - left.x);
			if (cmp1 < cmp2)
				return -1;
			else if (cmp1 > cmp2)
				return 1;
			else {	// collinear case
				gr_cmp = (gr_p.y - left.y) * (p1.x - left.x);
				curr_cmp = (p1.y - left.y) * (gr_p.x - left.x);
				if (gr_cmp == curr_cmp) {
					if (sqDist(p1,left) < sqDist(p2,left))
						return 1;
					else
						return -1;
				}
				else {
					if (sqDist(p1,left) < sqDist(p2,left))
						return -1;
					else
						return 1;
				}
			}
		}
		sorted.sort(comp);
		
		// pushed sorted list of vertices onto input stack
		var input:Array = sorted.reverse();
		
		// run graham scan
		hull.push(left);
		hull.push(input.pop());
		while (input.length > 0) {
			var point:Point = input.pop();
			var ccw:int;
			while ((ccw = CCW(hull[hull.length-2],hull[hull.length-1],point)) < 0) {
				hull.pop();
			}
			hull.push(point);
		}
		
		// return point array as output
		return hull;
	}
	
	private static function comparePoints(p1:Point, p2:Point):int {
		if (p1.x > p2.x)
			return 1;
		if (p1.x < p2.x)
			return -1;
		if (p1.y > p2.y)
			return 1;
		if (p1.y < p2.y)
			return -1;
		return 0;
	}
	
	private static function CCW(p1:Point, p2:Point, p3:Point):int {
		var det:Number = p1.x*(p2.y-p3.y)-p2.x*(p1.y-p3.y)+p3.x*(p1.y-p2.y);
		
		if (det < 0)
			return -1;
		else if (det > 0)
			return 1;
		else
			return 0;
	}
	
	private static function sqDist(p1:Point, p2:Point):int {
		var x_dist:Number = p2.x - p1.x;
		var y_dist:Number = p2.y - p1.y;
		return x_dist * x_dist + y_dist * y_dist;
	}

	private static function compLineDist(lp1:Point, lp2:Point, p1:Point, p2:Point):int {
		var A:Number = lp1.y - lp2.y;
		var B:Number = lp2.x - lp1.x;
		var C:Number = lp1.y * (lp1.x-lp2.x) + lp1.x * (lp2.y-lp1.y);
		
		// numerators of point-line distance
		var num1:Number = Math.abs(A * p1.x + B * p1.y + C);
		var num2:Number = Math.abs(A * p2.x + B * p2.y + C);
		
		if (num1 > num2)
			return 1;
		if (num1 < num2)
			return -1;
		return 0;
	}
}
}