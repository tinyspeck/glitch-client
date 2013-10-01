package com.tinyspeck.engine.util.geom {
	import flash.geom.Rectangle;

	public class Line {
		public var x1:Number;
		public var y1:Number;
		public var x2:Number;
		public var y2:Number;
		
		public function Line(x1:Number, y1:Number, x2:Number, y2:Number) {
			this.x1 = x1;
			this.y1 = y1;
			this.x2 = x2;
			this.y2 = y2;
		}
		
		public function clip(rect:Rectangle):Line {
			LineClip.cohenSutherland(this, rect);
			return this;
		}
		
		public function clone():Line {
			return new Line(x1, y1, x2, y2);
		}
		
		public function toString():String {
			return x1+" "+y1+" "+x2+" "+y2;
		}
		
		public function equals(other:Line):Boolean {
			return (x1 == other.x1 && y1 == other.y1 && x2 == other.x2 && y2 == other.y2);
		}
	}
}