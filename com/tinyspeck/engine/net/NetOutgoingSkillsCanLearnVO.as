package com.tinyspeck.engine.net
{
	import com.tinyspeck.engine.model.TSModelLocator;

	public class NetOutgoingSkillsCanLearnVO extends NetOutgoingMessageVO
	{	
		public var new_style:Boolean;
		public var include_unlearned:Boolean;
		
		public function NetOutgoingSkillsCanLearnVO()
		{
			super(MessageTypes.SKILLS_CAN_LEARN);
			this.new_style = true;
			this.include_unlearned = true;
		}
	}
}