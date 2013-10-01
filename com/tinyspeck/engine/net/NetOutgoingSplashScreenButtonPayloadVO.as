package com.tinyspeck.engine.net
{
	public class NetOutgoingSplashScreenButtonPayloadVO extends NetOutgoingMessageVO
	{
		public var click_payload:Object;
		
		public function NetOutgoingSplashScreenButtonPayloadVO(click_payload:Object)
		{
			super(MessageTypes.SPLASH_SCREEN_BUTTON_PAYLOAD);
			this.click_payload = click_payload;
		}
	}
}