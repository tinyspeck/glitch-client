package com.tinyspeck.engine.perf
{
import com.tinyspeck.engine.view.renderer.RenderMode;

/** Describes a test session */
internal final class PerfTestInfo
{
	public var testLocation:String;
	public var emptyLocation:String;
	public var fakeFriends:uint;
	public var renderMode:RenderMode;
		
	public function PerfTestInfo(testLocation:String, emptyLocation:String, fakeFriends:uint, renderMode:RenderMode) {
		this.testLocation = testLocation;
		this.emptyLocation = emptyLocation;
		this.fakeFriends = fakeFriends;
		this.renderMode = renderMode;
	}
}
}