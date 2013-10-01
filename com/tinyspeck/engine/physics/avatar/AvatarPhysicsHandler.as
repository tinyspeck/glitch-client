package com.tinyspeck.engine.physics.avatar
{
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.PhysicsModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.colliders.ColliderCircle;
	import com.tinyspeck.engine.physics.colliders.ColliderLine;
	import com.tinyspeck.engine.physics.data.PhysicsQuery;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.renderer.debug.PhysicsLoopRenderer;
	import com.tinyspeck.engine.view.renderer.debug.PhysicsMovementRenderer;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	CONFIG const notgod:Boolean = !(CONFIG::god);
	CONFIG const BOUNCE = 1.0;
	
	final public class AvatarPhysicsHandler
	{
		public var lastQuery:PhysicsQuery;
		
		private var hitFlags:AvatarPhysicsHitFlags;
		private var keyMan:KeyBeacon;
		private var triple_jump_tim:uint;
		
		private var location:Location;
		
		private var fvm:FlashVarModel;
		private var pm:PhysicsModel;
		private var model:TSModelLocator;
		private var loopsSinceJumped:int; // tracks how many loops have run since a jump was started, used to keep from canceling a jump when it still looks like we're on the floor
		
		public function AvatarPhysicsHandler() {
			model = TSModelLocator.instance;
			pm = model.physicsModel;
			fvm = model.flashVarModel;
			keyMan = KeyBeacon.instance;
			hitFlags = new AvatarPhysicsHitFlags();
			
			lastQuery = new PhysicsQuery();
		}
		
		private function shouldIgnoreKeyPress():Boolean {
			const tf:TextField = (StageBeacon.stage.focus as TextField);
			return (tf && (tf.type == TextFieldType.INPUT));
		}
		
		public function applyPhysicsToOther(dynamicPhysicsObject:AvatarPhysicsObject, time:Number, location:Location):void {
			this.location = location;
			const apo:AvatarPhysicsObject = (dynamicPhysicsObject as AvatarPhysicsObject);
			const secs_passed:Number = time/1000;
			
			
			//Apply velocities, old style.
			//updateAvatarVelocities(apo, secs_passed);
			applyAvatarPhysicsToOther(apo, secs_passed);
			
			CONFIG::debugging {
				Console.trackPhysicsValue('APH other '+apo.pc.tsid, 'x:'+apo.pc.x+' y:'+apo.pc.y+' '+'vx:'+int(apo.vx)+' vy:'+int(apo.vy));
			}
		}
		
		private var applyPhysicsToSelf_time:int = getTimer();
		public function applyPhysicsToSelf(dynamicPhysicsObject:AvatarPhysicsObject, elapsed_ms:Number, location:Location):void {
			this.location = location;
			
			var this_time:int = getTimer();
			if (PhysicsLoopRenderer.instance.visible) model.physicsModel.logLoop(model.physicsModel.physics_time_log, this_time);
			
			// This was an experiment in letting this class keep its own time elapsed values:
			//elapsed_ms = Math.min(StageBeacon.max_ms_per_loop, this_time-applyPhysicsToSelf_time);
			
			// This was an experiment in adding in any time that has elapsed in the game loop since it was started
			//elapsed_ms+= this_time-model.physicsModel.physics_start_time;
			
			// this should be uncommented if wither of the above experiments are uncommented
			//applyPhysicsToSelf_time = this_time;
			
			const apo:AvatarPhysicsObject = (dynamicPhysicsObject as AvatarPhysicsObject);
			const secs_passed:Number = elapsed_ms/1000;
			CONFIG::debugging {
				Console.trackPhysicsValue('APH secs_passed', secs_passed.toFixed(3));
			}
			
			handleVelocityTriggers(apo);
			
			// Apply implicit triggers from the controls.
			// WE MUST DO THIS IF apo.triggerGetOffLadder==true because that can happen from an
			// in location teleport when the user is focused in a text area. Ideally, we would
			// have a separate routine for getting off a ladder that did not require handleAvatarControls
			// to be run, but I am not tearing it all apart right now.
			// same for triggerGetOnLadder which can happen if you click a ladder whiel standing on top of it
			if (!shouldIgnoreKeyPress() || apo.triggerGetOffLadder || apo.triggerGetOnLadder) {
				handleAvatarControls(apo);
			}
			
			//Apply velocities, old style.
			updateAvatarVelocities(apo, secs_passed);
			
			//Apply boundings on velocities.
			boundAvatarVelocities(apo);
			
			CONFIG::debugging {
				Console.trackPhysicsValue('APH apo.vx', apo.vx.toFixed(3));
				Console.trackPhysicsValue('APH apo.vy', apo.vy.toFixed(3));
				Console.trackPhysicsValue('APH apo.vx_accel_perc', apo.vx_accel_perc.toFixed(3));
				Console.trackPhysicsValue('APH apo.distFromFloor', apo.distFromFloor.toFixed(3));
				Console.trackPhysicsValue('APH apo.fallDuration', apo.fallDuration.toFixed(3));
			}
			
			//Solve the new settings.
			applyAvatarPhysicsToSelf(apo, secs_passed);
		}
		
		private function handleVelocityTriggers(apo:AvatarPhysicsObject):void {
			if(apo.triggerReduceVelocity){
				apo.vy = apo.vy*.5;
				apo.vx = apo.vx*.5;
				apo.triggerReduceVelocity = false;
			}
			if(apo.triggerResetVelocityX){
				apo.vx_accel_perc = 0;
				apo.vx = 0;
				apo.triggerResetVelocityX = false;
			}
			if(apo.triggerResetVelocity){
				apo.vx = apo.vy = 0;
				apo.triggerResetVelocity = false;
			}
			if (apo.triggerResetVelocityXPerc) {
				apo.vx_accel_perc = 0;
				apo.triggerResetVelocityXPerc = false;
			}
		}
		
		private function handleAvatarControls(apo:AvatarPhysicsObject):void {
			if(apo.triggerGetOnLadder){
				if(!apo.onLadder){
					//Ok, we're going to try and get on this thing.
					if(apo.targetLadder){
						apo.ladderXDist = (apo.targetLadder.x - apo.pc.x)/2;
						apo.onLadder = true;
						apo.onFloor = false;
						apo.onWall = false;
						// reset vy so when you got off your are not still moving horizontally
						apo.triggerResetVelocityX = true;
						resetTripleJumpCount(apo);
					}					
				}				
				apo.triggerGetOnLadder = false;
			}
			
			if(apo.triggerGetOffLadder){
				if(apo.onLadder){
					// when exiting a ladder: horizontal movement is prioritized
					// over vertical -- you shouldn't jump off a ladder if you
					// had the up arrow pressed though you also had right/left pressed
					// http://bugs.tinyspeck.com/4261
					if(keyMan.pressed(Keyboard.LEFT) || keyMan.pressed(Keyboard.RIGHT) || keyMan.pressed(Keyboard.A) || keyMan.pressed(Keyboard.D)) {
						apo.vy = apo.setting.vy_jump/10;
						apo.jumping = true;
						loopsSinceJumped = -1;
						apo.onFloor = false;
						if(keyMan.pressedBefore(Keyboard.LEFT, Keyboard.RIGHT) || keyMan.pressedBefore(Keyboard.A, Keyboard.D)) {
							apo.vx = -apo.setting.vx_off_ladder;
						} else {
							apo.vx = apo.setting.vx_off_ladder;
						}
					} else if(keyMan.pressedBefore(Keyboard.UP, Keyboard.DOWN) || keyMan.pressedBefore(Keyboard.W, Keyboard.S)){
						apo.vy = apo.setting.vy_jump;
						apo.jumping = true;
						loopsSinceJumped = -1;
						apo.onFloor = false;
					}
					
					if(apo.triggerJump){
						apo.vy = apo.setting.vy_jump;
						apo.jumping = true;
						loopsSinceJumped = -1;
						apo.onFloor = false;
						apo.hasJumpedSinceFloor = true; // prevents a jump after jumping off a ladder
					}
					apo.onLadder = false;
					apo.targetLadder = null;
				}
				apo.triggerGetOffLadder = false;
			}
			
			if(apo.triggerJump){
				// this might get changed if jetpacking or triple jumping
				var vy_jump:int = apo.setting.vy_jump;
				var doJump:Boolean = false;
				if(apo.jumping == false){
					if(apo.onFloor || apo.onLadder){
						doJump = true;
					}
					if(!apo.hasJumpedSinceFloor){
						doJump = true;
						apo.vy = 0;
					}
				}
				
				if (!doJump && apo.onWall && apo.setting.can_wall_jump) {
					// apply force of the vertical jump to move the player off the wall
					var wall_jump_vx:Number = apo.setting.vy_jump*pm.wall_jump_multiplier_x;
					apo.vx = (apo.onWall_side<0) ? -wall_jump_vx : wall_jump_vx;
					
					// cancel accel, so holding the key down moving you towards the wall does not keep you from jumping off the wall
					apo.vx_accel_perc = 0;
					
					vy_jump*= pm.wall_jump_multiplier_y;
					
					doJump = true;
				}
				
				// check this before we do jetpack "jumps" so that jetpack jumps are not counted as a true jump
				if (doJump) {
					model.stateModel.report_a_jump = true;
				}
				
				if (apo.setting.jetpack && !doJump){
					doJump = true;
					// if moving up, only apply half the force (the 2 should be moved into the physics defs)
					if (apo.vy < 0) vy_jump = apo.setting.vy_jump/2;
				}
				
				if (doJump) {
					if (apo.setting.can_3_jump && apo.setting.multiplier_3_jump > 0) {
						if (apo.onFloor) {
							StageBeacon.clearTimeout(triple_jump_tim);
							apo.triple_jump_cnt++;
							CONFIG::debugging {
								Console.warn('jump #'+apo.triple_jump_cnt);
							}
							
							if (apo.triple_jump_cnt == 1) {
								// no special checks, any jump from the floor can count as the first jump in a triple
							} else if (apo.triple_jump_cnt == 2) {
								// no special checks, any jump from the floor can count as the second jump in a triple
							}

							if (apo.triple_jump_cnt == 3 || pm.triple_jump_multiplier_overide) {
								// we're good, do the big jump now!
								
								// let's measure how long it took to press jump key after hitting the floor and calc a multiplier
								var ms_since_landing:uint = apo.triggerJump_time-apo.landing_time;
								
								// let's measure how fast we are moving
								var vx_perc:Number = Math.abs(apo.vx) / apo.setting.vx_max;
								
								var multiplier:Number = calcTripleJumpMultiplier(apo, ms_since_landing, vx_perc);
								vy_jump*= multiplier;
								apo.triple_jumping = true;
								resetTripleJumpCount(apo);
								SoundMaster.instance.playSound('TRIPLE_JUMP');
								
								CONFIG::debugging {
									Console.warn('jump #3 GO! '+ms_since_landing+'ms vx_perc:'+vx_perc+'% multiplier:'+multiplier+' multiplier_3_jump:'+apo.setting.multiplier_3_jump+' vy_jump:'+vy_jump);
								}
							}
						} else {
							resetTripleJumpCount(apo);
						}
					}
					
					apo.vy = vy_jump;
					apo.jumping = true;
					loopsSinceJumped = -1;
					
					apo.onFloor = false;
					apo.onWall = false;
					apo.hasJumpedSinceFloor = true;
				}
				apo.triggerJump = false;
			}
			
			if (apo.jumping) loopsSinceJumped++;
		}
		
		private function calcTripleJumpMultiplier(apo:AvatarPhysicsObject, ms_since_landing:uint, vx_perc:Number):Number {
			var multiplier:Number;
			if (pm.triple_jump_multiplier_overide) {
				multiplier = pm.triple_jump_multiplier_overide;
			} else if (ms_since_landing < 30) {
				multiplier = 1.5 + (.3*vx_perc);
			} else if (ms_since_landing < 100) {
				multiplier = 1.4 + (.2*vx_perc);
			} else if (ms_since_landing < 200) {
				multiplier = 1.3 + (.1*vx_perc);
			} else {
				multiplier = 1.2;
			}
			
			return 1+((multiplier-1)*apo.setting.multiplier_3_jump);
		}
		
		private function increaseVXAccel(apo:AvatarPhysicsObject, secondsPassed:Number):void {
			if (apo.vx_accel_perc < 1){
				var vx_accel_add_in:Number = (apo.onFloor && apo.setting.gravity > 0) ? apo.setting.vx_accel_add_in_floor : apo.setting.vx_accel_add_in_air;
				apo.vx_accel_perc = Math.min(1, apo.vx_accel_perc+(vx_accel_add_in*secondsPassed));
			}
		}
		
		private function updateAvatarVelocities(apo:AvatarPhysicsObject, secondsPassed:Number):void {
			const setting:PhysicsSetting = apo.setting;
			
			//Apply the physics, old style.
			var moving_by_kb_x:Boolean = false;
			var go_left_on_path:Boolean = false;
			var go_right_on_path:Boolean = false;
			
			const allowance:int = (model.stateModel.avatar_gs_path_pt) ? pm.gs_path_end_allowance : pm.path_end_allowance;
			
			//For the path.
			if (apo.path_destination_pt && apo.path_destination) {
				if (apo.path_destination_pt.x <= apo.pc.x-allowance) {
					go_left_on_path = true;
				} else if (apo.path_destination_pt.x >= apo.pc.x+allowance) {
					go_right_on_path = true;
				}
			}
			
			if (apo.onLadder) {//Ladder state
				if (keyMan.pressedBefore(Keyboard.UP, Keyboard.DOWN) || keyMan.pressedBefore(Keyboard.W, Keyboard.S)) {
					if (!apo.ignore_keys) apo.vy = -setting.vx_max;
				} else if (keyMan.pressedBefore(Keyboard.DOWN, Keyboard.UP) || keyMan.pressedBefore(Keyboard.S, Keyboard.W)) {
					if (!apo.ignore_keys) apo.vy = setting.vx_max;
				} else {
					apo.vy = 0;
				}
			} else {
				
				//Do left right movement.
				const shouldNotIgnoreKeyPress:Boolean = !shouldIgnoreKeyPress();
				if((shouldNotIgnoreKeyPress && ((keyMan.pressedBefore(Keyboard.LEFT, Keyboard.RIGHT) || keyMan.pressedBefore(Keyboard.A, Keyboard.D))) || go_left_on_path) && !go_right_on_path) {
					// after bumping your head on the ceiling, you can't move left or right until 500ms has elapsed
					// (so that you can't headslide along an angled ceiling, arrows add vx that bumping eliminates)
					if (!apo.fallingAfterCeilingHit || (apo.fallDuration > 0.5)) {
						if (!apo.ignore_keys || go_left_on_path) { // go ahead and do it if we're on a path
							increaseVXAccel(apo, secondsPassed);
							apo.vx -= (setting.vx_max-apo.extra_vx)*apo.vx_accel_perc;
							moving_by_kb_x = true;
						}
					}
				} else if ((shouldNotIgnoreKeyPress && ((keyMan.pressedBefore(Keyboard.RIGHT, Keyboard.LEFT) || keyMan.pressedBefore(Keyboard.D, Keyboard.A))) || go_right_on_path) && !go_left_on_path) {
					// after bumping your head on the ceiling, you can't move left or right until 500ms has elapsed
					// (so that you can't headslide along an angled ceiling, arrows add vx that bumping eliminates)
					if (!apo.fallingAfterCeilingHit || (apo.fallDuration > 0.5)) {
						if (!apo.ignore_keys || go_right_on_path) { // go ahead and do it if we're on a path
							increaseVXAccel(apo, secondsPassed);
							apo.vx+= (setting.vx_max+apo.extra_vx)*apo.vx_accel_perc;
							moving_by_kb_x = true;
						}
					}
				}
				
				CONFIG::debugging {
					Console.trackPhysicsValue('APH extra_x_force applied', '0');
				}
				// it we're not using the kb to move, and not already moving faster than apo.extra_vx, apply the extra_vx force
				var apply_extra_vx:Boolean = apo.extra_vx && !moving_by_kb_x && Math.abs(apo.extra_vx) >= Math.abs(apo.vx);
				if (apply_extra_vx) {
					apo.vx = apo.extra_vx;
					CONFIG::debugging {
						Console.trackPhysicsValue('APH extra_x_force applied', apo.extra_vx);
					}
				}
				
				// reset to zero because keys have been released (and not on a path)
				if (!moving_by_kb_x) apo.vx_accel_perc = 0;
				
				// this keeps the inertial slowdown from going on too long; brings a "sudden" halt to movement when it gets slow enough 
				if (!moving_by_kb_x && (!apply_extra_vx || ((apo.extra_vx<0 && apo.vx>0) || (apo.extra_vx>0 && apo.vx<0)))) {
					if (apo.vx < setting.friction_thresh && apo.vx > -setting.friction_thresh){
						apo.vx = 0;
					}
				}
				
				CONFIG::debugging {
					Console.trackPhysicsValue('APH floor friction applied', 0);
				}
				//Apply friction for X
				if (apo.onFloor && apo.setting.gravity > 0) {
					if (!moving_by_kb_x && !apply_extra_vx) {
						const friction_floor_impulse_x:Number = (-apo.vx*setting.friction_floor);
						apo.vx+= (friction_floor_impulse_x*secondsPassed);
						CONFIG::debugging {
							Console.trackPhysicsValue('APH floor friction applied', friction_floor_impulse_x*secondsPassed);
						}
					}
				} else {
					const friction_air_impulse_x:Number = (-apo.vx*setting.friction_air);
					apo.vx+= (friction_air_impulse_x*secondsPassed);
				}
				
				//Apply friction and gravity for Y
				if (!apo.onFloor || apo.setting.gravity <= 0) {
					const friction_air_impulse_y:Number = (-apo.vy*setting.friction_air);
					apo.vy += (friction_air_impulse_y*secondsPassed);
					apo.vy += setting.gravity*secondsPassed;
				} else if (!apo.jumping){
					// this keeps you from sliding down slopes
					apo.vy = -0.01;
				}
			}
		}
		
		private function boundAvatarVelocities(apo:AvatarPhysicsObject):void {
			const signX:int = (apo.vx>=0) ? 1 :-1;
			const signY:int = (apo.vy>=0) ? 1 :-1;
			if (apo.vx) { 
				if (apo.vx > 0) {
					apo.vx = Math.min(apo.vx, (apo.setting.vx_max+apo.extra_vx)*signX);
				} else {
					apo.vx = Math.max(apo.vx, (apo.setting.vx_max-apo.extra_vx)*signX);
				}
			}
			if (apo.vy) {
				if (apo.vy > 0) {
					apo.vy = Math.min(apo.vy, apo.setting.vy_max*signY);
				} else {
					if (apo.triple_jumping) {
						apo.vy = Math.max(apo.vy, apo.setting.vy_max*signY*2);
					} else {
						apo.vy = Math.max(apo.vy, apo.setting.vy_max*signY);
					}
				}
			}
		}
		
		private function setAndBoundPositionOnOther(apo:AvatarPhysicsObject, x:Number, y:Number):void {
			var min_x:Number;
			var max_x:Number;
			var min_y:Number;
			var max_y:Number;
			
			//Set to normal bounds
			min_x = location.l+Math.round(apo.avatarViewBounds.width/2);
			max_x = location.r-Math.round(apo.avatarViewBounds.width/2);
			min_y = location.t;
			max_y = location.b;
			
			apo.pc.x = Math.round(Math.min(Math.max(min_x,x),max_x));
			apo.pc.y = Math.round(Math.min(Math.max(min_y,y),max_y));
		}
		
		private function setAndBoundPositionOnSelf(apo:AvatarPhysicsObject, x:Number, y:Number):void {
			var min_x:Number;
			var max_x:Number;
			var min_y:Number;
			var max_y:Number;
			if(!apo.onLadder){
				//Set to normal bounds
				min_x = location.l+Math.round(apo.avatarViewBounds.width/2);
				max_x = location.r-Math.round(apo.avatarViewBounds.width/2);
				min_y = location.t;
				max_y = location.b;
				
				if (x >= max_x || x <= min_x) {
					TSFrontController.instance.cancelAllAvatarPaths('APH.setAndBoundPositionOnSelf');
				}
				
				// the rounds are necessary to keep you from going through walls
				apo.pc.x = Math.round(Math.min(Math.max(min_x,x),max_x));
				apo.pc.y = Math.round(Math.min(Math.max(min_y,y),max_y));
			}else if(apo.onLadder && apo.targetLadder){
				//Set to ladder bounds.
				min_y = (apo.targetLadder.y-apo.targetLadder.h);
				max_y = apo.targetLadder.y-2;
				apo.pc.y = Math.round(Math.min(Math.max(min_y,y),max_y));
			}
		}
		
		private function areaQuery(query:PhysicsQuery, apo:AvatarPhysicsObject, oldX:Number, oldY:Number, newX:Number, newY:Number):PhysicsQuery {
			const queryRect:Rectangle = query.geometryQuery;
			const viewWidth:Number = apo.avatarViewBounds.width;
			const viewWidthDiv2:Number = apo.avatarViewBounds.width*0.5;
			const viewHeight:Number = apo.avatarViewBounds.height;
			
			apo.collider.avatarCircle.x = newX;
			apo.collider.avatarCircle.y = newY-viewHeight*0.5;
			// pretty expensive, but the viewBounds can change
			apo.collider.avatarCircle.radius = 0.5*(Math.sqrt(viewWidth*viewWidth + viewHeight*viewHeight));
			
			//Construct query coordinates based upon speed.
			var boundLeft:Number;
			var boundRight:Number;
			var boundTop:Number;
			if (oldX == newX) {
				// standing still
				boundLeft = (oldX-viewWidthDiv2)-20;
				boundRight = (oldX+viewWidthDiv2)+20;
			} else if (newX < oldX) {
				// moving left
				boundLeft = (newX-viewWidthDiv2)-20;
				boundRight = (oldX+viewWidthDiv2)+40;
			} else {
				// moving right
				boundLeft = (oldX-viewWidthDiv2)-20;
				boundRight = (newX+viewWidthDiv2)+40;
			}
			
			if (oldY == newY) {
				boundTop = (oldY-viewHeight)-20;
			} else if (newY < oldY) {
				boundTop = (newY-viewHeight)-20;
			} else {
				boundTop = (oldY-viewHeight)-20;
			}
			
			//Do a query in the quadtree to find possible colliders.
			query.reset();
			queryRect.x = boundLeft;
			queryRect.y = boundTop;
			queryRect.width = boundRight-boundLeft;
			if(apo.falling){
				// predetect the ground so we can stop without falling through
				queryRect.height = viewHeight+460;
			}else{
				queryRect.height = viewHeight+60;
			}
			
			return pm.physicsQuadtree.queryRect(query);
		}
		
		private function applyAvatarPhysicsToOther(apo:AvatarPhysicsObject, secondsPassed:Number):void {
			CONFIG::debugging {
				Console.trackPhysicsValue(' APH applyAvatarPhysicsToOther secondsPassed', secondsPassed);
			}
			
			var oldX:Number = apo.pc.x;
			var oldY:Number = apo.pc.y;
			var newX:Number = oldX;
			var newY:Number = oldY;
			var nvx:Number = apo.vx*secondsPassed;
			var nvy:Number = apo.vy*secondsPassed;
			// apply new velocities to avatar coords
			newX = oldX + nvx;
			newY = oldY + nvy;
			setAndBoundPositionOnOther(apo, newX, newY);
		}
		
		private function resetTripleJumpCount(apo:AvatarPhysicsObject):void {
			apo.triple_jump_cnt = 0;
		}
		
		// we used to have 80 hardcorded where all calls to this func now are.
		private function calcCircleGap(apo:AvatarPhysicsObject):int {
			//apo.avatarViewBounds.height = 150 is the default, when at display_scale 1, and 80 is the ditance that works best at that scale
			if (model.worldModel.location) {
				// the 30 is because there are two circles, each with radius of 15
				return Math.max(0, apo.avatarViewBounds.height+(-40*apo.setting.pc_scale)+(-30));
			}
			return 80;
		}
		
		private function applyAvatarPhysicsToSelf(apo:AvatarPhysicsObject, secondsPassed:Number):void {
			CONFIG::debugging {
				Console.trackPhysicsValue(' APH applyAvatarPhysicsToSelf secondsPassed', secondsPassed);
			}
			
			var oldX:Number = apo.pc.x;
			var oldY:Number = apo.pc.y;
			var newX:Number = oldX;
			var newY:Number = oldY;
			var nvx:Number = apo.vx*secondsPassed;
			var nvy:Number = apo.vy*secondsPassed;
			
			/*if (apo.vx && Math.abs(apo.vx) != 355) {
				Console.info(apo.vx);
			}*/
			
			// at least abs(1)? maybe...
			if (false && nvx) {
				if (nvx > 0) {
					nvx = Math.max(1, nvx);
				} else {
					nvx = Math.min(-1, nvx);
				}
			}
			
			CONFIG::debugging var last:String = 'go ';
			
			//Only apply physics if the avatar is not on a ladder.
			if(apo.onLadder) {
				//We're on a ladder, so we have switched physics off completely.
				//Do initial tweening to ladder center.
				apo.falling = false;
				apo.jumping = false;
				apo.triple_jumping = false;
				apo.fallingAfterJump = false;
				apo.fallingAfterCeilingHit = false;
				if(apo.pc.x != apo.targetLadder.x){
					var dst:Number = (apo.targetLadder.x - apo.pc.x);
					if(dst > 1 || dst < -1){
						apo.pc.x += apo.ladderXDist/2;
					}else{
						apo.pc.x = apo.targetLadder.x;
					}
				}
				newY = oldY + nvy;
				CONFIG::debugging {
					last+=' 4:'+newY;
				}

				// Do the query for itemstacks on the current area of the avatar
				lastQuery.doColliderLines = false;
				lastQuery.doLadders = false;
				lastQuery.doSignPosts = false;
				lastQuery.doDoors = false;
				lastQuery = areaQuery(lastQuery, apo, oldX, oldY, newX, newY);
			} else {
				// not on a ladder
				// apply new velocities to avatar coords
				newX = oldX + nvx;
				newY = oldY + nvy;
				CONFIG::debugging {
					last+=' 1:'+newY;
				}
				
				//Do the query for the current and future local area of the avatar
				if(apo.vx != 0 || apo.vy != 0){
					const doGeo:Boolean = !fvm.no_geo_collision;
					lastQuery.doColliderLines = doGeo;
					lastQuery.doLadders = doGeo;
					lastQuery.doSignPosts = doGeo;
					lastQuery.doDoors = doGeo;
				} else {
					lastQuery.doColliderLines = false;
					lastQuery.doLadders = false;
					lastQuery.doSignPosts = false;
					lastQuery.doDoors = false;
				}
				lastQuery = areaQuery(lastQuery, apo, oldX, oldY, newX, newY);
				
				//Set the floor wall collider circle (at the base of the feet), to current position
				
				const footCircle:ColliderCircle = apo.collider.footCircle;
				footCircle.vx = nvx;
				footCircle.vy = nvy;
				footCircle.x = oldX;
				footCircle.y = oldY-footCircle.radius;
				
				apo.collider.headCircle.x = footCircle.x;
				apo.collider.headCircle.y = footCircle.y - calcCircleGap(apo);
				
				//Run the solver
				hitFlags.reset();
				solver(apo, lastQuery.resultColliderLines, Math.ceil(secondsPassed*1000));

				// I DO NOT UNDERSTAND WHY footCircle.x is always changed by running solver(), even if there is no collision
				// but keeps you from going through walls:
				newX = footCircle.x;
				
				newY = footCircle.y+footCircle.radius;
				CONFIG::debugging {
					last+=' 2:'+newY+' apo.footCircle.y:'+footCircle.y+' apo.footCircle.radius:'+footCircle.radius;
				}
				
				//Bounce off the ceiling.
				if(hitFlags.hasHitCeiling){
					// get from pool
					var reflectedVelocity:Point = EnginePools.PointPool.borrowObject();
					
					// reflect our current velocity against the surface
					MathUtil.reflectVector(apo.vx, apo.vy, hitFlags.ceilingVector.x, hitFlags.ceilingVector.y, reflectedVelocity);

					apo.vx = -reflectedVelocity.x;
					apo.vy = -reflectedVelocity.y;
					
					// absorb shock
					apo.vx *= 0.8;
					apo.vy *= 0.1;
					
					// return to pool
					EnginePools.PointPool.returnObject(reflectedVelocity);
					
					// prevent arrow keys from moving us until we hit the ground
					// (further prevents head-slides when arrow key is held
					//  resulting in renewed vx; also you hit your damn head!)
					// checking for if we're on the floor makes sure we don't
					// ignore key control if you are still on a floor
					 if (!apo.onFloor) apo.fallingAfterCeilingHit = true;
					 
					 // if we're on a floor and have hit a ceiling, we can go no further
					 if (apo.onFloor) TSFrontController.instance.cancelAllAvatarPaths('applyAvatarPhysicsToSelf hasHitCeiling');
					
					// don't let heads stick to ceilings
					// (happens when oldY and newY round to the same number while
					// falling -- a feedback loop -- this keeps them one integer
					// apart in the direction away from the ceiling)
					const yDelta:Number = Math.abs(newY - oldY);
					if ((yDelta > 0) && (yDelta < 1)) {
						if (newY < oldY) {
							newY = oldY - 1;
						} else {
							newY = oldY + 1;
						}
						CONFIG::debugging {
							last+=' 5:'+newY + ' oldY:' + oldY;
						}
					}
				}
				
				//We've hit a wall, bounce back.
				if(hitFlags.hasHitWall){
					TSFrontController.instance.cancelAllAvatarPaths('APH.applyAvatarPhysicsToSelf hasHitWall');
					if(!apo.onWall){
						apo.onWall = true;
					}
					apo.vx*= apo.setting.bounce;
				} else {
					apo.onWall = false;
				}
				
				//Check if we're on the floor.
				if(hitFlags.hasHitFloor){
					if(!apo.onFloor){
						apo.onFloor = true;
						apo.falling = false;
						apo.fallingAfterJump = false;
						apo.fallingAfterCeilingHit = false;
					} else if (apo.jumping && loopsSinceJumped > 5) {
						//Console.warn('loopsSinceJumped: '+loopsSinceJumped);
						apo.jumping = false; // without this, you can be jumping AND on the floor when you hit a sloped platform 
						                     // during the ascent of a jump (resulting in the springsteen knee slide)
						apo.triple_jumping = false;
					}
					if(!apo.jumping){
						apo.hasJumpedSinceFloor = false;
					}
				}else{
					apo.onFloor = false;
				}
				
				// we were doing this below, but that only updates it when we're falling, which means it can be wrong at the top of a jump
				//get the nearest floor.
				apo.distFromFloor = newY - getNearestFloorYAt(apo,lastQuery.resultColliderLines,location.b);
				
				//Set jumping / falling state
				if(apo.vy > 0){
					//If we were jumping, we are now falling 
					if(apo.jumping){
						apo.jumping = false;
						apo.triple_jumping = false;
						apo.fallingAfterJump = true;
					}
					//Falling
					if(!apo.onFloor || apo.setting.gravity <= 0){
						if(!apo.falling){
							apo.falling = true;
							apo.fallDuration = 0;
						}else{
							//Update the fall duration (to intercept "step" falls from sloped platforms).
							apo.fallDuration += secondsPassed;
							//get the nearest floor.
							//apo.distFromFloor = newY - getNearestFloorYAt(apo,avatarQuery.resultColliderLines,location.b);
							CONFIG::debugging {
								last+=' 3:'+newY;
							}
						}	
					}
				}
			}
			
			apo.movingLeft = false;
			apo.movingRight = false;
			apo.movingUp = false;
			apo.movingDown = false;
			//apo.walkSpeed = Math.abs(apo.vx/apo.setting.vx_max); // ignore apo.extra_vx here
			
			if(Math.round(oldX) > Math.round(newX)){
				apo.movingLeft = true;
			}else if(Math.round(oldX) < Math.round(newX)){
				apo.movingRight = true;
			}
			if(Math.round(oldY) > Math.round(newY)){
				apo.movingUp = true;
			}else if(Math.round(oldY) < Math.round(newY)){
				apo.movingDown = true;
			}
			
			//trace('------------');
			//trace('diff', Math.abs(newY-oldY), oldY, newY, apo.vx, apo.vy);
			//trace('last:'+last);
			//trace('secondsPassed:'+secondsPassed+' nvy:'+nvy+' nvx:'+nvx);
			//trace('newY:'+newY.toFixed(6)+' oldY:'+oldY.toFixed(6)+' vx:'+apo.vx.toFixed(2)+' vy:'+apo.vy.toFixed(2)+' vx_accel_perc:'+apo.vx_accel_perc.toFixed(2)+' onLadder:'+apo.onLadder+' onFloor:'+apo.onFloor+' jumping:'+apo.jumping+' falling:'+apo.falling+' fallingAfterJump:'+apo.fallingAfterJump+' fallDuration:'+apo.fallDuration.toFixed(2)+' movingLeft:'+apo.movingLeft+' movingRight:'+apo.movingRight+' movingUp:'+apo.movingUp+' movingDown:'+apo.movingDown+' hasJumpedSinceFloor:'+apo.hasJumpedSinceFloor+' walkSpeed:'+apo.walkSpeed.toFixed(2)+' distFromFloor:'+apo.distFromFloor.toFixed(2));
			//trace('hasHitCeiling:'+hitFlags.hasHitCeiling+' hasHitWall:'+hitFlags.hasHitWall+' hasHitFloor:'+hitFlags.hasHitFloor);
			
			//no_trace_available >>> NaN secondsPassed:0.059 oldY:-163 apo.vy:0 apo.vx:0 go
			if (isNaN(newY)) {
				CONFIG::debugging {
					Console.error(newY+' secondsPassed:'+secondsPassed+' oldY:'+oldY+' apo.vy:'+apo.vy+' apo.vx:'+apo.vx+' '+last+' FIN');
				}
				return;
			}
			
			setAndBoundPositionOnSelf(apo, newX, newY);
			
			if (model.flashVarModel.display_ava_path || PhysicsMovementRenderer.instance.visible) {
				if (!model.worldModel.pc.path) model.worldModel.pc.path = [];
				var A:Array = model.worldModel.pc.path;
				if (!A.length || (int(A[A.length-1][0]) != int(apo.pc.x)/* || int(A[A.length-1][1]) != int(apo.pc.y)*/)) {
					//if (A.length) Console.info(A[A.length-1][0] +' '+ apo.pc.x+' -- '+A[A.length-1][1] +' '+ apo.pc.y);
					
					var diff_x:Number = apo.pc.x-oldX;
					var co:Array = [
						apo.pc.x,
						apo.pc.y,
						model.physicsModel.physics_start_time,
						apo.vx,
						nvx/secondsPassed,
						diff_x/secondsPassed,
						nvx,
						diff_x,
						secondsPassed*1000
					];
					if (A.length > 100) A.shift();
					A.push(co);
					if (model.flashVarModel.display_ava_path) {
						model.activityModel.dots_to_draw = {
							coords: A,
							size: 4,
							color: 'ffffff',
							clear:true
						}
					}
				}
			}
			
			if (model.flashVarModel.run_av_from_aph) {
				var ava_view:AvatarView = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
				if (ava_view) {
					ava_view.updateModel();
				}
			}
			if (model.flashVarModel.run_mv_from_aph) {
				TSFrontController.instance.getMainView().gameRenderer.onEnterFrame(secondsPassed*1000);
			}
		}

		private function getNearestFloorYAt(apo:AvatarPhysicsObject, lines:Vector.<ColliderLine>, maxY:Number):Number {
			const x:Number = apo.collider.footCircle.x;
			const y:Number = apo.collider.footCircle.y;
			const ll:int = lines.length;
			
			var line:ColliderLine;
			var dx:Number;
			var dy:Number;
			var dxd:Number;
			var dyd:Number;
			var side:Number;
			var yAtX:Number = maxY;
			var curY:Number;
			for(var i:int=ll-1; i>=0; --i){
				line = lines[int(i)];
				if(line.isPlatform){
					if(x >= line.x1 && x <= line.x2){
						dx = line.dx;
						dy = line.dy;
						dxd = (x-line.x1);
						dyd = (y-line.y1);
						side = dx*dyd-dy*dxd;
						if(side < 0 && line.pc_solid_from_top)
						{
							curY = line.y1 + (dxd/dx)*dy;
							if(curY < yAtX){
								yAtX = curY;
							}	
						}
					}
				}
			}
			return yAtX;
		}
		
		/**
		 * This function solves the avatar circles against n number of colliderlines.
		 * It selects colliders, and then does a main loop at a "frequency". The frequency means that the movement will be 
		 * subdivided in N steps.
		 */
		private function solver(apo:AvatarPhysicsObject, lines:Vector.<ColliderLine>, frequency:int):void {
			CONFIG::debugging {
				Console.trackPhysicsValue(' APH frequency', frequency);
			}
			
			var side:Number;
			var dx:Number;
			var dy:Number;
			var dxd:Number;
			var dyd:Number;
			var position:Number;
			var px:Number;
			var py:Number;
			var compVel:Number;
			var dt:Number;
			var velA:Number;
			var velB:Number;
			var velAP:Number;
			var distance:Number;
			var distance_sq:Number;
			var line:ColliderLine;
			var rad:Number;
			var isFoot:Boolean;
			var testCircle:ColliderCircle;
			
			const footCircle:ColliderCircle = apo.collider.footCircle;
			const headCircle:ColliderCircle = apo.collider.headCircle;
			const circle_gap:int = calcCircleGap(apo);
			//TODO eliminate this crap:
			const circleA:Vector.<ColliderCircle> = new <ColliderCircle>[headCircle, footCircle];
			
			// Create a new list of lines to be checked, based upon permeability
			// This new list will be checked at high frequency.
			const checkLines:Vector.<ColliderLine> = new Vector.<ColliderLine>();
			for(var k:int=lines.length-1; k>=0; --k){
				line = lines[int(k)];
				//Check if this is a valid line at all.
				if(line.lengthSquared > 0) {
					//Check which side of the line we are on.
					dx = line.dx;
					dy = line.dy;
					dxd = (footCircle.x-line.x1);
					dyd = (footCircle.y-line.y1);
					side = dx*dyd-dy*dxd;
					line.client::side = side;
					if(line.isPlatform) {
						/*
						removed these because they caused herky jerky movement when walking up sloes.
						I only added them because I added similar to the isWall section to fix the problem with getting stuck in
						walls passable form one side when passing though, but plats don't seem to need that anyway
						if (!line.pc_solid_from_top && footCircle.vy>=0) {
							// line is not a collider for pcs in this direction, pass through
							continue;
						} else if (!line.pc_solid_from_bottom && footCircle.vy<=0) {
							// line is not a collider for pcs in this direction, pass through
							continue;
						} else */
						
						if (!(line.pc_solid_from_top || line.pc_solid_from_bottom)) {
							// line is not a collider for pcs at all, pass through
							continue;
						} else if(side < 0 && !line.pc_solid_from_top) {
							//We are above, but we can pass through, so stop testing.
							continue;
						}else if(side > 0 && !line.pc_solid_from_bottom) {
							//We are below but we can pass through
							continue;
						}
					}else if(line.isWall) {
						var notSolidFromLeft:Boolean  = !line.pc_solid_from_left;
						var notSolidFromRight:Boolean = !line.pc_solid_from_right;
						if (notSolidFromLeft && footCircle.vx>=0) {
							// line is not a collider for pcs in this direction, pass through
							continue;
						} else if (notSolidFromRight && footCircle.vx<=0) {
							// line is not a collider for pcs in this direction, pass through
							continue;
						} else if (notSolidFromRight && notSolidFromLeft) {
							// line is not a collider for pcs at all, pass through
							continue;
						}else if(side < 0 && notSolidFromRight) {
							//We are on the right???, but we can pass through
							continue;
						}else if (side > 0 && notSolidFromLeft) {
							//We are on the left???, but we can pass though
							continue;
						}
					}
					//Add to the checked lines
					checkLines.push(line);
				}
			}
			
			//To loop over the actually to be checked lines.
			const ll:int = checkLines.length;
			//Run through the solving algo, "frequency" times.
			for (var i:int=frequency; i>=0; --i) {
				//Update position.
				footCircle.x += footCircle.vx/frequency;
				footCircle.y += footCircle.vy/frequency;
				headCircle.x = footCircle.x;
				headCircle.y = footCircle.y - circle_gap;
				//Loop through the collider lines.
				for (var j:int=ll-1; j>=0; --j) {
					line = checkLines[int(j)];
					// let's do it twice, so we can check the top and bottom
					// circes against walls (what a hack)
					for (var t:int=0; t<2; t++) {
						//Select which circle collider to use (to differentiate between ceiling and floor hit).
						if(line.isPlatform && line.client::side > 0) {
							testCircle = headCircle;
							dx = line.dx;
							dy = line.dy;
							dxd = (testCircle.x-line.x1);
							dyd = (testCircle.y-line.y1);
							side = dx*dyd-dy*dxd;
							//Double check if we are on the right side right now.
							if(side <= 0){
								continue;
							}
							isFoot = false;
							t++; // double increment t, so we do not run twice in this case;
						} else {
							if (line.isWall) {
								// only in this case do we not want to double increment it, because only for walls do we want to run this twice
								testCircle = circleA[t];
							} else {
								t++; // double increment t, so we do not run twice in this case;
								testCircle = footCircle;
							}
							dx = line.dx;
							dy = line.dy;
							dxd = (testCircle.x-line.x1);
							dyd = (testCircle.y-line.y1);
							isFoot = true;
						}
						position = (dxd*dx+dyd*dy)/line.lengthSquared;
						if (position < 0) {
							position = 0;
						} else if(position > 1) {
							position = 1;
						}					
						//Find tangent.
						px = line.x1+position*dx;
						py = line.y1+position*dy;
						dx = px-testCircle.x;
						dy = py-testCircle.y;
						
						// don't get the sqrt until we actually need it
						distance_sq = dx*dx + dy*dy;
						
						//Total radius of line and circle.
						rad = testCircle.radius+line.radius;
						
						// LOGGING HERE BECAUSE IT LOOKS LIKE THIS IS THE KEY DIFFERENCE WHEN TRYING TO JUMP AND IT FAILS IN THE MIDDLE
						// OF A BARELY SLOPED LINE
						CONFIG::debugging {
							Console.trackPhysicsValue('APH distance_sq stuff', (distance_sq <= (rad*rad)));
							Console.trackPhysicsValue('APH distance_sq stuff2', distance_sq +' '+ (rad*rad));
						}

						//Check for collision.
						if (distance_sq <= (rad*rad)) {
							//The most expensive thing in here, the sqrt for distance (but still pretty fast in Flash 10+)
							distance = Math.sqrt(distance_sq);
							
							//We had a collision, mark the event, dance a happy dance.
							if(line.isWall){
								hitFlags.hasHitWall = true;
								apo.onWall_side = line.client::side;
							} else if(line.isPlatform && line.client::side > 0 && apo.vy <= 0){
								hitFlags.hasHitCeiling = true;
								hitFlags.ceilingVector.x = (line.x2 - line.x1);
								hitFlags.ceilingVector.y = (line.y2 - line.y1);
							}
							
							//normalize to a unit vector.
							dx/=distance;
							dy/=distance;
							
							//calculate the component of velocity in the direction
							compVel = footCircle.vx*dx+footCircle.vy*dy;
							
							//Adjust to move back before collision, update velocities.
							if (compVel!=0) {
								//Perc collision velocity.
								dt = (rad-distance)/compVel;
								//move the ball back to collision point.
								testCircle.x -= footCircle.vx*dt;
								testCircle.y -= footCircle.vy*dt;
								//velocities in this direction.
								velA = compVel; //(footCircle.vx*dx+footCircle.vy*dy);
								velB = (-footCircle.vx*dy+footCircle.vy*dx);
								//new velocities in this direction.
								velAP = velA+CONFIG::BOUNCE*(0-velA);
								footCircle.vx = velAP*dx-velB*dy;
								footCircle.vy = velAP*dy+velB*dx;
								
								//move the ball forward.
								testCircle.x+=footCircle.vx*dt;
								testCircle.y+=footCircle.vy*dt;
								if(isFoot) {
									headCircle.x = footCircle.x;
									headCircle.y = footCircle.y - circle_gap;
								} else {
									footCircle.x = headCircle.x;
									footCircle.y = headCircle.y + circle_gap;
								}
							}
						}
						
						// This tests a secondary circle to check if we are hitting a floor
						if (line.isPlatform && isFoot && apo.vy >= -1) { // this has to be apo.vy >= -1, not 0, else you slide down slopes
							if (!hitFlags.hasHitFloor) {
								// 0.5 adds some thickness to the line (mathemagically, a 1px thick rectangle with rounded ends)
								// so avatars don't vibrate up and down when standing still on a slope (http://bugs.tinyspeck.com/3661)
								// (to prevent sliding down slope, we apply -0.01 vy, which causes the
								//  y position to fluctuate even when not moving; you're on the floor,
								//  you move -0.01vy above it, then fall back down to it, and again)
								if ((line.client::side <= 0) && (distance_sq <= (rad + 0.5)*(rad + 0.5))) {
									if (!apo.onFloor && !hitFlags.hasHitFloor) {
										apo.landing_time = getTimer();
										triple_jump_tim = StageBeacon.setTimeout(resetTripleJumpCount, pm.triple_jump_allowance_ms, apo);
									}
									hitFlags.hasHitFloor = true;
								}
							}
						}
					}
				}
			
				// maybe we can early exit one day; maybe we sort the lines in a certain way?
				//if (hitFlags.hasHitCeiling || hitFlags.hasHitFloor || hitFlags.hasHitWall) return;
			}
		}
	}
}
