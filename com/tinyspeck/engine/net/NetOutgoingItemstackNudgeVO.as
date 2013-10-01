package com.tinyspeck.engine.net
{
	public class NetOutgoingItemstackNudgeVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var x:int;
		public var y:int;
		
		public function NetOutgoingItemstackNudgeVO(itemstack_tsid:String, x:int, y:int) {
			super(MessageTypes.ITEMSTACK_NUDGE);
			this.itemstack_tsid = itemstack_tsid;
			this.x = x;
			this.y = y;
		}
	}
}