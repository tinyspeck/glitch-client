package com.tinyspeck.engine.net
{
	public class NetOutgoingCameraModeStartedVO extends NetOutgoingMessageVO
	{
		public function NetOutgoingCameraModeStartedVO()
		{
			super(MessageTypes.CAMERA_MODE_STARTED);
		}
	}
}