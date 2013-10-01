package com.tinyspeck.engine.net {
	public class NetOutgoingTowerSetFloorNameVO extends NetOutgoingMessageVO {
		
		public var connect_id:String;
		public var custom_label:String;
		
		public function NetOutgoingTowerSetFloorNameVO(connect_id:String, custom_label:String) 
		{
			super(MessageTypes.TOWER_SET_FLOOR_NAME);
			this.connect_id = connect_id;
			this.custom_label = custom_label;
		}
	}
}