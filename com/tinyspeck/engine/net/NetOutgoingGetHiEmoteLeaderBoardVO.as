package com.tinyspeck.engine.net {
	
	public class NetOutgoingGetHiEmoteLeaderBoardVO extends NetOutgoingMessageVO {
		
		public function NetOutgoingGetHiEmoteLeaderBoardVO() 
		{
			super(MessageTypes.GET_HI_EMOTE_LEADERBOARD);
		}
	}
}