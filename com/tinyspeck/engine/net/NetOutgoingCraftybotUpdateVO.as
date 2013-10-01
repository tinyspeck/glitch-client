package com.tinyspeck.engine.net {
	public class NetOutgoingCraftybotUpdateVO extends NetOutgoingMessageVO {
		
		public function NetOutgoingCraftybotUpdateVO() 
		{
			super(MessageTypes.CRAFTYBOT_UPDATE);
		}
	}
}