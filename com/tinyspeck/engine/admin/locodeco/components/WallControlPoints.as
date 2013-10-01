package com.tinyspeck.engine.admin.locodeco.components
{
import com.tinyspeck.core.beacon.StageBeacon;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

public class WallControlPoints extends MoveableControlPoints
{
	private static const HANDLE_RADIUS:int = 15;
	
	private static const TOP:String = 'top';
	private static const BOTTOM:String = 'bottom';
	
	private const _handleTop:Sprite = createHandle(TOP);
	private const _handleEnd:Sprite = createHandle(BOTTOM);
	
	private var _dragHandleName:String;
	private var _initY:int;
	
	public function WallControlPoints() {
		super();
		
		// handles
		addChild(_handleTop);
		addChild(_handleEnd);
	}
	
	override public function set target(t:Object):void {
		endHandleMove();
		super.target = t;
	}
	
	override protected function markStartingPosition():void {
		super.markStartingPosition();
		_initY = _target.y;
	}
	
	
	override public function redraw():void {
		if (!_target) return;
		
		super.redraw();

		const r:Rectangle = _lastTargetBounds;
		const middleX:int = r.x+r.width/2;
		const topY:int = r.y;
		const middleY:int = r.y+r.height/2;
		const bottomY:int = r.bottom;
		
		_handleTop.x = middleX;
		_handleTop.y = topY;
		_handleEnd.x = middleX;
		_handleEnd.y = bottomY;
	}
	
	override public function restartMove():void {
		move();
	}
	
	public function startEndHandleMove():void {
		_dragHandleName = BOTTOM;
		markStartingPosition();
		StageBeacon.game_loop_sig.add(onEnterFrame);
		StageBeacon.mouse_up_sig.add(onMouseUp);
	}
	
	private function createHandle(name:String):Sprite {
		const _handle:Sprite = new Sprite();
		_handle.name = name;
		_handle.addEventListener(MouseEvent.MOUSE_DOWN, startHandleMove, false, 0, true);
		_handle.buttonMode = true;
		_handle.useHandCursor = true;
		_handle.graphics.beginFill(0, 0);
		_handle.graphics.drawCircle(0, 0, HANDLE_RADIUS);
		return _handle;
	}
	
	private function startHandleMove(e:MouseEvent):void {
		_dragHandleName = e.target.name;
		markStartingPosition();
		StageBeacon.game_loop_sig.add(onEnterFrame);
		StageBeacon.mouse_up_sig.add(onMouseUp);
	}
	
	private function onMouseUp(e:MouseEvent):void {
		endHandleMove();
	}
	
	private function onEnterFrame(ms_elapsed:int):void {
		move();
	}
	
	private function move():void {
		const delta:Point = mouseDragDelta;
		const yDelta:int = delta.y;
		switch (_dragHandleName) {
			case TOP:
				target.y = Math.min(_initY + _initH, _initY + yDelta);
				_target.h = Math.max(1, (_initH - yDelta));
				break;
			case BOTTOM:
				_target.h = Math.max(1, (_initH + yDelta));
				break;
		}
		redraw();
	}
	
	private function endHandleMove():void {
		StageBeacon.game_loop_sig.remove(onEnterFrame);
		StageBeacon.mouse_up_sig.remove(onMouseUp);
	}
}
}
