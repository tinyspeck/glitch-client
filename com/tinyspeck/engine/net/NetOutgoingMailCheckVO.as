package com.tinyspeck.engine.net
{
	public class NetOutgoingMailCheckVO extends NetOutgoingMessageVO
	{		
		public function NetOutgoingMailCheckVO()
		{
			super(MessageTypes.MAIL_CHECK);
		}
	}
}