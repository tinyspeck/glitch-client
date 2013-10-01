package com.tinyspeck.engine.net {
	public class NetOutgoingOverlayDoneVO extends NetOutgoingMessageVO
	{
		public var done_payload:Object;
		public function NetOutgoingOverlayDoneVO(done_payload:Object)
		{
			this.done_payload = done_payload;
			super(MessageTypes.OVERLAY_DONE);
		}
	}
}