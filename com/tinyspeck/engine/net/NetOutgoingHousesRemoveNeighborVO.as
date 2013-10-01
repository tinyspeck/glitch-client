package com.tinyspeck.engine.net {
	public class NetOutgoingHousesRemoveNeighborVO extends NetOutgoingMessageVO {
		
		public var position:int;
		
		public function NetOutgoingHousesRemoveNeighborVO(sign_id:int) 
		{
			super(MessageTypes.HOUSES_REMOVE_NEIGHBOR);
			this.position = sign_id;
		}
	}
}