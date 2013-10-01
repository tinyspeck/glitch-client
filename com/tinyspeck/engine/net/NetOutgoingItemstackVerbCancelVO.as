package com.tinyspeck.engine.net
{
	public class NetOutgoingItemstackVerbCancelVO extends NetOutgoingMessageVO
	{
		
		public var itemstack_tsid:String;
		
		public function NetOutgoingItemstackVerbCancelVO(itemstack_tsid:String)
		{
			super(MessageTypes.ITEMSTACK_VERB_CANCEL);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}