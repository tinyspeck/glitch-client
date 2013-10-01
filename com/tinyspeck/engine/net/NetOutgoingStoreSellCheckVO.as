package com.tinyspeck.engine.net {
	public class NetOutgoingStoreSellCheckVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var sellstack_tsid:String;
		public var sellstack_class:String;
		public var verb:String;
		
		public function NetOutgoingStoreSellCheckVO(store_tsid:String, verb:String, sellstack_tsid:String, sellstack_class:String) {
			super(MessageTypes.STORE_SELL_CHECK);
			this.itemstack_tsid = store_tsid;
			this.verb = verb;
			this.sellstack_tsid = sellstack_tsid;
			this.sellstack_class = sellstack_class;
		}
	}
}

/*


req from client:

{
	type: "store_sell_check",
	msg_id:1,
	itemstack_tsid: {tsid-of-store-item},
	sellstack_class: {item class of stack to sell}
}
		
rsp:
		
{
	type: "store_sell_check",
	msg_id:1,
	success: true,
	itemstack_tsid: {tsid-of-store-item},
	sellstack_class: {item class of stack to sell},
	cost: {how many currants the store will give for the item}
}


*/