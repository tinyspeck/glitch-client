package com.tinyspeck.engine.net {
	public class NetOutgoingItemstackMouseOverVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		
		public function NetOutgoingItemstackMouseOverVO(itemstack_tsid:String = '') {
			super(MessageTypes.ITEMSTACK_MOUSE_OVER);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}