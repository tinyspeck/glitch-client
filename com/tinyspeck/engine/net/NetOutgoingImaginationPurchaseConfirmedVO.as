package com.tinyspeck.engine.net {
	public class NetOutgoingImaginationPurchaseConfirmedVO extends NetOutgoingMessageVO {
		
		public var imagination_id:String;
		
		public function NetOutgoingImaginationPurchaseConfirmedVO(card_class_tsid:String) 
		{
			super(MessageTypes.IMAGINATION_PURCHASE_CONFIRMED);
			this.imagination_id = card_class_tsid;
		}
	}
}