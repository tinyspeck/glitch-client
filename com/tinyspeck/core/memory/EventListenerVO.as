package com.tinyspeck.core.memory
{
import de.polygonal.core.IPoolableObject;

	final public class EventListenerVO implements IDisposable, IPoolableObject
	{
		public var type:String;
		public var listener:Function;
		public var useCapture:Boolean;
		
		public function EventListenerVO()
		{
			this.type = type;
			this.listener = listener;
			this.useCapture = useCapture;
		}
		
		public static function resetInstance(obj:EventListenerVO):void {
			obj.reset();
		}
		
		public function dispose():void
		{
			type = null;
			listener = null;
			useCapture = false;
		}
		
		public function reset():void {
			dispose();
		}
		
		public function toString():String {
			return "EventListenerVO[type:" + type + ', useCapture:' + useCapture + ']';
		}
		
	}
}