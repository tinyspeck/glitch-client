package com.tinyspeck.engine.net {
	public class NetOutgoingPerfTeleportVO extends NetOutgoingMessageVO
	{
		public var loc_tsid:String;
		
		public function NetOutgoingPerfTeleportVO(loc_tsid:String)
		{
			super(MessageTypes.PERF_TELEPORT);
			this.loc_tsid = loc_tsid;
		}
	}
}