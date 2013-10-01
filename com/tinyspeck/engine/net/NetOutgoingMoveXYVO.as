package com.tinyspeck.engine.net
{
	public class NetOutgoingMoveXYVO extends NetOutgoingMessageVO
	{
		public var x:int;
		public var y:int;
		public var s:String;
		public var render:Array;
		public var script:Array;
		public var fps:int;
		public var is_jump:*; // we don't make it boolean because we want it not be sent to server at all if false, so we set it to null in that case
		
		public function NetOutgoingMoveXYVO(x:int, y:int, s:String)
		{
			super(MessageTypes.MOVE_XY);
			this.x = x;
			this.y = y;
			this.s = s;
		}
	}
}