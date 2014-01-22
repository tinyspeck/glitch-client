package locodeco.util
{
import flash.geom.Point;
import flash.geom.Rectangle;

/** Find the smallest bounding rect of all given rects */
public class QuadHull extends Object
{
	public static function quadHull(rects:Vector.<Rectangle>):Vector.<Point> {
		var quadHull:Rectangle = rectHull(rects);
		var hull:Vector.<Point> = new Vector.<Point>();
		hull.push(quadHull.topLeft, new Point(quadHull.right, quadHull.top), quadHull.bottomRight, new Point(quadHull.left, quadHull.bottom));
		return hull;
	}
	
	public static function rectHull(rects:Vector.<Rectangle>):Rectangle {
		var quadHull:Rectangle = new Rectangle();
		for each (var rect:Rectangle in rects) {
			quadHull = quadHull.union(rect);
		}
		return quadHull;
	}
}
}