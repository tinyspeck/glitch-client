package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.chat.ChatHistory;
	import com.tinyspeck.engine.data.chat.ChatHistoryElement;
	import com.tinyspeck.engine.data.chat.FeedItem;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.UICalloutView;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.chat.ChatElement;
	import com.tinyspeck.engine.view.ui.chat.ContactList;
	import com.tinyspeck.engine.view.ui.chat.CreateAccountUI;
	import com.tinyspeck.engine.view.ui.chat.FeedChatArea;
	import com.tinyspeck.engine.view.ui.map.MapChatArea;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;

	public class RightSideView extends TSSpriteWithModel
	{
		/*****************************************************************
		 * The purpose of this class is to hold and update the components
		 * within it. Buddy list, local chat, etc.
		 * 
		 * See RightSideManager for all message parsing that gets passed
		 * to this class.
		 *****************************************************************/
		
		public static const CHAT_PADD:uint = 12;
		
		public static const MIN_WIDTH_CLOSED:uint = 264;
		private static const MAX_WIDTH_CLOSED:uint = 383; //not used at the moment, if/when the chat area can scale, this would kick in
		
		private const contact_list:ContactList = new ContactList();
		private const other_chats:Vector.<ChatArea> = new Vector.<ChatArea>();
		private const map_chat:MapChatArea = new MapChatArea();
		
		private var all_holder:Sprite = new Sprite();
		private var all_mask:Sprite = new Sprite();
		private var resizer:Sprite;
		
		private var local_chat:ChatArea;
		private var active_chat:ChatArea;
		private var last_focused_chat:ChatArea;
		private var main_view:TSMainView;
		private var lm:LayoutModel;
		private var cdVO:ConfirmationDialogVO;
		private var create_account_ui:CreateAccountUI;
		
		private var drag_rect:Rectangle = new Rectangle();
		
		private var tab_before_hide:String;
		
		private var local_chat_y:int = CHAT_PADD;
		private var old_map_h:int; //used when hiding the map
		
		private var is_multi_built:Boolean;
		private var inited:Boolean;
				
		public function RightSideView(){
			if (inited) throw new Error('This is already inited. Access via RightSideManager.rsv');
			lm = model.layoutModel;
			
			//right side column is dynamic
			lm.right_col_w = MIN_WIDTH_CLOSED;
			
			main_view = TSFrontController.instance.getMainView();
			
			//give the look and feel without populating the data
			buildBase();
			KeyBeacon.instance.addEventListener(KeyBeacon.CTRL_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.ENTER, ctrlPlusEnterHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.TAB, tabKeyDownHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.SLASH, slashKeyDownHandler);
			visible = false;
		}
		
		private function ctrlPlusEnterHandler(e:Event):void {
			CONFIG::perf {
				// disable during testing
				if (model.flashVarModel.run_automated_tests) return;
			}
			focusCycle();
		}
		
		private function tabKeyDownHandler(e:Event):void {
			CONFIG::perf {
				// disable during testing
				if (model.flashVarModel.run_automated_tests) return;
			}
			if (KeyBeacon.instance.pressed(Keyboard.ALTERNATE)) return; // cmd/tab is used for maps
			if (InputDialog.instance.parent) return; //InputDialog manages it's own TAB cycle
			if (NoteDialog.instance.parent) return; //note dialog manages it's own TAB cycle
			
			if ((!last_focused_chat || !last_focused_chat.hasFocus()) && model.stateModel.focus_is_in_input) return;
			focusCycle();
		}
		
		private function slashKeyDownHandler(e:Event):void {
			CONFIG::perf {
				// disable during testing
				if (model.flashVarModel.run_automated_tests) return;
			}
			if (model.stateModel.focus_is_in_input) return; // stop this if we're typing in any input
			if (active_chat && active_chat.hasFocus()) return;
			local_chat.focus();
			last_focused_chat = local_chat;
			
			// NOTE: this puts a slash in the input after focussing on it.
			// not sure if that is desired (though it is handy if you want to type a slash command)
			// but there is no simple way to stop the / from getting entered
		}
		
		public function focusCycle():void {
			last_focused_chat = null;
			
			if (local_chat.hasFocus()) {
				last_focused_chat = local_chat;
			} else if (active_chat && active_chat.hasFocus()) {
				last_focused_chat = active_chat;
			}
			
			if (last_focused_chat) {
				/*CONFIG::debugging {
					Console.warn('there is a focused chat');
				}*/
				// switch to the top dude if local_chat is in focus, else release focus back to whatever had it before
				if (last_focused_chat == local_chat && active_chat && active_chat.input_field.enabled) {
					/*CONFIG::debugging {
						Console.warn('focus on active_chat');
					}*/
					active_chat.focus();
				} else {
					/*CONFIG::debugging {
						Console.warn('blur it');
					}*/
					last_focused_chat.blur();
				}
			} else {
				/*CONFIG::debugging {
					Console.warn('there is a NO focused chat');
				}*/
				// no chat was focused, give local chat focus
				local_chat.focus();
				last_focused_chat = local_chat;
			}
		}
		
		private function buildBase():void {
			//add it to the stage
			main_view.main_container.addChild(this);
			
			//all holder		
			all_holder.filters = StaticFilters.chat_right_shadowA;
			addChild(all_holder);
			
			//add the contact list
			contact_list.addEventListener(TSEvent.TOGGLE, onContactToggle, false, 0, true);
			addChild(contact_list);
			
			CONFIG::perf {
				contact_list.visible = false;
			}
			
			//set the contact list to be what they last left it as
			if(LocalStorage.instance.getUserData(LocalStorage.CONTACT_LIST_OPEN) != null){
				contact_list.is_open = LocalStorage.instance.getUserData(LocalStorage.CONTACT_LIST_OPEN) == 'true' ? true : false;
			}
			//force it closed
			else {
				contact_list.is_open = false;
			}
			
			//put the local chat there
			local_chat = createChatArea(ChatArea.NAME_LOCAL, 'Local Chat / Activity');
			local_chat.enabled = false;
			local_chat.addEventListener(TSEvent.CHANGED, onLocalChange, false, 0, true);
			all_holder.addChild(local_chat);
			
			//load the local history in
			chatShowHistory(local_chat, ChatHistory.getHistoryFromStorage(ChatArea.NAME_LOCAL));
			
			//a mask to put over everything
			mask = all_mask;
			all_mask.mouseEnabled = false;
			addChild(all_mask);
			
			addChild(map_chat);
			
			//set the drag rect
			drag_rect.x = 0;
			drag_rect.width = 0;
			
			refresh();
		}
		
		private function buildMulti():void {			
			resizer = new Sprite();
			resizer.addChild(new AssetManager.instance.assets.chat_divider());
			resizer.addEventListener(MouseEvent.MOUSE_DOWN, onResizeStart, false, 0, true);
			
			all_holder.addChild(resizer);
			
			is_multi_built = true;
		}
		
		public function init():void {			
			if(inited) return;
			
			//now that we have data, let's put this together!
			local_chat.enabled = true;
			
			contact_list.start();
			
			//do we still need to create an account?
			if(model.worldModel.pc && model.worldModel.pc.needs_account){
				createAccountShowHide(true);
			}
			
			//does this location not want us to see things?
			accountFeaturesShowHide();
			
			inited = true;
		}
		
		public function rejoin():void {
			//open any chats they may have had open before
			var i:int;
			var histories:Vector.<ChatHistory> = ChatHistory.getAllHistoryFromStorage();
			var history:ChatHistory;
			var history_tsid:String;
			var pc:PC;
			var itemstack:Itemstack;
							
			if(histories && histories.length){
				for(i = 0; i < histories.length; i++){
					history = histories[int(i)];
					
					//set a local var so we don't destroy the SO
					history_tsid = history.tsid;
															
					//see if this is a player chat and they are not in the world
					if(history_tsid.substr(0,1) == 'P' && !model.worldModel.getPCByTsid(history_tsid)){
						if(history.label){
							pc = PC.fromAnonymous({tsid:history_tsid, label:history.label}, history_tsid);
							
							//inject it in the world, if they sign back on later, the label will update
							model.worldModel.pcs[history_tsid] = pc;
						}
						else{
							//this won't do.
							ChatHistory.removeFromStorage(history_tsid);
						}
					}
					else if((history_tsid.substr(0,1) == 'I' || history_tsid.substr(0,1) == 'B') && !model.worldModel.getItemstackByTsid(history_tsid)){
						//we were talking to an itemstack
						if(history.label){
							itemstack = Itemstack.fromAnonymous({tsid:history_tsid, label:history.label}, history_tsid);
							
							//inject in the world
							model.worldModel.itemstacks[history_tsid] = itemstack;
						}
						else {
							//bye
							ChatHistory.removeFromStorage(history_tsid);
						}
					}
					
					//support legacy that has the global and live help saved as TSID instead of the string
					if(history_tsid == RightSideManager.instance.global_chat_tsid || history_tsid == RightSideManager.instance.live_help_tsid){
						ChatHistory.removeFromStorage(history_tsid, false);
						
						CONFIG::debugging {
							Console.warn('Found legacy global/live in history, deleting...');
						}
						continue;
					}
					
					//was this a global chat?
					if(history_tsid == ChatHistory.GLOBAL_CHAT){
						history_tsid = RightSideManager.instance.global_chat_tsid;
					}
					else if(history_tsid == ChatHistory.HELP_CHAT){
						history_tsid = RightSideManager.instance.live_help_tsid;
					}
					else if(history_tsid == ChatArea.NAME_PARTY){
						//if this is party chat let the server rejoin us
						continue;
					}
											
					//was this group chat?
					if(model.worldModel.getGroupByTsid(history_tsid)){
						RightSideManager.instance.groupStart(history_tsid, true);
					}
					else if(history.is_other && history_tsid != ChatArea.NAME_LOCAL) {
						RightSideManager.instance.chatStart(history_tsid, false, false);
					}
					else if(history.is_group){
						//it must be a group the player left since last in client
						ChatHistory.removeFromStorage(history_tsid);
						
						CONFIG::debugging {
							Console.warn('Killing history for group: '+history_tsid);
						}
					}
				}
				
				//after all the chats are created, set the active one
				for(i = 0; i < histories.length; i++){
					history = histories[int(i)];
					history_tsid = history.tsid;
					
					//was this a global chat?
					if(history_tsid == ChatHistory.GLOBAL_CHAT){
						history_tsid = RightSideManager.instance.global_chat_tsid;
					}
					else if(history_tsid == ChatHistory.HELP_CHAT){
						history_tsid = RightSideManager.instance.live_help_tsid;
					}
					
					//found the active one, set it as so!
					if(history.is_active) {
						chatActive(history_tsid, false);
						break;
					}
				}
			}
			
			//force a stage resize
			onContactToggle();
		}
		
		private function chatShowHistory(chat_area:ChatArea, history:ChatHistory):void {
			if(!chat_area) return;
			const total:int = history && history.elements_storage_array ? history.elements_storage_array.length : 0;
			const start_index:int = Math.max(0, total-ChatArea.MAX_ELEMENTS);
			var history_element:ChatHistoryElement;
			var i:int;
			var pc:PC;
			
			if(total && chat_area){
				//add them to the chat window
				// don't add more than the max allowed (making sure we get the most recent ones)
				Benchmark.addCheck('RSV.rejoin '+history.tsid+' '+start_index+' -> '+total);
				for(i = start_index; i < total; i++){
					history_element = ChatHistoryElement.fromHistoryArray(history.elements_storage_array[int(i)]);
									
					if(history_element && history_element.tsid){
						//make sure they have the proper perms
						pc = model.worldModel.getPCByTsid(history_element.tsid);
						if (pc) {
							if (!pc.is_admin && history_element.is_admin) pc.is_admin = true;
							if (!pc.is_guide && history_element.is_guide) pc.is_guide = true;
						} else if(history_element.tsid.substr(0,1) == 'P'){
							//we don't know about this PC yet, let's add it to the world!
							pc = new PC(history_element.tsid);
							pc.tsid = history_element.tsid;
							pc.label = history_element.label;
							pc.is_admin = history_element.is_admin;
							pc.is_guide = history_element.is_guide;
							
							model.worldModel.pcs[pc.tsid] = pc;
						}
						
						//add the element to the chat area (unless they were requests, then we don't care since they are in the past)
						if(history_element.type != ChatElement.TYPE_REQUEST){
							chat_area.addElement(history_element.tsid, history_element.text, history_element.type, history_element.tsid, .6, history_element.unix_timestamp);
						}
					}
					else {
						CONFIG::debugging {
							Console.warn('Element missing data! '+history.elements_storage_array[int(i)]);
						}
					}
				}
			}
			
			//see if there are any new messages in the trade dialog that needs to go in here
			if(TradeDialog.instance.visible && TradeManager.instance.player_tsid == chat_area.tsid){
				const trade_elements:Vector.<ChatElement> = TradeDialog.instance.getChatElements();
				var chat_element:ChatElement;
				
				for(i = 0; i < trade_elements.length; i++){
					chat_element = trade_elements[int(i)];
					
					//let's see if we have a match
					if(!chat_area.getChatElementMatch(chat_element)){
						//no match, go ahead and add it
						chat_area.addElement(chat_element.pc_tsid, chat_element.text, chat_element.type, chat_element.name, 1, chat_element.unix_timestamp);
					}
				}
			}
			
			//show the current time with a line to divide history from present
			if(total) chat_area.addElement(WorldModel.NO_ONE, '', ChatElement.TYPE_TIMESTAMP);
		}
		
		public function chatStart(tsid:String, is_pc:Boolean, force_active:Boolean, and_focus:Boolean=true):Boolean {
			if(!inited) return false;
			
			var pc:PC = is_pc ? model.worldModel.getPCByTsid(tsid) : null;
			var group:Group = is_pc ? null : model.worldModel.getGroupByTsid(tsid);
			var title:String;
			var chat_area:ChatArea;
			var i:int;
			
			//make sure the local chat knows where to go
			if(LocalStorage.instance.getUserData(LocalStorage.CONTACT_LIST_Y) != null){
				local_chat_y = LocalStorage.instance.getUserData(LocalStorage.CONTACT_LIST_Y);
			}
			else {
				local_chat_y = local_chat_y == CHAT_PADD ? chat_h/2 + CHAT_PADD*2 : local_chat_y;
			}
			
			//if this is our first new chat, make sure to build the multi-chat elements
			if(!is_multi_built) buildMulti();
			resizer.y = local_chat_y - CHAT_PADD*2;
			resizer.visible = true;
			
			//see if we already have this chat setup, and since we asked to use it, bring it to the front
			chat_area = getChatArea(tsid);

			if(!chat_area) {
				if(is_pc && pc){
					title = pc.label;
				}
				else if(tsid == ChatArea.NAME_PARTY){
					title = 'Party Chat';
				}
				else if(group){
					title = group.label;
				}
				else if(!pc && !group){
					//this is an itemstack chatting
					const itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
					if(itemstack){
						title = itemstack.label || itemstack.item.label;
					}
					else {
						title = 'Something';
					}
				}
				else {
					CONFIG::debugging {
						Console.warn('what is this?!:'+tsid);
					}
					return false;
				}
								
				//create the chat
				chat_area = createChatArea(tsid, title, tsid == ChatArea.NAME_UPDATE_FEED);
				
				//shove it in with the others
				other_chats.push(chat_area);
				
				//listen for things that happen
				chat_area.addEventListener(TSEvent.CLOSE, onChatClose, false, 0, true);
				
				//if we dont' have an active chat open, go ahead and open this one
				if(!active_chat) all_holder.addChild(chat_area);
				
				//add the history to the window if we have it
				chatShowHistory(chat_area, ChatHistory.getHistoryFromStorage(tsid));
				
				dispatchEvent(new TSEvent(TSEvent.CHAT_STARTED, tsid));
			}
			
			//set this chat as the active one
			if(!active_chat) active_chat = chat_area;
			
			//make sure it's enabled
			chat_area.enabled = is_pc ? (pc ? pc.online : false) : true;
			chat_area.online = chat_area.enabled;
			
			//tell the contact list to make this the active chat
			contact_list.chatOpen(tsid);
			
			//if this is a feed, load the first batch
			if(tsid == ChatArea.NAME_UPDATE_FEED){
				FeedManager.instance.refreshFeed(tsid, true);
			}
			
			refresh();
			
			if(force_active) chatActive(tsid, and_focus);
			
			return true;
		}
		
		public function chatUpdate(tsid:String, pc_tsid:String, txt:String, chat_element_type:String = '', chat_element_name:String = ''):void {
			if (!chat_element_type) chat_element_type = ChatElement.TYPE_CHAT;
			if (!chat_element_name) chat_element_name = pc_tsid;
			
			//throw the thing in the chat
			var chat_area:ChatArea = getChatArea(tsid);
			
			//if this is the global channel and we don't have it open, then jump out
			if(!chat_area && tsid == ChatArea.NAME_GLOBAL) return;
			if(!chat_area && tsid == ChatArea.NAME_HELP) return;
			if(!chat_area && tsid == ChatArea.NAME_TRADE) return;
						
			//we don't know about this chat yet, go ahead and start it up!
			if(!chat_area) {
				RightSideManager.instance.chatStart(tsid, false);
				chat_area = getChatArea(tsid);
				SoundMaster.instance.playSound('INCOMING_CHAT_NEW');
			}
			
			//add the element
			chat_area.addElement(pc_tsid, txt, chat_element_type, chat_element_name);
			
			//if this chat is active and the type is chat, make a sound
			//[SY] added that global chat doesn't make sounds. This might be good to have as a preference per channel. Dropdown maybe?
			if(model.worldModel.pc
				&& pc_tsid != model.worldModel.pc.tsid
				&& tsid != ChatArea.NAME_LOCAL
				&& tsid != ChatArea.NAME_GLOBAL
				&& tsid != ChatArea.NAME_TRADE
				&& chat_element_type == ChatElement.TYPE_CHAT 
				&& (chat_area == active_chat || tsid == ChatArea.NAME_LOCAL)){
				SoundMaster.instance.playSound('INCOMING_CHAT');
			}
			
			//update the contact list
			if(tsid != ChatArea.NAME_LOCAL && pc_tsid != WorldModel.NO_ONE) contactUpdate(tsid, false);
			if(model.worldModel.pc && pc_tsid != model.worldModel.pc.tsid) contactUpdate(pc_tsid, true);
			
			dispatchEvent(new TSEvent(TSEvent.CHAT_UPDATED, tsid));
		}
		
		public function chatActive(tsid:String, and_focus:Boolean=true):void {
			//see if we have the chat first
			var chat_area:ChatArea = getChatArea(tsid);
			var tmp_chat_area:ChatArea;
			var i:int;
			var pc:PC = model.worldModel.getPCByTsid(tsid);
			var is_enabled:Boolean = pc ? (pc.online ? true : false) : true;
			
			//check if it's party chat and there is in fact a party
			if(tsid == ChatArea.NAME_PARTY){
				is_enabled = model.worldModel.party ? true : false;
			}
						
			if(chat_area){
				//disable the other ones that are active
				for(i = 0; i < other_chats.length; i++){
					tmp_chat_area = other_chats[int(i)];
					if (tmp_chat_area != chat_area) {
						tmp_chat_area.enabled = false;
						if(tmp_chat_area.parent) tmp_chat_area.parent.removeChild(tmp_chat_area);
					}
				}
				
				chat_area.enabled = is_enabled;
				all_holder.addChild(chat_area);
				chat_area.setWidthHeight(MIN_WIDTH_CLOSED - CHAT_PADD*2, resizer.y - CHAT_PADD);
				chat_area.clearCounter();
				
				active_chat = chat_area;
				
				contact_list.chatActive(tsid);
				
				if(resizer) resizer.visible = true;
				refresh();
			}
			else {
				RightSideManager.instance.chatStart(tsid, true);
				chat_area = getChatArea(tsid);
			}
			
			if (chat_area && and_focus) {
				// we need a timeout here or there is a timing problem
				// and the chat_area does not successfully take focus
				StageBeacon.waitForNextFrame(chat_area.focus);
			}
		}
		
		public function chatEnd(tsid:String):void {
			var chat_area:ChatArea = all_holder.getChildByName(tsid) as ChatArea;
			
			if(!chat_area) {
				CONFIG::debugging {
					Console.warn('Chat area not found: '+tsid);
				}
				return;
			}
			
			//mark this for closing in the chat history
			ChatHistory.addHistoryToStorage(chat_area, true);
			
			other_chats.splice(other_chats.indexOf(chat_area), 1);
			all_holder.removeChild(chat_area);
			
			//let the contact list know what we are up to
			contact_list.chatClose(chat_area.name);
			
			//if this was a group chat, we need to tell the server that we closed it up
			if(model.worldModel.getGroupByTsid(tsid)){
				RightSideManager.instance.groupEnd(tsid);
			}
			
			//clean up the chat area
			chat_area.dispose();
			
			//get the last chat area in the list and show that
			if(other_chats.length > 0){
				if(!active_chat || active_chat.name == tsid){
					chat_area = other_chats[other_chats.length-1];
					chatActive(chat_area.name);
				}
			}
			//if that was the last one, put the local chat back to it's default state
			else {
				active_chat = null;
				local_chat_y = CHAT_PADD;
				resizer.visible = false;
				
				//if we have nothing open, clear it out, fixes dead groups
				LocalStorage.instance.removeUserData(LocalStorage.GROUPS_OPEN);
			}
			
			dispatchEvent(new TSEvent(TSEvent.CHAT_ENDED, tsid));
			
			refresh();
		}
		
		public function chatClear(tsid:String):void {
			//find the chat area and clear it out
			var chat_area:ChatArea = local_chat;
			
			if(tsid != ChatArea.NAME_LOCAL){
				chat_area = getChatArea(tsid);
			}
			
			if(chat_area) chat_area.clearElements();
		}
		
		public function chatCopy(tsid:String):void {
			//find the chat area and copy the elements
			var chat_area:ChatArea = local_chat;
			
			if(tsid != ChatArea.NAME_LOCAL){
				chat_area = getChatArea(tsid);
			}
			
			if(chat_area) {
				chat_area.copyElements();
			} else {
				model.activityModel.activity_message = Activity.createFromCurrentPlayer('Chat NOT copied to clipboard');
			}
		}
		
		public function chatDisableElement(tsid:String, chat_element_name:String, text_to_remove:String = ''):void {
			if(!chat_element_name) return;
			
			var chat_area:ChatArea = local_chat;
			
			if(tsid != ChatArea.NAME_LOCAL){
				chat_area = getChatArea(tsid);
			}
			
			if(chat_area) chat_area.disableElement(chat_element_name, text_to_remove);
		}
		
		public function chatRemoveElement(tsid:String, chat_element_name:String, only_disabled:Boolean = false):void {
			if(!chat_element_name) return;
			
			var chat_area:ChatArea = local_chat;
			
			if(tsid != ChatArea.NAME_LOCAL){
				chat_area = getChatArea(tsid);
			}
			
			if(chat_area) chat_area.removeElement(chat_element_name, only_disabled);
		}
		
		public function chatUpdateElement(tsid:String, chat_element_name:String, new_txt:String, text_to_remove:String = ''):void {
			if(!chat_element_name || !new_txt) return;
			
			var chat_area:ChatArea = local_chat;
			
			if(tsid != ChatArea.NAME_LOCAL){
				chat_area = getChatArea(tsid);
			}
			
			if(chat_area) chat_area.updateElement(chat_element_name, new_txt, text_to_remove);
		}
		
		public function chatsFlush():void {
			//go over all the chats and clear them
			if(!cdVO){
				cdVO = new ConfirmationDialogVO();
				cdVO.callback = onChatsFlushConfirm;
				cdVO.txt = "This will permanently empty the chat history currently saved on your computer and visible in your chat panes on the right. " +
						   "It's no big deal, but if there's stuff there you wanted to note down, you might want to do that first.";
				cdVO.escape_value = false;
				cdVO.choices = [
					{value:false, label:'No, nevermind'},
					{value:true, label:'Yes, go ahead!'}					
				];
			}
			TSFrontController.instance.confirm(cdVO);
		}
		
		/**
		 * Loops through all open chats and makes sure we have proper labels for everything
		 */		
		public function chatsUpdate():void {
			var chat_area:ChatArea;
			var i:int;
			var pc:PC;
			var group:Group;
			
			for(i = 0; i < other_chats.length; i++){
				chat_area = other_chats[int(i)];
				
				//get the tsid and check it against groups and players
				pc = model.worldModel.getPCByTsid(chat_area.tsid);
				group = model.worldModel.getGroupByTsid(chat_area.tsid, false);
				if(pc){
					chat_area.setTitle(pc.label);
					contactUpdate(pc.tsid, true);
				}
				else if(group){
					chat_area.setTitle(group.label);
					contactUpdate(group.tsid, false);
				}
			}
		}
		
		private function onChatsFlushConfirm(is_flush:Boolean):void {
			if(is_flush){
				//go ahead and clear all the chats
				const total:int = other_chats.length;
				var i:int;
				var chat_area:ChatArea;
				for(i; i < total; i++){
					chat_area = other_chats[int(i)];
					
					//don't clear out the updates
					if(chat_area.name != ChatArea.NAME_UPDATE_FEED){
						chat_area.clearElements();
					}
				}
				
				//also do local chat
				if(local_chat) local_chat.clearElements();
			}
		}
		
		public function feedUpdate(tsid:String, feed_item:FeedItem):void {
			//throw the thing in the chat
			const chat_area:FeedChatArea = getChatArea(tsid) as FeedChatArea;
			
			//unknown feed, throw an error and gtfo
			if(!chat_area) {
				CONFIG::debugging {
					Console.warn('Unable to find this feed in the chat areas:'+tsid);
				}
				return;
			}
			
			//add the item to the chat
			chat_area.addFeedItem(feed_item);
			
			dispatchEvent(new TSEvent(TSEvent.FEED_UPDATED, tsid));
		}
		
		public function contactUpdate(tsid:String, is_pc:Boolean):void {
			//update the contact list
			if(is_pc){
				contact_list.contactUpdate(tsid);
			}
			else if(!TradeDialog.instance.visible && TradeManager.instance.player_tsid != tsid){
				contact_list.chatUpdate(tsid);
			}
		}
		
		public function contactListToggle(is_open:Boolean):void {
			//toggle the contact list
			contact_list.toggleForce(is_open);
		}
		
		public function contactListShowHide():void {
			//if we are in capture mode, don't show it
			contact_list.visible = !model.stateModel.in_capture_mode;
		}
		
		public function contactListOpen():Boolean {
			return contact_list.is_open;
		}
		
		public function refresh(from_click:Boolean = false):void {
			if(!parent) return;
			
			//keep it on top TODO: find where this can be done ONCE
			parent.setChildIndex(this, parent.numChildren-1);
			
			const create_h:int = create_account_ui && create_account_ui.parent ? create_account_ui.height + 17 : 0;
			
			map_chat.refresh();
			map_chat.y = -map_chat.height;
			
			if(create_account_ui) {
				create_account_ui.x = contact_list.width;
				create_account_ui.y = map_chat.y - create_account_ui.height - 17;
			}
			y = map_h + create_h;
			
			//make sure the contact list is at the right height
			contact_list.y = map_tab_h ? -y + map_tab_h + create_h : 0;
			contact_list.refresh(null, chat_h + y - map_tab_h - create_h);
			
			all_holder.x = contact_list.width;
			
			//place the local chat in the right place
			if(local_chat) {
				const local_min_h:int = local_chat.getMinHeight();
				const active_min_h:int = active_chat ? active_chat.getMinHeight() : 0;
				
				//set the tab name incase we need to hide it
				if(map_chat && map_h && map_chat.tab_name != MapChatArea.TAB_NOTHING){
					tab_before_hide = map_chat.tab_name;
				}
				
				local_chat.y = local_chat_y;
				if(local_chat.height != local_min_h || !active_chat){
					local_chat.setWidthHeight(MIN_WIDTH_CLOSED - CHAT_PADD*2, chat_h - local_chat_y - CHAT_PADD);
				}
				
				if(resizer){
					//move the resizer so it's always just above it
					resizer.y = int(chat_h - local_chat.height - CHAT_PADD*3);
					onResizeMove();
					
					//can the active chat fit in there?
					if(active_chat && !active_chat.parent && (chat_h - local_min_h - CHAT_PADD*4 >= active_min_h)){
						active_chat.setWidthHeight(MIN_WIDTH_CLOSED - CHAT_PADD*2, active_min_h);
						chatActive(active_chat.tsid, false);
					}
					
					//if the local chat Y is all up in active_chat's shit, then move it down
					if(active_chat && active_chat.parent && resizer.y < active_chat.y + active_chat.height){
						resizer.y = int(active_chat.y + active_chat.height);
						resizer.visible = true;
						onResizeMove();
					}
					
					//if the min height of local chat puts it past the height + padd, we need to push it up
					if(local_chat.y + local_chat.height + CHAT_PADD > chat_h){
						if(active_chat && active_chat.parent && active_chat.height == active_min_h) {
							resizer.y = int(active_chat.y + active_chat.height);
						}
						else {
							resizer.y = chat_h - local_chat.height - CHAT_PADD*3;
						}
						onResizeMove();
						
						//if we still have our local chat too far down, then we need to hide the map until they click it (which hides the active chat)
						if(local_chat.y + local_chat.height + CHAT_PADD > chat_h){
							//-4 is to account for some padding on map_h, otherwise it'll hide itself when dragged around
							if(map_chat.tab_name == MapChatArea.TAB_MAP && map_h-4 > MapChatArea.MIN_HEIGHT){
								//size this down a bit
								map_chat.height = lm.loc_vp_h - chat_h - 4;
							}
							else {
								//remember what was there before having to hide it
								tab_before_hide = map_chat.tab_name;
								old_map_h = map_h;
								map_chat.setCurrentTab(MapChatArea.TAB_NOTHING);
								
								//keep local chat at the smallest height
								resizer.y = lm.loc_vp_h - local_min_h - CHAT_PADD*3 - y;
								onResizeMove();
							}
							
							if(from_click){
								//this means that the player clicked the teleport/map tab and we don't have enough room
								//gotta hide active_chat
								if(active_chat && active_chat.parent){
									active_chat.parent.removeChild(active_chat);
									contact_list.chatActive('nothing');
								}
								map_chat.setCurrentTab(tab_before_hide);
								tab_before_hide = null;
								resizer.y = -CHAT_PADD;
								resizer.visible = false;
								onResizeMove();
							}
						}
					}
					
					//did we have to hide the map chat before? If so, can we fit it back in here?
					if(active_chat && active_chat.parent && tab_before_hide && (chat_h - local_min_h - active_min_h > old_map_h + CHAT_PADD*4)){
						map_chat.setCurrentTab(tab_before_hide);
						tab_before_hide = null;
					}
				}
			}
			
			draw();
			
			//tell the model of our new width
			lm.right_col_w = all_mask.width - 32; //accounts for the negative X the mask has
			x = lm.loc_vp_w;
		}
		
		private function createChatArea(unique_id:String, title:String, is_feed:Boolean = false):ChatArea {
			var chat_area:ChatArea = (!is_feed ? new ChatArea(unique_id) : new FeedChatArea(unique_id));
			chat_area.x = chat_area.y = CHAT_PADD;
			chat_area.setWidthHeight(MIN_WIDTH_CLOSED - CHAT_PADD*2, (resizer && resizer.visible ? resizer.y - CHAT_PADD : chat_h - local_chat_y - CHAT_PADD));
			chat_area.setTitle(title);
			chat_area.addEventListener(TSEvent.MSG_SENT, onMsgSent, false, 0, true);
			chat_area.addEventListener(TSEvent.FOCUS_IN, onChatFocus, false, 0, true);
			
			return chat_area;
		}
		
		public function getChatArea(unique_id:String):ChatArea {
			if(unique_id == ChatArea.NAME_LOCAL) return local_chat;
			
			var i:int;
			var chat_area:ChatArea;
			
			for(i; i < other_chats.length; i++){
				chat_area = other_chats[int(i)];
				if(chat_area.name == unique_id) return chat_area;
			}
			
			return null;
		}
		
		public function getChatAreaPt(tsid:String):Point {
			var pt:Point = new Point(0,0);
			var chat_area:ChatArea = local_chat;
			
			if(tsid != ChatArea.NAME_LOCAL) chat_area = getChatArea(tsid);
			
			if(chat_area){
				if(tsid != ChatArea.NAME_LOCAL) chatActive(tsid, false);
				pt = chat_area.input_field.localToGlobal(new Point(0, chat_area.input_field.height/2));
			}
			
			pt.x -= model.layoutModel.gutter_w;
			pt.y -= model.layoutModel.header_h;
			
			return pt;
		}
		
		public function getChatToFocus():ChatArea {									
			if(active_chat && active_chat == last_focused_chat){
				return active_chat;
			}
			
			return local_chat;
		}
		
		public function getOpenChats():Vector.<ChatArea> {
			var chats:Vector.<ChatArea> = other_chats.concat();
			chats.push(local_chat);
			
			return chats;
		}
		
		public function isChatOpen(tsid:String):Boolean {
			if(getChatArea(tsid)) return true;
			return false;
		}
		
		public function isActiveChat(tsid:String):Boolean {
			if(active_chat && active_chat.tsid == tsid) return true;
			return false;
		}
		
		public function getContactsPt(is_active:Boolean):Point {			
			return contact_list.getContactsPt(is_active);
		}
		
		public function getContactPt(tsid:String):Point {			
			return contact_list.getContactPt(tsid);
		}
		
		public function getToggleButtonPt():Point {
			return contact_list.getToggleButtonPt();
		}
		
		public function getCreateAccountPt():Point {
			var pt:Point = new Point();
			if(create_account_ui && create_account_ui.parent){
				pt = create_account_ui.localToGlobal(new Point(0, create_account_ui.height/2));
			}
			
			return pt;
		}
		
		public function getVisibleChatAreas():Vector.<ChatArea> {
			var chat_areas:Vector.<ChatArea> = new Vector.<ChatArea>();
			chat_areas.push(local_chat);
			
			if(active_chat) chat_areas.push(active_chat);
			
			return chat_areas;
		}
		
		public function buddyManage(pc_tsid:String, is_online:Boolean, is_add:Boolean):void {
			//let the contact list deal with it
			contact_list.buddyManage(pc_tsid, is_online, is_add);
		}
		
		public function buddyUpdate(pc_tsid:String, is_online:Boolean):void {
			//tell the contact list to deal with them
			contact_list.buddyUpdate(pc_tsid, is_online);
			
			//if they have an active chat going with them, make sure to enable/disable it
			var chat_area:ChatArea = getChatArea(pc_tsid);
			if(chat_area){
				chat_area.online = is_online;
				
				//PC may have changed their name, or a stranger coming from being offline
				var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
				if(pc && pc.label) chat_area.setTitle(pc.label);
			} 
		}
		
		public function groupManage(group_tsid:String, is_join:Boolean):void {
			//update contact list
			contact_list.groupManage(group_tsid, is_join);
			
			//if we have an active chat and we are leaving, close it up
			if(!is_join && isChatOpen(group_tsid)) chatEnd(group_tsid);
		}
		
		public function groupSwitch(old_tsid:String, new_tsid:String):void {
			//update the contact list
			contact_list.groupSwitch(old_tsid, new_tsid);
			
			//update the chat area
			const chat_area:ChatArea = getChatArea(old_tsid);
			if(chat_area){
				chat_area.tsid = new_tsid;
				chat_area.name = new_tsid;
			}
		}
		
		public function localTradeStart():void {
			if(local_chat) local_chat.localTradeStart();
		}
		
		public function localTradeEnd():void {
			if(local_chat) local_chat.localTradeEnd();
		}
		
		public function updateMap():void {
			//show our current location
			map_chat.show();
			refresh();
		}
		
		public function updateYouOnMap():void {
			map_chat.updateYouOnMap();
		}
		
		public function setChatMapTab(tab_name:String = ''):void {
			if(!tab_name) tab_name = MapChatArea.TAB_MAP;
			map_chat.setCurrentTab(tab_name);
		}
		
		public function getChatMapTab():String {
			return map_chat.tab_name;
		}
		
		public function createAccountShowHide(is_showing:Boolean):void {
			//create it if we haven't already
			if(is_showing){
				if(!create_account_ui) create_account_ui = new CreateAccountUI();
				create_account_ui.show();
				addChild(create_account_ui);
			}
			else if(!is_showing && create_account_ui){
				create_account_ui.hide();
			}			
			
			refresh();
		}
		
		public function accountFeaturesShowHide():void {
			const is_showing:Boolean = !model.worldModel.location.no_account_required_features;
			
			//remove the global/updates from the feed if it's there
			contact_list.groupManage(ChatArea.NAME_UPDATE_FEED, is_showing, true);
			contact_list.groupManage(ChatArea.NAME_GLOBAL, is_showing, true);
			
			//toggle the add friends button
			contact_list.addFriendsShowHide(is_showing);
			
			refresh();
		}
		
		private function draw():void {
			//draw the base of this bad boy
			var g:Graphics = all_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			
			if(!map_chat.height){
				g.drawRoundRect(0, 0, MIN_WIDTH_CLOSED, chat_h, lm.loc_vp_elipse_radius*2);
			}
			else {
				//hard corners up top to butt up against the map
				g.drawRoundRectComplex(0, 0, MIN_WIDTH_CLOSED, chat_h, 0, 0, lm.loc_vp_elipse_radius, lm.loc_vp_elipse_radius);
			}
			
			g = all_mask.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(-20, -y, (contact_list.width + MIN_WIDTH_CLOSED) + 33, chat_h + y);
			
			if(resizer){
				g = resizer.graphics;
				g.clear();
				g.beginFill(0xffffff);
				g.drawRect(0, 0, MIN_WIDTH_CLOSED, resizer.height + 8); //buffer to grab it better
				
				var divider:DisplayObject = resizer.getChildAt(0);
				if(divider){
					divider.x = int(resizer.width/2 - divider.width/2);
					divider.y = int(resizer.height/2 - divider.height/2);
				} 
			}
		}
		
		private function onMsgSent(event:TSEvent):void {
			var chat_area:ChatArea = event.data as ChatArea;
			var txt:String = chat_area.input_field.text;
			
			//fire it off to the server
			RightSideManager.instance.sendToServer(chat_area.name, txt);
			
			//clear out the input field
			chat_area.input_field.text = '';
		}
		
		private function onContactToggle(event:TSEvent = null):void {
			//update the model with our width and refresh the VP						
			main_view.resizeToStage();
			
			LocalStorage.instance.setUserData(LocalStorage.CONTACT_LIST_OPEN, contact_list.is_open.toString(), true);
		}
		
		private function onChatClose(event:TSEvent):void {
			//remove it from the other chat list and let the contact list know we've removed it
			var chat_area:ChatArea = event.data as ChatArea;
			
			//if this is party chat, make sure they know that closing it means they leave the party
			if(chat_area.name == ChatArea.NAME_PARTY && chat_area.enabled){
				RightSideManager.instance.partyChatClose();
				return;
			}
			
			chatEnd(chat_area.name);
		}
		
		private function onChatFocus(event:TSEvent):void {
			//just make sure the last focused chat is updated
			last_focused_chat = event.data as ChatArea;
		}
		
		private function onResizeStart(event:MouseEvent):void {
			if(!local_chat || !active_chat) return;
			
			StageBeacon.mouse_move_sig.add(onResizeMove);
			StageBeacon.mouse_up_sig.add(onResizeEnd);
			
			active_chat.enabled = false;
			local_chat.enabled = false;
			
			const top:int = active_chat.getMinHeight() + CHAT_PADD;
			const bottom:int = chat_h - top - (local_chat.getMinHeight() + CHAT_PADD*3);
			drag_rect.y = top;
			drag_rect.height = bottom;
			
			/** DEBUG
			var g:Graphics = Sprite(resizer.parent).graphics;
			g.clear();
			g.beginFill(0xffcc00, .5);
			g.drawRect(0, top, MIN_WIDTH_CLOSED, bottom);
			//**/
			
			resizer.startDrag(false, drag_rect);
		}
		
		private function onResizeMove(event:MouseEvent = null):void {
			local_chat_y = resizer.y + CHAT_PADD*2;
			
			if(active_chat) active_chat.setWidthHeight(MIN_WIDTH_CLOSED - CHAT_PADD*2, resizer.y - CHAT_PADD);
			local_chat.y = local_chat_y;
			local_chat.setWidthHeight(MIN_WIDTH_CLOSED - CHAT_PADD*2, chat_h - local_chat_y - CHAT_PADD);
			
			//edge case, but it could happen!
			if(UICalloutView.instance.visible) UICalloutView.instance.refresh();
		}
		
		private function onResizeEnd(event:MouseEvent):void {
			StageBeacon.mouse_move_sig.remove(onResizeMove);
			StageBeacon.mouse_up_sig.remove(onResizeEnd);
			resizer.stopDrag();
			
			if(active_chat) active_chat.enabled = active_chat.online;
			local_chat.enabled = true;
			
			refresh();
			
			//save the Y value for next refresh
			LocalStorage.instance.setUserData(LocalStorage.CONTACT_LIST_Y, local_chat_y);
		}
		
		private function onLocalChange(event:TSEvent):void {
			//just force a refresh to make sure things are all lined up
			refresh();
		}
		
		private function get chat_h():int {
			return lm.loc_vp_h + (lm.pack_is_wide || (model.worldModel.location && !model.worldModel.location.show_pack) ? 0 : TSEngineConstants.MIN_PACK_HEIGHT - 10) - y;
		}
		
		public function get map_h():int {
			return map_chat.height;
		}
		
		public function get map_tab_h():int {
			return map_chat.tab_height;
		}
		
		public function get contact_list_w():int {
			return contact_list.width;
		}
		
		public function get available_h():int {
			//how much space can we afford to take up
			var room_left:int = chat_h - (local_chat.getMinHeight() + CHAT_PADD*3);
			if(active_chat) room_left -= active_chat.getMinHeight() + CHAT_PADD;
			
			return room_left;
		}
	}
}