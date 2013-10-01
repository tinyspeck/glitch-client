package com.tinyspeck.engine.net
{
	

	public class NetOutgoingItemstackVerbVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var verb:String;
		public var count:int;
		public var target_itemstack_tsid:String;
		public var target_item_class:String;
		public var target_item_class_count:*;
		public var object_pc_tsid:String;
		public var destination_tsid:String; // used for pick_up only right now, to place a picked up item directly into a container
		public var destination_slot:*; // used for pick_up only right now, to place a picked up item directly into a container slot
		public var drop_x:*;
		public var drop_y:*;
		public var no_merge:*;
		public var check_for_proximity:Boolean;
		
		public function NetOutgoingItemstackVerbVO(
			
			itemstack_tsid:String,
			verb:String,
			count:int,
			target_itemstack_tsid:String='',
			target_item_class:String='',
			object_pc_tsid:String='',
			destination_tsid:String='',
			destination_slot:* = null,
			target_item_class_count:* = null,
			drop_x:* = null,
			drop_y:* = null,
			no_merge:Boolean=false
		){
			super(MessageTypes.ITEMSTACK_VERB);
			this.itemstack_tsid = itemstack_tsid;
			this.verb = verb;
			this.count = count;
			this.target_itemstack_tsid = target_itemstack_tsid;
			this.target_item_class = target_item_class;
			this.object_pc_tsid = object_pc_tsid;
			this.destination_tsid = destination_tsid;
			this.destination_slot = destination_slot;
			this.target_item_class_count = target_item_class_count;
			this.drop_x = drop_x;
			this.drop_y = drop_y;
			if (no_merge) this.no_merge = true;
		}
	}
}
