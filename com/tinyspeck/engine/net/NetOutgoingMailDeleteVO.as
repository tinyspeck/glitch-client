package com.tinyspeck.engine.net
{
	public class NetOutgoingMailDeleteVO extends NetOutgoingMessageVO
	{
		public var message_ids:Array;
		
		public function NetOutgoingMailDeleteVO(message_ids:Array)
		{
			super(MessageTypes.MAIL_DELETE);
			this.message_ids = message_ids;
		}
	}
}