package com.tinyspeck.engine.net
{
	public class NetOutgoingStoreSellVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var sellstack_tsid:String;
		public var sellstack_class:String;
		public var verb:String;
		public var count:int;
		
		public function NetOutgoingStoreSellVO(itemstack_tsid:String, verb:String, sellstack_tsid:String, sellstack_class:String, count:int)
		{
			super(MessageTypes.STORE_SELL);
			this.itemstack_tsid = itemstack_tsid;
			this.verb = verb;
			this.sellstack_tsid = sellstack_tsid;
			this.sellstack_class = sellstack_class;
			this.count = count;
		}
	}
}

/*

{
	type: 'store_sell',
	itemstack_tsid: current_ob.item_tsid,
		verb: current_ob.verb,
			sellstack_tsid: itemstack_tsid,
	count: x
}
*/