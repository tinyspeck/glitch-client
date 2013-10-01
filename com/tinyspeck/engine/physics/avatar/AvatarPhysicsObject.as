package com.tinyspeck.engine.physics.avatar
{
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.physics.colliders.ColliderAvatar;
	import com.tinyspeck.engine.port.TSSprite;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;

	final public class AvatarPhysicsObject
	{
		/** These are the bounds from the view. Need a way to abstract this */
		// EC: I upped this to 150 height (from 120) because it was a litle too
		// restrictive (colliding with firefly_whistle, for example, was too
		// hard where it is placed on the stand)
		public const avatarViewBounds:Rectangle = new Rectangle(0, 0, 63, 150);
		
		/** Physics representation of where the avatar is */
		public const collider:ColliderAvatar = new ColliderAvatar();
		
		//Permanant and the basis for all ongoing development
		/** Interaction initiated by clicking/enter */
		//Legacy
		public const _interaction_spV:Vector.<TSSprite> = new Vector.<TSSprite>();
		
		//Keep track of "real world" object.
		public var pc:PC;
		public var is_self:Boolean = false;
		
		public var base_setting:PhysicsSetting; // this is the setting from the location before we apply adjustment
		public var setting:PhysicsSetting;
		
		//Current velocities and acceleration.
		public var vx:Number = 0;
		public var vy:Number = 0;
		public var vx_accel_perc:Number = 0;
		public var extra_vx:int;
			
		//States of physics.
		public var onLadder:Boolean;
		public var onFloor:Boolean;
		public var landing_time:uint; // the time when we hit the floor
		public var onWall:Boolean;
		public var onWall_side:Number;
		public var jumping:Boolean;
		public var falling:Boolean;
		public var fallingAfterJump:Boolean;
		/** After you hit your noggin against the ceiling */
		public var fallingAfterCeilingHit:Boolean;
		public var fallDuration:Number;
		
		public var movingLeft:Boolean;
		public var movingRight:Boolean;
		public var movingUp:Boolean;
		public var movingDown:Boolean;
		
		public var hasJumpedSinceFloor:Boolean = false;
		
		//public var walkSpeed:Number;
		public var distFromFloor:Number = 0;
		
		//Targets for the avatar. This should probably be moved.
		public var targetLadder:Ladder;
		public var ladderXDist:Number;
				
		//Ok, so this seems to be related to the avatar controller.
		public var onPath:Boolean = false;
		public var path_destination_pt:Point;
		public var path_destination:Object;//This can't be right ? 
		
		//Triggers for AvatarPhysicsHandler.
		public var triggerResetVelocity:Boolean = false;
		public var triggerReduceVelocity:Boolean = false;
		public var triggerResetVelocityX:Boolean = false;
		public var triggerResetVelocityXPerc:Boolean = false;
		public var triggerJump:Boolean = false;
		public var triggerJump_time:uint; // the time when the key was depressed
		public var triggerGetOnLadder:Boolean = false;
		public var triggerGetOffLadder:Boolean = false;
		
		public var triple_jump_cnt:uint;
		public var triple_jumping:Boolean;
		
		//Way to notify the avatarphysics handler from the avatarcontroller that he shouldn't take key input.
		public var ignore_keys:Boolean = true;
				
		public function AvatarPhysicsObject(pc:PC)
		{
			this.pc = pc;
		}

		/**
		 * Returns whether we are moving at all, within EPSILON units.
		 * (There is usually -0.01 vy active, hence the EPSILON.)
		 */
		public function isMoving(EPSILON:Number = 0.1):Boolean {
			return (((vx < 0 ? -vx : vx) > EPSILON) || ((vy < 0 ? -vy : vy) > EPSILON));
		}
		
		/** Returns whether either vx or vy is at the max */
		public function isAtMaxVelocity():Boolean {
			return ((((vx < 0) ? -vx : vx) == setting.vx_max) || (((vy < 0) ? -vy : vy) == setting.vy_max));
		}
		
		/** Returns whether vx_accel is at the max */
		public function isAtMaxAcceleration():Boolean {
			return (vx_accel_perc == 1);
		}
		
		/** Returns whether we're accelerating horizontally or falling */
		public function isAccelerating():Boolean {
			return ((vx_accel_perc != 0) || falling);
		}
	}
}