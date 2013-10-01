package com.tinyspeck.engine.net
{
	public class NetOutgoingPartyChatVO extends NetOutgoingMessageVO
	{
		public var txt:String;
		public function NetOutgoingPartyChatVO(txt:String)
		{
			super(MessageTypes.PARTY_CHAT);
			this.txt = txt;
		}
	}
}