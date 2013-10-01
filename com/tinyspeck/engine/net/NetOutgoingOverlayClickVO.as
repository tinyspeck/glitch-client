package com.tinyspeck.engine.net
{
	public class NetOutgoingOverlayClickVO extends NetOutgoingMessageVO
	{
		public var uid:String;
		public var click_payload:Object;
		
		public function NetOutgoingOverlayClickVO(uid:String, click_payload:Object = null)
		{
			super(MessageTypes.OVERLAY_CLICK);
			this.uid = uid;
			this.click_payload = click_payload;
		}
	}
}