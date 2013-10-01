package com.tinyspeck.engine.net {
	public class NetOutgoingMoveVecVO extends NetOutgoingMessageVO {
		public var vx:Number;
		public var vy:Number;
		public var s:String;
		
		public function NetOutgoingMoveVecVO() {
			super(MessageTypes.MOVE_VEC);
		}
	}
}