package com.tinyspeck.engine.net {
	public class NetOutgoingCloseImgMenuVO extends NetOutgoingMessageVO {
		
		public var close_payload:Object;
		
		public function NetOutgoingCloseImgMenuVO(close_payload:Object) 
		{
			super(MessageTypes.CLOSE_IMG_MENU);
			this.close_payload = close_payload;
		}
	}
}