package com.tinyspeck.engine.net
{
	public class NetOutgoingMailCancelVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		
		public function NetOutgoingMailCancelVO(itemstack_tsid:String)
		{
			super(MessageTypes.MAIL_CANCEL);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}