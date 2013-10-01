package com.tinyspeck.engine.net {
	public class NetOutgoingTeleportationMapVO extends NetOutgoingMessageVO {
		
		public var loc_tsid:String;
		public var is_token:Boolean;
		
		public function NetOutgoingTeleportationMapVO(location_tsid:String, is_token:Boolean) {
			super(MessageTypes.TELEPORTATION_MAP);
			this.loc_tsid = location_tsid;
			this.is_token = is_token;
		}
	}
}