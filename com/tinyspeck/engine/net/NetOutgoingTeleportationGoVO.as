package com.tinyspeck.engine.net {
	public class NetOutgoingTeleportationGoVO extends NetOutgoingMessageVO {
		
		public var teleport_id:uint;
		
		public function NetOutgoingTeleportationGoVO(teleport_id:uint) {
			super(MessageTypes.TELEPORTATION_GO);
			this.teleport_id = teleport_id;
		}
	}
}