package com.tinyspeck.engine.net {
	public class NetOutgoingAFKVO extends NetOutgoingMessageVO {
		
		public var afk:Boolean;
		
		public function NetOutgoingAFKVO(afk:Boolean) {
			super(MessageTypes.AFK);
			this.afk = afk;
		}
	}
}