package com.tinyspeck.engine.net
{
	public class NetOutgoingPcVerbMenuVO extends NetOutgoingMessageVO
	{
		public var pc_tsid:String;
		
		public function NetOutgoingPcVerbMenuVO(pc_tsid:String)
		{
			super(MessageTypes.PC_VERB_MENU);
			this.pc_tsid = pc_tsid;
		}
	}
}