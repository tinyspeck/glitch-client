package com.tinyspeck.engine.net {
	public class NetOutgoingHousesAddNeighborVO extends NetOutgoingMessageVO {
		
		public var neighbor:String;
		public var position:int;
		
		public function NetOutgoingHousesAddNeighborVO(sign_id:int, pc_tsid:String) 
		{
			super(MessageTypes.HOUSES_ADD_NEIGHBOR);
			this.position = sign_id;
			this.neighbor = pc_tsid;
		}
	}
}