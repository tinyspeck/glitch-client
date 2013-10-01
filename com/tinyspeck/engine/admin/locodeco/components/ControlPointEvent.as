package com.tinyspeck.engine.admin.locodeco.components
{
import flash.events.Event;

public class ControlPointEvent extends Event
{
	public static const START_MOVE:String   = "startMove";
	public static const START_RESIZE:String = "startResize";
	
	public var origin:AbstractControlPoints;
	public var resizeHandleName:String;
	
	public function ControlPointEvent(type:String, origin:AbstractControlPoints) {
		super(type, false, false);
		this.origin = origin;
	}
}
}