package com.tinyspeck.engine.net {
	public class NetOutgoingHousesStyleSwitchVO extends NetOutgoingMessageVO {
		
		public var style_id:String;
		
		public function NetOutgoingHousesStyleSwitchVO(tsid:String) {
			super(MessageTypes.HOUSES_STYLE_SWITCH);
			this.style_id = tsid;
		}
	}
}