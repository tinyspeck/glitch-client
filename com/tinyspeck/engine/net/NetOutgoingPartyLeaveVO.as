package com.tinyspeck.engine.net {
	public class NetOutgoingPartyLeaveVO extends NetOutgoingMessageVO
	{
		
		public var pc_tsid:String;
		
		public function NetOutgoingPartyLeaveVO()
		{
			super(MessageTypes.PARTY_LEAVE);
		}
	}
}