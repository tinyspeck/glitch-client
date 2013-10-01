package com.tinyspeck.engine.net {
	public class NetOutgoingOverlayDismissedVO extends NetOutgoingMessageVO
	{
		public var dismiss_payload:Object;
		public function NetOutgoingOverlayDismissedVO(dismiss_payload:Object)
		{
			this.dismiss_payload = dismiss_payload;
			super(MessageTypes.OVERLAY_DISMISSED);
		}
	}
}