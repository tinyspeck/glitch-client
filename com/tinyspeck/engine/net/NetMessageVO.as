package com.tinyspeck.engine.net
{
	import com.tinyspeck.engine.vo.TSVO;

	public class NetMessageVO extends TSVO
	{
		public static var MESSAGE_ID_COUNTER:int = 0;
		
		public var type:String;
		public var token:String;
		public var msg_id:String;
		public var session_stamp:String;
		
		public var payload:Object;
		
		public function NetMessageVO()
		{
			
		}
	}
}