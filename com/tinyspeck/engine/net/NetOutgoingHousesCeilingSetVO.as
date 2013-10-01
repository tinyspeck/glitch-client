package com.tinyspeck.engine.net {
	public class NetOutgoingHousesCeilingSetVO extends NetOutgoingMessageVO {
		
		public var ceiling_key:String;
		public var ceiling_type:String;
		
		public function NetOutgoingHousesCeilingSetVO(ceiling_key:String, ceiling_type:String) {
			super(MessageTypes.HOUSES_CEILING_SET);
			
			this.ceiling_key = ceiling_key;
			this.ceiling_type = ceiling_type;
		}
	}
}