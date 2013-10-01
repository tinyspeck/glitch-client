package com.tinyspeck.engine.net {
	public class NetOutgoingSetPrefsVO extends NetOutgoingMessageVO {
		
		public var prefs:Object;
		
		public function NetOutgoingSetPrefsVO(prefs:Object) {
			super(MessageTypes.SET_PREFS);
			this.prefs = prefs;
		}
	}
}