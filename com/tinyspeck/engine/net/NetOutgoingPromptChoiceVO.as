package com.tinyspeck.engine.net {
	public class NetOutgoingPromptChoiceVO extends NetOutgoingMessageVO {
		
		public var uid:String;
		public var value:String;
		
		public function NetOutgoingPromptChoiceVO(uid:String, value:String) {
			super(MessageTypes.PROMPT_CHOICE);
			this.uid = uid;
			this.value = value;
		}
	}
}