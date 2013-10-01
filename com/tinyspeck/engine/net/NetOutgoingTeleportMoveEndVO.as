package com.tinyspeck.engine.net {
	public class NetOutgoingTeleportMoveEndVO extends NetOutgoingMessageVO {
		
		public var from_location_tsid:String;
		public var to_location_tsid:String;
		
		public function NetOutgoingTeleportMoveEndVO(from_location_tsid:String, to_location_tsid:String) {
			super(MessageTypes.TELEPORT_MOVE_END);
			this.from_location_tsid = from_location_tsid;
			this.to_location_tsid = to_location_tsid;
		}
	}
}