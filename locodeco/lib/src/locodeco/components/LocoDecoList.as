package locodeco.components
{
import flash.events.KeyboardEvent;

import mx.events.DragEvent;
import mx.managers.DragManager;

import spark.components.List;

/** Disables copy-dragging and keyboard on List */
public final class LocoDecoList extends List
{
	/** Convenience function */
	public function scrollToSelectedIndex():void {
		ensureIndexIsVisible(selectedIndex);
	}
	
	override protected function dragDropHandler(event:DragEvent):void {
		event.ctrlKey = false;
		event.action = DragManager.MOVE;
		super.dragDropHandler(event);
	}
	
	override protected function dragOverHandler(event:DragEvent):void {
		event.ctrlKey = false;
		super.dragOverHandler(event);
	}
	
	override protected function keyDownHandler(event:KeyboardEvent):void {
		//
	}
}
}