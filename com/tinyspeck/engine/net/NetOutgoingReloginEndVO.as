package com.tinyspeck.engine.net
{
	public class NetOutgoingReloginEndVO extends NetOutgoingMessageVO
	{
		public var relogin_type:String;
		
		public function NetOutgoingReloginEndVO(relogin_type:String)
		{
			super(MessageTypes.RELOGIN_END);
			this.relogin_type = relogin_type;
		}
	}
}