package com.tinyspeck.engine.net {
	public class NetOutgoingSkillUnlearnCancelVO extends NetOutgoingMessageVO {
		
		public function NetOutgoingSkillUnlearnCancelVO() 
		{
			super(MessageTypes.SKILL_UNLEARN_CANCEL);
		}
	}
}