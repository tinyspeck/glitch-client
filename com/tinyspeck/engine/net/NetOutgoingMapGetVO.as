package com.tinyspeck.engine.net
{
	public class NetOutgoingMapGetVO extends NetOutgoingMessageVO
	{
		public var hub_id:String;
		public var tsid:String; //the location TSID
		
		public function NetOutgoingMapGetVO(hub_id:String, loc_tsid:String = '')
		{
			super(MessageTypes.MAP_GET);
			this.hub_id = hub_id;
			this.tsid = loc_tsid;
		}
	}
}