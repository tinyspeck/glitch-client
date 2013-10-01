package com.tinyspeck.engine.net {
	public class NetOutgoingCraftybotPauseVO extends NetOutgoingMessageVO {
		
		public var is_pause:Boolean;
		public var item_class:String;
		
		public function NetOutgoingCraftybotPauseVO(is_pause:Boolean, item_class:String) 
		{
			super(MessageTypes.CRAFTYBOT_PAUSE);
			this.is_pause = is_pause;
			this.item_class = item_class;
		}
	}
}