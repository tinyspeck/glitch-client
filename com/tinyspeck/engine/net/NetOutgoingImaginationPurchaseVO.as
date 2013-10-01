package com.tinyspeck.engine.net {
	public class NetOutgoingImaginationPurchaseVO extends NetOutgoingMessageVO {
		
		public var imagination_id:int;
		
		public function NetOutgoingImaginationPurchaseVO(imagination_id:int) 
		{
			super(MessageTypes.IMAGINATION_PURCHASE);
			this.imagination_id = imagination_id;
		}
	}
}