package com.tinyspeck.engine.net {
	public class NetOutgoingCraftybotCostVO extends NetOutgoingMessageVO {
		
		public var item_class:String;
		public var count:uint;
		
		public function NetOutgoingCraftybotCostVO(item_class:String, count:uint) 
		{
			super(MessageTypes.CRAFTYBOT_COST);
			this.item_class = item_class;
			this.count = count;
		}
	}
}