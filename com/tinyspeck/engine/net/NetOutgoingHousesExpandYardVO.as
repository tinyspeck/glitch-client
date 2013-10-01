package com.tinyspeck.engine.net {
	public class NetOutgoingHousesExpandYardVO extends NetOutgoingMessageVO {
		
		public var side:String;
		
		public function NetOutgoingHousesExpandYardVO(side:String) {
			super(MessageTypes.HOUSES_EXPAND_YARD);
			this.side = side;
		}
	}
}