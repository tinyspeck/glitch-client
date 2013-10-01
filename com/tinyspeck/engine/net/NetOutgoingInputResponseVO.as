package com.tinyspeck.engine.net {
	public class NetOutgoingInputResponseVO extends NetOutgoingMessageVO {
		
		public var uid:String;
		public var value:String;
		public var itemstack_tsid:String;
		
		public function NetOutgoingInputResponseVO(uid:String, value:String, itemstack_tsid:String) {
			super(MessageTypes.INPUT_RESPONSE);
			
			this.uid = uid;
			this.value = value;
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}