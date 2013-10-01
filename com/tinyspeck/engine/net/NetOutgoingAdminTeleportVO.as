package com.tinyspeck.engine.net {
	public class NetOutgoingAdminTeleportVO extends NetOutgoingMessageVO
	{
		public var loc_tsid:String;
		
		public function NetOutgoingAdminTeleportVO(loc_tsid:String)
		{
			super(MessageTypes.ADMIN_TELEPORT);
			this.loc_tsid = loc_tsid;
		}
	}
}