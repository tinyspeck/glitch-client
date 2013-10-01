package com.tinyspeck.engine.physics.colliders
{
import flash.geom.Point;

public class InfiniteVerticalColliderLine extends InfiniteColliderLine
{
	public function InfiniteVerticalColliderLine(x:Number, radius:Number=1) {
		super(x, -Infinity, x, Infinity, radius);
	}
	
	override public function distance(pointX:Number, pointY:Number):Number {
		//TODO fastest way to do this?
		return ((pointX - x1) > 0 ? (pointX - x1) : (x1 - pointX));
	}
	
	override public function distanceSquared(pointX:Number, pointY:Number):Number {
		// avoiding the function call to distance() for performance reasons:
		return ((pointX - x1) * (pointX - x1));
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
		//TODO faster way?
		// return (distance(pointX, pointY) <= (EPSILON + radius));
		return (((pointX - x1) > 0 ? (pointX - x1) : (x1 - pointX)) <= (EPSILON + radius));
	}
	
	override public function recalc():void {
		super.recalc();
		// The infinite length messes up the general normal calculation.
		xNormal = -1;
		yNormal = 0;
	}
}
}