package com.tinyspeck.engine.net {
	public class NetOutgoingHousesCeilingPreviewVO extends NetOutgoingMessageVO {
		
		public var ceiling_key:String;
		public var ceiling_type:String;
		public var preview_key:String;
		
		public function NetOutgoingHousesCeilingPreviewVO(ceiling_key:String, ceiling_type:String, preview_key:String) {
			super(MessageTypes.HOUSES_CEILING_PREVIEW);
			
			this.ceiling_key = ceiling_key;
			this.ceiling_type = ceiling_type;
			this.preview_key = preview_key;
		}
	}
}