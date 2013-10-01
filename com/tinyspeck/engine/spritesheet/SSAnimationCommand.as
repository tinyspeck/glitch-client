package com.tinyspeck.engine.spritesheet {

	import de.polygonal.core.IPoolableObject;

	public class SSAnimationCommand implements IPoolableObject {
		
		public var state_ob:Object;
		public var config:Object;
		public var scale:Number = 1;

		public static function resetInstance(obj:SSAnimationCommand):void {
			obj.reset();
		}
		
		public function get state_str():String {
			if (state_ob && typeof state_ob != 'object') return String(state_ob);
			return '';
		}
		
		public function get state_args():Object {
			if (state_ob && typeof state_ob == 'object') return state_ob;
			return null;
		}

		// IPoolableObject
		public function reset():void {
			state_ob = null;
			config = null;
			scale = 1;
		}
	}
}