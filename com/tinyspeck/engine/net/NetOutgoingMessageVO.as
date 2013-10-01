package com.tinyspeck.engine.net
{
	public class NetOutgoingMessageVO extends NetMessageVO
	{
		public var needs_msg_id:Boolean = false;
		public var time_sent:int;
		public var sent_timeout:Number;
			
		public function NetOutgoingMessageVO(type:String) {
			this.type = type;
		}
	}
}