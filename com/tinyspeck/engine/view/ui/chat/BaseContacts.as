package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.SortTools;
	
	import flash.display.Sprite;

	public class BaseContacts extends TSSpriteWithModel
	{
		protected var contacts:Array;
		protected var groups:Array;
		
		protected var contacts_holder:Sprite = new Sprite();
		
		protected var type:String;
		
		public function BaseContacts(w:int, type:String, contacts:Array, groups:Array = null){
			_w = w;
			this.type = type;
			this.contacts = contacts ? contacts : new Array();
			this.groups = groups ? groups : new Array();
			
			addChild(contacts_holder);
			
			//sort the contacts straight away
			sortContacts(true);
			sortContacts(false);
			
			//build out each element
			buildElements(false);
		}
		
		protected function buildElements(is_rebuild:Boolean = true):void {
			var i:int;
			var next_x:int;
			var next_y:int;
			var element:ContactElement;
			
			for(i = 0; i < contacts.length; i++){
				element = getElement(contacts[int(i)]);
				
				if(!element){
					element = new ContactElement(type, contacts[int(i)]);
					element.w = _w;
					contacts_holder.addChild(element);
					
					//if this contact is coming online, show the alert
					if(type == ContactElement.TYPE_ONLINE && is_rebuild) {
						element.alert();
					}
				}
				element.x = next_x;
				element.y = next_y;
				
				next_y += element.height;
			}
			
			for(i = 0; i < groups.length; i++){
				element = getElement(groups[int(i)]);
				
				if(!element){
					element = new ContactElement(type, null, groups[int(i)]);
					contacts_holder.addChild(element);
				}	
				element.y = next_y;
				element.w = _w;
				
				next_y += element.height;
			}
		}
		
		public function getElement(tsid:String):ContactElement {
			return contacts_holder.getChildByName(tsid) as ContactElement;
		}
		
		public function addContact(pc_tsid:String, group_tsid:String = null):void {			
			if(pc_tsid){
				//put it at the end and sort
				if(contacts.indexOf(pc_tsid) == -1) contacts.push(pc_tsid);
				sortContacts(false);
			}
			else if(group_tsid){
				//put it at the end and sort
				if(groups.indexOf(group_tsid) == -1) groups.push(group_tsid);
				sortContacts(true);
			}
			
			buildElements();
		}
		
		public function removeContact(tsid:String):void {
			//if the contact is found it returns that element and rebuilds the list
			var element:ContactElement = getElement(tsid);
			
			if(contacts.indexOf(tsid) >= 0)contacts.splice(contacts.indexOf(tsid), 1);
			if(groups.indexOf(tsid) >= 0) groups.splice(groups.indexOf(tsid), 1);
			
			if(element){				
				//remove it
				element.parent.removeChild(element);
				
				//layout the elements again
				buildElements();
			}
		}
		
		public function switchContact(old_tsid:String, new_tsid:String, is_group:Boolean = true):void {
			const element:ContactElement = getElement(old_tsid);
			
			if(element){
				element.name = new_tsid;
			}
		}
		
		private function sortContacts(is_group:Boolean):void {
			var contact_sort:Vector.<PC> = new Vector.<PC>();
			var contact:PC;
			var group_sort:Vector.<Group> = new Vector.<Group>();
			var group:Group;
			var i:int;
			var to_sort:Array = is_group ? groups : contacts;
			
			if(is_group){
				//remove the global chat from groups so it doesn't get sorted
				var global_index:int = groups.indexOf(ChatArea.NAME_GLOBAL);
				if(global_index != -1) groups.splice(global_index, 1);
				
				var help_index:int = groups.indexOf(ChatArea.NAME_HELP);
				if(help_index != -1) groups.splice(help_index, 1);
				
				var updates_index:int = groups.indexOf(ChatArea.NAME_UPDATE_FEED);
				if(updates_index != -1) groups.splice(updates_index, 1);
				
				var trade_index:int = groups.indexOf(ChatArea.NAME_TRADE);
				if(trade_index != -1) groups.splice(trade_index, 1);
			}
			
			//loop through the to_sort to get labels
			for(i; i < to_sort.length; i++){
				if(!is_group){
					contact = model.worldModel.getPCByTsid(to_sort[int(i)]);
					if(contact) contact_sort.push(contact);
				}
				else {
					group = model.worldModel.getGroupByTsid(to_sort[int(i)]);
					if(group) group_sort.push(group);
				}
			}
						
			//sort
			if(!is_group){
				SortTools.vectorSortOn(contact_sort, ['label'], [Array.CASEINSENSITIVE]);
				
				//rebuild the to_sort
				to_sort.length = 0;
				for(i = 0; i < contact_sort.length; i++){
					to_sort.push(contact_sort[int(i)].tsid);
				}
				contacts = to_sort;
			}
			else {				
				SortTools.vectorSortOn(group_sort, ['label'], [Array.CASEINSENSITIVE]);
				
				//rebuild the to_sort
				to_sort.length = 0;
				for(i = 0; i < group_sort.length; i++){
					to_sort.push(group_sort[int(i)].tsid);
				}
				groups = to_sort;
				
				//place the global chats in order (Live Help, Global, Updates)
				if(trade_index != -1) groups.unshift(ChatArea.NAME_TRADE);
				if(updates_index != -1) groups.unshift(ChatArea.NAME_UPDATE_FEED);
				if(global_index != -1) groups.unshift(ChatArea.NAME_GLOBAL);
				if(help_index != -1) groups.unshift(ChatArea.NAME_HELP);
			}
		}
		
		public function get element_count():uint { return contacts_holder.numChildren; }
		
		public function updateGroups(groups:Array):void {
			this.groups = groups ? groups : new Array();
		}
		
		public function updateContacts(contacts:Array):void {
			this.contacts = contacts ? contacts : new Array();
		}
		
		public function refresh(pc_tsid:String = null):Boolean {
			//if they are an active chat, change the status
			if(pc_tsid){
				if(getElement(pc_tsid)){
					getElement(pc_tsid).refresh();
					return true;
				}
			}
			else {
				//loop through them all and refresh them
				const total:int = contacts_holder.numChildren;
				var i:int;
				
				for(i; i < total; i++){
					(contacts_holder.getChildAt(i) as ContactElement).refresh();
				}
				return true;
			}
			
			return false;
		}
				
		/*
		override public function set width(value:Number):void {
			//set the mask on each element
			var masker:Sprite;
			var element:ContactElement;
			var i:int;
			var g:Graphics;
			
			for(i; i < contacts_holder.numChildren; i++){
				element = contacts_holder.getChildAt(i) as ContactElement;
				if(element.getChildByName('masker')){
					masker = element.getChildByName('masker') as Sprite;
				}
				else {
					masker = new Sprite();
					masker.mouseEnabled = false;
					masker.name = 'masker';
					element.addChild(masker);
				}
				
				g = masker.graphics;
				g.clear();
				g.beginFill(0,0);
				g.drawRect(0, 0, value, element.height);
				
				element.mask = masker;
			}
		}
		*/
	}
}