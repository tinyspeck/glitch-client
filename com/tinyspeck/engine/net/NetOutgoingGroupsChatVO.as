package com.tinyspeck.engine.net {
	public class NetOutgoingGroupsChatVO extends NetOutgoingMessageVO {
		public var tsid:String;
		public var txt:String;
		
		public function NetOutgoingGroupsChatVO(tsid:String, txt:String) {
			super(MessageTypes.GROUPS_CHAT);
			this.tsid = tsid;
			this.txt = txt;
		}
	}
}