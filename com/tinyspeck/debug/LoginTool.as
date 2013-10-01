package com.tinyspeck.debug {
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.StringUtil;

	public class LoginTool {
		
		private static var login_active:Boolean = false;
		private static var step:int = 0;
		private static var total_steps:int = parseInt(EnvironmentUtil.getUrlArgValue('SWF_login_total_steps')) || 15;
		private static var halt_step:int = parseInt(EnvironmentUtil.getUrlArgValue('SWF_login_halt_step')); // set at higger than o to force a halt to the loading for debugging
		
		public function LoginTool() {
			//
		}
		
		public static function start():void {
			login_active = true;
		}
		
		public static function reportStep(s:int, desc:String):Boolean {
			if (!login_active) {
				CONFIG::debugging {
					Console.priinfo(841, 'IGNORING reported:'+s+' because login_active:'+login_active+' '+StringUtil.getCallerCodeLocation());
				}
				return true;
			}
			
			if (s != step+1) {
				CONFIG::debugging {
					var str:String = 'WRONG STEP reported:'+s+' expected step:'+(step+1)+' '+StringUtil.getCallerCodeLocation();
					Console.error(str);
					BootError.addErrorMsg(str, null, ['login']);
				}
				return false;
			}
			
			NewxpLogger.log(desc, 'login_step_'+s);
			step++;
			
			if (step == halt_step) {
				CONFIG::debugging {
					Console.error('HALTING halt_step:'+step+' '+StringUtil.getCallerCodeLocation());
				}
				return false;
			}
			
			if (step == total_steps) {
				login_active = false;
			}
			
			CONFIG::debugging {
				Console.priinfo(841, 'LoginTool step:'+step+' '+StringUtil.getCallerCodeLocation());
			}
			
			return true;
		}
	}
}