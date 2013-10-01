package com.tinyspeck.engine.net {
	public class NetOutgoingEmblemSpendVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		
		public function NetOutgoingEmblemSpendVO(itemstack_tsid:String) {
			super(MessageTypes.EMBLEM_SPEND);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}