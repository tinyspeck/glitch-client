/**
 * Use this class freely - 2009 blog.efnx.com
 * JONO: Modified from original sources to support vectors and fix edge cases.
 */
package locodeco.util
{
import flash.geom.Point;

public class GrahamScan extends Object
{
	/**
	 *  The Graham scan is a method of computing the convex hull of a finite set of points
	 *  in the plane with time complexity O(n log n). It is named after Ronald Graham, who
	 *  published the original algorithm in 1972. The algorithm finds all vertices of
	 *  the convex hull ordered along its boundary. It may also be easily modified to report
	 *  all input points that lie on the boundary of their convex hull.
	 */
	public function GrahamScan()
	{
		super();
	}
	
	/**
	 *  Returns a convex hull given an unordered vector of points.
	 */
	public static function convexHull(data:Vector.<Point>):Vector.<Point>
	{
		return (data.length <= 1) ? data : findHull( order(data) );
	}
	
	/**
	 *  Orders a vector of points counterclockwise.
	 */
	public static function order(data:Vector.<Point>):Vector.<Point>
	{
		//trace("GrahamScan::order()");
		// first run through all the points and find the upper left [lower left]
		var p:Point = data[0];
		var n:int   = data.length;
		for (var i:int = 1; i < n; i++)
		{
			//trace("   p:",p,"d:",data[int(i)]);
			if(data[int(i)].y < p.y)
			{
				//trace("   d.y < p.y / d is new p.");
				p = data[int(i)];
			}
			else if(data[int(i)].y == p.y && data[int(i)].x < p.x)
			{
				//trace("   d.y == p.y, d.x < p.x / d is new p.");
				p = data[int(i)];
			}
		}
		// next find all the cotangents of the angles made by the point P and the
		// other points
		var sorted  :Array = [];
		// we need arrays for positive and negative values, because Array.sort
		// will put sort the negatives backwards.
		var pos     :Array = [];
		var neg     :Array = [];
		// add points back in order
		for (i = 0; i < n; i++)
		{
			var a   :Number = data[int(i)].x - p.x;
			var b   :Number = data[int(i)].y - p.y;
			var cot :Number = b/a;
			if(cot < 0)
				neg.push({point:data[int(i)], cotangent:cot});
			else
				pos.push({point:data[int(i)], cotangent:cot});
		}
		// sort the arrays
		pos.sortOn("cotangent", Array.NUMERIC | Array.DESCENDING);
		neg.sortOn("cotangent", Array.NUMERIC | Array.DESCENDING);
		sorted = neg.concat(pos);
		
		var ordered :Vector.<Point> = new Vector.<Point>();
		ordered.push(p);
		for (i = 0; i < n; i++)
		{
			if(p == sorted[int(i)].point)
				continue;
			ordered.push(sorted[int(i)].point)
		}
		return ordered;
	}
	
	/**
	 *  Given an array of points ordered counterclockwise, findHull will
	 *  filter the points and return an array containing the vertices of a
	 *  convex polygon that envelopes those points.
	 */
	public static function findHull(data:Vector.<Point>):Vector.<Point>
	{
		if (data.length < 2) return data;
		
		//trace("GrahamScan::findHull()");
		var n   :int    = data.length;
		var hull:Vector.<Point>  = new Vector.<Point>();
		hull.push(data[0]); // add the pivot
		hull.push(data[1]); // makes first vector
		
		for (var i:int = 2; i < n; i++)
		{
			while(direction(hull[hull.length - 2], hull[hull.length - 1], data[int(i)]) >= 0)
				hull.pop();
			hull.push(data[int(i)]);
		}
		
		return hull;
	}
	
	/**
	 *
	 */
	private static function direction(p1:Point, p2:Point, p3:Point):Number
	{
		// > 0  is right turn
		// == 0 is collinear
		// < 0  is left turn
		// we only want right turns, usually we want right turns, but
		// flash's grid is flipped on y.
		return (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x);
	}
}
}