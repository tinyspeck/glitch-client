package com.tinyspeck.engine.net {
	public class NetOutgoingBuddyAddVO extends NetOutgoingMessageVO
	{
		
		public var pc_tsid:String;
		public var group_id:String;
		
		public function NetOutgoingBuddyAddVO(pc_tsid:String, group_id:String)
		{
			super(MessageTypes.BUDDY_ADD);
			this.pc_tsid = pc_tsid;
			this.group_id = group_id;
		}
	}
}