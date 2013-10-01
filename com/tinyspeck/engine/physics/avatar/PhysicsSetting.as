package com.tinyspeck.engine.physics.avatar
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSModelLocator;

	final public class PhysicsSetting
	{
		public var name:String;
		
		public var vx_max:Number;
		public var vy_max:Number;
		public var gravity:Number;
		public var vy_jump:Number;
		public var vx_accel_add_in_floor:Number;
		public var vx_accel_add_in_air:Number;
		public var friction_floor:Number;
		public var friction_air:Number;
		public var friction_thresh:Number;
		public var bounce:Number = -.1;
		public var vx_off_ladder:Number;
		public var pc_scale:Number = 1;
		public var item_scale:Number = 1;
		public var y_cam_offset:Number = 150;
		public var jetpack:Boolean;
		private var _can_3_jump:Boolean;
		public var multiplier_3_jump:Number = 1;
		public var can_wall_jump:Boolean;

		public function get can_3_jump():Boolean {
			// a quick hack for rayn's level quest, until we have a real way to turn off triple jump, even for peeps that have the img upgrade
			if (TSModelLocator.instance.worldModel.location && TSModelLocator.instance.worldModel.location.tsid == 'LDOC5JL49ST21SG') {
				return false;
			}
			return _can_3_jump;
		}

		public function set can_3_jump(value:Boolean):void {
			_can_3_jump = value;
		}

		public function clone():PhysicsSetting {
			var clone:PhysicsSetting = new PhysicsSetting();
			clone.name = name;
			clone.vx_max = vx_max;
			clone.vy_max = vy_max;
			clone.gravity = gravity;
			clone.vy_jump = vy_jump;
			clone.vx_accel_add_in_floor = vx_accel_add_in_floor;
			clone.vx_accel_add_in_air = vx_accel_add_in_air;
			clone.friction_floor = friction_floor;
			clone.friction_air = friction_air;
			clone.friction_thresh = friction_thresh;
			clone.bounce = bounce;
			clone.vx_off_ladder = vx_off_ladder;
			clone.pc_scale = pc_scale;
			clone.item_scale = item_scale;
			clone.y_cam_offset = y_cam_offset;
			clone.jetpack = jetpack;
			clone.can_3_jump = _can_3_jump;
			clone.multiplier_3_jump = multiplier_3_jump;
			clone.can_wall_jump = can_wall_jump;
			return clone;
		}
		
		public static function fromAnonymous(object:Object, name:String):PhysicsSetting {
			var aps:PhysicsSetting = new PhysicsSetting();
			aps.name = name; // this is location tsid when added from location geo data
			return PhysicsSetting.updateFromAnonymous(object, aps);
		}
		
		public static function updateFromAnonymous(object:Object, aps:PhysicsSetting):PhysicsSetting {
			// account for the fact that we called this pc_and_item_scale at one time, though it never affected items (then we added item_scale)
			// but do this before the loop, so we make sure that a real pc_scale prop on the object takes precedence
			if ('pc_and_item_scale' in object) {
				aps.pc_scale = object.pc_and_item_scale;
			}
			
			for(var i:String in object){
				
				if(i in aps){
					aps[i] = object[i];
				}else{
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('AvatarPhysicsSettings does not recognize anon prop:'+i);
					}
				}
			}
			
			return aps;
		}
		
		public function toString():String {
			return ("PhysicsSetting\n" +
				'\tname: ' + name + '\n' +
				'\tvx_max: ' + vx_max + '\n' +
				'\tvy_max: ' + vy_max + '\n' +
				'\tgravity: ' + gravity + '\n' +
				'\tvy_jump: ' + vy_jump + '\n' +
				'\tvx_accel_add_in_floor: ' + vx_accel_add_in_floor + '\n' +
				'\tvx_accel_add_in_air: ' + vx_accel_add_in_air + '\n' +
				'\tfriction_floor: ' + friction_floor + '\n' +
				'\tfriction_air: ' + friction_air + '\n' +
				'\tfriction_thresh: ' + friction_thresh + '\n' +
				'\tbounce: ' + bounce + '\n' +
				'\tvx_off_ladder: ' + vx_off_ladder + '\n' +
				'\tpc_scale: ' + pc_scale + '\n' +
				'\titem_scale: ' + item_scale + '\n' +
				'\ty_cam_offset: ' + y_cam_offset + '\n' +
				'\tjetpack: ' + jetpack + '\n' +
				'\tcan_3_jump: ' + can_3_jump + '\n' +
				'\tmultiplier_3_jump: ' + multiplier_3_jump + '\n' +
				'\tcan_wall_jump: ' + can_wall_jump);
		}
	}
}