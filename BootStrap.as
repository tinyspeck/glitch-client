package {
	/**
	 * Bootstrap
	 * Set stage properties
	 * 
	 * Initializes BootController which : 
	 * Checks Connection
	 * Loads Engine
	 * Initializes Engine
	 */
	import com.tinyspeck.bootstrap.Version;
	import com.tinyspeck.bootstrap.control.BootStrapController;
	import com.tinyspeck.bootstrap.model.BootStrapModel;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.FlashVarData;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Security;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	[SWF(width="800", height="600", backgroundColor="#E8ECEE", frameRate='30')]
	public class BootStrap extends MovieClip {
		public static var instance:BootStrap;
		public static const menu:ContextMenu = new ContextMenu();
		{ // static init
			menu.hideBuiltInItems();
			menu.customItems.push(new ContextMenuItem('A game by Tiny Speck', true, true));
			menu.customItems[0].addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function():void{
				navigateToURL(new URLRequest('http://www.tinyspeck.com/'), '_blank');
			});
		}
		
		public static var version:Version;
		
		public function BootStrap() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			instance = this;

			contextMenu = menu;
			
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');
			
			// get these set up asap
			const fvm:FlashVarModel = new FlashVarModel(FlashVarData.createFlashVarData(this));
			StageBeacon.init(stage, fvm, BootStrapModel.instance.prefsModel);
			BootStrapController.instance.init(fvm);
			BootError.fvm = fvm;
			
			//make sure local storage knows this PC TSID
			if (CONFIG::perf) {
				LocalStorage.instance.boot_pc_tsid = 'PERFTEST';
				LocalStorage.instance.removeLocalStorage();
				LocalStorage.instance.boot_pc_tsid = 'PERFTEST';
			} else {
				LocalStorage.instance.boot_pc_tsid = fvm.pc_tsid;
			}
			
			this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, BootError.handleGlobalErrors);
			version = new Version();
			
			// set initial framerate
			stage.frameRate = fvm.fps;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			// disable yellow tabbing rectangle
			stage.stageFocusRect = false;
			
			// disable tabbing altogether
			stage.tabChildren = false;
			
			if (!fvm.no_bug) {
				if (!fvm.disable_bug_reporting) {
					//this will get removed from the stage once we load
					var bug:Sprite = new Sprite();
					bug.name = 'bug';
					bug.x = bug.y = 2;
					bug.useHandCursor = bug.buttonMode = true;
					stage.addChild(bug);
					bug.addEventListener(MouseEvent.CLICK, function():void {
						BootError.openBugReportUI();
					});
					
					var bug_str:String = 'iVBORw0KGgoAAAANSUhEUgAAABcAAAAUCAYAAABmvqYOAAABv0lEQVQ4y62VTUtCQRSGZ1OLIBKqvUQ/4P4Eg7aBP6DwVuQqUjAqMEIUod3dRNFKAgkhjBZFuDKoXVBtMoLw1qJF0IfRpwuZ5pVzQtT7kTfhZe7MvOeZ8cw9c4WUUtipazymKWWUXpQktehrTrFOYJ2AVtI7gqvAoAOYFfwTXAX4RlJrucHwsi0Y8/DB7xo+EI6v9k4ufkW2dr+tFsA45uGDvy1cGQ06pCh2ACGAIaGN7er0Zk7yImjRxzh7yO8jRYlniIPzUnYokqrB1D0xX+kJLRw377JvaqnKMLToN3sQh3g8gwcutq89vX3cJfMFyYtYaf/s0vYMEA8OeOByfnAgCSXTLng2k0/ZzSOeOL62B+oR3nKgKJQEyfACp3hm6cI/l7xyWSxu4L8CV5xcl0+PSjeS5QXeyAG3/rYoBVgecx5okNZynwxH0x3BKS7YUv50SZn/lHOTF+Hyl/0z8Vosu1fPl9V9YgWHH3GIB4ffHLGyc1hAVT2/f1bUagbyVX54fB1Nr7uCwwc/5dkABzxwkRa9sapIfqXixe19fTd8DgxHH+OYh4/8zdWuC4dPlUb/BmWN3xi1Jo3bfup+AMuvHRf6+A1OAAAAAElFTkSuQmCC';
					AssetManager.instance.loadBitmapFromBASE64('bug_icon', bug_str, function(key:String, bm:Bitmap):void {
						bug.addChild(bm);
					});
				}
			}
			
			// get this party started
			BootStrapController.instance.run();
		}
	}
}