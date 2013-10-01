package com.tinyspeck.engine.net {
	public class NetOutgoingCraftybotAddVO extends NetOutgoingMessageVO {
		
		public var item_class:String;
		public var count:uint;
		
		public function NetOutgoingCraftybotAddVO(item_class:String, count:uint) 
		{
			super(MessageTypes.CRAFTYBOT_ADD);
			this.item_class = item_class;
			this.count = count;
		}
	}
}