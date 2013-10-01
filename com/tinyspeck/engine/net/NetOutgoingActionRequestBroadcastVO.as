package com.tinyspeck.engine.net
{
	public class NetOutgoingActionRequestBroadcastVO extends NetOutgoingMessageVO
	{
		public var event_type:String;
		public var player_tsid:String;
		public var event_tsid:String;
		public var txt:String;
		public var got:int;
		public var need:int;
		
		public function NetOutgoingActionRequestBroadcastVO(player_tsid:String, event_type:String, event_tsid:String, txt:String, got:int = 0, need:int = 0)
		{
			super(MessageTypes.ACTION_REQUEST_BROADCAST);
			this.player_tsid = player_tsid;
			this.event_type = event_type;
			this.event_tsid = event_tsid;
			this.txt = txt;
			this.got = got;
			this.need = need;
		}
	}
}