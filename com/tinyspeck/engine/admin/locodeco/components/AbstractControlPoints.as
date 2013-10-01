package com.tinyspeck.engine.admin.locodeco.components
{
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;

public class AbstractControlPoints extends Sprite implements IControlPoints
{
	/** When true, ControlPointEvents are dispatched */
	public var enableControlPointEvents:Boolean = true;
	
	protected var _stage:Stage;
	protected var _target:Object;
	
	public function AbstractControlPoints() {
		//
	}
	
	override public function dispatchEvent(event:Event):Boolean {
		return enableControlPointEvents ? super.dispatchEvent(event) : false;
	}
	
	public function get displayObject():DisplayObject {
		return this;
	}
	
	public function set stage(s:Stage):void {
		_stage = s;
	}
	
	public function get target():Object {
		return _target;
	}
	
	/**
	 * The target should be a DisplayObject, but is typed as Object so that
	 * Proxy is supported too. Dang.
	 */
	public function set target(t:Object):void {
		_target = t;
		redraw();
	}
	
	public function redraw():void {
		//
	}
}
}