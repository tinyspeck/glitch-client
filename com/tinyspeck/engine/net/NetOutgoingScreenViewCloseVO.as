package com.tinyspeck.engine.net
{
	public class NetOutgoingScreenViewCloseVO extends NetOutgoingMessageVO
	{
		public var close_payload:Object;
		
		public function NetOutgoingScreenViewCloseVO(close_payload:Object)
		{
			super(MessageTypes.SCREEN_VIEW_CLOSE);
			this.close_payload = close_payload;
		}
	}
}