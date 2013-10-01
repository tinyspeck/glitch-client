package com.tinyspeck.engine.net
{
	public class NetOutgoingMailReceiveVO extends NetOutgoingMessageVO
	{
		public var message_ids:Array;
		
		public function NetOutgoingMailReceiveVO(message_ids:Array)
		{
			super(MessageTypes.MAIL_RECEIVE);
			this.message_ids = message_ids;
		}
	}
}
