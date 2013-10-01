package com.tinyspeck.engine.physics.data {
	import flash.geom.Point;
	
	/**
	 * Extends flash.geom.Point with vector math methods, e.g. dot product.
	 * Vector2D's methods optimistically accept any object with x and y properties.
	 * Enables method chaining, e.g. a.plusEquals(b).dot(c);
	 */
	public class Vector2D extends Point {
		
		public function Vector2D(x:Number = 0, y:Number = 0) {
			super(x, y);
		}
		
		public function get lengthSquared():Number {
			return x*x + y*y;
		}
		
		public function get unit():Vector2D {
			const len:Number = length;
			return new Vector2D(x / len, y / len);
		}	
			
		public function get normal():Vector2D {
			const len:Number = length;
			return new Vector2D(y / len, -x / len);
		}

		public function plus(point:*):Vector2D
		{
			return new Vector2D(x + point.x, y + point.y);
		}		
		
		public function minus(point:*):Vector2D
		{
			return new Vector2D(x - point.x, y - point.y);
		}
		
		public function plusEquals(point:*):Vector2D {
			x += point.x;
			y += point.y;
			return this;
		}
		
		public function minusEquals(point:*):Vector2D {
			x -= point.x;
			y -= point.y;
			return this;
		}
		
		public function timesEquals(point:*):Vector2D {
			x *= point.x;
			y *= point.y;
			return this;
		}
		
		public function dividedByEquals(point:*):Vector2D {
			x /= point.x;
			y /= point.y;
			return this;
		}
		
		public function negate():Vector2D {
			x = -x;
			y = -y;
			return this;
		}
		
		public function dot(point:*):Number {
			return x*point.x + y*point.y;
		}		
		
		override public function clone():Point {
			return new Vector2D(x, y);
		}
		
	}
}