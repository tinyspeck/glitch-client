package com.tinyspeck.engine.net {
	public class NetOutgoingHousesFloorSetVO extends NetOutgoingMessageVO {
		
		public var floor_key:String;
		public var floor_type:String;
		
		public function NetOutgoingHousesFloorSetVO(floor_key:String, floor_type:String) {
			super(MessageTypes.HOUSES_FLOOR_SET);
			
			this.floor_key = floor_key;
			this.floor_type = floor_type;
		}
	}
}