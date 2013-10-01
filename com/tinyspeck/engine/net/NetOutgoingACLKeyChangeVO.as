package com.tinyspeck.engine.net {
	public class NetOutgoingACLKeyChangeVO extends NetOutgoingMessageVO {
		
		public var pc_tsid:String;
		public var is_grant:Boolean;
		
		public function NetOutgoingACLKeyChangeVO(pc_tsid:String, is_grant:Boolean) 
		{
			super(MessageTypes.ACL_KEY_CHANGE);
			this.pc_tsid = pc_tsid;
			this.is_grant = is_grant;
		}
	}
}