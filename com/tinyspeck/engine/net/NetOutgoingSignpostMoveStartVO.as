package com.tinyspeck.engine.net
{
	public class NetOutgoingSignpostMoveStartVO extends NetOutgoingMessageVO
	{
		
		public var from_signpost_tsid:String;
		public var destination_index:String;
		
		public function NetOutgoingSignpostMoveStartVO(from_signpost_tsid:String, destination_index:String)
		{
			super(MessageTypes.SIGNPOST_MOVE_START);
			this.from_signpost_tsid = from_signpost_tsid;
			this.destination_index = destination_index;
		}
	}
}