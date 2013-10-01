package com.tinyspeck.engine.physics.colliders
{
	public class ColliderCircle
	{
		public var x:Number = 127;
		public var y:Number = 127;
		public var radius:Number = 15;
		public var vx:Number = 0;
		public var vy:Number = 0;
	
		public function copyFrom(other:ColliderCircle):void {
			x = other.x;
			y = other.y;
			vx = other.vx;
			vy = other.vy;
			radius = other.radius;
		}
	}
}