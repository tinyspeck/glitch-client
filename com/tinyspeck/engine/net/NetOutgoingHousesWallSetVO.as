package com.tinyspeck.engine.net {
	public class NetOutgoingHousesWallSetVO extends NetOutgoingMessageVO {
		
		public var wp_key:String;
		public var wp_type:String;
		
		public function NetOutgoingHousesWallSetVO(wp_key:String, wp_type:String) {
			super(MessageTypes.HOUSES_WALL_SET);
			
			this.wp_key = wp_key;
			this.wp_type = wp_type;
		}
	}
}