package {
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.engine.Version;
	import com.tinyspeck.engine.control.MainEngineController;
	
	import flash.display.Sprite;
	import flash.events.UncaughtErrorEvent;
	import flash.system.Security;
	
	public class Engine extends Sprite {
		public var version:Version;
		public var mainEngineController:MainEngineController;
				
		public function Engine() {
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');
			this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, BootError.handleGlobalErrors);
			version = new Version();
			mainEngineController = new MainEngineController();
		}
		
		public function run():void {
			mainEngineController.run();
		}
	}
}