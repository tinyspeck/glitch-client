package com.tinyspeck.engine.util.geom
{
	public class Range {
		/** Inclusive */
		public var x1:int;
		/** Inclusive */
		public var x2:int;
		
		public function Range(x1:int, x2:int) {
			this.x1 = x1;
			this.x2 = x2;
		}
		
		public function toString():String {
			return '[x1:'+x1+', x2:'+x2+']';
		}
		
		public function clone():Range {
			return new Range(x1, x2);
		}
	}
}