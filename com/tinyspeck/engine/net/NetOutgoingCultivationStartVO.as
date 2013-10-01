package com.tinyspeck.engine.net {
	public class NetOutgoingCultivationStartVO extends NetOutgoingMessageVO
	{
		public function NetOutgoingCultivationStartVO() {
			super(MessageTypes.CULTIVATION_START);
		}
	}
}