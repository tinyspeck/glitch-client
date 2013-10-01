package com.tinyspeck.engine.net {
	public class NetOutgoingInventoryDragTargetsVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		
		public function NetOutgoingInventoryDragTargetsVO(itemstack_tsid:String) {
			super(MessageTypes.INVENTORY_DRAG_TARGETS);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}