package com.tinyspeck.engine.net {
	public class NetOutgoingFollowStartVO extends NetOutgoingMessageVO
	{
		
		public var pc_tsid:String;
		
		public function NetOutgoingFollowStartVO(pc_tsid:String)
		{
			super(MessageTypes.FOLLOW_START);
			this.pc_tsid = pc_tsid;
		}
	}
}