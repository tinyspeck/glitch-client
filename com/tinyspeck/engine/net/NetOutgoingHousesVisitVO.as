package com.tinyspeck.engine.net {
	public class NetOutgoingHousesVisitVO extends NetOutgoingMessageVO {
		
		public var player_tsid:String;
		
		public function NetOutgoingHousesVisitVO(player_tsid:String) 
		{
			super(MessageTypes.HOUSES_VISIT);
			this.player_tsid = player_tsid;
		}
	}
}