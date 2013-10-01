package com.tinyspeck.engine.net
{
	public class NetOutgoingQuestConversationChoiceVO extends NetOutgoingMessageVO
	{
		
		public var choice:String;
		public var quest_id:String;
		
		public function NetOutgoingQuestConversationChoiceVO(quest_id:String, choice:String)
		{
			super(MessageTypes.QUEST_CONVERSATION_CHOICE);
			this.quest_id = quest_id;
			this.choice = choice;
		}
	}
}