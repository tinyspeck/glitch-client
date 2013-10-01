package com.tinyspeck.engine.data.location {
	
	public class AbstractPositionableLocationEntity extends AbstractLocationEntity {
		private var _x:int;
		private var _y:int;
		
		public function AbstractPositionableLocationEntity(hashName:String) {
			super(hashName);
		}
		
		public function get x():int {
			return _x;
		}

		public function set x(value:int):void {
			_x = value;
		}

		public function get y():int {
			return _y;
		}

		public function set y(value:int):void {
			_y = value;
		}

		override public function AMF():Object {
			const ob:Object = super.AMF();
			ob.x = x;
			ob.y = y;
			return ob;
		}
	}
}