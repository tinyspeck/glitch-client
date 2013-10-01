package com.tinyspeck.engine.net {
	public class NetOutgoingPartyInviteVO extends NetOutgoingMessageVO
	{
		
		public var pc_tsid:String;
		
		public function NetOutgoingPartyInviteVO(pc_tsid:String)
		{
			super(MessageTypes.PARTY_INVITE);
			this.pc_tsid = pc_tsid;
		}
	}
}