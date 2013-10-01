package com.tinyspeck.engine.physics.avatar
{
import flash.geom.Point;

	final public class AvatarPhysicsHitFlags
	{
		public var hasHitWall:Boolean;
		public var hasHitFloor:Boolean;
		public var hasHitCeiling:Boolean;
		
		public const ceilingVector:Point = new Point();
		
		public function reset():void
		{
			hasHitCeiling = false;
			hasHitFloor = false;
			hasHitWall = false;
		}
	}
}