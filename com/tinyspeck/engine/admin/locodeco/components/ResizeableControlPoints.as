package com.tinyspeck.engine.admin.locodeco.components
{
import com.tinyspeck.core.beacon.KeyBeacon;
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.engine.util.MathUtil;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.ui.Keyboard;

import locodeco.models.DecoModel;

[Event(name="startMove", type="com.tinyspeck.engine.admin.locodeco.components.ControlPointEvent")]
[Event(name="startResize", type="com.tinyspeck.engine.admin.locodeco.components.ControlPointEvent")]

public class ResizeableControlPoints extends MoveableControlPoints
{
	public static const HANDLE_WIDTH:Number   = 8;
	public static const HANDLE_OFFSET:Number  = HANDLE_WIDTH/2;

	protected static const LEFT_TOP:String      = 'leftTop';
	protected static const MIDDLE_TOP:String    = 'middleTop';
	protected static const RIGHT_TOP:String     = 'rightTop';
	protected static const RIGHT_MIDDLE:String  = 'rightMiddle';
	protected static const LEFT_BOTTOM:String   = 'leftBottom';
	protected static const MIDDLE_BOTTOM:String = 'middleBottom';
	protected static const RIGHT_BOTTOM:String  = 'rightBottom';
	protected static const LEFT_MIDDLE:String   = 'leftMiddle';
	
	/** Transforms a coordinate in _target space to _target.parent space */
	protected var _targetToParent:Matrix;
	
	private const _handleLeftTop:Sprite       = createHandle(LEFT_TOP);
	private const _handleMiddleTop:Sprite     = createHandle(MIDDLE_TOP);
	private const _handleRightTop:Sprite      = createHandle(RIGHT_TOP);
	private const _handleRightMiddle:Sprite   = createHandle(RIGHT_MIDDLE);
	private const _handleLeftBottom:Sprite    = createHandle(LEFT_BOTTOM);
	private const _handleMiddleBottom:Sprite  = createHandle(MIDDLE_BOTTOM);
	private const _handleRightBottom:Sprite   = createHandle(RIGHT_BOTTOM);
	private const _handleLeftMiddle:Sprite    = createHandle(LEFT_MIDDLE);

	private var _dragHandleName:String;
	
	public function ResizeableControlPoints() {
		super();
		
		// handles
		addChild(_handleLeftTop);
		addChild(_handleMiddleTop);
		addChild(_handleRightTop);
		addChild(_handleRightMiddle);
		addChild(_handleLeftBottom);
		addChild(_handleMiddleBottom);
		addChild(_handleRightBottom);
		addChild(_handleLeftMiddle);
	}
	
	override public function set target(t:Object):void {
		endResize();
		super.target = t;
	}
	
	override public function redraw():void {
		if (!_target) return;
		
		super.redraw();
		
		const r:Rectangle = _lastTargetBounds;
		const leftX:Number = r.x - HANDLE_OFFSET;
		const middleX:Number = r.x + r.width/2 - HANDLE_OFFSET;
		const rightX:Number = r.right - HANDLE_OFFSET;
		const topY:Number = r.y - HANDLE_OFFSET;
		const middleY:Number = r.y + r.height/2 - HANDLE_OFFSET;
		const bottomY:Number = r.bottom - HANDLE_OFFSET;
		
		_handleLeftTop.x = leftX
		_handleLeftTop.y = topY;
		_handleMiddleTop.x = middleX;
		_handleMiddleTop.y = topY;
		_handleRightTop.x = rightX;
		_handleRightTop.y = topY;
		_handleRightMiddle.x = rightX;
		_handleRightMiddle.y = middleY;
		_handleLeftBottom.x = leftX;
		_handleLeftBottom.y = bottomY;
		_handleMiddleBottom.x = middleX;
		_handleMiddleBottom.y = bottomY;
		_handleRightBottom.x = rightX;
		_handleRightBottom.y = bottomY;
		_handleLeftMiddle.x = leftX;
		_handleLeftMiddle.y = middleY;
	}
	
	override protected function markStartingPosition():void {
		super.markStartingPosition();

		_targetToParent = new Matrix();
		_targetToParent.rotate(_initR*MathUtil.DEG_TO_RAD);
		_targetToParent.translate(_target.x, _target.y);
	}
	
	private static function drawRect(g:Graphics, w:int, h:int):void {
		g.lineStyle(0);
		g.lineTo(w, 0);
		g.lineTo(w, h);
		g.lineTo(0, h);
		g.lineTo(0, 0);
	}
	
	private function createHandle(name:String):Sprite {
		const _handle:Sprite = new Sprite();
		_handle.name = name;
		_handle.addEventListener(MouseEvent.MOUSE_DOWN, startResize);
		_handle.buttonMode = true;
		_handle.useHandCursor = true;
		_handle.graphics.beginFill(0);
		drawRect(_handle.graphics, HANDLE_WIDTH, HANDLE_WIDTH);
		return _handle;
	}
	
	public function startResizeFromHandleName(name:String):void {
		_dragHandleName = name;
		startResizeHelper();
	}
	
	private function startResize(e:MouseEvent):void {
		_dragHandleName = e.target.name;
		startResizeHelper();
	}
	
	private function startResizeHelper():void {
		markStartingPosition();
		
		StageBeacon.game_loop_sig.add(onEnterFrame);
		StageBeacon.mouse_up_sig.add(onMouseUp);
		
		const cpe:ControlPointEvent = new ControlPointEvent(ControlPointEvent.START_RESIZE, this);
		cpe.resizeHandleName = _dragHandleName;
		dispatchEvent(cpe);
	}
	
	private function onMouseUp(e:MouseEvent):void {
		endResize();
	}
	
	private function onEnterFrame(ms_elapsed:int):void {
		resize();
	}
	
	private function resize():void {
		// transform the drag points into the (rotated) _target coordinate space
		const rotatedStartPt:Point = _target.globalToLocal(new Point(_initMouseXInTargetSpace, _initMouseYInTargetSpace));
		const rotatedEndPt:Point = _target.globalToLocal(mouseCoordinatesInTargetSpace);
		
		const xDelta:int = (target.h_flip ? -1 : 1) * (rotatedEndPt.x - rotatedStartPt.x);
		const yDelta:int = (rotatedEndPt.y - rotatedStartPt.y);
		
		// newPosition should be in _target coordinate space
		var newPosition:Point = new Point();
		switch (_dragHandleName) {
			case LEFT_MIDDLE:
				_target.w = Math.max(DecoModel.MIN_DIMS, (_initW - xDelta));
				newPosition.x = Math.min(_initW/2, xDelta/2);
				break;
			case RIGHT_MIDDLE:
				_target.w = Math.max(DecoModel.MIN_DIMS, (_initW + xDelta));
				newPosition.x = Math.max(-(_initW/2), xDelta/2);
				break;
			case MIDDLE_TOP:
				_target.h = Math.max(DecoModel.MIN_DIMS, (_initH - yDelta));
				break;
			case MIDDLE_BOTTOM:
				_target.h = Math.max(DecoModel.MIN_DIMS, (_initH + yDelta));
				newPosition.y = Math.max(-(_initH), yDelta);
				break;
			case LEFT_TOP:
				_target.w = Math.max(DecoModel.MIN_DIMS, (_initW - xDelta));
				_target.h = Math.max(DecoModel.MIN_DIMS, (_initH - yDelta));
				newPosition.x = Math.min(_initW/2, xDelta/2);
				break;
			case RIGHT_TOP:
				_target.w = Math.max(DecoModel.MIN_DIMS, (_initW + xDelta));
				_target.h = Math.max(DecoModel.MIN_DIMS, (_initH - yDelta));
				newPosition.x = Math.max(-(_initW/2), xDelta/2);
				break;
			case LEFT_BOTTOM:
				_target.w = Math.max(DecoModel.MIN_DIMS, (_initW - xDelta));
				_target.h = Math.max(DecoModel.MIN_DIMS, (_initH + yDelta));
				newPosition.x = Math.min(_initW/2, xDelta/2)
				newPosition.y = Math.max(-(_initH), yDelta);
				break;
			case RIGHT_BOTTOM:
				_target.w = Math.max(DecoModel.MIN_DIMS, (_initW + xDelta));
				_target.h = Math.max(DecoModel.MIN_DIMS, (_initH + yDelta));
				newPosition.x = Math.max(-(_initW/2), xDelta/2);
				newPosition.y = Math.max(-(_initH), yDelta);
				break;
		}
		
		// constrain proportions
		if (KeyBeacon.instance.pressed(Keyboard.SHIFT)) {
			_target.h = Math.max(DecoModel.MIN_DIMS, Math.round(_initH * (_target.w / _initW)));
			switch (_dragHandleName) {
				case LEFT_BOTTOM:
				case RIGHT_BOTTOM:
					newPosition.y = Math.max(-(_initH), _target.h - _initH);
					break;
			}
		}
		
		// transform new _target coordinates to _target.parent and set!
		newPosition = _targetToParent.transformPoint(newPosition);
		_target.x = newPosition.x;
		_target.y = newPosition.y;
		
		redraw();
	}
	
	private function endResize():void {
		StageBeacon.game_loop_sig.remove(onEnterFrame);
		StageBeacon.mouse_up_sig.remove(onMouseUp);
		redraw();
	}
}
}
