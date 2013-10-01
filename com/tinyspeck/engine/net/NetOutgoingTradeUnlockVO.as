package com.tinyspeck.engine.net {
	public class NetOutgoingTradeUnlockVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		
		public function NetOutgoingTradeUnlockVO(player_tsid:String) {
			super(MessageTypes.TRADE_UNLOCK);
			
			this.tsid = player_tsid;
		}
	}
}