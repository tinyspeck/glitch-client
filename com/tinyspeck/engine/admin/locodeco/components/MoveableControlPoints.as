package com.tinyspeck.engine.admin.locodeco.components
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.engine.control.TSFrontController;
import com.tinyspeck.engine.util.DrawUtil;

import flash.display.BlendMode;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.ui.Mouse;
import flash.ui.MouseCursor;

[Event(name="startMove", type="com.tinyspeck.engine.admin.locodeco.components.ControlPointEvent")]

public class MoveableControlPoints extends AbstractControlPoints
{
	public static const MOVE_HANDLE:String = "moveHandle";
	
	protected var _lastTargetBounds:Rectangle = new Rectangle();
	
	protected var _initMouseXInTargetSpace:Number;
	protected var _initMouseYInTargetSpace:Number;
	protected var _initOffsetX:int;
	protected var _initOffsetY:int;
	protected var _initW:int;
	protected var _initH:int;
	protected var _initR:Number;

	private const _border:Sprite = new Sprite();
	
	private const _tmpPoint:Point = new Point();
	
	public function MoveableControlPoints() {
		super();
		
		blendMode = BlendMode.INVERT;
		
		_border.name = MOVE_HANDLE;
		_border.addEventListener(MouseEvent.MOUSE_DOWN, startMove);
		_border.addEventListener(MouseEvent.MOUSE_OVER, showHandCursor);
		_border.addEventListener(MouseEvent.MOUSE_OUT, resetCursor);
		addChild(_border);
	}
	
	/**
	 * The target should be a DisplayObject, but is typed as Object so that
	 * Proxy is supported too. Dang.
	 */
	override public function set target(t:Object):void {
		endMove();
		super.target = t;
		visible = (target != null);
	}
	
	override public function redraw():void {
		if (!_target) return;
		
		super.redraw();
		
		// rotation MUST be set before getBounds measurement of _target
		rotation = _target.r;
		const r:Rectangle = _target.getBounds(this);
	
		// performance optimization, skip unnecessary renders
		if (r.equals(_lastTargetBounds)) return;
		_lastTargetBounds = r;
		
		// border has an invisible fill (so the mouse collides with it)
		const bG:Graphics = _border.graphics;
		_border.x = r.x;
		_border.y = r.y;
		bG.clear();
		bG.beginFill(0, 0);
		bG.drawRect(0, 0, r.width, r.height);
		bG.endFill();
		DrawUtil.drawDashedRect(bG, r.width, r.height);
	}
	
	private static function showHandCursor(e:* = null):void {
		Mouse.cursor = MouseCursor.HAND;
	}
	
	private static function resetCursor(e:* = null):void {
		Mouse.cursor = MouseCursor.AUTO;
	}
	
	protected function markStartingPosition():void {
		// store the starting dimensions of our target
		const mouse:Point = mouseCoordinatesInTargetSpace;
		_initMouseXInTargetSpace = mouse.x;
		_initMouseYInTargetSpace = mouse.y;
		_initOffsetX = (mouse.x - _target.x);
		_initOffsetY = (mouse.y - _target.y);
		_initW = _target.w;
		_initH = _target.h;
		_initR = _target.r;
	}
	
	protected function get mouseCoordinatesInTargetSpace():Point {
		_tmpPoint.x = _stage.mouseX;
		_tmpPoint.y = _stage.mouseY;
		return _target.parent.globalToLocal(_tmpPoint);
	}
	
	protected function get mouseDragDelta():Point {
		const mouse:Point = mouseCoordinatesInTargetSpace;
		mouse.x -= _initMouseXInTargetSpace;
		mouse.y -= _initMouseYInTargetSpace;
		return mouse;
	}
	
	public static function isMouseOverMoveHandle(e:MouseEvent):Boolean {
		return ((e.target as DisplayObject).name == MOVE_HANDLE);
	}
	
	/** Public so I can start a move manually after the mouse is already down */
	public function startMove(e:MouseEvent = null):void {
		markStartingPosition();
		StageBeacon.mouse_up_sig.add(onMouseUp);
		StageBeacon.game_loop_sig.add(onEnterFrame);
		dispatchEvent(new ControlPointEvent(ControlPointEvent.START_MOVE, this));
		
		TSFrontController.instance.changeTipsVisibility(false, 'MoveableControlPoints');
	}
	
	public function restartMove():void {
		move();
	}
	
	private function onEnterFrame(ms_elapsed:int):void {
		move();
	}
	
	private function move():void {
		// it's possible, somehow, that _target went null
		if (_target) {
			const offset:Point = mouseCoordinatesInTargetSpace;
			_target.x = int(Math.round(offset.x - _initOffsetX));
			_target.y = int(Math.round(offset.y - _initOffsetY));
			redraw();
		}
	}
	
	private function onMouseUp(e:MouseEvent):void {
		endMove();
	}
	
	private function endMove():void {
		StageBeacon.mouse_up_sig.remove(onMouseUp);
		StageBeacon.game_loop_sig.remove(onEnterFrame);
		
		redraw();
		
		TSFrontController.instance.changeTipsVisibility(true, 'MoveableControlPoints');
	}
}
}