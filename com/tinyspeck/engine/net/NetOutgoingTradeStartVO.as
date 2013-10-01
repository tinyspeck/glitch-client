package com.tinyspeck.engine.net {
	public class NetOutgoingTradeStartVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		
		public function NetOutgoingTradeStartVO(player_tsid:String) {
			super(MessageTypes.TRADE_START);
			
			this.tsid = player_tsid;
		}
	}
}