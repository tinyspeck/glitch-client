package com.tinyspeck.engine.perf {

import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.engine.model.LayoutModel;
import com.tinyspeck.engine.model.TSModelLocator;
import com.tinyspeck.engine.model.WorldModel;
import com.tinyspeck.engine.port.RightSideManager;
import com.tinyspeck.engine.view.ui.chat.ChatArea;
import com.tinyspeck.engine.view.ui.chat.ChatElement;

import flash.display.Stage;

/**
 * Decides what tests need to be run and arranges for the PerfTestController
 * to do each test.
 */
final public class PerformanceMonitor {
	private static const HELP_URL:String = '/help/faq/#q204';
	
	private static const INTERVAL_MINUTES:Number = 5;
	private static const WARN_FPS:Number = 25;
	private static const WARN_STAGE_WIDTH:Number = 1680;
	private static const WARN_STAGE_HEIGHT:Number = 1050;
	private static const WARN_SESSION_MINUTES:Number = 90;
	private static const WARN_MEMORY_MB:Number = 1024;
	
	private static var warned_memory_usage:Boolean;
	private static var warned_session_minutes:Boolean;
	private static var warned_stage_dimensions:Boolean;
	
	private static var sessionMinutes:uint;
	private static var fpsTracker:FPSTracker;
	
	public static function init(stage:Stage):void {
		fpsTracker = new FPSTracker(StageBeacon.stage);
		StageBeacon.setInterval(auditPerformance, INTERVAL_MINUTES*60*1000);
	}
	
	private static function auditPerformance():void {
		sessionMinutes += INTERVAL_MINUTES;
		
		if ((fpsTracker.avg_fps < WARN_FPS) && StageBeacon.isActivelyPlaying()) {
			const layoutModel:LayoutModel = TSModelLocator.instance.layoutModel;
			if (!warned_stage_dimensions &&
				(((layoutModel.loc_vp_w == layoutModel.max_vp_w) && (StageBeacon.stage.stageWidth > WARN_STAGE_WIDTH)) ||
				 ((layoutModel.loc_vp_h == layoutModel.max_vp_h) && (StageBeacon.stage.stageHeight > WARN_STAGE_HEIGHT))))
			{
				warned_stage_dimensions = true;
				annc("Your web browser's window is rather large! " +
					"Glitch may run faster if you make your browser window smaller.");
			} else if (!warned_memory_usage && (fpsTracker.avg_mem > WARN_MEMORY_MB)) {
				warned_memory_usage = true;
				annc("Your web browser is using a lot of memory! " +
					"Glitch will run faster if you reload the game — or, even better, restart your web browser.");
			} else if (!warned_session_minutes && (sessionMinutes > WARN_SESSION_MINUTES)) {
				warned_session_minutes = true;
				annc("You've been playing for a long while! " +
					"Glitch will run faster if you reload the game — or, even better, restart your web browser");
			}
			 //"Reminder: Glitch runs fastest if you use two separate browsers for Glitch and your normal web use."
		}
		
		fpsTracker.reset();
	}
	
	private static function annc(str:String):void {
		str += "<br/><a target='_blank' href='" + HELP_URL + "' class='chat_element_perf_url'>Learn more</a>";
		RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, WorldModel.NO_ONE, str, ChatElement.TYPE_PERF_MSG);
	}
}
}
