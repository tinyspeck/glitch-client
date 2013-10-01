package com.tinyspeck.engine.net {
	public class NetOutgoingHousesFloorBuyVO extends NetOutgoingMessageVO {
		
		public var floor_type:String;
		
		public function NetOutgoingHousesFloorBuyVO(floor_type:String) {
			super(MessageTypes.HOUSES_FLOOR_BUY);
			
			this.floor_type = floor_type;
		}
	}
}