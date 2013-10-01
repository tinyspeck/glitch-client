package com.tinyspeck.engine.net
{
	public class NetOutgoingGuideStatusChangeVO extends NetOutgoingMessageVO
	{
		public var on_duty:Boolean;
		
		public function NetOutgoingGuideStatusChangeVO(on_duty:Boolean)
		{
			super(MessageTypes.GUIDE_STATUS_CHANGE);
			this.on_duty = on_duty;
		}
	}
}