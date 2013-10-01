package com.tinyspeck.engine.net {
	public class NetOutgoingShareTrackVO extends NetOutgoingMessageVO {
		
		public var share_type:String;
		public var button_type:String;
		public var short_url:String;
		
		public function NetOutgoingShareTrackVO(share_type:String, button_type:String, short_url:String) 
		{
			super(MessageTypes.SHARE_TRACK);
			this.share_type = share_type;
			this.button_type = button_type;
			this.short_url = short_url;
		}
	}
}