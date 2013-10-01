package com.tinyspeck.engine.net
{
	public class NetOutgoingLocationLockRequestVO extends NetOutgoingMessageVO
	{
		
		public function NetOutgoingLocationLockRequestVO()
		{
			super(MessageTypes.LOCATION_LOCK_REQUEST);
		}
	}
}