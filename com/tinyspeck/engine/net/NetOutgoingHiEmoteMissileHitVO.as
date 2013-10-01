package com.tinyspeck.engine.net {
	public class NetOutgoingHiEmoteMissileHitVO extends NetOutgoingMessageVO {
		
		public var seconds:uint;
		public var from_tsid:String;
		public var location_tsid:String;
		public var location_template_tsid:String;
		public var log_data:Object;
		public var version:uint;
		
		public function NetOutgoingHiEmoteMissileHitVO(seconds:uint, from_tsid:String, location_tsid:String, location_template_tsid:String, version:uint, log_data:Object) 
		{
			super(MessageTypes.HI_EMOTE_MISSILE_HIT);
			this.seconds = seconds;
			this.from_tsid = from_tsid;
			this.location_tsid = location_tsid;
			this.location_template_tsid = location_template_tsid;
			this.log_data = log_data;
			this.version = version;
		}
	}
}