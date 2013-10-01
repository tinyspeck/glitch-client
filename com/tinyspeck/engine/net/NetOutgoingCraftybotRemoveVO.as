package com.tinyspeck.engine.net {
	public class NetOutgoingCraftybotRemoveVO extends NetOutgoingMessageVO {
		
		public var item_class:String;
		public var count:uint;
		
		public function NetOutgoingCraftybotRemoveVO(item_class:String, count:uint) 
		{
			super(MessageTypes.CRAFTYBOT_REMOVE);
			this.item_class = item_class;
			this.count = count;
		}
	}
}