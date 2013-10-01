package com.tinyspeck.engine.view.ui.chat
{
	public class OnlineContacts extends BaseContacts
	{		
		public function OnlineContacts(online_contacts:Array, w:int){
			super(w, ContactElement.TYPE_ONLINE, online_contacts);
		}
	}
}