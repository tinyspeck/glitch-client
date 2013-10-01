package com.tinyspeck.bootstrap {
	
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.Console;
	
	import flash.system.ApplicationDomain;
	
	public class BootUtil {
		public static var ava_app_domain:ApplicationDomain;
		public static var root_url:String;
		
		public function BootUtil() {
			//
		}
		
		public static function setUpAPIAndConsole(fvm:FlashVarModel):void {
			BootUtil.root_url = fvm.root_url;
			
			API.setFVM(fvm);
			API.setSessionId(fvm.session_id);
			API.setPcTsid(fvm.pc_tsid);
			API.setAPIUrl(fvm.api_url, fvm.api_token);
			
			CONFIG::debugging {
				Console.setSessionId(String(new Date().getTime()));
				Console.setPcTsid(fvm.pc_tsid);
				Console.setAppVersion(fvm.engineUrl);
				Console.setOutput(Console.FIREBUG, fvm.log_to_firebug);
				Console.setOutput(Console.TRACE, fvm.log_to_trace);
				Console.setOutput(Console.SCRIBE, fvm.log_to_scribe);// && (CONFIG::debugging || fvm.pc_tsid == 'PIF101S2TIPFC'));
				Console.setPri(fvm.priority);
			}
		}
	}
}