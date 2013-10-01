package com.tinyspeck.engine.net {
	public class NetOutgoingHousesWallBuyVO extends NetOutgoingMessageVO {
		
		public var wp_type:String;
		
		public function NetOutgoingHousesWallBuyVO(wp_type:String) {
			super(MessageTypes.HOUSES_WALL_BUY);
			
			this.wp_type = wp_type;
		}
	}
}