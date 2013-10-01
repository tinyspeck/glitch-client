package com.tinyspeck.engine.net {
	public class NetOutgoingEmoteVO extends NetOutgoingMessageVO {
		
		public var emote:String;
		
		public function NetOutgoingEmoteVO(emote:String) 
		{
			super(MessageTypes.EMOTE);
			this.emote = emote;
		}
	}
}