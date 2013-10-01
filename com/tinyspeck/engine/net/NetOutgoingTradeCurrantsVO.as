package com.tinyspeck.engine.net {
	public class NetOutgoingTradeCurrantsVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		public var amount:int;
		
		public function NetOutgoingTradeCurrantsVO(player_tsid:String, amount:int) {
			super(MessageTypes.TRADE_CURRANTS);
			
			this.tsid = player_tsid;
			this.amount = amount;
		}
	}
}