package com.tinyspeck.bridge
{
import flash.display.InteractiveObject;
import flash.events.MouseEvent;

/** Supports mouse movement in two directions at the same time */
public class CartesianMouseEvent extends MouseEvent
{
	public static const CARTESIAN_MOUSE_WHEEL:String = "cartesianMouseWheel";
	
	public var xDelta:Number;
	public var yDelta:Number;
	
	public function CartesianMouseEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false, localX:Number=0, localY:Number=0, relatedObject:InteractiveObject=null, ctrlKey:Boolean=false, altKey:Boolean=false, shiftKey:Boolean=false, buttonDown:Boolean=false, delta:int=0, xDelta:int=0, yDelta:int=0) {
		super(type, bubbles, cancelable, localX, localY, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta);
		this.xDelta = xDelta;
		this.yDelta = yDelta;
	}
}
}