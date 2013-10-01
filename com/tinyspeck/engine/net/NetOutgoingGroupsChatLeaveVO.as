package com.tinyspeck.engine.net {
	public class NetOutgoingGroupsChatLeaveVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		
		public function NetOutgoingGroupsChatLeaveVO(tsid:String) {
			super(MessageTypes.GROUPS_CHAT_LEAVE);
			this.tsid = tsid;
		}
	}
}