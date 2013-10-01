package com.tinyspeck.engine.net
{
	public class NetOutgoingNoticeBoardActionVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var note_itemstack_tsid:String;
		public var action:String;
		
		public function NetOutgoingNoticeBoardActionVO(itemstack_tsid:String, note_itemstack_tsid:String, action:String){
			super(MessageTypes.NOTICE_BOARD_ACTION);
			this.itemstack_tsid = itemstack_tsid;
			this.note_itemstack_tsid = note_itemstack_tsid;
			this.action = action;
		}
	}
}