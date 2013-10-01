package com.tinyspeck.engine.net
{
	public class NetOutgoingPlayMusicVO extends NetOutgoingMessageVO
	{
		public var name:String;
		public var loops:int;
		
		public function NetOutgoingPlayMusicVO(name:String, loops:uint = 0)
		{
			super(MessageTypes.PLAY_MUSIC);
			this.name = name;
			this.loops = loops;
		}
	}
}