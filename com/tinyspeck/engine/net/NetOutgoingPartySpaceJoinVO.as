package com.tinyspeck.engine.net {
	public class NetOutgoingPartySpaceJoinVO extends NetOutgoingMessageVO {
		public function NetOutgoingPartySpaceJoinVO() {
			super(MessageTypes.PARTY_SPACE_JOIN);
		}
	}
}