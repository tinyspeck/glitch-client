package com.tinyspeck.engine.net
{
	public class NetOutgoingMailReadVO extends NetOutgoingMessageVO
	{
		public var message_ids:Array;
		public var is_unread:Boolean;
		
		public function NetOutgoingMailReadVO(message_ids:Array, is_unread:Boolean)
		{
			super(MessageTypes.MAIL_READ);
			this.message_ids = message_ids;
			this.is_unread = is_unread;
		}
	}
}