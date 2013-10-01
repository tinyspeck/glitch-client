package com.tinyspeck.engine.physics.avatar
{
	final public class PhysicsSettables {
		public var parametersV:Vector.<PhysicsParameter>;
		private var settingsV:Vector.<PhysicsSetting>;
		
		public function PhysicsSettables() {
			parametersV = new Vector.<PhysicsParameter>();
			//                                    name                     label                      min      max     type
			parametersV.push(new PhysicsParameter("vx_max",                "vx_max",                  0,       1000,     PhysicsParameter.TYPE_INT ));
			parametersV.push(new PhysicsParameter("vy_max",                "vy_max",                  0,       2000,     PhysicsParameter.TYPE_INT ));
			parametersV.push(new PhysicsParameter("gravity",               "gravity",                 0,       2000,     PhysicsParameter.TYPE_INT ));
			parametersV.push(new PhysicsParameter("vy_jump",               "vy_jump",                -1000,    0,        PhysicsParameter.TYPE_INT ));
			parametersV.push(new PhysicsParameter("vx_accel_add_in_floor", "vx_accel_add_in_floor",   0,       1,        PhysicsParameter.TYPE_NUM ));
			parametersV.push(new PhysicsParameter("vx_accel_add_in_air",   "vx_accel_add_in_air",     0,       1,        PhysicsParameter.TYPE_NUM ));
			parametersV.push(new PhysicsParameter("friction_floor",        "friction_floor",         -2,       10,       PhysicsParameter.TYPE_NUM ));
			parametersV.push(new PhysicsParameter("friction_air",          "friction_air",           -2,       10,       PhysicsParameter.TYPE_NUM ));
			parametersV.push(new PhysicsParameter("friction_thresh",       "friction_thresh",         0,       200,      PhysicsParameter.TYPE_INT ));
			parametersV.push(new PhysicsParameter("vx_off_ladder",         "vx_off_ladder",           0,       1000,     PhysicsParameter.TYPE_INT ));
			parametersV.push(new PhysicsParameter("pc_scale",              "pc_scale",                0,       1,        PhysicsParameter.TYPE_NUM ));
			parametersV.push(new PhysicsParameter("item_scale",            "item_scale",              0,       1,        PhysicsParameter.TYPE_NUM ));
			parametersV.push(new PhysicsParameter("jetpack",               "jetpack",       		  0,       1,        PhysicsParameter.TYPE_BOOL));
			parametersV.push(new PhysicsParameter("y_cam_offset",          "y_cam_offset",           -300,     300,      PhysicsParameter.TYPE_INT ));
			parametersV.push(new PhysicsParameter("can_3_jump",            "can_3_jump",       		  0,       1,        PhysicsParameter.TYPE_BOOL));
			parametersV.push(new PhysicsParameter("multiplier_3_jump",     "multiplier_3_jump",       0,       2,        PhysicsParameter.TYPE_NUM ));
			parametersV.push(new PhysicsParameter("can_wall_jump",         "can_wall_jump",       	  0,       1,        PhysicsParameter.TYPE_BOOL));

			settingsV = new Vector.<PhysicsSetting>();
		}
		
		public function addSetting(setting:PhysicsSetting):void {
			settingsV.push(setting);
		}
		
		public function getSettingByName(name:String):PhysicsSetting {
			for(var i:int=settingsV.length-1; i>=0; --i){
				if(settingsV[int(i)].name == name){
					return settingsV[int(i)];
				}
			}
			//Console.warn(names+' does not contain '+name);
			return null;
		}
		
		private var namesA:Array = [];
		public function getSettingNames():Array {
			namesA.length = 0;
			for(var i:int=settingsV.length-1; i>=0; --i){
				namesA.push(settingsV[int(i)].name);
				
			}
			return namesA;
		}
		
		public function getParameterByName(name:String):PhysicsParameter {
			for(var i:int=parametersV.length-1; i>=0; --i){
				if(parametersV[int(i)].name == name){
					return parametersV[int(i)];
				}
			}
			return null;
		}
	}
}