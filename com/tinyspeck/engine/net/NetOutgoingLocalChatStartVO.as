package com.tinyspeck.engine.net {
	public class NetOutgoingLocalChatStartVO extends NetOutgoingMessageVO {
		
		public function NetOutgoingLocalChatStartVO() 
		{
			super(MessageTypes.LOCAL_CHAT_START);
		}
	}
}