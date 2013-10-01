package com.tinyspeck.engine.net {
	public class NetOutgoingGroupsChatJoinVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		
		public function NetOutgoingGroupsChatJoinVO(tsid:String) {
			super(MessageTypes.GROUPS_CHAT_JOIN);
			this.tsid = tsid;
		}
	}
}