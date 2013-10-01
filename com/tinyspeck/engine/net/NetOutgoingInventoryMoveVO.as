package com.tinyspeck.engine.net {
	public class NetOutgoingInventoryMoveVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var from_path_tsid:String;
		public var to_path_tsid:String;
		public var to_slot:*;
		/*public var count:int;*/ // not in use

		public function NetOutgoingInventoryMoveVO(itemstack_tsid:String, from_path_tsid:String, to_path_tsid:String, to_slot:* = null) {
			super(MessageTypes.INVENTORY_MOVE);
			this.itemstack_tsid = itemstack_tsid;
			this.from_path_tsid = from_path_tsid;
			this.to_path_tsid = to_path_tsid;
			this.to_slot = to_slot;
		}
	}
}
/*{
	type: "inventory_move",
	from_path_tsid: "PM416KGKTEL94", // the path of the bag to move from
	from_slot: 1, // the slot to move from
	to_path_tsid: "PM416KGKTEL94", // the path of the bag to move to
	to_slot: 1, // the slot to move to
	count: 5, // optional number of the stack to store (otherwise all)
}
*/