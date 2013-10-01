package com.tinyspeck.engine.perf {

import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.API;
import com.tinyspeck.debug.Benchmark;
import com.tinyspeck.debug.BootError;
import com.tinyspeck.engine.control.TSFrontController;
import com.tinyspeck.engine.control.engine.AnnouncementController;
import com.tinyspeck.engine.data.client.Announcement;
import com.tinyspeck.engine.model.TSModelLocator;
import com.tinyspeck.engine.net.NetOutgoingPerfTeleportVO;
import com.tinyspeck.engine.port.RightSideManager;
import com.tinyspeck.engine.sound.SoundMaster;
import com.tinyspeck.engine.util.EnvironmentUtil;
import com.tinyspeck.engine.util.VectorUtil;
import com.tinyspeck.engine.view.renderer.RenderMode;
import com.tinyspeck.engine.view.ui.chat.ChatArea;
import com.tinyspeck.engine.view.ui.map.MapChatArea;

import flash.display.Stage;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.Capabilities;

/**
 * Decides what tests need to be run and arranges for the PerfTestController
 * to do each test.
 */
final public class PerfTestManager {
	private static const testController:PerfTestController = new PerfTestController();
	private static const testsToRun:Vector.<PerfTestInfo> = new Vector.<PerfTestInfo>();
		
	private static var fpsTracker:FPSTracker;
	private static var sessionID:String;
	private static var gpuInfo:GPUInfo;
	
	private static var model:TSModelLocator;
	
	public static function init(stage:Stage):void {
		model = TSModelLocator.instance;
		
		fpsTracker = new FPSTracker(stage);
		BootError.handleErrorCallback = handleError;
		
		checkPreconditions();
		
		if (model.flashVarModel.test_chat_filler) {
			populateChat();
		}
		
		// we need this before we can begin
		gpuInfo = new GPUInfo(stage);
		StageBeacon.waitForNextFrame(function isGPUInfoReady():void {
			if (gpuInfo.ready) {
				// this kicks things off
				getSessionID();
			} else {
				// waiting on context 3D...
				StageBeacon.waitForNextFrame(isGPUInfoReady);
			}
		});
	}
	
	public static function fail(msg:String):void {
		if (!testController.running) return;
		
		Benchmark.addCheck('[PTM] fail: ' + msg);
		annc('Test failed: ' + msg);
		
		// stop whatever it may be doing
		testController.reset();
		
		// just try to run the next test
		StageBeacon.setTimeout(runNextTest, 2000);
	}
	
	public static function fatal(msg:String):void {
		model.netModel.disconnected_msg = 'Ack! Something went wrong...';
		navigateToURL(new URLRequest(model.flashVarModel.root_url + 'perf/done/?msg=' + escape(msg)), '_self');
	}
	
	public static function teleportTo(tsid:String):void {
		StageBeacon.setTimeout(TSFrontController.instance.genericSend, 3000, new NetOutgoingPerfTeleportVO(tsid));
	}
	
	public static function resetPerformanceMeasurements():void {
		//trace('reset!');
		RightSideManager.instance.setChatMapTab(MapChatArea.TAB_NOTHING);
		if (!model.flashVarModel.test_chat_filler) {
			RightSideManager.instance.chatClear(ChatArea.NAME_LOCAL);
		}
		fpsTracker.reset();
	}
	
	public static function reportTestSegmentsComplete():void {
		trace('tests_complete');
		runNextTest();
	}
	
	public static function report(segmentName:String, testInfo:PerfTestInfo):void {
		trace('report(' + segmentName + '):', fpsTracker.report());
		
		API.perfStore(
			sessionID,
			model.worldModel.pc.tsid,
			testInfo.testLocation,
			testInfo.renderMode.name,
			testInfo.fakeFriends,
			StageBeacon.stage.width,
			StageBeacon.stage.height,
			model.layoutModel.loc_vp_w,
			model.layoutModel.loc_vp_h,
			segmentName,
			fpsTracker.time,
			fpsTracker.frames,
			fpsTracker.avg_fps,
			fpsTracker.avg_mem,
			fpsTracker.mem_delta,
			function handleAPIResponse(ok:Boolean, rsp:Object):void {
				if (!ok) {
					fatal("API error storing performance results: " + rsp)
				}
			}
		);
	}
	
	private static function runNextTest():void {
		if (testsToRun.length) {
			Benchmark.addCheck('[PTM] starting test');
			annc('Starting test...');
			
			testController.reset();
			testController.run(testsToRun.pop());
			PerfTestToolbarUI.instance.update(testsToRun.length);
		} else {
			// all tests complete
			model.netModel.disconnected_msg = 'Thank You For Testing!';
			navigateToURL(new URLRequest(model.flashVarModel.root_url + 'perf/done/?pass=1'), '_self');
		}
	}
	
	private static function getSessionID():void {
		API.perfStart(
			model.worldModel.pc.tsid,
			model.flashVarModel.current_trial_name,
			EnvironmentUtil.platform,
			Capabilities.version,
			EnvironmentUtil.getMajorFlashVersion(),
			EnvironmentUtil.getMinorFlashVersion(),
			gpuInfo.GPUAvailable,
			gpuInfo.driverInfo,
			function handleAPIResponse(ok:Boolean, rsp:Object):void {
				if (ok) {
					// kick things off
					sessionID = rsp.session_id;
					prepareToTest();
					runNextTest();
				} else {
					fatal("API error retrieving session_id: " + rsp)
				}
			}
		);
	}
	
	private static function prepareToTest():void {
		populateTestSuite(model.flashVarModel.empty_test_location, model.flashVarModel.test_locations);
		PerfTestToolbarUI.instance.show();
	}
	
	private static function populateTestSuite(emptyLoc:String, testLocs:Array):void {
		for each (var loc:Object in testLocs) {
			testsToRun.push(new PerfTestInfo(loc.tsid, emptyLoc, loc.fake_friends, RenderMode.BITMAP));
		}
		
		// shuffle the test order
		VectorUtil.shuffle(testsToRun);
	}
	
	private static function handleError(error:Error):void {
		fatal('Flash Error: ' + (error ? error.getStackTrace() : error));
	}
	
	private static function checkPreconditions():void {
		SoundMaster.instance.sfx_volume = 0;
		SoundMaster.instance.music_volume = 0;
		
		// close right side contact list
		RightSideManager.instance.contactListToggle(false);
		
		// return to original scale
		TSFrontController.instance.resetViewportScale(0);
		TSFrontController.instance.resetViewportOrientation();
		
		if (EnvironmentUtil.getMajorFlashVersion() < 11) {
			fatal("Flash player version " + EnvironmentUtil.getMajorFlashVersion() + "." + EnvironmentUtil.getMinorFlashVersion() + " is too old");
		}
	}
	
	private static function annc(str:String):void {
		AnnouncementController.instance.cancelOverlay('perf_test_annc');
		TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([{
			type: "vp_overlay",
			dismissible: false,
			locking: false,
			click_to_advance: false,
			text: ['<p align="center"><span class="nuxp_big">' + str + '</span></p>'],
			x: '50%',
			y: '50%',
			duration: 1500,
			width: Math.max(TSModelLocator.instance.layoutModel.min_vp_w-100, TSModelLocator.instance.layoutModel.loc_vp_w-200),
			uid: 'perf_test_annc',
			bubble_god: true,
			allow_in_locodeco: true
		}]);
	}
	
	private static function populateChat():void {
		const hipsterIpsum:Array = [
			"Etsy gentrify cray, iphone ethnic jean shorts banh mi occupy synth portland quinoa.",
			"Synth brunch photo booth lo-fi, gastropub truffaut carles terry richardson ennui butcher pour-over pork belly.",
			"Brooklyn jean shorts yr 8-bit, master cleanse ethical bushwick skateboard keffiyeh.",
			"Chillwave wolf iphone, trust fund street art brunch keytar squid echo park authentic odd future helvetica DIY.",
			"Pitchfork iphone hoodie, viral beard brooklyn shoreditch fap farm-to-table 3 wolf moon godard.",
			"Synth skateboard put a bird on it odd future pork belly, swag art party squid lo-fi bicycle rights godard umami wes anderson brooklyn.",
			"Umami fixie swag, occupy portland wayfarers banh mi keytar salvia chambray wolf four loko retro organic."
		];
		
		RightSideManager.instance.chatStart(ChatArea.NAME_GLOBAL, false);
		RightSideManager.instance.chatStart(ChatArea.NAME_HELP, false);
		for (var i:int=0; i<20; i++) {
			for each (var filler:String in hipsterIpsum) {
				RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, model.worldModel.pc.tsid, filler);
				RightSideManager.instance.chatUpdate(ChatArea.NAME_GLOBAL, model.worldModel.pc.tsid, filler);
				RightSideManager.instance.chatUpdate(ChatArea.NAME_HELP, model.worldModel.pc.tsid, filler);
			}
		}
	}
}
}
