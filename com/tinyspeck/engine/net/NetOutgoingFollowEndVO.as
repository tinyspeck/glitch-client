package com.tinyspeck.engine.net {
	public class NetOutgoingFollowEndVO extends NetOutgoingMessageVO
	{
		public function NetOutgoingFollowEndVO()
		{
			super(MessageTypes.FOLLOW_END);
		}
	}
}