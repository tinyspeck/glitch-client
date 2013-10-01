package com.tinyspeck.engine.net
{
	public class NetOutgoingLocationLockReleaseVO extends NetOutgoingMessageVO
	{
		
		public function NetOutgoingLocationLockReleaseVO()
		{
			super(MessageTypes.LOCATION_LOCK_RELEASE);
		}
	}
}