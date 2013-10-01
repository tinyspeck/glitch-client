package com.tinyspeck.engine.net
{
	public class NetOutgoingActionRequestReplyVO extends NetOutgoingMessageVO
	{
		public var event_type:String;
		public var player_tsid:String;
		public var event_tsid:String;
		
		public function NetOutgoingActionRequestReplyVO(player_tsid:String, event_type:String, event_tsid:String)
		{
			super(MessageTypes.ACTION_REQUEST_REPLY);
			this.player_tsid = player_tsid;
			this.event_type = event_type;
			this.event_tsid = event_tsid;
		}
	}
}