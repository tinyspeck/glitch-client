package com.tinyspeck.engine.net
{
	public class NetOutgoingLocalChatVO extends NetOutgoingMessageVO
	{
		public var txt:String;
		public function NetOutgoingLocalChatVO(txt:String)
		{
			super(MessageTypes.LOCAL_CHAT);
			this.txt = txt;
		}
	}
}