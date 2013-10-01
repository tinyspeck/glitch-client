package com.tinyspeck.engine.net {
	public class NetOutgoingLocationMoveVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var from_path_tsid:String;
		public var to_path_tsid:String;
		public var to_slot:*;
		/*public var count:int;*/ // not in use

		public function NetOutgoingLocationMoveVO(itemstack_tsid:String, from_path_tsid:String, to_path_tsid:String, to_slot:* = null) {
			super(MessageTypes.LOCATION_MOVE);
			this.itemstack_tsid = itemstack_tsid;
			this.from_path_tsid = from_path_tsid;
			this.to_path_tsid = to_path_tsid;
			this.to_slot = to_slot;
		}
	}
}