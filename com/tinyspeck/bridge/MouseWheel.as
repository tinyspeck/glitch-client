package com.tinyspeck.bridge
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	
	import flash.display.InteractiveObject;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;

	/**
	 * Based on Gabriel Bucknall's AS3 MacMouseWheel class,
	 * but supports multidirectional mouse wheeling.
	 * 
	 * Requires javascript class macmousewheel.js
	 */
	public class MouseWheel
	{
		public static const instance:MouseWheel = new MouseWheel();
		
		private var _currItem:InteractiveObject;
		private var _clonedEvent:MouseEvent;

		public function init():void {
			StageBeacon.mouse_move_sig.add(_getItemUnderCursor);
			
			if(ExternalInterface.available) {
				ExternalInterface.addCallback('externalMouseEvent', _externalMouseEvent);
			}
		}
		
		private function _getItemUnderCursor(e:MouseEvent):void {
			_currItem = InteractiveObject(e.target);
			_clonedEvent = MouseEvent(e);
		}

		// Webkit may give you TWO non-zero values as it allows simultaneous scrolling
		private function _externalMouseEvent(xDelta:Number, yDelta:Number):void
		{
			if (!_clonedEvent) {
				CONFIG::debugging {
					Console.warn('no _clonedEvent in MacMouseWheel wtf');
				}
				return;
			}
			var wheelEvent:MouseEvent = new MouseEvent( 
					MouseEvent.MOUSE_WHEEL, 
					true, 
					false, 
					_clonedEvent.localX, 
					_clonedEvent.localY, 
					_clonedEvent.relatedObject, 
					_clonedEvent.ctrlKey, 
					_clonedEvent.altKey, 
					_clonedEvent.shiftKey, 
					_clonedEvent.buttonDown, 
					int(yDelta)
				);
			_currItem.dispatchEvent(wheelEvent);
			
			wheelEvent = new CartesianMouseEvent( 
				CartesianMouseEvent.CARTESIAN_MOUSE_WHEEL, 
				true, 
				false, 
				_clonedEvent.localX, 
				_clonedEvent.localY, 
				_clonedEvent.relatedObject, 
				_clonedEvent.ctrlKey, 
				_clonedEvent.altKey, 
				_clonedEvent.shiftKey, 
				_clonedEvent.buttonDown, 
				int(yDelta),
				int(xDelta),
				int(yDelta)
			);
			_currItem.dispatchEvent(wheelEvent);
		}
	}
}
