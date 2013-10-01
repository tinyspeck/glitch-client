package com.tinyspeck.engine.net {
	public class NetOutgoingBuddyRemoveVO extends NetOutgoingMessageVO
	{
		
		public var pc_tsid:String;
		public var group_id:String;
		
		public function NetOutgoingBuddyRemoveVO(pc_tsid:String, group_id:String)
		{
			super(MessageTypes.BUDDY_REMOVE);
			this.pc_tsid = pc_tsid;
			this.group_id = group_id;
		}
	}
}