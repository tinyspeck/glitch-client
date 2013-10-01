package com.tinyspeck.engine.net
{
	public class NetOutgoingCameraModeEndedVO extends NetOutgoingMessageVO
	{
		public function NetOutgoingCameraModeEndedVO()
		{
			super(MessageTypes.CAMERA_MODE_ENDED);
		}
	}
}