package com.tinyspeck.engine.net {
	public class NetOutgoingTeleportationSetVO extends NetOutgoingMessageVO {
		
		public var teleport_id:uint;
		
		public function NetOutgoingTeleportationSetVO(teleport_id:uint) {
			super(MessageTypes.TELEPORTATION_SET);
			this.teleport_id = teleport_id;
		}
	}
}