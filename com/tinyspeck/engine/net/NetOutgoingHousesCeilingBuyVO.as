package com.tinyspeck.engine.net {
	public class NetOutgoingHousesCeilingBuyVO extends NetOutgoingMessageVO {
		
		public var ceiling_type:String;
		
		public function NetOutgoingHousesCeilingBuyVO(ceiling_type:String) {
			super(MessageTypes.HOUSES_CEILING_BUY);
			
			this.ceiling_type = ceiling_type;
		}
	}
}