package com.tinyspeck.engine.net
{
	public class NetOutgoingLogoutVO extends NetOutgoingMessageVO
	{
		public function NetOutgoingLogoutVO()
		{
			super(MessageTypes.LOGOUT);
		}
	}
}