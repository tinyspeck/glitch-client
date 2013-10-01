package com.tinyspeck.engine.net {
	
	public class NetOutgoingNoEnergyModeVO extends NetOutgoingMessageVO {
		public var enabled:Boolean;
		
		public function NetOutgoingNoEnergyModeVO(enabled:Boolean) {
			super(MessageTypes.NO_ENERGY_MODE);
			this.enabled = enabled;
		}
	}
}