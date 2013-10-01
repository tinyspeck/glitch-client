package com.tinyspeck.engine.net
{
	public class NetOutgoingLoginEndVO extends NetOutgoingMessageVO
	{
		public function NetOutgoingLoginEndVO()
		{
			super(MessageTypes.LOGIN_END);
		}
	}
}