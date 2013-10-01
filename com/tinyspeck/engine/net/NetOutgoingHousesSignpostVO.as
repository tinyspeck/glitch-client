package com.tinyspeck.engine.net {
	public class NetOutgoingHousesSignpostVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		
		public function NetOutgoingHousesSignpostVO(pc_tsid:String) 
		{
			super(MessageTypes.HOUSES_SIGNPOST);
			this.tsid = pc_tsid;
		}
	}
}