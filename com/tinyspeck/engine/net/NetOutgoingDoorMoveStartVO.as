package com.tinyspeck.engine.net
{
	public class NetOutgoingDoorMoveStartVO extends NetOutgoingMessageVO
	{
		
		public var from_door_tsid:String;
		
		public function NetOutgoingDoorMoveStartVO(from_door_tsid:String)
		{
			super(MessageTypes.DOOR_MOVE_START);
			this.from_door_tsid = from_door_tsid;
		}
	}
}