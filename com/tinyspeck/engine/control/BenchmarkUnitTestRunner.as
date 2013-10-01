package com.tinyspeck.engine.control
{
import asunit.framework.IResult;
import asunit.framework.IRunListener;
import asunit.framework.ITestFailure;
import asunit.framework.ITestSuccess;
import asunit.framework.ITestWarning;
import asunit.framework.Method;

import com.tinyspeck.debug.Benchmark;
import com.tinyspeck.engine.data.client.Announcement;
import com.tinyspeck.engine.model.TSModelLocator;

public class BenchmarkUnitTestRunner implements IRunListener
{
	public function BenchmarkUnitTestRunner() {
		//
	}
	
	public function onRunStarted():void {
		//
	}
	
	public function onRunCompleted(result:IResult):void {
		if (result.wasSuccessful) {
			Benchmark.addCheck('Unit tests passed!');
		} else {
			Benchmark.addCheck('Unit tests failed!');
			TSModelLocator.instance.activityModel.announcements = Announcement.parseMultiple([{
				type: "vp_overlay",
				dismissible: false,
				locking: false,
				click_to_advance: true,
				text: ['<p align="center"><span class="nuxp_medium">AS3 UNIT TESTS FAILED<br/>Now go tell someone!</span></p>'],
				x: '50%',
				y: '50%',
				duration: 1500,
				width: Math.max(TSModelLocator.instance.layoutModel.min_vp_w-100, TSModelLocator.instance.layoutModel.loc_vp_w-200),
				uid: 'unit_test_msg',
				bubble_god: true
			}]);
		}
	}
	
	public function onTestStarted(test:Object):void {
		//
	}
	
	public function onTestCompleted(test:Object):void {
		//
	}
	
	public function onTestFailure(failure:ITestFailure):void {
		//
	}
	
	public function onTestSuccess(success:ITestSuccess):void {
		//
	}
	
	public function onTestIgnored(method:Method):void {
		//
	}
	
	public function onWarning(warning:ITestWarning):void {
		//
	}
}
}