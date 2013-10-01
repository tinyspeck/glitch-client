package com.tinyspeck.engine.net
{
	public class NetOutgoingCultivationPurchaseVO extends NetOutgoingMessageVO
	{
		public var class_id:String;
		public var x:int;
		public var y:int;
		
		public function NetOutgoingCultivationPurchaseVO(class_id:String, x:int, y:int) {
			super(MessageTypes.CULTIVATION_PURCHASE);
			this.class_id = class_id;
			this.x = x;
			this.y = y;
		}
	}
}