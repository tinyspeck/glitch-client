package com.tinyspeck.engine.net {
	
	public class NetOutgoingCultivationModeEndedVO extends NetOutgoingMessageVO {
		
		public function NetOutgoingCultivationModeEndedVO() {
			super(MessageTypes.CULTIVATION_MODE_ENDED);
		}
	}
}