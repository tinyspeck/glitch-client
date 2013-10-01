package com.tinyspeck.engine.net {
	public class NetOutgoingLocationDragTargets extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		
		public function NetOutgoingLocationDragTargets(itemstack_tsid:String) {
			super(MessageTypes.LOCATION_DRAG_TARGETS);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}