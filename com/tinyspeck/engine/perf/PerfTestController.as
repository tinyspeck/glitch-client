package com.tinyspeck.engine.perf {

import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.FakeFriends;
import com.tinyspeck.engine.control.TSFrontController;
import com.tinyspeck.engine.model.TSModelLocator;
import com.tinyspeck.engine.port.IMoveListener;
import com.tinyspeck.engine.port.IRenderListener;
import com.tinyspeck.engine.view.IFocusableComponent;
import com.tinyspeck.engine.view.renderer.commands.LocationCommands;

import flash.events.TimerEvent;
import flash.geom.Point;
import flash.utils.Timer;

/**
 * Controls the avatar through a series of rendering tests and reports FPS
 * and memory statistics.
 * 
 * The location being tested is SWF_test_location; before the tests begin
 * you are taken to SWF_empty_location to start fresh.
 */
final public class PerfTestController implements IMoveListener, IRenderListener, IFocusableComponent {
	private static const STATIC_CAMERA_MS:int = 8*1000;
	
	private const timeout:Timer = new Timer(2*60*1000, 1);
	private var testSegmentIntervalTimer:uint;
	
	private var model:TSModelLocator;
	private var has_focus:Boolean;
	
	/** Parameters for this test; when non-null, the test is running */
	private var testInfo:PerfTestInfo;
	
	// game loads, wait until we get to the test location
	private var s0_waitingForFirstTestLocationLoad:Boolean;
	
	// from the test location, teleport to the empty location
	private var s1_waitingForEmptyLocationLoad:Boolean;
	
	// in the empty location, switch to the target renderer
	private var s2_waitingForRenderModeToChange:Boolean;
	
	// from the empty location, teleport back to the test location
	private var s2_waitingForSecondTestLocationLoad:Boolean;
	
	// conditions required to transition out of state 2
	private var s2_renderComplete:Boolean;
	private var s2_moveComplete:Boolean;

	public function PerfTestController() {
		model = TSModelLocator.instance;
		
		timeout.addEventListener(TimerEvent.TIMER, onTimeout, false, 0, true);
		
		TSFrontController.instance.registerMoveListener(this);
		TSFrontController.instance.registerRenderListener(this);
		registerSelfAsFocusableComponent();
	}
	
	public function get running():Boolean {
		return (testInfo != null);
	}

	public function run(testInfo:PerfTestInfo):void {
		if (running) PerfTestManager.fatal("PTC is already running");

		if (model.worldModel.location.isFullyLoaded) {
			// location is loaded, this will cause running to be true:
			this.testInfo = testInfo;
			// and now re-run this handler
			moveMoveEnded();
		} else {
			// wait until the current location has loaded before beginning
			StageBeacon.waitForNextFrame(run, testInfo);
		}
	}
	
	public function reset():void {
		// just in case we were in the middle of a test...
		cancelTimeout();
		TSFrontController.instance.cancelAllAvatarPaths('Performance Test Reset');
		StageBeacon.clearInterval(testSegmentIntervalTimer);
		testSegmentIntervalTimer = 0;
		
		testInfo = null;
		
		s0_waitingForFirstTestLocationLoad = true;
		s1_waitingForEmptyLocationLoad = false;
		s2_waitingForRenderModeToChange = false;
		s2_waitingForSecondTestLocationLoad = false;
		s2_renderComplete = false;
		s2_moveComplete = false;
		
		if (hasFocus()) TSFrontController.instance.releaseFocus(this);
	}
	
	////////////////////////////////////////////////////////////////////////////////
	//////// FOCUS /////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////
	
	public function hasFocus():Boolean {
		return has_focus;
	}
	
	public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
		//
	}
	
	public function demandsFocus():Boolean {
		return true;
	}
	
	public function get stops_avatar_on_focus():Boolean {
		return false;
	}
	
	public function blur():void {
		has_focus = false;
	}
	
	public function registerSelfAsFocusableComponent():void {
		model.stateModel.registerFocusableComponent(this as IFocusableComponent);
	}
	
	public function removeSelfAsFocusableComponent():void {
		model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
	}
	
	public function focus():void {
		has_focus = true;
	}
	
	////////////////////////////////////////////////////////////////////////////////
	//////// IRENDERLISTENER ///////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////
	
	public function renderHasStarted():void {
		if (!running) return;
		
		if (s2_waitingForSecondTestLocationLoad) {
			PerfTestManager.resetPerformanceMeasurements();
		}
	}
	
	public function renderHasEnded():void {
		if (!running) return;
		
		if (s2_waitingForRenderModeToChange) {
			if (model.stateModel.render_mode == testInfo.renderMode) {
				// we're in the correct mode
				s2_waitingForRenderModeToChange = false;
				// now teleport back to the test location, measuring render time
				s2_waitingForSecondTestLocationLoad = true;
				PerfTestManager.teleportTo(testInfo.testLocation);
				// moveMoveEnded will handle the next state
			} else {
				// load the correct mode and wait for renderHasEnded again
				LocationCommands.changeRenderMode(testInfo.renderMode);
			}
		} else if (s2_waitingForSecondTestLocationLoad) {
			PerfTestManager.report('reticulation', testInfo);
			
			// exit state 2 if all conditions have been met
			s2_renderComplete = true;
			tryToExitState2();
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////
	//////// IMOVELISTENER /////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////
	
	public function moveLocationHasChanged():void {
		//
	}
	
	public function moveLocationAssetsAreReady():void {
		//
	}
	
	public function moveMoveStarted():void {
		//
	}
	
	public function moveMoveEnded():void {
		if (!running) return;
		
		if (s0_waitingForFirstTestLocationLoad) {
			// is the first location our test location already
			if (model.worldModel.location.tsid == testInfo.testLocation) {
				// we've arrived at the test location the first time
				s0_waitingForFirstTestLocationLoad = false;
				// now teleport to the empty location
				s1_waitingForEmptyLocationLoad = true;
				PerfTestManager.teleportTo(testInfo.emptyLocation);
			} else if (model.worldModel.location.tsid == testInfo.emptyLocation) {
				// teleport to the test location and wait for another moveMoveEnded
				PerfTestManager.teleportTo(testInfo.testLocation);
			} else {
				// we're somewhere else:
				// teleport to the test location and wait for another moveMoveEnded
				PerfTestManager.teleportTo(testInfo.testLocation);
			}
			
		} else if (s1_waitingForEmptyLocationLoad) {
			// assert that we arrived at the empty location
			if (model.worldModel.location.tsid != testInfo.emptyLocation) PerfTestManager.fatal("Assertion failed: Not at empty location");
			s1_waitingForEmptyLocationLoad = false;
			s2_waitingForRenderModeToChange = true;
			// now call renderHasEnded again, which will switch to the correct renderer
			renderHasEnded();
			
		} else if (s2_waitingForSecondTestLocationLoad) {
			// now we've arrived at test location for the second time
			if (model.worldModel.location.tsid != testInfo.testLocation) PerfTestManager.fatal("Assertion failed: Not at test location");
			
			// exit state 2 if all conditions have been met
			s2_moveComplete = true;
			tryToExitState2();
		}
	}
	
	////////////////////////////////////////////////////////////////////////////////
	//////// ETC ///////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////

	private function startTimeout():void {
		cancelTimeout();
		timeout.start();
	}
	
	private function cancelTimeout():void {
		timeout.reset();
	}
	
	private function onTimeout(e:TimerEvent):void {
		if (!running) return;
		
		cancelTimeout();
		PerfTestManager.fail('Timeout');
		stopTesting();
	}
	
	private function tryToExitState2():void {
		if (!running) return;
		if (!s2_waitingForSecondTestLocationLoad) return;
		
		// The condition for transitioning out of state 2 is that both move and render must complete.
		if (!(s2_renderComplete && s2_moveComplete)) return;
		
		s2_waitingForSecondTestLocationLoad = false;
		
		if (testInfo.fakeFriends) {
			FakeFriends.instance.insertFakesIntoLocation(testInfo.fakeFriends);
		}
		
		// start measuring performance for the dynamic camera
		// wait a bit for initial GC
		StageBeacon.setTimeout(startTesting, 2000);
	}
	
	private function startTesting():void {
		if (!running) return;
		
		if (!hasFocus() && !TSFrontController.instance.requestFocus(this)) {
			PerfTestManager.fatal('Test Controller could not get focus');
		}
		
		// path to walk and actions to play
		// functions will be run until there is a Point
		// at which point we'll go to that point and won't continue processing
		// the Array until we get there
		const pathAndActions:Array = [
			// start timeout
			startTimeout,
			// clear performance
			PerfTestManager.resetPerformanceMeasurements,
			// pass one:
			// preload left half of location
			new Point(model.worldModel.location.l, 0),
			// report
			reportDynamicCameraPerformanceMeasurementsUncachedPass,
			// cancel timeout
			cancelTimeout,
			
			// start timeout
			startTimeout,
			// preload right right half of location
			new Point(model.worldModel.location.r, 0),
			// cancel timeout
			cancelTimeout,
			
			// pass two:
			// start timeout
			startTimeout,
			// clear performance
			PerfTestManager.resetPerformanceMeasurements,
			// walk all the way left
			new Point(model.worldModel.location.l, 0),
			// report
			reportDynamicCameraPerformanceMeasurementsCachedPass,
			// cancel timeout
			cancelTimeout,
			
			// start timeout
			startTimeout,
			// back to center
			new Point(0, 0),
			// start final test
			startStaticCameraPerformanceMeasurements,
			// cancel timeout
			cancelTimeout
		];
		
		// start walking this path
		testSegmentIntervalTimer = StageBeacon.setInterval(function():void {
			if (!running) return;
			
			// are we not currently on a path
			if (!model.worldModel.pc.apo.onPath) {
				while (pathAndActions.length) {
					var nextThing:Object = pathAndActions.shift();
					
					// keep running functions until we hit a Point
					if (nextThing is Function) {
						nextThing();
					} else {
						TSFrontController.instance.startMovingAvatarOnGSPath(nextThing as Point);
						break;
					}
				}
				
				if (pathAndActions.length == 0) {
					StageBeacon.clearInterval(testSegmentIntervalTimer);
				}
			}
		}, 33);
	}
	
	private function stopTesting():void {
		if (!running) return;
		
		// this will release focus and stop the test
		reset();
		
		PerfTestManager.reportTestSegmentsComplete();
	}

	// the first pass reveals how the renderer performs during a pass over
	// completely unseen territory
	private function reportDynamicCameraPerformanceMeasurementsUncachedPass():void {
		if (!running) return;
		
		PerfTestManager.report('dynamic_camera_uncached_pass', testInfo);
	}
	
	// the second pass reveals how the renderer performs over seen territory
	private function reportDynamicCameraPerformanceMeasurementsCachedPass():void {
		if (!running) return;
		
		PerfTestManager.report('dynamic_camera_cached_pass', testInfo);
	}
	
	private function startStaticCameraPerformanceMeasurements():void {
		if (!running) return;
		
		PerfTestManager.resetPerformanceMeasurements();
		StageBeacon.setTimeout(reportStaticCameraPerformanceMeasurements, STATIC_CAMERA_MS);
	}
	
	private function reportStaticCameraPerformanceMeasurements():void {
		if (!running) return;
		
		PerfTestManager.report('static_camera', testInfo);
		stopTesting();
	}
}
}
