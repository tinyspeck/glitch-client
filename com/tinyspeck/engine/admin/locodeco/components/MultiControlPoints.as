package com.tinyspeck.engine.admin.locodeco.components
{
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.MouseEvent;
import flash.utils.Dictionary;

public class MultiControlPoints extends Sprite implements IControlPoints
{
	//TODO pool these?
	private var _targetToControlPoint:Dictionary = new Dictionary;
	private var _stage:Stage;
	
	public function MultiControlPoints() {
		//
	}
	
	public function get displayObject():DisplayObject {
		return this;
	}
	
	public function set stage(s:Stage):void {
		_stage = s;
	}
	
	public function isMouseOverMoveHandle(e:MouseEvent):Boolean {
		return MoveableControlPoints.isMouseOverMoveHandle(e);
	}
	
	/**
	 * Key is the key which will be used to later removeTarget();
	 * target should be a DisplayObject, but is typed as Object so that
	 * Proxy is supported too. Dang.
	 */
	public function registerControlPoint(key:Object, cp:AbstractControlPoints):void {
		if (!_targetToControlPoint[key]) {
			// these handlers catch a single ACP doing an action and
			// broadcasts the action to all other active ACPs
			if (cp is MoveableControlPoints) cp.addEventListener(ControlPointEvent.START_MOVE, startMoveHandler);
			if (cp is ResizeableControlPoints) cp.addEventListener(ControlPointEvent.START_RESIZE, startResizeHandler);
			
			_targetToControlPoint[key] = cp;
			addChild(cp);
			cp.redraw();
		}
	}
	
	public function unregisterControlPoint(key:Object):void {
		const cp:AbstractControlPoints = _targetToControlPoint[key];
		if (cp) {
			removeChild(cp);
			cp.removeEventListener(ControlPointEvent.START_MOVE, startMoveHandler);
			cp.removeEventListener(ControlPointEvent.START_RESIZE, startResizeHandler);
			// target must be null before stage
			cp.target = null;
			cp.stage  = null;
			delete _targetToControlPoint[key];
		}
	}	
	
	public function clearTargets():void {
		while (numChildren) removeChildAt(0);
		for each (var cp:AbstractControlPoints in _targetToControlPoint) {
			cp.removeEventListener(ControlPointEvent.START_MOVE, startMoveHandler);
			cp.removeEventListener(ControlPointEvent.START_RESIZE, startResizeHandler);
			// target must be null before stage
			cp.target = null;
			cp.stage  = null;
		}
		_targetToControlPoint = new Dictionary();
	}
	
	public function redraw():void {
		for each (var cp:AbstractControlPoints in _targetToControlPoint) cp.redraw();
	}
	
	/**
	 * Use if programmatically moving the object's coordinates while a drag
	 * is in progress. E.g. when dragging off the edge of the screen, you may
	 * pan the screen, in which case we'll need a new relative drag start point.
	 */
	public function restartMove():void {
		for each (var cp:AbstractControlPoints in _targetToControlPoint) {
			if (cp is MoveableControlPoints) {
				MoveableControlPoints(cp).restartMove();
			}
		}
	}
	
	/** Meant to be called when there's only one control point active */
	public function startMove():void {
		for each (var cp:AbstractControlPoints in _targetToControlPoint) {
			if (cp is MoveableControlPoints) {
				MoveableControlPoints(cp).startMove();
			}
			break;
		}
	}
	
	/** Meant to be called when there's only one control point active */
	public function startEndHandleMove():void {
		for each (var cp:AbstractControlPoints in _targetToControlPoint) {
			if (cp is PlatformControlPoints) {
				PlatformControlPoints(cp).startEndHandleMove();
			} else if (cp is WallControlPoints) {
				WallControlPoints(cp).startEndHandleMove();
			} else if (cp is LadderControlPoints) {
				LadderControlPoints(cp).startEndHandleMove();
			}
			break;
		}
	}
	
	private function startMoveHandler(e:ControlPointEvent):void {
		const origin:AbstractControlPoints = e.origin;
		for each (var cp:AbstractControlPoints in _targetToControlPoint) {
			if ((cp != origin) && (cp is MoveableControlPoints)) {
				cp.enableControlPointEvents = false;
				MoveableControlPoints(cp).startMove();
				cp.enableControlPointEvents = true;
			}
		}
	}
	
	private function startResizeHandler(e:ControlPointEvent):void {
		const origin:AbstractControlPoints = e.origin;
		const resizeHandleName:String = e.resizeHandleName;
		for each (var cp:AbstractControlPoints in _targetToControlPoint) {
			if ((cp != origin) && (cp is ResizeableControlPoints)) {
				cp.enableControlPointEvents = false;
				ResizeableControlPoints(cp).startResizeFromHandleName(resizeHandleName);
				cp.enableControlPointEvents = true;
			}
		}
	}
}
}
