package com.tinyspeck.engine.net
{
	public class NetOutgoingStoreBuyVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var class_tsid:String;
		public var verb:String;
		public var count:int;
		public var price:int;
		
		public function NetOutgoingStoreBuyVO(itemstack_tsid:String, verb:String, class_tsid:String, count:int, price:int)
		{
			super(MessageTypes.STORE_BUY);
			this.itemstack_tsid = itemstack_tsid;
			this.verb = verb;
			this.class_tsid = class_tsid;
			this.count = count;
			this.price = price;
		}
	}
}

/*
{
	type: 'store_buy',
	itemstack_tsid: current_ob.item_tsid,
		verb: current_ob.verb,
			class_tsid: item_class,
	count: x
}
*/