package com.tinyspeck.engine.net
{
	public class NetOutgoingReloginStartVO extends NetOutgoingMessageVO
	{
		public var relogin_type:String;
		CONFIG::perf public var perf_testing:Boolean;
		
		public function NetOutgoingReloginStartVO(relogin_type:String)
		{
			super(MessageTypes.RELOGIN_START);
			this.relogin_type = relogin_type;
		}
	}
}