package com.tinyspeck.engine.physics.colliders {
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.data.Vector2D;
	import com.tinyspeck.engine.util.geom.Line;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/** A finite line explicitly defined by two endpoints */
	// maths from http://seb.ly/2010/01/predicting-circle-line-collisions
	public class ColliderLine extends Line {
		/** this is for the quadtree */
		client var physRect:Rectangle;
		/** cached computation for the solver */
		client var side:Number;
		
		//Geom properties
		public var radius:Number;
		public var isWall:Boolean;
		public var isPlatform:Boolean;
		
		//Precalc for the solver
		public var dx:Number;
		public var dy:Number;
		public var dxSquared:Number;
		public var dySquared:Number;
		public var lengthSquared:Number;
		public var length:Number;
		public var xNormal:Number;
		public var yNormal:Number;
		
		//For walls
		public var pc_solid_from_left:Boolean;
		public var pc_solid_from_right:Boolean;
		public var item_solid_from_left:Boolean;
		public var item_solid_from_right:Boolean;
		
		//For platforms
		public var pc_solid_from_top:Boolean;
		public var pc_solid_from_bottom:Boolean;
		public var item_solid_from_top:Boolean;
		public var item_solid_from_bottom:Boolean;

		/** If you change anything after constructing, you MUST recalc()! */
		public function ColliderLine(x1:Number, y1:Number, x2:Number, y2:Number, radius:Number = 1) {
			super(x1, y1, x2, y2);
			this.radius = radius;
			recalc();
		}
		
		public function get isInfinite():Boolean {
			return false;
		}
		
		/** Call this if you modify any of the public variables */
		//TODO This won't work for platforms with moving endpoints.
		public function recalc():void {
			dx = x2-x1;
			dy = y2-y1;
			
			dxSquared = dx*dx;
			dySquared = dy*dy;
			
			lengthSquared = (dxSquared + dySquared);
			length = Math.sqrt(lengthSquared);
			
			xNormal =  dy / length;
			yNormal = -dx / length;

			isWall = (dx == 0);
			isPlatform = !isWall;
		}

		/** @param EPSILON The 'tolerance' -- the amount of wiggle-room allowed. */
		public function touches(pointX:Number, pointY:Number, EPSILON:Number = 0.00001):Boolean {
			// alternative way (mathematically identical):
			//return (MathUtil.distanceFromPointToFiniteLine(pointX, pointY, x1, y1, x2, y2) <= (touchRadius + radius))
			return distanceSquared(pointX, pointY) <= (EPSILON + radius) * (EPSILON + radius);
		}

		/**
		 * Returns the distance from a point to this line.
		 * 
		 * Try to avoid this function for performance reasons and use
		 * touches() if you're just checking whether a point is within EPSILON
		 * pixels of this line.
		 * 
		 * If you're checking the distance to an InfiniteColliderLine, this
		 * function is very fast.
		 */
		public function distance(pointX:Number, pointY:Number):Number {
			return Math.sqrt(distanceSquared(pointX, pointY));
		}
		
		/**
		 * Fast way to get the distance to this line, squared, for comparison
		 * purposes to another length squared. Returning a squared number saves
		 * the Math.sqrt() call if you only care about the RELATIVE distance
		 * and not the ACTUAL distance.
		 * Optimized early returns are from 
		 * http://softsurfer.com/Archive/algorithm_0102/algorithm_0102.htm#dist_Point_to_Segment()
		 */
		public function distanceSquared(pointX:Number, pointY:Number):Number {
			// Take the dot product of 2 vectors. Both start at (x1, y1).
			// One vector goes to (x2, y2), the other to (pointX, pointY).
			const numer:Number = (dx*(pointX - x1) + dy*(pointY - y1));
			
			// This is somewhat like casting a shadow from the point onto this ColliderLine,
			// and u is the percent of the line covered by the shadow.
			
			// A negative shadow means (x1, y1) is the closest point to (pointX, pointY). 
			if (numer <= 0) {
				return ((x1 - pointX) * (x1 - pointX) 
				      + (y1 - pointY) * (y1 - pointY));
			}			
			// Too much shadow means (x2, y2) is the closest point to (pointX, pointY). 
			if (numer >= lengthSquared) {
				return ((x2 - pointX) * (x2 - pointX) 
				      + (y2 - pointY) * (y2 - pointY));
			}
			// The closest point falls on this line.
			const u:Number = (numer / lengthSquared);
			const intersectionX:Number = x1 + u*dx;
			const intersectionY:Number = y1 + u*dy;
			
			return ((intersectionX - pointX) * (intersectionX - pointX) 
			      + (intersectionY - pointY) * (intersectionY - pointY));
		}
		
		/** 
		 * @return The time when a moving circle would touch this line, IF IT WERE INFINITE (currently). 
		 * Time 0 is at the motion's start point, i.e. (xStart, yStart).
		 * Time 1 is at the motion's end point. 
		 * Time NaN means the motion is parallel to this line and thus touches always or never.
		 * Time < 0 or > 1 indicate a collision would occur outside of the range in question. 
		 */
		public function motionTouchTime(xStart:Number, yStart:Number, xDelta:Number, yDelta:Number, touchRadius:Number = 0):Number {
			// Exit early if no movement
			if (!xDelta && !yDelta) return NaN;
			// Find the distance from (xStart, yStart) to this line. 
			// For now, pretend this line is infinite to use a fast formula.
			// Take the dot product between this line's normal and vector from (x1, y1) to (xStart, yStart).
			// NOTE: this formula can produce negative distances.
			const distance1:Number = xNormal*(xStart - x1) + yNormal*(yStart - y1);
			// Does the motion get closer to this line or farther away?
			// Take the dot product of this line's normal and the motion vector.
			const distanceDelta:Number = xNormal*xDelta + yNormal*yDelta;
			
			// longer way to get the same thing
			//const distance2:Number = xNormal*(xStart + xDelta - x1) + yNormal*(yStart + yDelta - y1);
			//const distanceDelta:Number = distance2 - distance1;
			
			// The distance to this line is changing over time, thus the motion crosses somewhere
			if (distanceDelta) {	
				// Find the moment of collision. 
				// If the motion starts on the other side of the line, 
				// distance1 is negative, thus we must solve for a negative radius.
				const time:Number = (distance1 < 0) 
					? (-touchRadius - radius - distance1) / distanceDelta
					:  (touchRadius + radius - distance1) / distanceDelta;
				return time;
			}
			
			// The distance isn't changing, so the motion is parallel to this line.
			// Thus, it will either never or always touch the infinite line.
			// This next section may look heavy but it only executes with parallel motion.
			
			// Moving parallel but too far from the line, thus it never touches
			if (distance1 > (touchRadius + radius)) return NaN;
			// Moving parallel and will hit one of the endpoints 
			// Find which endpoint is closest
			const start:Vector2D = new Vector2D(xStart, yStart);
			const delta:Vector2D = new Vector2D(xDelta, yDelta);
			const lineA:Vector2D = new Vector2D(x1, y1);
			const lineB:Vector2D = new Vector2D(x2, y2);
			const startToA:Vector2D = lineA.minus(start);
			const startToB:Vector2D = lineB.minus(start);
			const closest:Vector2D = (startToA.lengthSquared < startToB.lengthSquared) ? lineA : lineB;
			const closestDiff:Vector2D = closest.minus(start);

			// See if there's a time when the motion comes close enough to the line's endpoints
			// Calculate coefficients for the quadratic equation
			const a:Number = delta.dot(delta);
			const b:Number = 2 * delta.dot(closestDiff);
			const c:Number = closestDiff.dot(closestDiff) - (touchRadius + radius) * (touchRadius + radius);
			const d:Number = b*b - 4*a*c;
			// No solution to quadratic equation, thus no time of contact. 
			if (d < 0) return NaN;
			// NOTE: b is supposed to be negative in the formula,
			// but currently tests pass when it's positive.
			const t:Number = (b - Math.sqrt(d)) / (2*a);
			//TODO: test with radius > 0
				if (t < 0) {		
					return (b + Math.sqrt(d)) / (2*a);
				}
			return t;
		}
		
		/**
		 * @return The Point of collision, or null if no collision within the chosen interval. 
		 */
		public function motionTouchPoint(xStart:Number, yStart:Number, xDelta:Number, yDelta:Number, touchRadius:Number = 0):Point {
			const time:Number = motionTouchTime(xStart, yStart, xDelta, yDelta, touchRadius);
			// rule out collisions that don't occur between the 2 timeframes/positions
			if (isNaN(time) || time < 0 || time > 1) {
				return null;
			}
			
			// find the location of the moving circle when it touches the infinite line
			const xTouch:Number = xStart + time*xDelta;
			const yTouch:Number = yStart + time*yDelta;
			
			// Check if the point is touching this line segment at the time
			// Inflate the touchRadius by sqrt(2) (or 2*sin(45)) to catch circles trying to sneak past the endpoints
			// This can be made more precise at the edges but ok for now.
			if (this.touches(xTouch, yTouch, touchRadius * 1.414)) {
				return new Point(xTouch, yTouch);
			}
			return null;
		}

		/**
		 * Reflects a vector off this line with a given strength.
		 * @param vector The incoming vector.
		 * @param strength The ratio between the magnitudes of the reflection and the incoming vector. 
		 * Defaults to 1, meaning no momentum is lost.
		 * Also called the "coefficient of restitution".
		 * http://en.wikipedia.org/wiki/Coefficient_of_restitution
		 * @return The reflection vector, scaled by strength. 
		 * The angle between the reflection and this line's normal 
		 * is the same as between the incoming vector and the normal. 
		 */
		public function reflect(vector:Vector2D, strength:Number = 1):Vector2D
		{
			const coef:Number = -2 * (xNormal * vector.x + yNormal * vector.y);
			return new Vector2D((coef * xNormal + vector.x) * strength, 
			                    (coef * yNormal + vector.y) * strength);
		}
	}
}