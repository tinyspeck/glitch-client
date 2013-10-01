package com.tinyspeck.engine.net {
	public class NetOutgoingTradeCancelVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		
		public function NetOutgoingTradeCancelVO(player_tsid:String) {
			super(MessageTypes.TRADE_CANCEL);
			
			this.tsid = player_tsid;
		}
	}
}