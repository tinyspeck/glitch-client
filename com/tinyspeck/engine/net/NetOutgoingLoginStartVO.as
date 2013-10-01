package com.tinyspeck.engine.net
{
	public class NetOutgoingLoginStartVO extends NetOutgoingMessageVO
	{
		CONFIG::perf public var perf_testing:Boolean;
		
		public function NetOutgoingLoginStartVO()
		{
			super(MessageTypes.LOGIN_START);
		}
	}
}