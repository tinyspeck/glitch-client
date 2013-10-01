package com.flexamphetamine
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.engine.model.TSModelLocator;

import flash.utils.getTimer;

/**
 * This is a finite state machine (FSM) that keeps moving through states
 * (via calls to start()/dispatch()) as long as it can until a timeout
 * occurs (via workerTimedOut()), then automatically resume()s on the next frame
 * until a state of FINISHED or FAILED has been returned by dispatch().
 * 
 * To use:
 * Override dispatch() with your FSM logic.
 * Optionally override callbacks: start()/resumed()/stopped()/failed()/finished().
 */
public class InterruptableWorker
{
	protected static const FAILED:int = -1;
	protected static const FINISHED:int = 0;
	
	protected var ms_per_timeslice:int;
	private var timeslice_start:int;
	
	public function InterruptableWorker(ms_per_timeslice:int) {
		this.ms_per_timeslice = ms_per_timeslice;
	}
	
	/**
	 * Extend this function and implement your finite state machine.
	 * Switch on @state, do work, and return the next state the FSM should be in.
	 */
	protected function dispatch(state:int, data:Object):int {
		return FAILED;
	}
	
	/**
	 * Call this when you want to start the worker with the initial state you
	 * want to start with. Pass in an optional mutable data Object that will be
	 * passed to every other function call until the FSM terminates.
	 * 
	 * Be sure to call super.start() if you extend this. It will kick off the
	 * first state of the machine (via resume/dispatch).
	 */
	protected function start(firstStep:int, data:Object):void {
		resume(firstStep, data);
	}
	
	/**
	 * This is automatically called when the worker is resumed with the next
	 * state to be run.
	 * 
	 * Be sure to call super.resume() if you extend this
	 */
	protected function resume(nextState:Number, data:Object):void {
		timeslice_start = getTimer();
		while (1) {
			nextState = dispatch(nextState, data);
			if (nextState == FAILED) {
				terminated(nextState, data);
				break;
			} else if (nextState == FINISHED) {
				terminated(nextState, data);
				break;
			} else if (workerTimedOut()) {
				if (TSModelLocator.instance.flashVarModel.workers_wait_until_next_frame) {
					StageBeacon.waitForNextFrame(resume, nextState, data);
				} else {
					StageBeacon.setTimeout(resume, 0, nextState, data);
				}
				stopped(nextState, data);
				break;
			}
		}
	}
	
	/**
	 * Called when the worker has been interruped by a timeout with the last
	 * state run passed to it.
	 */
	protected function stopped(lastState:int, data:Object):void {
		//
	}
	
	/**
	 * Called when the worker has terminated (dispatch returned FINISHED/FAILED)
	 * with the last state run passed to it.
	 */
	protected function terminated(lastState:int, data:Object):void {
		//
	}
	
	/** Returns whether the current timeslice has expired */
	protected function workerTimedOut():Boolean {
		return ((getTimer() - timeslice_start) > ms_per_timeslice);
	}
}
}