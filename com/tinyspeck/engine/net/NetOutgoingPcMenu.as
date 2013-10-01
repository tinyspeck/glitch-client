package com.tinyspeck.engine.net
{
	public class NetOutgoingPcMenu extends NetOutgoingMessageVO
	{
		public var target_tsid:String;
		public var command:String;
		
		public function NetOutgoingPcMenu(target_tsid:String, command:String)
		{
			super(MessageTypes.PC_MENU);
			this.target_tsid = target_tsid;
			this.command = command;
		}
	}
}