package com.tinyspeck.engine.net
{
	public class NetOutgoingActionRequestCancelVO extends NetOutgoingMessageVO
	{
		public var event_type:String;
		public var event_tsid:String;
		
		public function NetOutgoingActionRequestCancelVO(event_type:String, event_tsid:String)
		{
			super(MessageTypes.ACTION_REQUEST_CANCEL);
			this.event_type = event_type;
			this.event_tsid = event_tsid;
		}
	}
}