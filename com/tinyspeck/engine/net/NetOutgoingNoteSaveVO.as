package com.tinyspeck.engine.net {
	public class NetOutgoingNoteSaveVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var body:String;
		public var title:String;
		
		public function NetOutgoingNoteSaveVO(itemstack_tsid:String, body:String, title:String) {
			super(MessageTypes.NOTE_SAVE);
			
			this.itemstack_tsid = itemstack_tsid;
			this.body = body;
			this.title = title;
		}
	}
}