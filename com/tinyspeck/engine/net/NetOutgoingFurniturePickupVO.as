package com.tinyspeck.engine.net
{
	public class NetOutgoingFurniturePickupVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var x:int;
		public var y:int;
		
		public function NetOutgoingFurniturePickupVO(itemstack_tsid:String) {
			super(MessageTypes.FURNITURE_PICKUP);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}