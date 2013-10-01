package com.tinyspeck.engine.net
{
	public class NetOutgoingMailArchiveVO extends NetOutgoingMessageVO
	{
		public var message_ids:Array;
		
		public function NetOutgoingMailArchiveVO(message_ids:Array)
		{
			super(MessageTypes.MAIL_ARCHIVE);
			this.message_ids = message_ids;
		}
	}
}