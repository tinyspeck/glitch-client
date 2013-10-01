package com.tinyspeck.engine.net {
	public class NetOutgoingPartySpaceResponseVO extends NetOutgoingMessageVO {
		
		public var spend_energy:Boolean;
		public var spend_token:Boolean;
		
		public function NetOutgoingPartySpaceResponseVO(spend_energy:Boolean, spend_token:Boolean) {
			super(MessageTypes.PARTY_SPACE_RESPONSE);
			this.spend_energy = spend_energy;
			this.spend_token = spend_token;
		}
	}
}