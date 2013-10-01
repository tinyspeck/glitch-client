package com.tinyspeck.engine.net {
	public class NetOutgoingAvatarGetChoicesVO extends NetOutgoingMessageVO {
		public function NetOutgoingAvatarGetChoicesVO() {
			super(MessageTypes.AVATAR_GET_CHOICES);
		}
	}
}