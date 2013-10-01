package com.tinyspeck.engine.physics.colliders
{
import flash.geom.Point;

/** An infinitely long line implicitly defined by two midpoints */
public class InfiniteColliderLine extends ColliderLine
{
	public function InfiniteColliderLine(x1:Number, y1:Number, x2:Number, y2:Number, radius:Number = 1) {
		super(x1, y1, x2, y2, radius);
	}
	
	override public function get isInfinite():Boolean {
		return true;
	}

	/** Returns the actual distance to this INFINITE line; very fast. */
	override public function distance(pointX:Number, pointY:Number):Number {
		// this awesome formula applies when the line is infinite
		// the dot product between the line normal and the point gives the distance
		const dist:Number = xNormal*(pointX - x1) + yNormal*(pointY - y1);
		return (dist > 0) ? dist : -dist;
	}
	
	/**
	 * For INFINITE lines, this is actually slower than just calling distance(),
	 * but still faster than calling distance() on a FINITE line. So if you
	 * don't know what kind of ColliderLine you're using, just use
	 * distanceSquared() or touches() for the best performance.
	 */
	override public function distanceSquared(pointX:Number, pointY:Number):Number {
		// avoiding the function call to distance() for performance reasons:
		const dist:Number = xNormal*(pointX - x1) + yNormal*(pointY - y1);
		return (dist*dist);
	}
	
	override public function motionTouchPoint(xStart:Number, yStart:Number, xDelta:Number, yDelta:Number, touchRadius:Number=0):Point {
		//TODO faster way?
		return super.motionTouchPoint(xStart, yStart, xDelta, yDelta, touchRadius);
	}
	
	override public function motionTouchTime(xStart:Number, yStart:Number, xDelta:Number, yDelta:Number, touchRadius:Number=0):Number {
		//TODO faster way?
		return super.motionTouchTime(xStart, yStart, xDelta, yDelta, touchRadius);
	}
	
	override public function touches(pointX:Number, pointY:Number, EPSILON:Number=0.00001):Boolean {
		// return (distance(pointX, pointY) <= (EPSILON + radius));
		var dist:Number = xNormal*(pointX - x1) + yNormal*(pointY - y1);
		if (dist < 0) dist = -dist;
		return (dist <= (EPSILON + radius));
	}
}
}