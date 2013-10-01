package com.tinyspeck.engine.net {
	public class NetOutgoingNoteCloseVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		
		public function NetOutgoingNoteCloseVO(itemstack_tsid:String) {
			super(MessageTypes.NOTE_CLOSE);
			
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}