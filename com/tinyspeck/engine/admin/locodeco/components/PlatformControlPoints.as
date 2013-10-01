package com.tinyspeck.engine.admin.locodeco.components
{
import com.tinyspeck.core.beacon.KeyBeacon;
import com.tinyspeck.core.beacon.StageBeacon;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.ui.Keyboard;

public class PlatformControlPoints extends MoveableControlPoints
{
	private static const HANDLE_WIDTH:int = 15;
	private static const START:String  = 'start';
	private static const HEIGHT:String = 'height';
	private static const END:String    = 'end';
	
	protected var _initX1:int;
	protected var _initY1:int;
	protected var _initX2:int;
	protected var _initY2:int;
	protected var _initHeight:int;
	
	private const _handleStart:Sprite  = createHandle(START);
	private const _handleHeight:Sprite = createHandle(HEIGHT, 8, 1);
	private const _handleEnd:Sprite    = createHandle(END);
	
	private var _dragHandleName:String;
	
	public function PlatformControlPoints() {
		super();
		
		// handles
		addChild(_handleStart);
		addChild(_handleHeight);
		addChild(_handleEnd);
	}
	
	override public function set target(t:Object):void {
		endHandleMove();
		super.target = t;
	}
	
	override public function redraw():void {
		if (!_target) return;
		
		super.redraw();
		
		_handleStart.x = _target.x1;
		_handleStart.y = _target.y1;
		_handleHeight.visible = _target.is_for_placement;
		_handleHeight.x = _target.x1 + ((_target.x2 - _target.x1) / 2);
		_handleHeight.y = _target.y1 + ((_target.y2 - _target.y1) / 2) - _target.placement_plane_height;
		_handleEnd.x = _target.x2;
		_handleEnd.y = _target.y2;
	}
	
	override protected function markStartingPosition():void {
		super.markStartingPosition();
		
		_initX1 = _target.x1;
		_initY1 = _target.y1;
		_initX2 = _target.x2;
		_initY2 = _target.y2;
		_initHeight = _target.placement_plane_height;
	}
	
	override public function restartMove():void {
		handleMove();
	}
	
	public function startEndHandleMove():void {
		_dragHandleName = END;
		markStartingPosition();
		StageBeacon.game_loop_sig.add(onEnterFrame);
		StageBeacon.mouse_up_sig.add(onMouseUp);
	}
	
	private function createHandle(name:String, width:int = HANDLE_WIDTH, alpha:Number = 0):Sprite {
		const _handle:Sprite = new Sprite();
		_handle.name = name;
		_handle.addEventListener(MouseEvent.MOUSE_DOWN, startHandleMove, false, 0, true);
		_handle.buttonMode = true;
		_handle.useHandCursor = true;
		_handle.graphics.beginFill(0, alpha);
		_handle.graphics.drawRect(-width/2, -width/2, width, width);
		return _handle;
	}
	
	private function startHandleMove(e:MouseEvent):void {
		_dragHandleName = e.target.name;
		markStartingPosition();
		StageBeacon.game_loop_sig.add(onEnterFrame);
		StageBeacon.mouse_up_sig.add(onMouseUp);
	}
	
	private function onEnterFrame(ms_elapsed:int):void {
		handleMove();
	}
	
	private function handleMove():void {
		const delta:Point = mouseDragDelta;
		const xDelta:int = delta.x;
		const yDelta:int = delta.y;

		// holding shift should snap horizontal
		// as when there's "placement_plane_height" (when the platform is also a plane)
		const snapToHorizontal:Boolean = (KeyBeacon.instance.pressed(Keyboard.SHIFT) || (_target.placement_plane_height !== 0));
		
		switch (_dragHandleName) {
			case START:
				_target.x1 = _initX1 + xDelta;
				_target.y1 = (snapToHorizontal ? _target.y2 : (_initY1 + yDelta));
				break;
			case HEIGHT:
				_target.placement_plane_height = _initHeight - yDelta;
				break;
			case END:
				_target.x2 = _initX2 + xDelta;
				_target.y2 = (snapToHorizontal ? _target.y1 : (_initY2 + yDelta));
				break;
		}
		
		redraw();
	}
	
	private function onMouseUp(e:MouseEvent):void {
		endHandleMove();
	}
	
	private function endHandleMove():void {
		StageBeacon.game_loop_sig.remove(onEnterFrame);
		StageBeacon.mouse_up_sig.remove(onMouseUp);
		redraw();
	}
}
}