package com.tinyspeck.engine.net
{
	public class NetOutgoingConversationChoiceVO extends NetOutgoingMessageVO
	{
		
		public var itemstack_tsid:String;
		public var choice:String;
		public var uid:String;
		
		public function NetOutgoingConversationChoiceVO(itemstack_tsid:String, choice:String, uid:String)
		{
			super(MessageTypes.CONVERSATION_CHOICE);
			this.itemstack_tsid = itemstack_tsid;
			this.choice = choice;
			this.uid = uid;
		}
	}
}