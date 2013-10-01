package com.tinyspeck.engine.net
{
	public class NetOutgoingDoorMoveEndVO extends NetOutgoingMessageVO
	{
		
		public var from_door_tsid:String;
		
		public function NetOutgoingDoorMoveEndVO(from_door_tsid:String)
		{
			super(MessageTypes.DOOR_MOVE_END);
			this.from_door_tsid = from_door_tsid;
		}
	}
}