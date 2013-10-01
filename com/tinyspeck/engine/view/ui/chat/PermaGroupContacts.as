package com.tinyspeck.engine.view.ui.chat
{
	public class PermaGroupContacts extends BaseContacts
	{		
		public function PermaGroupContacts(groups:Array, w:int){
			super(w, ContactElement.TYPE_GROUP, null, groups);
		}
	}
}