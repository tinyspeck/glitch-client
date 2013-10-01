package com.tinyspeck.engine.net
{
	public class NetOutgoingNudgeryStartVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		
		public function NetOutgoingNudgeryStartVO(itemstack_tsid:String) {
			super(MessageTypes.NUDGERY_START);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}