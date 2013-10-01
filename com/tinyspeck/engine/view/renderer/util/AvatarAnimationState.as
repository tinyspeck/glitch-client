package com.tinyspeck.engine.view.renderer.util
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;

	public class AvatarAnimationState
	{
		public static var DEFAULT_IDLE_STR:String = 'idle4';
		
		public static const CLIMB:AvatarAnimationState = new AvatarAnimationState("climb", 0, true);
		public static const CLIMB_PAUSE:AvatarAnimationState = new AvatarAnimationState("climb", 1, false, true);
		public static const JUMP_UP:AvatarAnimationState = new AvatarAnimationState("jumpOver_lift", 2);
		public static const JUMP_OVER:AvatarAnimationState = new AvatarAnimationState("jumpOver_lift", 3);
		public static const JUMP_UP_LAND:AvatarAnimationState = new AvatarAnimationState("jumpOver_land", 4);
		public static const JUMP_OVER_LAND:AvatarAnimationState = new AvatarAnimationState("jumpOver_land", 5);
		public static const STAND:AvatarAnimationState = new AvatarAnimationState(DEFAULT_IDLE_STR, 6, true);
		public static const WALK_1X:AvatarAnimationState = new AvatarAnimationState("walk1x", 7, true);
		public static const WALK_2X:AvatarAnimationState = new AvatarAnimationState("walk2x", 8, true);
		public static const FALL:AvatarAnimationState = new AvatarAnimationState("jumpOver_fall", 9);
		public static const ANGRY:AvatarAnimationState = new AvatarAnimationState("angry", 10);
		public static const HAPPY:AvatarAnimationState = new AvatarAnimationState("happy", 11);
		public static const SURPRISE:AvatarAnimationState = new AvatarAnimationState("surprise", 12);
		public static const IDLE0:AvatarAnimationState = new AvatarAnimationState("idle0", 13);
		public static const IDLE1:AvatarAnimationState = new AvatarAnimationState("idle1", 14);
		public static const IDLE2:AvatarAnimationState = new AvatarAnimationState("idle2", 15);
		public static const IDLE3:AvatarAnimationState = new AvatarAnimationState("idle3", 16);
		public static const IDLE4:AvatarAnimationState = new AvatarAnimationState("idle4", 17);
		public static const JUMP_UP_FALL:AvatarAnimationState = new AvatarAnimationState("jumpOver_fall", 18);
		public static const JUMP_OVER_FALL:AvatarAnimationState = new AvatarAnimationState("jumpOver_fall", 19);
		public static const DO:AvatarAnimationState = new AvatarAnimationState("do", 20, true);
		public static const IDLE_SLEEPY:AvatarAnimationState = new AvatarAnimationState("idleSleepy", 21);
		public static const HIT1:AvatarAnimationState = new AvatarAnimationState("hit1", 22, false, true);
		public static const HIT2:AvatarAnimationState = new AvatarAnimationState("hit2", 23, false, true);
		public static const AFK:AvatarAnimationState = 
			new AvatarAnimationState("idleSleepyStart,idleSleepyLoop,idleSleepyLoop,idleSleepyLoop,idleSleepyLoop,idleSleepyLoop,idleSleepyEnd", 24, false, false, true);
		public static const MAP:Array = [
			'CM',
			'CMP',
			'JU',
			'JO',
			'JUL',
			'JOL',
			'ST',
			'1X',
			'2X',
			'FA',
			'AN',
			'HA',
			'SU',
			'I0',
			'I1',
			'I2',
			'I3',
			'I4',
			'JUF',
			'JOF',
			'Do',
			'ISL',
			'H1',
			'H2',
			'AF'
		];
		
		public static var paused:Boolean = false;
		private static var last_aas:int = STAND.ID;
		public static const IDLES_TO_RANDOM:Array = [
			AvatarAnimationState.IDLE1.ID,
			AvatarAnimationState.IDLE2.ID,
			AvatarAnimationState.IDLE3.ID,
			AvatarAnimationState.IDLE0.ID,
			AvatarAnimationState.IDLE4.ID
		];
		
		public static const historyA:Array = [];
		public static const jump_historyA:Array = [];
		
		private var _name:String;
		private var _ID:int;
		private var _loop:Boolean;
		private var _stop:Boolean;
		private var _sequence:Boolean = true;
				
		public function AvatarAnimationState(name:String, ID:int, loop:Boolean = false, stop:Boolean = false, sequence:Boolean = false) {
			_name = name;
			_ID = ID;
			_loop = loop;
			_stop = stop;
			_sequence = sequence;
		}
		
		public function get name():String { return _name; }
		public function get ID():int { return _ID; }
		public function get loop():Boolean { return _loop; }
		public function get stop():Boolean { return _stop; }
		public function get sequence():Boolean { return _sequence; }
		
		public static function getStateByID(ID:int):AvatarAnimationState {
			
			switch(ID) {
				case 0 : return CLIMB;
				case 1 : return CLIMB_PAUSE;
				case 2 : return JUMP_UP;
				case 3 : return JUMP_OVER;
				case 4 : return JUMP_UP_LAND;
				case 5 : return JUMP_OVER_LAND;
				case 6 : return STAND;
				case 7 : return WALK_1X;
				case 8 : return WALK_2X;
				case 9 : return FALL;
				case 10 : return ANGRY;
				case 11 : return HAPPY;
				case 12 : return SURPRISE;
				case 13 : return IDLE0;
				case 14 : return IDLE1;
				case 15 : return IDLE2;
				case 16 : return IDLE3;
				case 17 : return IDLE4;
				case 18 : return JUMP_UP_FALL;
				case 19 : return JUMP_OVER_FALL;
				case 20 : return DO;
				case 21 : return IDLE_SLEEPY;
				case 22 : return HIT1;
				case 23 : return HIT2;
				case 24 : return AFK;
				
				default :
					return STAND;
			}
			
			return null;
		}

		public static function getAnimationStateFromAPO(apo:AvatarPhysicsObject):int {
			
			if (paused) return last_aas;
			
			var aas:int = calcAnimationStateFromAPO(apo);
			
			CONFIG::debugging {
				var max:int = 13;
				var str:String = MAP[aas];
				if (!historyA.length || historyA[0] != str) {
					historyA.unshift(str);
					if (historyA.length>max) historyA.splice(max);
					Console.trackPhysicsValue('AAS state', historyA.join('.'));
				}
				
				if (str.substr(0,1) == 'J') {
					if (!jump_historyA.length || jump_historyA[0] != str) {
						jump_historyA.unshift(str);
						if (jump_historyA.length>max) jump_historyA.splice(max);
						Console.trackPhysicsValue('AAS jumps', jump_historyA.join('.'));
					}
				}
			}
			
			last_aas = aas;
			return aas;
		}
		
		private static function getStandState():int {
			return STAND.ID;
		}
		
		private static function calcAnimationStateFromAPO(apo:AvatarPhysicsObject):int {
			var model:TSModelLocator = TSModelLocator.instance;
			
			CONFIG::debugging {
				Console.trackPhysicsValue('AAS onFloor', apo.onFloor);
				Console.trackPhysicsValue('AAS jumping', apo.jumping);
				Console.trackPhysicsValue('AAS falling', apo.falling);
				Console.trackPhysicsValue('AAS fallingAfterJump', apo.fallingAfterJump);
				Console.trackPhysicsValue('AAS fallingAfterCeilingHit', apo.fallingAfterCeilingHit);
			}
				
			if (apo.onLadder) { // need a check for on Ladder here
				if (apo.movingDown || apo.movingUp) {
					return CLIMB.ID;
				} else {
					return CLIMB_PAUSE.ID;
				}
			} else if (apo.jumping) {
				if (!apo.movingLeft && !apo.movingRight) {// && !apo.physicsSettings.jetpack) {
					return (last_aas == JUMP_OVER.ID) ? JUMP_OVER.ID : JUMP_UP.ID;
				} else {
					return (last_aas == JUMP_UP.ID) ? JUMP_UP.ID : JUMP_OVER.ID;
				}
			} else if (apo.onFloor) {
				if (!apo.movingLeft && !apo.movingRight) {
					return getStandState();
				} else {
					//if (apo.walkSpeed < .5) { used to be that, but doesn;t make much sense since you are  below half speed a fraction of a second
					if (Math.abs(apo.vx) < 150 && apo.setting.vx_max < 150) {
						return WALK_1X.ID;
					} else {
						return WALK_2X.ID;
					}
				}
			} else if (apo.setting.gravity <= 0) {
				// reversed gravity
				if (Math.abs(apo.vx) < 200) {
					if (apo.vy > 0) {
						return AvatarAnimationState.JUMP_UP_FALL.ID;
					} else {
						return AvatarAnimationState.JUMP_UP.ID;
					}
				} else {
					if (apo.vy > 0) {
						return AvatarAnimationState.JUMP_OVER_FALL.ID;
					} else {
						return AvatarAnimationState.JUMP_OVER.ID;
					}
				}
			} else if (apo.fallingAfterJump || apo.falling) {
				// normal gravity
				
				const land_limit:int = -(model.worldModel.pc.apo.vy*model.physicsModel.anim_state_land_limit_perc);
				const close_limit:int = Math.min(land_limit*model.physicsModel.anim_state_close_limit_perc, model.physicsModel.anim_state_close_limit_max);
				//close_limit = Math.max(close_limit, land_limit+5)
				
				// TODO: figure out how to make it so that close_limit does not prevent the fall animations in swim mode
				CONFIG::debugging {
					Console.trackPhysicsValue('AAS land_limit', land_limit);
					Console.trackPhysicsValue('AAS close_limit', close_limit);
				}
					
				// when we're very close to the platform, don't change current state
				if (apo.distFromFloor > close_limit) {
					return last_aas;
				}
				
				// we're not too close to the platform, but we're approaching it, so land
				if (apo.distFromFloor > land_limit && !model.flashVarModel.no_landing) {
					if (!apo.movingLeft && !apo.movingRight) {
						return (last_aas == JUMP_OVER.ID || last_aas == JUMP_OVER_LAND.ID || last_aas == JUMP_OVER_FALL.ID) ? JUMP_OVER_LAND.ID : JUMP_UP_LAND.ID;
					} else {
						return (last_aas == JUMP_UP.ID || last_aas == JUMP_UP_LAND.ID || last_aas == JUMP_UP_FALL.ID) ? JUMP_UP_LAND.ID : JUMP_OVER_LAND.ID;
					}
				}
				
				// not near a platform at all, so: just fall if not part of a jump; otherwise, don't change state
				if (!apo.movingLeft && !apo.movingRight && apo.fallingAfterJump) {
					return (last_aas == JUMP_OVER.ID || last_aas == JUMP_OVER_LAND.ID || last_aas == JUMP_OVER_FALL.ID) ? JUMP_OVER_FALL.ID : JUMP_UP_FALL.ID;
				} else {
					return (last_aas == JUMP_UP.ID || last_aas == JUMP_UP_LAND.ID || last_aas == JUMP_UP_FALL.ID) ? JUMP_UP_FALL.ID : JUMP_OVER_FALL.ID;
				}
			}
			
			//trace('no match! was:'+last_aas)
			// don't change state it there were no matches above
			return last_aas;
		}
	}
}