package com.tinyspeck.engine.net {
	public class NetOutgoingHousesWallPreviewVO extends NetOutgoingMessageVO {
		
		public var wp_key:String;
		public var wp_type:String;
		public var preview_key:String;
		
		public function NetOutgoingHousesWallPreviewVO(wp_key:String, wp_type:String, preview_key:String) {
			super(MessageTypes.HOUSES_WALL_PREVIEW);
			
			this.wp_key = wp_key;
			this.wp_type = wp_type;
			this.preview_key = preview_key;
		}
	}
}