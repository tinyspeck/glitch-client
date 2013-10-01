package com.tinyspeck.engine.net
{
	public class NetOutgoingConversationCancelVO extends NetOutgoingMessageVO
	{
		
		public var itemstack_tsid:String;
		public var uid:String;
		
		public function NetOutgoingConversationCancelVO(itemstack_tsid:String, uid:String)
		{
			super(MessageTypes.CONVERSATION_CANCEL);
			this.itemstack_tsid = itemstack_tsid;
			this.uid = uid;
		}
	}
}