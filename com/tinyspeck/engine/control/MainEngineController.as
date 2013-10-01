package com.tinyspeck.engine.control {
	import com.tinyspeck.bootstrap.model.BootStrapModel;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.bridge.IMainEngineController;
	import com.tinyspeck.bridge.MouseWheel;
	import com.tinyspeck.bridge.PrefsModel;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableEventDispatcher;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.LoginTool;
	import com.tinyspeck.debug.PerfLogger;
	import com.tinyspeck.engine.control.engine.AvatarController;
	import com.tinyspeck.engine.control.engine.DataLoaderController;
	import com.tinyspeck.engine.control.engine.NetController;
	import com.tinyspeck.engine.control.engine.PhysicsController;
	import com.tinyspeck.engine.control.engine.TimeController;
	import com.tinyspeck.engine.control.engine.ViewController;
	import com.tinyspeck.engine.control.mapping.ControllerMap;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.memory.ClientOnlyPools;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.physics.util.LocationPhysicsHealer;
	import com.tinyspeck.engine.port.InfoManager;
	import com.tinyspeck.engine.port.JS_interface;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.PNGUtil;
	import com.tinyspeck.engine.view.LoginProgressView;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	
	import flash.display.MovieClip;
	import flash.utils.getTimer;
	
	CONFIG::god { import com.tinyspeck.engine.view.renderer.debug.PhysicsRenderer; }
	CONFIG::god { import com.tinyspeck.engine.view.renderer.debug.PhysicsMovementRenderer; }
	CONFIG::god { import com.tinyspeck.engine.view.renderer.debug.PhysicsLoopRenderer; }
	
	public class MainEngineController extends DisposableEventDispatcher implements IMainEngineController {
		private var model:TSModelLocator;
			
		private var avatarController:AvatarController;
		private var netController:NetController;
		private var dataLoaderController:DataLoaderController;
		private var timeController:TimeController;
		private var viewController:ViewController;
		private var physicsController:PhysicsController;
		private var interactionMenuController:InteractionMenuController;

		private var controllerMap:ControllerMap;
		private var tsfc:TSFrontController;
		private var avatar_mc:MovieClip;
		
		public function MainEngineController() {
			Benchmark.addCheck('Engine.init');
			
			//Setup global pools.
			EnginePools.init();
			ClientOnlyPools.init();
			
			//Get reference to model locator.
			model = TSModelLocator.instance;
			
			// pass in some values
			model.moveModel.host = BootStrapModel.instance.host;
			model.moveModel.low_port = BootStrapModel.instance.low_port;
			model.moveModel.use_high_port = BootStrapModel.instance.use_high_port;
			model.moveModel.token = BootStrapModel.instance.token;
			
			Benchmark.addCheck('Engine.init end');
		}
		
		private var do_connect:Boolean;
		public function runAndConnect():void {
			do_connect = true;
			run();
		}
		
		public function connect():void {
			if (do_connect) {
				LoginProgressView.instance.start();
				netController.getTokenAndConnect();
			}
			do_connect = true;
		}
		
		public function run():void {
			JS_interface.instance.init();
			KeyBeacon.instance.setStage(StageBeacon.stage);
			PerfLogger.init(model.flashVarModel);
			
			LoginTool.start();
			if (!LoginTool.reportStep(1, 'mec_run')) return;
			Benchmark.startSection(Benchmark.SECTION_ENGINE_STARTING);
			Benchmark.addCheck('Engine.run');
			
			Benchmark.addSnippetCallback(function(snippet:String):void {
				//model.activityModel.growl_message = snippet;
				model.activityModel.activity_message = Activity.fromAnonymous({txt:snippet});
			});
			
			//This is the front for the view.
			tsfc = TSFrontController.instance;
			
			//Net Controller
			netController = new NetController();
			
			//Data Loader Controller
			dataLoaderController = new DataLoaderController();
			
			//Time Controller
			timeController = new TimeController();
			
			//View Controller
			viewController = new ViewController();
			
			//Physics Controller
			LocationPhysicsHealer.init();
			physicsController = new PhysicsController();
			
			//Avatar motion controller
			avatarController = new AvatarController();
			
			//for menus
			interactionMenuController = new InteractionMenuController();
			
			//Setup the controllermap for the frontcontroller.
			controllerMap = new ControllerMap();
			controllerMap.mainEngineController = this;
			controllerMap.viewController = viewController;
			controllerMap.dataLoaderController = dataLoaderController;
			controllerMap.netController = netController;
			controllerMap.timeController = timeController;
			controllerMap.physicsController = physicsController;
			controllerMap.avatarController = avatarController;
			controllerMap.interactionMenuController = interactionMenuController;
			
			tsfc.setControllerMap(controllerMap);
			
			AvatarResourceManager.avatar_url = model.flashVarModel.avatar_url;
			var load_ava_sheets_pngs:Boolean = (EnvironmentUtil.getUrlArgValue('SWF_load_ava_sheets_pngs') != '0');
			AvatarSSManager.init(model.flashVarModel.placeholder_sheet_url, load_ava_sheets_pngs);
			AvatarSSManager.run(avatar_mc, onAvatarReady);
		}
		
		private function onAvatarReady():void {
			if (!LoginTool.reportStep(3, 'mec_ava_rdy')) return;

			// set up gameloop
			setupGameLoop();
			
			// this is what starts views
			viewController.init();
			MouseWheel.instance.init();
			
			if (do_connect) {
				LoginProgressView.instance.start();
				netController.getTokenAndConnect();
			} else {
				do_connect = true;
			}
		}
		
		private function setupGameLoop():void {
			if (model.flashVarModel.new_physics) {
				CONFIG::god {
					if (model.flashVarModel.report_rendering) {
						StageBeacon.game_loop_sig.add(onGameLoop);
						StageBeacon.game_loop_end_sig.add(onGameLoopEnd);
					}
				}
				StageBeacon.game_loop_sig.add(InfoManager.instance.onGameLoop);
				StageBeacon.game_loop_sig.add(avatarController.onGameLoop);
				
				// the problem with running this on a separate loop from the render loop is 
				// that the render loop can fall between game loops, and thus be out of sync
				//StageBeacon.game_loop_sig.add(physicsController.onGameLoop);
				// so instead:
				StageBeacon.enter_frame_sig.addWithPriority(physicsController.onGameLoop);
				
			} else {
				CONFIG::god {
					if (model.flashVarModel.report_rendering) {
						StageBeacon.enter_frame_sig.add(onGameLoop);
						StageBeacon.game_loop_end_sig.add(onGameLoopEnd);
					}
				}
				StageBeacon.enter_frame_sig.add(InfoManager.instance.onGameLoop);
				StageBeacon.enter_frame_sig.add(avatarController.onGameLoop);
				StageBeacon.enter_frame_sig.add(physicsController.onGameLoop);
				
			}
			
			StageBeacon.enter_frame_sig.add(CameraMan.instance.onGameLoop);
			StageBeacon.enter_frame_sig.add(MiniMapView.instance.onEnterFrame);
			StageBeacon.enter_frame_sig.add(HubMapDialog.instance.onEnterFrame);
			StageBeacon.enter_frame_sig.add(RightSideManager.instance.onEnterFrame);
			StageBeacon.enter_frame_sig.add(viewController.onEnterFrame);
			StageBeacon.enter_frame_sig.add(TipDisplayManager.instance.onEnterFrame);
			StageBeacon.enter_frame_sig.add(AvatarSSManager.onEnterFrame);
			StageBeacon.enter_frame_sig.add(ItemSSManager.onEnterFrame);
			
			CONFIG::god {
				StageBeacon.enter_frame_sig.add(PhysicsRenderer.instance.onEnterFrame);
				StageBeacon.enter_frame_sig.add(PhysicsMovementRenderer.instance.onEnterFrame);
				StageBeacon.enter_frame_sig.add(PhysicsLoopRenderer.instance.onEnterFrame);
			}
		}
		
		public function setAvatar(avatar:MovieClip):void {
			if (!avatar) return;
			avatar_mc = avatar;
		}
		
		public function setPrefsModel(pm:PrefsModel):void {			
			model.prefsModel = pm;
		}
		
		public function setFlashVarModel(fvm:FlashVarModel):void {			
			model.flashVarModel = fvm;
			
			CONFIG::god {
				// hacky but I need a place to set this initial state so we can stop
				// using the FlashVarModel to track it's value
				model.stateModel.hide_platforms = !fvm.draw_plats;
			}
			
			PNGUtil.setAPIUrl(fvm.api_url, fvm.api_token);
		}
		
		CONFIG::god private var timer:uint;
		CONFIG::god private var fps:uint;
		CONFIG::god private var ms_prev:uint;
		CONFIG::god private var script_timer:int;
		CONFIG::god private var render_timer:int;
		
		/** only run when (model.flashVarModel.report_rendering) */
		CONFIG::god private function onGameLoop(ms_elapsed:int):void {
			timer = getTimer();
			
			model.stateModel.renderA.unshift(getTimer()-render_timer);
			CONFIG::debugging {
				Console.trackValue(' render_time', model.stateModel.renderA[0]);
				Console.trackValue(' renderA', model.stateModel.renderA);
			}
			if (model.stateModel.renderA.length > 10) model.stateModel.renderA.pop(); // we only keep 10, but it gets cleared out if report_rendering=true when the move_xy msg is sent
			
			script_timer = timer;
			
			// once per second
			if (timer - 1000 > ms_prev) {
				ms_prev = timer;
				if (model.flashVarModel.report_rendering) {
					model.stateModel.fps.push(fps);
				}
				CONFIG::debugging {
					Console.trackValue(' FPS', fps);
					Console.trackValue(' FPS avg', model.stateModel.fps.averageValue);
				}
				fps = 0;
			}
			fps++;
		}
		
		/** only run when (model.flashVarModel.report_rendering) */
		CONFIG::god private function onGameLoopEnd():void {
			if (model.flashVarModel.report_rendering) {
				render_timer = getTimer();
			}
			
			model.stateModel.scriptA.unshift(getTimer()-script_timer);
			CONFIG::debugging {
				Console.trackValue(' script_time', model.stateModel.scriptA[0]);
				Console.trackValue(' scriptA', model.stateModel.scriptA);
			}
			if (model.stateModel.scriptA.length > 10) model.stateModel.scriptA.pop(); // we only keep 10, but it gets cleared out if report_rendering=true when the move_xy msg is sent
		}
	}
}