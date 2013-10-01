package com.tinyspeck.engine.net
{
	public class NetOutgoingMailCostVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var count:int;
		public var currants:int;
		
		public function NetOutgoingMailCostVO(itemstack_tsid:String, count:int, currants:int)
		{
			super(MessageTypes.MAIL_COST);
			this.itemstack_tsid = itemstack_tsid;
			this.count = count;
			this.currants = currants;
		}
	}
}