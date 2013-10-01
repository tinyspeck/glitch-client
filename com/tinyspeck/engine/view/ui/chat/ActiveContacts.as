package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.RightSideManager;
	
	import flash.display.Graphics;

	public class ActiveContacts extends BaseContacts
	{		
		public function ActiveContacts(w:int){
			super(w, ContactElement.TYPE_ACTIVE, null);
		}
		
		override protected function buildElements(is_rebuild:Boolean = true):void {
			var i:int;
			var next_y:int;
			var element:ContactElement;
			var g:Graphics = graphics;
			g.clear();
			
			for(i = 0; i < contacts_holder.numChildren; i++){
				element = contacts_holder.getChildAt(i) as ContactElement;
				element.w = _w;
				element.y = next_y;
				next_y += element.height + 3;
			}
		}
		
		override public function addContact(contact:String, group:String = null):void {
			//because we want the newest on top, create a contact element and shuffle
			var element:ContactElement;
						
			if(contact){
				element = getElement(contact);
				if(contacts.indexOf(contact) == -1) contacts.unshift(contact);
			}
			else if(group){
				element = getElement(group);
				if(groups.indexOf(group) == -1) groups.unshift(group);
			}
			
			//add a new contact/group to the top of the list
			if(!element) {
				element = new ContactElement(type, contact, group);
				element.addEventListener(TSEvent.CHANGED, onChangeActive, false, 0, true);
				element.enabled = contacts_holder.numChildren > 0 ? false : true;
				contacts_holder.addChildAt(element, 0);
			}
			
			buildElements();
		}
		
		public function incomingMessage(tsid:String):void {
			//see if we have an element that's not active, if so, update the message counter
			var element:ContactElement = getElement(tsid);
			if(element) element.incrementCounter();
		}
		
		public function setActive(tsid:String):void {
			var element:ContactElement;
			var i:int;
			
			for(i = 0; i < contacts_holder.numChildren; i++){
				element = contacts_holder.getChildAt(i) as ContactElement;
				element.enabled = element.name != tsid ? false : true;
			}
		}
		
		private function onChangeActive(event:TSEvent):void {
			var i:int;
			var element:ContactElement;
			var active_element:ContactElement = event.data as ContactElement;
			
			for(i = 0; i < contacts_holder.numChildren; i++){
				element = contacts_holder.getChildAt(i) as ContactElement;
								
				//if this is the active contact, set it as so
				element.enabled = element != active_element ? false : true;
			}
			
			//tell the right side what's going on
			RightSideManager.instance.right_view.chatActive(active_element.name);
		}
	}
}