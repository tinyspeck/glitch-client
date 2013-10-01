package com.tinyspeck.engine.net
{
	public class NetOutgoingImSendVO extends NetOutgoingMessageVO
	{
		public var pc_tsid:String;
		public var txt:String;
		public var itemstack_tsid:String;
		
		public function NetOutgoingImSendVO(pc_tsid:String, txt:String, itemstack_tsid:String = null)
		{
			super(MessageTypes.IM_SEND);
			this.pc_tsid = pc_tsid;
			this.txt = txt;
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}