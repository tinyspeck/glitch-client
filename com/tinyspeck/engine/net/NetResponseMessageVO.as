package com.tinyspeck.engine.net
{
	public class NetResponseMessageVO extends NetIncomingMessageVO
	{
		public var success:Boolean;
		public var request:NetOutgoingMessageVO;
		public var time_recv:int;
	}
}