package com.tinyspeck.engine.data.chat
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.chat.ChatElement;

	public class ChatHistory extends AbstractTSDataEntity
	{		
		public static const GLOBAL_CHAT:String = 'global_chat';
		public static const HELP_CHAT:String = 'help_chat';
		
		private static var histories:Vector.<ChatHistory>;
		
		public var tsid:String;
		public var elements_storage_array:Array = []; //strings to re-create the elements
		public var is_closed:Boolean;
		public var is_group:Boolean;
		public var is_other:Boolean;
		public var is_active:Boolean;
		public var label:String;
		
		public function ChatHistory(hashName:String){
			super(hashName);
			tsid = hashName;
		}
		
		public static function getHistoryFromStorage(tsid:String, convert_global_tsid:Boolean = true):ChatHistory {
			buildFromStorage();
			
			//convert the TSID to global_chat, when deleting legacy pass false so it deletes the right one
			if(convert_global_tsid) tsid = convertGlobalTsid(tsid);
			
			var i:int;
			
			if(histories && histories.length){
				for(i; i < histories.length; i++){
					if(histories[int(i)].tsid == tsid) return histories[int(i)];
				}
			}
			
			return null;
		}
		
		public static function addHistoryToStorage(chat_area:ChatArea, is_closed:Boolean):String {
			if(!chat_area) return 'no chat area?';
			
			buildFromStorage();
			
			//if this is a global channel, make sure we handle it
			const chat_name:String = convertGlobalTsid(chat_area.name);
			
			//let's see if it's already in the history, and just update it
			var history:ChatHistory = getHistoryFromStorage(chat_name);
			var i:int;
			var element:ChatElement;
			
			if(history){
				//found an old one, kill it
				removeFromStorage(chat_name);
				history = null;
			}
						
			//build the chat elements array
			history = new ChatHistory(chat_name);
			history.elements_storage_array = [];
			
			//we don't want the updates feed elements in history
			if(chat_name != ChatArea.NAME_UPDATE_FEED){
				const start:int = Math.max(0, chat_area.elements.length-ChatArea.MAX_ELEMENTS);
				for(i = start; i < chat_area.elements.length; i++){
					element = chat_area.elements[int(i)];
					
					//we need to ignore the timestamp type since it's only for visual
					if(element.type == ChatElement.TYPE_TIMESTAMP) continue;
					
					history.elements_storage_array.push(ChatHistoryElement.toHistoryArray(element));
				}
			}
			
			history.is_closed = is_closed;
			history.is_group = TSModelLocator.instance.worldModel.getGroupByTsid(chat_area.name) ? true : false;
			history.is_other = !history.is_group;
			history.label = chat_area.raw_title;
			history.is_active = RightSideManager.instance.right_view.isActiveChat(chat_area.name);
			
			//push it in the history
			histories.push(history);
						
			//dump it to the storage
			var success:Boolean = LocalStorage.instance.setUserData(LocalStorage.CHAT_HISTORY, histories, true);
			if (success) {
				return null;
			} else {
				return 'LocalStorage.instance.setUserData return false';
			}
		}
		
		public static function removeFromStorage(tsid:String, convert_global_tsid:Boolean = true):Boolean {
			var history:ChatHistory = getHistoryFromStorage(tsid, convert_global_tsid);
			
			if(history && histories && histories.indexOf(history) != -1){
				histories.splice(histories.indexOf(history), 1);
				history = null;
			}
			
			//dump it to the storage
			return LocalStorage.instance.setUserData(LocalStorage.CHAT_HISTORY, histories, true);
		}
		
		public static function clearClosedFromStorage():Boolean {
			buildFromStorage();
			
			var i:int;
			var to_keep:Vector.<ChatHistory> = new Vector.<ChatHistory>();
			
			if(histories && histories.length){
				for(i; i < histories.length; i++){
					if(!histories[int(i)].is_closed) to_keep.push(histories[int(i)]);
				}
			}
			
			//histories is new now
			histories = to_keep;
			
			//dump it to the storage
			return LocalStorage.instance.setUserData(LocalStorage.CHAT_HISTORY, histories);
		}
		
		public static function getAllHistoryFromStorage():Vector.<ChatHistory> {
			buildFromStorage();
			return histories;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):ChatHistory {
			var history:ChatHistory = new ChatHistory(hashName);
			var val:*;
			var k:String;
			
			for(k in object){
				val = object[k];
				
				if(k in history && k != 'elements'){ //checking for elements for lagecy, once everyone has done a /clear this can be killed
					history[k] = val;
				}
				else{
					resolveError(history,object,k);
				}
			}
			
			return history;
		}
		
		private static function buildFromStorage():void {
			if(!histories){
				histories = new Vector.<ChatHistory>();
				
				//loop through the local storage and populate the vector
				const data:Object = LocalStorage.instance.getUserData(LocalStorage.CHAT_HISTORY);
				
				if(data){
					var k:String;
					
					for(k in data){
						if(data[k] && data[k]['tsid'] && !getHistoryFromStorage(data[k]['tsid'])){
							histories.push(fromAnonymous(data[k], data[k]['tsid']));
						}
					}					
				}
			}
		}
		
		private static function convertGlobalTsid(tsid:String):String {			
			if(tsid == ChatArea.NAME_GLOBAL){
				tsid = GLOBAL_CHAT;
			}
			else if(tsid == ChatArea.NAME_HELP){
				tsid = HELP_CHAT;
			}
			
			return tsid;
		}
	}
}