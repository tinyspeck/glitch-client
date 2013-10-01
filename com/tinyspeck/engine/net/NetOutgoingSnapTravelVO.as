package com.tinyspeck.engine.net {
	public class NetOutgoingSnapTravelVO extends NetOutgoingMessageVO {
		
		public var tsid:String;
		public var location_x:Number;
		public var location_y:Number;
		
		public function NetOutgoingSnapTravelVO(location_tsid:String, location_x:Number, location_y:Number) 
		{
			super(MessageTypes.SNAP_TRAVEL);
			this.tsid = location_tsid;
			this.location_x = location_x;
			this.location_y = location_y;
		}
	}
}