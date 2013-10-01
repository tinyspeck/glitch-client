package com.tinyspeck.engine.net {
	public class NetOutgoingShrineSpendVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		
		public function NetOutgoingShrineSpendVO(itemstack_tsid:String) {
			super(MessageTypes.SHRINE_SPEND);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}