package com.tinyspeck.debug {
	import com.tinyspeck.bridge.FlashVarModel;

	public class NewxpLogger {
		
		private static var fvm:FlashVarModel;
		private static var pc:Object; // an Object, not a PC, to avoid dependencies on the model!
		private static var log_step:int;
		private static var do_log_jumps:Boolean;
		
		public function NewxpLogger() {}
		
		public static function setFVM(fvm:FlashVarModel):void {
			NewxpLogger.fvm = fvm;
			if (fvm.newxp_log_step) {
				log_step = fvm.newxp_log_step;
				log_step++; // we up it by one, to keep them consistent with TS.source.js, which does one log after embedding this swf
			}
		}
		
		public static function setPC(pc:Object):void {
			NewxpLogger.pc = pc;
		}
		
		public static function log(marker:String, data:String=''):void {
			if (!fvm) return;
			if (!fvm.has_not_done_intro && !fvm.needs_todo_leave_gentle_island) {
				return;
			}
			
			// only log jumps if we have turned on jump logging!
			if (marker == 'jump' && !do_log_jumps) return;
			
			log_step++;
			
			const x:int = (pc) ? pc.x : 0;
			const y:int = (pc) ? pc.y : 0;
			
			API.logNewxp(marker, data, log_step, x, y);
			
			if (marker == 'bought_img_upg_jump_1') {
				// start logging jumps to track progress up the mushrooms/platforms in TR1
				do_log_jumps = true;
				log('start_logging_jumps');
			} else if (marker == 'input_request_player_name_picker' && do_log_jumps) {
				// stop logging jumps, they are being asked for their name
				do_log_jumps = false;
				log('stop_logging_jumps');
			}
		}
		
		
	}
}