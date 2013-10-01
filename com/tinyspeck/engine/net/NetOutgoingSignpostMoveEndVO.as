package com.tinyspeck.engine.net
{
	public class NetOutgoingSignpostMoveEndVO extends NetOutgoingMessageVO
	{
		
		public var from_signpost_tsid:String;
		public var destination_index:String;
		
		public function NetOutgoingSignpostMoveEndVO(from_signpost_tsid:String, destination_index:String)
		{
			super(MessageTypes.SIGNPOST_MOVE_END);
			this.from_signpost_tsid = from_signpost_tsid;
			this.destination_index = destination_index;
		}
	}
}