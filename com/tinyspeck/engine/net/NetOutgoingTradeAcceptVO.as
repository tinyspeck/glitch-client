package com.tinyspeck.engine.net {
	public class NetOutgoingTradeAcceptVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		
		public function NetOutgoingTradeAcceptVO(player_tsid:String) {
			super(MessageTypes.TRADE_ACCEPT);
			
			this.tsid = player_tsid;
		}
	}
}