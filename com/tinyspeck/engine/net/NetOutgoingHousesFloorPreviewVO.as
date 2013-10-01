package com.tinyspeck.engine.net {
	public class NetOutgoingHousesFloorPreviewVO extends NetOutgoingMessageVO {
		
		public var floor_key:String;
		public var floor_type:String;
		public var preview_key:String;
		
		public function NetOutgoingHousesFloorPreviewVO(floor_key:String, floor_type:String, preview_key:String) {
			super(MessageTypes.HOUSES_FLOOR_PREVIEW);
			
			this.floor_key = floor_key;
			this.floor_type = floor_type;
			this.preview_key = preview_key;
		}
	}
}