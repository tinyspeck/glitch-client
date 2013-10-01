package com.tinyspeck.engine.net
{
	public class NetOutgoingQuestBeginVO extends NetOutgoingMessageVO
	{
		
		public var quest_id:String;
		
		public function NetOutgoingQuestBeginVO(quest_id:String)
		{
			super(MessageTypes.QUEST_BEGIN);
			this.quest_id = quest_id;
		}
	}
}