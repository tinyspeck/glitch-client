package com.tinyspeck.engine.perf
{
import com.tinyspeck.core.beacon.StageBeacon;

import flash.display.Stage;
import flash.net.LocalConnection;
import flash.system.System;
import flash.utils.getTimer;

final internal class FPSTracker {
	private var stage:Stage;
	
	private var _frames:uint;
	
	private var startMem:Number;
	private var endMem:uint;
	private var totalMem:Number = 0;
	
	private var startTime:uint;
	private var endTime:uint;
	
	/**
	 * Starts tracking immediately; you SHOULD call reset() before you actually
	 * want to begin collecting data, ideally at least one frame later.
	 */
	public function FPSTracker(stage:Stage):void {
		this.stage = stage;
		StageBeacon.enter_frame_sig.add(onEnterFrame);
		reset();
	}
	
	/** Call when you're completely done with this class, no more reset()s */
	public function dispose():void {
		StageBeacon.enter_frame_sig.remove(onEnterFrame);
	}
	
	/** Resets tracking data for another segment of time */
	public function reset():void {
		// Release mode gc().
		try {
			new LocalConnection().connect('_noop');
			new LocalConnection().connect('_noop');
		} catch (e:*) {}
		
		_frames = 1;
		startMem = endMem = totalMem = System.totalMemory;
		startTime = endTime = getTimer();
	}
	
	public function report():String {
		return ('['
			+ 'time=' + time + ', '
			+ 'frames=' + frames + ', '
			+ 'avg_fps=' + avg_fps + ', '
			+ 'avg_mem=' + avg_mem + ', '
			+ 'mem_delta=' + mem_delta + ']');
	}
	
	private function onEnterFrame(ms_elapsed:int):void {
		endTime = getTimer();
		endMem = System.totalMemory;
		totalMem += System.totalMemory;
		_frames++;
	}
	
	public function get avg_fps():uint {
		return Math.round(_frames * 1000 / time);
	}
	
	public function get avg_mem():uint {
		return Math.round((totalMem / _frames) * (1/1024/1024));
	}
	
	public function get frames():uint {
		return _frames;
	}
	
	public function get mem_delta():int {
		return Math.round((endMem - startMem) * (1/1024/1024));
	}
	
	public function get time():uint {
		return (endTime - startTime);
	}
}
}