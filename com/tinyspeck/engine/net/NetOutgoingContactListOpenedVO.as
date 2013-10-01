package com.tinyspeck.engine.net {
	public class NetOutgoingContactListOpenedVO extends NetOutgoingMessageVO {
		
		public function NetOutgoingContactListOpenedVO() 
		{
			super(MessageTypes.CONTACT_LIST_OPENED);
		}
	}
}