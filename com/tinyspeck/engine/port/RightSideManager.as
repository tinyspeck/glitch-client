package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.chat.ChatHistory;
	import com.tinyspeck.engine.data.chat.FeedItem;
	import com.tinyspeck.engine.data.chat.InputHistory;
	import com.tinyspeck.engine.data.client.ActionRequest;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.loading.LoadingInfo;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCParty;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingGroupsChatJoinVO;
	import com.tinyspeck.engine.net.NetOutgoingGroupsChatLeaveVO;
	import com.tinyspeck.engine.net.NetOutgoingGroupsChatVO;
	import com.tinyspeck.engine.net.NetOutgoingGuideStatusChangeVO;
	import com.tinyspeck.engine.net.NetOutgoingImSendVO;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.net.NetOutgoingPartyChatVO;
	import com.tinyspeck.engine.net.NetOutgoingPartyLeaveVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.gameoverlay.BuffViewManager;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.ChatGodDebug;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.avatar.ActionRequestUI;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.chat.ChatElement;
	import com.tinyspeck.engine.view.ui.chat.FeedChatArea;
	import com.tinyspeck.engine.view.ui.chat.InputField;
	import com.tinyspeck.engine.view.ui.map.MapChatArea;
	
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	CONFIG::god { import com.tinyspeck.engine.view.gameoverlay.ViewportScaleSliderView; }
	CONFIG::god { import com.tinyspeck.engine.view.ui.chrome.GodButtonView; }

	public class RightSideManager extends EventDispatcher implements IMoveListener
	{
		/*****************************************************************
		 * All messages related to the right side of the client will
		 * start here. This class will pass to other managers or UI
		 * elements for updating.
		 * 
		 * See RightSideView for all UI holders related to the right side.
		 *****************************************************************/
		
		/* singleton boilerplate */
		public static const instance:RightSideManager = new RightSideManager();
		
		public static const DIRECTION_BACK:String = 'back';
		public static const DIRECTION_FORWARD:String = 'forward';
		public static const CLIENT_LINK_WRAP:String = '!##TS##!';
		public static const SPECIAL_SLUG_GAP:String = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
		
		private var input_history:Vector.<InputHistory> = new Vector.<InputHistory>();
		private var chats_to_retry:Array = new Array();
		private var other_colors:Array = new Array();
		private var action_requests:Vector.<ActionRequestUI> = new Vector.<ActionRequestUI>();
		
		public var right_view:RightSideView; //only way to access the view is via manager
		
		private var model:TSModelLocator;
		private var retry_timer:Timer = new Timer(1000);
		private var current_colors:Dictionary = new Dictionary();
		private var last_im_tsid:String;
		private var last_loc_tsid:String;
		private var last_loc_pc_tsid:String;
		
		private var color_index:uint;
		private var you_color:uint = 0xaa322a;
		private var god_color:uint = 0x7b5445;
		
		private var last_guide_status:Boolean;
		
		private var _global_chat_tsid:String; //tsid of global chat sent on login
		private var _live_help_tsid:String; //tsid of live help sent on login
		private var _trade_chat_tsid:String; //tsid of the trade channel sent on login
		private var _request_event_tsid:String;
		private var _request_event_type:String;
		
		public function RightSideManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
		}
		
		public function init():void {
			//load the local chat history
			getInputHistory(ChatArea.NAME_LOCAL);
			
			//add god to the PC dict if it's not there already
			if(!model.worldModel.getPCByTsid(WorldModel.GOD)){
				const god:PC = new PC(WorldModel.GOD);
				god.tsid = WorldModel.GOD;
				god.label = 'GOD';
				model.worldModel.pcs[WorldModel.GOD] = god;
			}
			
			//populate the colors
			var count:uint;
			you_color = CSSManager.instance.getUintColorValueFromStyle('chat_element_you', 'color', you_color);
			god_color = CSSManager.instance.getUintColorValueFromStyle('chat_element_god', 'color', god_color);
			while(CSSManager.instance.getStyle('chat_element_others_'+count).color){
				other_colors.push(CSSManager.instance.getUintColorValueFromStyle('chat_element_others_'+count, 'color'));
				count++;
			}
			
			//setup the width right off the bat
			right_view = new RightSideView();
			
			//listen for timer updates
			retry_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			
			//listen for triggers
			model.worldModel.registerCBProp(partyChatStatus, "party");
			model.activityModel.registerCBProp(partyChatActivity, "party_activity_message");
			model.activityModel.registerCBProp(activityChat, "activity_message");
			model.activityModel.registerCBProp(godChat, "god_message");
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, onPackDragStart, false, 0, true);
			TSFrontController.instance.registerMoveListener(this);
			
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					// disable during testing
					right_view.mouseEnabled = false;
					right_view.mouseChildren = false;
				}
			}
		}
		
		public function chatStart(tsid:String, force_active:Boolean, and_focus:Boolean = true):void {
			if(tsid == model.worldModel.pc.tsid) return;
			
			//see if this is a PC chat or group chat
			const is_pc:Boolean = model.worldModel.getPCByTsid(tsid) != null ? true : false;
			const is_group:Boolean = model.worldModel.getGroupByTsid(tsid) != null ? true : false;
			
			//make sure it's one or the other
			if(!is_pc && !is_group && tsid != ChatArea.NAME_PARTY){
				//check if it's an itemstack chattin' away
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
				if(!itemstack){
					CONFIG::debugging {
						Console.warn('This TSID is not in the world: '+tsid);
					}
					return;
				}
			}
			
			//if this is a pc that the player is ignoring, bail out
			if(is_pc && model.worldModel.getPCByTsid(tsid).ignored){
				CONFIG::debugging {
					Console.warn(tsid+' is trying to start a chat, but is ignored');
				}
				return;
			}
						
			//if the chat failed to start, save the data and try again soon
			if(!right_view.chatStart(tsid, is_pc, force_active, and_focus)){
				if(chats_to_retry.indexOf(tsid) == -1){
					chats_to_retry.push(tsid);
				}
				if(!retry_timer.running) retry_timer.start();
			}
			//see if we were waiting for it, and if so, delete it
			else {
				if(chats_to_retry.indexOf(tsid) != -1){
					chats_to_retry.splice(chats_to_retry.indexOf(tsid), 1);
				}
			}
		}
		
		public function chatUpdate(chat_name:String, pc_tsid:String, txt:String, chat_element_type:String = '', extra_sp:Sprite = null, chat_element_name:String = '', txt_not_for_bubble:String = ''):void {
			if (!chat_element_type) chat_element_type = ChatElement.TYPE_CHAT;
			if (!chat_element_name) chat_element_name = pc_tsid;
			if (txt.toLowerCase().indexOf('prisencolinensinainciusol') > -1 && model.worldModel.pc && pc_tsid == model.worldModel.pc.tsid) {
				SoundMaster.instance.playSound('Prisencolinensinainciusol', 0);
			}
			
			//build out the text to include the player name
			var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			var avatar:AbstractAvatarView = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
			var show_in_pane:Boolean = true;
		
			if(pc){			
				//if this is god talking, let's do that
				if(pc_tsid == WorldModel.GOD && chat_element_type == ChatElement.TYPE_CHAT){
					model.activityModel.god_message = txt;
					return;
				}
				
				//if this is someone we are ignoring, bail out
				if(pc.ignored) {
					CONFIG::debugging {
						Console.warn('That TSID is being ignored. Name: '+pc.label);
					}
					return;
				}
				
				//get the avatar
				if(pc != model.worldModel.pc){
					avatar = TSFrontController.instance.getMainView().gameRenderer.getPcViewByTsid(pc_tsid);
				}
				
				//if we have an avatar and this is local chat, format the text for them
				if(avatar && chat_name == ChatArea.NAME_LOCAL && chat_element_type != ChatElement.TYPE_ACTIVITY && chat_element_type != ChatElement.TYPE_MOVE){
					if (txt.toLowerCase() != 'hi') {
						avatar.chatBubbleManager.showBubble(chatGetText(chat_name, pc_tsid, txt, chat_element_type, false), extra_sp, chat_element_type == ChatElement.TYPE_REQUEST);
					}
				}
				
				//if this is our request, don't show it in the pane
				if(chat_element_type == ChatElement.TYPE_REQUEST && pc == model.worldModel.pc){
					show_in_pane = false;
				}
				
				//if we have extra chat text that we don't want to show in the avatar bubble, tack it on
				txt += txt_not_for_bubble;
				
				//parse the text for the right side
				txt = chatGetText(chat_name, pc_tsid, txt, chat_element_type);
				
				//check if this message was while we are trading
				if(TradeDialog.instance.visible && chat_name == TradeManager.instance.player_tsid){
					//put the chat element in the trade dialog
					TradeDialog.instance.addChatElement(pc_tsid, txt, chat_element_type, 0, true);
					
					//if we don't have the chat open, don't open it
					if(!right_view.getChatArea(chat_name)) {
						show_in_pane = false;
					}
					else if(!right_view.isActiveChat(chat_name) && pc != model.worldModel.pc){
						//make the chat sound when the chat isn't in focus on the right
						SoundMaster.instance.playSound('INCOMING_CHAT');
					}
				}
				
				//send it off to the right side
				if(show_in_pane) right_view.chatUpdate(chat_name, pc_tsid, txt, chat_element_type, chat_element_name);
			}
			else if(model.worldModel.getItemstackByTsid(pc_tsid)){
				//NPC chatting
				txt = chatGetText(chat_name, pc_tsid, txt, chat_element_type);
				
				//send it off to the right side
				right_view.chatUpdate(chat_name, pc_tsid, txt, chat_element_type, chat_element_name);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Uhhh, pc is null: '+pc_tsid);
				}
			}
		}
		
		public function chatEnd(tsid:String):void {
			//close the chat window
			right_view.chatEnd(tsid);
		}
		
		public function chatGetText(chat_name:String, pc_tsid:String, txt:String, chat_element_type:String = '', show_pc_label:Boolean = true):String {
			if (!chat_element_type) chat_element_type = ChatElement.TYPE_CHAT;
			
			//build out the text to include the player name
			const pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			var label:String = model.worldModel.pc && pc_tsid == model.worldModel.pc.tsid 
				? '<font color="'+getPCColorHex(pc_tsid)+'">You</font>'
				: '<font color="'+getPCColorHex(pc_tsid)+'">GOD</font>';
			
			//replace the instances of you, your, etc. with the right color
			if(chat_element_type != ChatElement.TYPE_CHAT && model.worldModel.pc && pc_tsid == model.worldModel.pc.tsid){
				txt = youText(txt);
			}
			
			if(pc){
				//replace the linked player text with the proper color
				txt = otherText(txt);
				
				//set the label
				if(pc != model.worldModel.pc && pc_tsid != WorldModel.GOD){
					//PC.as handles the chars getting escapped in the label
					label = '<a href="event:'+TSLinkedTextField.LINK_PC+'|'+pc_tsid+'" class="'+getPCCSSClass(pc_tsid)+'">'+pc.label+'</a>';
					
					//check to make sure the location label is at least set to online until we get more data
					if(pc.location && pc.location.label == 'offline'){
						pc.location.label = 'online';
					}
				}
				
				//format the text for each element type
				if(chat_element_type == ChatElement.TYPE_CHAT){
					label = '<b>'+label+'</b>';
					txt = StringUtil.linkify(txt, 'chat_element_url');
					if(show_pc_label) txt = label+'  '+txt;
				}
				//bold the name and place the text after it
				else if(chat_element_type == ChatElement.TYPE_REQUEST || chat_element_type == ChatElement.TYPE_GOD_MSG){
					label = '<b>'+label+'</b>';
					if(show_pc_label) txt = label+' '+txt;
				}
				//nothing
				else if(chat_element_type == ChatElement.TYPE_ACTIVITY){
					
				}
				
				//if this is an admin, make the gap in chat text
				if(chat_element_type == ChatElement.TYPE_CHAT && show_pc_label){
					if(chat_name && chat_name == ChatArea.NAME_HELP){ 
						// guides only get a slug in help chat
						if (pc.is_admin || pc.is_guide) txt = SPECIAL_SLUG_GAP + txt;
					}else {
						if (pc.is_admin && !pc.is_guide) txt = SPECIAL_SLUG_GAP + txt;
					}
				}
			}
			else if(model.worldModel.getItemstackByTsid(pc_tsid)){
				//this is an itemstack/npc chattin' away
				//SY this style method is axed, but I'm keeping it here because I think it's better that
				//all NPCs share a similar color. Time will tell.
				//label = '<span class="chat_element_npc"><b>'+model.worldModel.getItemstackByTsid(pc_tsid).label+'</b></span>';
				//txt = '<span class="chat_element_npc_chat">'+txt+'</span>';
				label = '<b><span class="'+getPCCSSClass(pc_tsid)+'">'+model.worldModel.getItemstackByTsid(pc_tsid).label+'</span></b>';
				if(show_pc_label) txt = label+'  '+txt;
			}
			
			//if we are parsing a special type of link sent from the client, handle that
			txt = parseClientLink(txt);
			
			//wrap it in the right css
			if(show_pc_label) txt = '<p class="chat_element_'+chat_element_type+'">'+txt+'</p>';
			
			return txt;
		}
		
		public function chatClear(chat_name:String):void {
			if(!chat_name) chat_name = ChatArea.NAME_LOCAL;
			right_view.chatClear(chat_name);
		}
		
		public function chatCopy(chat_name:String):void {
			right_view.chatCopy(chat_name);
		}
		
		public function chatsFlush():void {
			//this just goes over each chat pane and clears it
			right_view.chatsFlush();
		}
		
		public function getContentsOfAllChatsThatReferenceStr(search_str:String=''):String {
			var txt:String = '';
			var chats:Vector.<ChatArea> = right_view.getOpenChats();
			
			var chat_area:ChatArea;
			var chat_copy:String = '';
			var i:int;
			var pc:PC;
			var group:Group;
			
			//loop through the open chats get and format the contents if relevant
			for(i = 0; i < chats.length; i++){
				chat_area = chats[int(i)];
				if (chat_area is FeedChatArea) continue;
				
				chat_copy = chat_area.getElements(true);
				if (!chat_copy) continue;
				if (search_str && chat_copy.indexOf(search_str) == -1) continue;
				
				txt+= '\n\nCHAT: '+chat_area.name;
				pc = model.worldModel.getPCByTsid(chat_area.name);
				if (pc) {
					txt+= ' (PC: '+pc.label+')';
				}
				group = model.worldModel.getGroupByTsid(chat_area.name);
				if (group) {
					txt+= ' (GROUP: '+group.label+')';
				}
				txt+= '\n-------------------------------------------------------';
				txt+= '\n'+chat_copy;
				txt+= '\n-------------------------------------------------------';
			}
			return txt;
		}
		
		private function partyChatStatus(party:PCParty):void {
			//if we have a party to start, then let's start it!
			if(party){
				chatStart(ChatArea.NAME_PARTY, true, false);
			}
			//last person left the party, go ahead and close this if it's open
			else if(right_view.isChatOpen(ChatArea.NAME_PARTY)){
				right_view.chatEnd(ChatArea.NAME_PARTY);
			}
		}
		
		private function partyChatActivity(txt:String):void {
			if(right_view.isChatOpen(ChatArea.NAME_PARTY)){
				chatUpdate(ChatArea.NAME_PARTY, model.worldModel.pc.tsid, txt, ChatElement.TYPE_ACTIVITY);
			}
			//if the chat is closed, throw it in local chat
			else {
				var activity:Activity = new Activity('party end');
				activity.pc_tsid = model.worldModel.pc.tsid;
				activity.txt = txt;
				activityChat(activity);
			}	
		}
		
		private function godChat(txt:String):void {			
			//convert this to something a little more noticeable
			chatUpdate(ChatArea.NAME_LOCAL, WorldModel.GOD, txt, ChatElement.TYPE_GOD_MSG);
		}
		
		private function activityChat(activity:Activity):void {
			if(!activity) return;
			
			//if we don't have a pc_tsid that means that the activity is neautral
			if(!activity.pc_tsid) activity.pc_tsid = WorldModel.NO_ONE;
			if(!model.worldModel.getPCByTsid(WorldModel.NO_ONE)){
				const no_one:PC = new PC(WorldModel.NO_ONE);
				no_one.tsid = WorldModel.NO_ONE;
				no_one.label = '';
				model.worldModel.pcs[WorldModel.NO_ONE] = no_one;
			}
			
			if(activity.auto_prepend || activity.pc_tsid == WorldModel.GOD){
				//add the player name to the txt
				const pc:PC = model.worldModel.getPCByTsid(activity.pc_tsid);
				if(activity.pc_tsid == WorldModel.GOD){
					activity.txt = '<span class="'+getPCCSSClass(pc.tsid)+'">'+pc.label+'</span> ' + activity.txt;
				}
				else if(pc){
					activity.txt = '<a href="event:'+TSLinkedTextField.LINK_PC+'|'+pc.tsid+'" class="'+getPCCSSClass(pc.tsid)+'">'+pc.label+'</a> ' + activity.txt;
				}
			}
			chatUpdate(ChatArea.NAME_LOCAL, activity.pc_tsid, activity.txt, ChatElement.TYPE_ACTIVITY);
		}
		
		public function feedUpdate(feed_tsid:String, feed_item:FeedItem):void {
			right_view.feedUpdate(feed_tsid, feed_item);
		}
		
		public function sendToServer(name:String, txt:String, is_from_right_side:Boolean = true):void {
			if(!txt) return;
			
			//see if the text is an emote
			if(name == ChatArea.NAME_LOCAL) {
				Emotes.instance.showEmote(txt);
			}
			
			txt = Emotes.instance.showAfk(txt);
			
			if(!txt) return;
			
			//client-side commands that bypass the debug ones
			//TODO [SY] move this into it's own class
			if(txt == '/clear'){
				chatClear(name);
				addToHistory(name, txt);
				return; //don't send it off to the server
			}
			else if(txt == '/flush'){
				chatsFlush();
				addToHistory(name, txt);
				return; //don't send it off to the server
			}
			//kristel needed a way to hide the UI to record the game screen
			else if(txt == '/capture'){
				const pc:PC = model.worldModel.pc;
				if(pc && pc.is_admin){
					model.stateModel.in_capture_mode = !model.stateModel.in_capture_mode;
					
					//get the metabolics outta here
					YouDisplayManager.instance.visible = !model.stateModel.in_capture_mode;
					YouDisplayManager.instance.pack_tabber.visible = !model.stateModel.in_capture_mode;
					BuffViewManager.instance.visible = !model.stateModel.in_capture_mode;
					MiniMapView.instance.visible = !model.stateModel.in_capture_mode;
					right_view.contactListShowHide();
					
					CONFIG::god {
						ViewportScaleSliderView.instance.visible = !model.stateModel.in_capture_mode;
						GodButtonView.instance.visible = !model.stateModel.in_capture_mode;
					}
					return;
				}
			}
			//want to test chat stuff? Throw it in ChatGodDebug
			else if(ChatGodDebug.instance.parse(txt, name)) {
				addToHistory(name, txt);
				return; //don't send it off to the server
			}
			
			//add it to the history
			addToHistory(name, txt);
			
			//handle outgoing text
			if(name == ChatArea.NAME_PARTY) {
				TSFrontController.instance.genericSend(new NetOutgoingPartyChatVO(txt), onPartySend, onPartySend);
			} 
			else if(name == ChatArea.NAME_LOCAL) {
				TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO(txt));
			}
			else if(name == ChatArea.NAME_UPDATE_FEED) {
				FeedManager.instance.setStatus(txt);
			}
			else if(model.worldModel.getPCByTsid(name)) {
				last_im_tsid = name;
				TSFrontController.instance.genericSend(new NetOutgoingImSendVO(name, txt), onIMSend, onIMSend);
				
				/*
				THIS HAS BEEN MOVED TO NC's handler for MessageTypes.IM_SEND messages, so we are using the properly formattd text provided in the response message
				
				//clean up any < or > before firing it to the chat area
				txt = StringUtil.encodeHTMLUnsafeChars(txt);
				
				//if we are chatting outside of the right side (trade dialog) make sure they already have an active chat before updating the right
				if(is_from_right_side || (!is_from_right_side && right_view.getChatArea(name))){
					chatUpdate(name, model.worldModel.pc.tsid, txt);
				}
				else if(TradeDialog.instance.visible && TradeManager.instance.player_tsid == name){
					TradeDialog.instance.addChatElement(model.worldModel.pc.tsid, txt);
				}
				*/
			}
			else if(model.worldModel.getItemstackByTsid(name)){
				last_im_tsid = name;
				TSFrontController.instance.genericSend(new NetOutgoingImSendVO(null, txt, name), onIMSend, onIMSend);
				
				/*
				THIS HAS BEEN MOVED TO NC's handler for MessageTypes.IM_SEND messages, so we are using the properly formattd text provided in the response message
				
				//clean up any < or > before firing it to the chat area
				txt = StringUtil.encodeHTMLUnsafeChars(txt);
				
				//toss it in the chat pane
				chatUpdate(name, model.worldModel.pc.tsid, txt);
				*/
			}
			else if(model.worldModel.getGroupByTsid(name)) {
				TSFrontController.instance.genericSend(new NetOutgoingGroupsChatVO(name, txt), onGroupSend, onGroupSend);
			}
		}
		
		private function onPartySend(nrm:NetResponseMessageVO):void {
			if(!nrm.success) {
				model.activityModel.party_activity_message = nrm.payload.error.msg;
				CONFIG::debugging {
					Console.warn('onPartySend failure');
					Console.dir(nrm.payload);
				}
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		private function onGroupSend(nrm:NetResponseMessageVO):void {
			if(!nrm.success) {
				model.activityModel.party_activity_message = nrm.payload.error.msg;
				CONFIG::debugging {
					Console.warn('onGroupSend failure');
					Console.dir(nrm.payload);
				}
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		private function onIMSend(nrm:NetResponseMessageVO):void {
			if(!nrm.success) {
				//create an activity to put in the chat pane
				var txt:String;
				const pc:PC = model.worldModel.getPCByTsid(last_im_tsid);
				if(pc){
					if (nrm.payload.reason == 'unknown command') {
						txt = nrm.payload.reason;
					} else {
						txt = '<a href="event:'+TSLinkedTextField.LINK_PC+'|'+pc.tsid+'" class="'+getPCCSSClass(pc.tsid)+'">'+pc.label+'</a> is ' + nrm.payload.reason;
					}
				}
				else {
					//we chatting to an itemstack perhaps?
					const itemstack:Itemstack = model.worldModel.getItemstackByTsid(last_im_tsid);
					if(itemstack){
						txt = itemstack.label || itemstack.item.label;
						txt += ' is ' + nrm.payload.reason;
					}
				}
				
				if(txt){
					//toss it in the pane
					chatUpdate(last_im_tsid, WorldModel.NO_ONE, txt, ChatElement.TYPE_ACTIVITY);
				}
				
				CONFIG::debugging {
					Console.warn('onIMSend failure');
					Console.dir(nrm.payload);
				}
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		private function addToHistory(tsid:String, txt:String):void {
			//add it to the history
			var history_str:String = StringUtil.trim(txt);
			var history:InputHistory = getInputHistory(tsid);
			
			//if we don't have have a history yet, let's make one!
			if(!history){
				history = new InputHistory(tsid);
				input_history.push(history);
			}
			
			// we only want unique slash commands in his history
			if(history_str.indexOf('/') == 0) { // it is a slash command
				var index_in_history:int = history.elements.indexOf(history_str);
				while (index_in_history != -1) { // is it already in the history?
					history.elements.splice(index_in_history, 1); // remove it
					index_in_history = history.elements.indexOf(history_str); // see if there is another one
				}
			}
			
			//make sure our elements aren't too large
			while(history.elements.length > InputHistory.MAX_ELEMENTS){
				history.elements.shift();
			}
			
			//throw it into the element if it wasn't the same as the last input
			if(history.elements.length && history_str == history.elements[history.elements.length-1]){
				//nuffin'
			}
			else {
				history.elements.push(history_str);
			}
			history.history_index = history.elements.length;
		}
		
		public function getHistory(tsid:String, direction:String = RightSideManager.DIRECTION_BACK):String {
			var history:InputHistory = getInputHistory(tsid);
			if(!history) return '';
			
			if(direction == DIRECTION_BACK){
				if(history.history_index > 0) history.history_index--;
			}
			//must want to go forward
			else {
				if(history.history_index < history.elements.length-1){
					history.history_index++;
				}
				else {
					//no more history, return nothing
					history.history_index = history.elements.length;
					return '';
				}
			}
			
			//put the history in the text field
			if(history.elements.length) return history.elements[history.history_index];
			
			return '';
		}
		
		public function stringInHistory(tsid:String, str_to_find:String):Boolean {		
			var history:InputHistory = getInputHistory(tsid);
			if(!history || (history && history.elements.indexOf(str_to_find) == -1)) return false;
			
			return true;
		}
		
		private function getInputHistory(tsid:String):InputHistory {
			var i:int;
			var history:InputHistory;
			var append:String = '_'+tsid;
			if(tsid == ChatArea.NAME_LOCAL) append = '';
			
			//check to see if we've already added it
			for(i; i < input_history.length; i++){
				history = input_history[int(i)];
				if(history.tsid == tsid) return history;
			}
			
			//check the local storage
			if(LocalStorage.instance.getUserData(LocalStorage.LOCAL_CHAT_HISTORY+append)) {
				history = new InputHistory(tsid);
				history.elements = Vector.<String>(LocalStorage.instance.getUserData(LocalStorage.LOCAL_CHAT_HISTORY+append));
				history.history_index = history.elements.length;
				
				input_history.push(history);
				
				return history;
			}
			
			return null;
		}
		
		public function partyChatClose():void {
			TSFrontController.instance.confirm(
				new ConfirmationDialogVO(
					onPartyConfirm,
					'Are you sure you want to leave your party? You\'ll have to be invited back to rejoin.',
					[
						{value: false, label: 'Never mind.'},
						{value: true, label: 'Yes, I\'d like to leave the party.'}
					],
					false
				)
			);
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function onPartyConfirm(value:*):void {
			if (value === true) {
				TSFrontController.instance.genericSend(new NetOutgoingPartyLeaveVO, onPartyLeave, onPartyLeave);
			}
		}
		
		private function onPartyLeave(nrm:NetResponseMessageVO):void {
			//they left the party, maybe
			SoundMaster.instance.playSound(nrm.success ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			
			//close the window if for some reason it's still there (shouldn't be)
			if(nrm.success && right_view.getChatArea(ChatArea.NAME_PARTY)){
				right_view.chatEnd(ChatArea.NAME_PARTY);
			}
		}
		
		private function onTimerTick(event:TimerEvent):void {
			//try again!
			var i:int;
			
			if(chats_to_retry.length > 0){
				for(i; i < chats_to_retry.length; i++){
					chatStart(chats_to_retry[int(i)], true, false);
				}
			}
			//no need for the timer anymore
			else {
				retry_timer.stop();
			}			
		}
		
		private function onPackDragStart(event:TSEvent):void {
			StageBeacon.mouse_move_sig.add(onPackDragMove);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragStop, false, 0, true);
		}
		
		private function onPackDragMove(event:MouseEvent = null):ChatArea {			
			var chat_areas:Vector.<ChatArea> = right_view.getVisibleChatAreas();
			var chat_area:ChatArea;
			var i:int;
			
			for(i; i < chat_areas.length; i++){
				chat_area = chat_areas[int(i)];
				chat_area.input_field.onRollOut();
				if(chat_area.isHittingChatArea(Cursor.instance.drag_DO)){
					Cursor.instance.showTip('Link to this item');
					chat_area.input_field.onRollOver();
					return chat_area;
				}
			}
			
			return null;
		}
		
		private function onPackDragStop(event:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(onPackDragMove);
			
			//did we drop this on the chat?
			var chat_area:ChatArea = onPackDragMove();
			if(chat_area){
				var iiv:ItemIconView = Cursor.instance.drag_DO as ItemIconView;
				
				if(iiv){
					var item:Item = model.worldModel.getItemByTsid(iiv.tsid);
					chat_area.input_field.focusOnInput();
					chat_area.input_field.setLinkText(item.label, TSLinkedTextField.LINK_ITEM+'|'+item.tsid);
				}
			}
			
			Cursor.instance.hideTip();
		}
		
		private function getPCColorIndex(pc_tsid:String):int {
			if(!current_colors.hasOwnProperty(pc_tsid)){
				current_colors[pc_tsid] = color_index;
				color_index++;
				if(color_index == other_colors.length) color_index = 0;
			}
			
			return current_colors[pc_tsid];
		}
		
		public function getPCColorUint(pc_tsid:String):uint {
			var color:uint = you_color;
			
			if(model.worldModel.pc && pc_tsid != model.worldModel.pc.tsid){
				color = other_colors[getPCColorIndex(pc_tsid)];
			}
			
			if(pc_tsid == WorldModel.GOD) color = god_color;
			
			return color;
		}
		
		public function getPCColorHex(pc_tsid:String):String {						
			return ColorUtil.colorNumToStr(getPCColorUint(pc_tsid), true);
		}
		
		public function getPCCSSClass(pc_tsid:String):String {			
			if(model && model.worldModel.pc && model.worldModel.pc.tsid == pc_tsid){
				return 'chat_element_you';
			}
			else {
				return 'chat_element_others_'+getPCColorIndex(pc_tsid);
			}
		}
		
		public function buddyManage(pc_tsid:String, is_add:Boolean):void {
			var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			
			if(pc){
				//using events for other classes to listen to
				if(is_add){
					dispatchEvent(new TSEvent(TSEvent.BUDDY_ADDED, pc_tsid));
				}
				else {
					dispatchEvent(new TSEvent(TSEvent.BUDDY_REMOVED, pc_tsid));
				}
				
				//update the right view
				right_view.buddyManage(pc.tsid, pc.online, is_add);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Missing the PC!');
				}
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		public function buddyUpdate(pc_tsid:String):void {
			var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			
			if(pc){
				//using events for other classes to listen to
				if(pc.online){
					dispatchEvent(new TSEvent(TSEvent.BUDDY_ONLINE, pc_tsid));
				}
				else {
					dispatchEvent(new TSEvent(TSEvent.BUDDY_OFFLINE, pc_tsid));
				}
				
				//update the right view
				right_view.buddyUpdate(pc.tsid, pc.online);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Missing the PC!');
				}
			}
		}
		
		public function groupStart(group_tsid:String, from_auto_join:Boolean = false):void {
			if(!RightSideManager.instance.right_view.isChatOpen(group_tsid)){
				//check to make sure if it's live help/trade that they clicked the button first
				if(group_tsid != ChatArea.NAME_HELP
					&& group_tsid != ChatArea.NAME_TRADE
					&& group_tsid != ChatArea.NAME_UPDATE_FEED 
					|| (group_tsid == ChatArea.NAME_HELP && from_auto_join == true)
					|| (group_tsid == ChatArea.NAME_TRADE && from_auto_join == true)){
					TSFrontController.instance.genericSend(new NetOutgoingGroupsChatJoinVO(group_tsid), onGroupConnect, onGroupConnect);
				}
			}
			
			//see if we are asking for live help/trade or not
			if((group_tsid != ChatArea.NAME_HELP && group_tsid != ChatArea.NAME_TRADE) || from_auto_join){
				chatStart(group_tsid, true, !from_auto_join);
			}
			//open the live help dialog
			else if(group_tsid == ChatArea.NAME_HELP){
				LiveHelpDialog.instance.start();
			}
			//open the trade channel dialog
			else if(group_tsid == ChatArea.NAME_TRADE){
				TradeChannelDialog.instance.start();
			}
			
			//don't blast the local storage if we don't need to
			if(from_auto_join) return;
			if(group_tsid == ChatArea.NAME_GLOBAL || group_tsid == ChatArea.NAME_HELP || group_tsid == ChatArea.NAME_TRADE) return;
			
			//add it to the list of open chats (if not already there)
			var group_chats:Array = LocalStorage.instance.getUserData(LocalStorage.GROUPS_OPEN);
			if(group_chats){
				if(group_chats.indexOf(group_tsid) == -1){
					group_chats.push(group_tsid);
				}
			}
			else {
				group_chats = new Array(group_tsid);
			}
			
			LocalStorage.instance.setUserData(LocalStorage.GROUPS_OPEN, group_chats, true);
		}
		
		public function groupEnd(group_tsid:String):void {
			if(!model.worldModel.getGroupByTsid(group_tsid)) return;
			
			//since updates are not something we join, don't send things to the server
			if(group_tsid != ChatArea.NAME_UPDATE_FEED){
				//leave the group
				TSFrontController.instance.genericSend(new NetOutgoingGroupsChatLeaveVO(group_tsid));
			}		
			
			var group_chats:Array = LocalStorage.instance.getUserData(LocalStorage.GROUPS_OPEN);
			
			//remove from the list of open groups
			if(group_chats && group_chats.indexOf(group_tsid) != -1){
				group_chats.splice(group_chats.indexOf(group_tsid), 1);
			}
			
			//throw it back in the SO
			LocalStorage.instance.setUserData(LocalStorage.GROUPS_OPEN, group_chats, true);
		}
		
		private function onGroupConnect(nrm:NetResponseMessageVO):void {
			if(!nrm.success){
				model.activityModel.party_activity_message = nrm.payload.error.msg;
				CONFIG::debugging {
					Console.warn('onGroupConnect failure');
					Console.dir(nrm.payload);
				}
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
			else {
				//SoundMaster.instance.playSound('CLICK_SUCCESS');
			}
		}
		
		public function groupUpdate(group_tsid:String, pc_tsid:String, txt:String):void {
			//if we got a group chat, but are not a member of that group, bail out
			if(!model.worldModel.getGroupByTsid(group_tsid)){
				CONFIG::debugging {
					Console.warn('Sending chat when this player --> '+pc_tsid+' is not a memeber of this group --> '+group_tsid);
				}
				return;
			} 
			
			//if god, make it no one since god doesn't care about your stupid group
			if(pc_tsid == WorldModel.GOD) pc_tsid = WorldModel.NO_ONE;
			
			//send it off to the group, but convert this into an activity if no_one
			chatUpdate(group_tsid, pc_tsid, txt, (pc_tsid != WorldModel.NO_ONE ? ChatElement.TYPE_CHAT : ChatElement.TYPE_ACTIVITY));
		}
		
		public function groupManage(group_tsid:String, is_join:Boolean):void {
			right_view.groupManage(group_tsid, is_join);
			
			//let whoever is listening know about it
			dispatchEvent(new TSEvent(TSEvent.GROUPS_CHANGED, group_tsid));
		}
		
		public function groupSwitch(old_tsid:String, new_tsid:String):void {
			if(!old_tsid || !new_tsid){
				CONFIG::debugging {
					Console.warn('Missing old_tsid or new_tsid');
				}
				return;
			}
			
			//change the model
			if(old_tsid == live_help_tsid){
				live_help_tsid = new_tsid;
			}
			else if(old_tsid == global_chat_tsid){
				global_chat_tsid = new_tsid;
			}
			else {
				var group:Group = model.worldModel.getGroupByTsid(old_tsid);
				if(group){
					delete model.worldModel.groups[group.tsid];
					
					group.tsid = new_tsid;
					model.worldModel.groups[group.tsid] = group;
				}
			}
			
			//let the view know!
			right_view.groupSwitch(old_tsid, new_tsid);
		}
		
		public function pcStatus(pc_tsid:String):void {
			//if we have been speaking with this person go ahead and update
			if(right_view.isChatOpen(pc_tsid)){
				var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
				if(pc){
					var txt:String = '<a href="event:'+TSLinkedTextField.LINK_PC+'|'+pc.tsid+'" class="'+getPCCSSClass(pc.tsid)+'">'+pc.label+'</a> is ' + 
									 (pc.online ? 'online' : 'offline');
					chatUpdate(pc.tsid, WorldModel.NO_ONE, txt, ChatElement.TYPE_ACTIVITY);
					
					//handle the contact list for this tsid
					right_view.buddyUpdate(pc.tsid, pc.online);
				}
			}
		}
		
		public function actionRequest(request:ActionRequest):void {
			if(!request || !request.player_tsid) return;
			
			//build out the text with the right accept link on it
			var txt:String = request.txt;
			var txt_not_for_bubble:String = '';
						
			if(model && request.player_tsid == model.worldModel.pc.tsid) {
				_request_event_type = request.event_type;
				_request_event_tsid = request.event_tsid;
				
				//if you update your old local trade it will cancel, so we need to show it again
				if(model.flashVarModel.use_local_trade && request.event_type == TSLinkedTextField.LINK_TRADE){
					const chat_area:ChatArea = right_view.getChatArea(ChatArea.NAME_LOCAL);
					if(chat_area && !chat_area.localTradeVisible()){
						chat_area.localTradeStart(request);
					}
				}
			}
			else {
				//if there isn't a link there already, let's add one in!
				txt_not_for_bubble = getActionLink(request);
			}
			
			chatUpdate(ChatArea.NAME_LOCAL, request.player_tsid, txt, ChatElement.TYPE_REQUEST, getActionUI(request), request.uid, txt_not_for_bubble);
		}
		
		public function actionRequestUpdate(request:ActionRequest):void {
			if(!request || !request.player_tsid) return;
			
			const pc:PC = model.worldModel.getPCByTsid(request.player_tsid);
			
			//if this is someone we are ignoring, bail out
			if(pc && pc.ignored) {
				CONFIG::debugging {
					Console.warn('That TSID is being ignored. Name: '+pc.label);
				}
				return;
			}
			
			//update the chat bubble to show the new data
			var avatar:AbstractAvatarView = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
			
			if(model && request.player_tsid != model.worldModel.pc.tsid){
				avatar = TSFrontController.instance.getMainView().gameRenderer.getPcViewByTsid(request.player_tsid);
			}
			
			//update the bubble with the txt
			if(avatar) avatar.chatBubbleManager.updateBubbleContent(request.txt, getActionUI(request));
			
			//update the chat text with the new text
			if(pc){
				var label:String;
				var new_txt:String;
				var text_to_remove:String;
				
				if(request.txt){
					//if we haven't added our own accept text in there, let's add it
					request.txt += getActionLink(request);
					label = '<b><a href="event:'+TSLinkedTextField.LINK_PC+'|'+pc.tsid+'" class="'+getPCCSSClass(pc.tsid)+'">'+pc.label+'</a></b>';
					new_txt = '<p class="chat_element_request">'+label+' '+otherText(request.txt)+'</p>';
				}
				//have we replied to it?
				else if(ActionRequestManager.instance.hasRespondedToRequestUid(request.uid)){
					//strip out the link if it's there
					text_to_remove = getActionLink(request);
					
					const local_chat:ChatArea = right_view.getChatArea(ChatArea.NAME_LOCAL);
					if(local_chat){
						const chat_elements:Vector.<ChatElement> = local_chat.getElementsByName(request.uid);
						const element:ChatElement = chat_elements.length ? chat_elements[0] : null;
						if(element) new_txt = element.text;
					}
				}
				
				//fire it off to the right side
				if(new_txt) right_view.chatUpdateElement(ChatArea.NAME_LOCAL, request.uid, new_txt, text_to_remove);
			}
			
			if(model && request.player_tsid == model.worldModel.pc.tsid) {
				_request_event_type = request.event_type;
				_request_event_tsid = request.event_tsid;
			}
		}
		
		public function actionRequestCancel(request:ActionRequest):void {
			if(!request || !request.player_tsid) return;
			
			const pc:PC = model.worldModel.getPCByTsid(request.player_tsid);
			
			//if this is someone we are ignoring, bail out
			if(pc && pc.ignored) {
				CONFIG::debugging {
					Console.warn('That TSID is being ignored. Name: '+pc.label);
				}
				return;
			}
			
			var avatar:AbstractAvatarView = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
			
			//if this is the player, go ahead and send the cancel off
			if(model && request.player_tsid != model.worldModel.pc.tsid){
				avatar = TSFrontController.instance.getMainView().gameRenderer.getPcViewByTsid(request.player_tsid);
			}
			
			//remove the chat bubble
			if(avatar) avatar.chatBubbleManager.hideBubble(true);
			
			//disable the element in the right side pane
			right_view.chatDisableElement(ChatArea.NAME_LOCAL, request.uid, getActionLink(request));
			
			//tell the manager this thing is no longer around
			ActionRequestManager.instance.removeRequestUid(request.uid);
			
			//if this was ours, kill stuff
			if(model && request.player_tsid == model.worldModel.pc.tsid) {
				dispatchEvent(new TSEvent(TSEvent.ACTION_REQUEST_CANCEL, _request_event_type));
				
				_request_event_type = null;
				_request_event_tsid = null;
			}
		}
		
		private function getActionLink(request:ActionRequest):String {
			var accept_txt:String = 'Accept!';
			switch(request.event_type){
				case TSLinkedTextField.LINK_TRADE:
					accept_txt = 'Start negotiation!';
					break;
				case TSLinkedTextField.LINK_QUEST_ACCEPT:
				case TSLinkedTextField.LINK_GAME_ACCEPT:
					accept_txt = 'Join!';
					break;
			}
			
			//other player's text, make sure we add the accept! link if it's not there already
			if(request.txt.indexOf('>'+accept_txt+'</a>') == -1){
				return '   <a href="event:'+request.event_type+'|'+request.event_tsid+'#'+request.uid+'">'+accept_txt+'</a>';
			}
			
			return '';
		}
		
		private function getActionUI(request:ActionRequest):ActionRequestUI {
			//check the pool to see if we have any available to reuse, otherwise create a new one
			var ui:ActionRequestUI;
			var i:int;
			var total:int = action_requests.length;
			
			for(i = 0; i < total; i++){
				if(!action_requests[int(i)].visible || action_requests[int(i)].name == request.uid) {
					ui = action_requests[int(i)];
					break;
				}
			}
			
			//if we don't have one, create it and add it to the pool
			if(!ui){
				ui = new ActionRequestUI();
				action_requests.push(ui);
			}
			
			//show the goods
			ui.show(request);
			
			return ui;
		}
		
		public function guideStatusChange(on_duty:Boolean):void {
			last_guide_status = on_duty;
			TSFrontController.instance.genericSend(new NetOutgoingGuideStatusChangeVO(on_duty), onGuideReply, onGuideReply);
		}
		
		private function onGuideReply(nrm:NetResponseMessageVO):void {
			//get the live help chat area and change the button
			var chat_area:ChatArea = right_view.getChatArea(ChatArea.NAME_HELP);
			if(chat_area){
				chat_area.on_duty = nrm.success && last_guide_status;
			}
		}
		
		public function localTooltip():String {
			//let's see who is in the zone with us
			var pc:PC;
			var players:Array = new Array('You');
			var tsid:String;
			var i:int;
			var total:int;
			var txt:String = 'People here';
			
			if (!model.worldModel.location || !model.worldModel.location.pc_tsid_list) return '';
			
			for(tsid in model.worldModel.location.pc_tsid_list) {
				pc = model.worldModel.getPCByTsid(tsid);
				if(!pc.online) continue;
				if(pc.tsid != model.worldModel.pc.tsid){
					players.push(pc.label);
				}
			}
			
			total = players.length;
			
			txt += ' ('+total+'): ';
			
			if(total > 1){
				for(i = 0; i < total; i++){
					if(i < total-1){
						txt += players[int(i)] + (total > 2 ? ', ' : ' ');
					}
					else {
						txt += total > 1 ? 'and ' : '';
						txt += players[int(i)];
					}
				}
			}
			else {
				txt += 'Just you!';
			}
			
			//fire it off to the view to update the tooltip for local chat
			//right_view.localUpdate(txt);
			
			//TEMP use this for tooltips of local chat
			return txt;
		}
		
		public function partyTooltip():String {
			var party:PCParty = model.worldModel.party;
			if (!party) return null;
			
			var pc:PC;
			var i:int;
			var total:int;
			var txt:String = 'Partiers';
			
			total = party.member_tsids.length;
			txt += ' ('+(total+1)+'): ';
			
			if (total > 0) {
				txt += 'You' + (total > 1 ? ', ' : ' and ');
				
				for (i=0;i<total;i++) {
					pc = model.worldModel.getPCByTsid(party.member_tsids[int(i)]);
					
					if(i < total-1){
						txt += pc.label + (total > 2 ? ', ' : ' ');
					}
					else {
						txt += total > 1 ? 'and ' : '';
						txt += pc.label;
					}
				}
			} else {
				txt+= 'Just you!';
			}
			
			return txt;
		}
		
		/**
		 * When you want to replace the words "you, your, you'll, etc" with the proper link color 
		 * @param txt
		 * @return String with the text modified to show the right color
		 */		
		public function youText(txt:String):String {
			var pattern:RegExp = /\b(you\'.+?|you|your)\b/i;
			
			return txt.replace(pattern, '<span class="chat_element_you">$1</span>');
		}
		
		/**
		 * When you want to replace a href with the proper color of that player 
		 * @param txt
		 * @return String with the proper class applied to the <a> tag
		 */		
		public function otherText(txt:String):String {
			var pattern:RegExp = /<a (href=\"event:pc\|(\w*)\")>(\w*)<\/a>/gi;
			
			function getClass():String {
				//0 - matched portion
				//1-N - matched groups (in our case 1 is href 2 is the tsid 3 is the label)
				if(arguments[2] != model.worldModel.pc.tsid){
					return '<a '+arguments[1] + ' class="'+getPCCSSClass(arguments[2])+'">'+arguments[3]+'</a>';
				}
				//return "You" and don't link it
				else {
					return '<span class="chat_element_you">You</span>';
				}
			}
			
			return txt.replace(pattern, getClass);
		}
		
		/**
		 * Create a clickable link that is parsed in TSLinkedTextfield
		 * @param txt The full string that you want displayed with any markup
		 * @param display_txt The part of the string that will be replaced with the client link
		 * @param client_link TYPE|TSID|LABEL  (label is optional otherwise it'll match [whatever] in display_txt
		 * @return A pimp-ass client link
		 * @see TSLinkedTextfield
		 */
		public function createClientLink(txt:String, display_txt:String, client_link:String):String {
			txt = txt || '';
			display_txt = display_txt || '';
			client_link = client_link || '';
			var pattern:RegExp = new RegExp(StringUtil.escapeRegEx(display_txt), 'i');
			var chunks:Array = client_link.split('|');
			
			//if we have 3 chunks, that means the label is already set, if not, set the label
			var type:String = chunks[0];
			var tsid:String = chunks[1];
			var label:String = chunks.length == 3 ? chunks[2] : display_txt.match(/(?<=\[)(.*?)(?=\\\])/g).toString();
						
			txt = txt.replace(pattern, CLIENT_LINK_WRAP+type+'|'+tsid+'|'+label+CLIENT_LINK_WRAP);
						
			return txt;
		}
		
		public function parseClientLink(txt:String, input_field:InputField = null):String {
			txt = txt || '';
			var pattern:RegExp = new RegExp(CLIENT_LINK_WRAP+'(.*?)'+CLIENT_LINK_WRAP, 'ig');
						
			function buildLink():String {
				//[1] is the matched group, so we need to get out the tsid to get the right name
				var chunks:Array = arguments[1].split('|');
				var label:String = chunks.length == 3 ? chunks[2] : null;
				
				if(label){
					if(!input_field){
						return '<a href="event:'+arguments[1]+'"><u>'+label+'</u></a>';
					}
					else {
						input_field.setLinkText(label, arguments[1], false);
						return '['+label+']';
					}
				}
				//not good, we don't know what this is
				else {
					CONFIG::debugging {
						Console.warn('Client link parsing failed: '+arguments[1], 'chunks: '+chunks);
					}
					return '';
				}
			}
			
			return txt.replace(pattern, buildLink);
		}
		
		public function saveOpenChats():void {
			if(!right_view) return; //if the client doesn't load and you close the window, this prevents a run time error
			
			var chats:Vector.<ChatArea> = right_view.getOpenChats();
			var chat_area:ChatArea;
			var chat_name:String = '';
			var i:int;
			var history:InputHistory;
			var append:String;
			
			//dump any that are marked for closing
			ChatHistory.clearClosedFromStorage();
			
			//loop through the open chats and add them to the local storage
			for(i = 0; i < chats.length; i++){
				chat_area = chats[int(i)];
				chat_name = chat_area.name;
				
				//if this is a global channel, be sure to use the static names
				if(chat_name == ChatArea.NAME_GLOBAL){
					chat_name = ChatHistory.GLOBAL_CHAT;
				}
				else if(chat_name == ChatArea.NAME_HELP){
					chat_name = ChatHistory.HELP_CHAT;
				}
				
				// returns an error reason if it fails, null if it succeeds
				var failed_cuz:String = ChatHistory.addHistoryToStorage(chat_area, false);
				if(failed_cuz){
					BootError.handleError('NAME: '+chat_name+
										  ' ELEMENT COUNT: '+chat_area.elements.length+(' but will be trimmed down to '+ChatArea.MAX_ELEMENTS+' max')+
										  ' SO SIZE: '+LocalStorage.instance.getStorageSize()+'b'+
										  ' failed_cuz:'+failed_cuz, 
										  new Error("Could not save chat to local storage"),
										  ['storage'], CONFIG::god
					);
					CONFIG::debugging {
						Console.warn('There was an issue saving chat history for TSID: '+chat_name);
					}
				}
				
				//remove from the input history so we don't purge it after
				history = getInputHistory(chat_name);
				if(history){
					append = history.tsid != ChatArea.NAME_LOCAL ? '_'+history.tsid : '';
					LocalStorage.instance.setUserData(LocalStorage.LOCAL_CHAT_HISTORY+append, history.elements);
					
					input_history.splice(input_history.indexOf(history), 1);
				}
			}
			
			//purge any left over chat input history
			for(i = 0; i < input_history.length; i++){
				history = input_history[int(i)];
				append = history.tsid != ChatArea.NAME_LOCAL ? '_'+history.tsid : '';
				LocalStorage.instance.removeUserData(LocalStorage.LOCAL_CHAT_HISTORY+append);
			}
		}
		
		public function localTradeStart():void {
			//player wants to start up the local trade UI stuff
			right_view.localTradeStart();
		}
		
		public function localTradeEnd():void {
			//no more local trade!
			right_view.localTradeEnd();
		}
		
		private function locationLink(location:Location, pc_tsid:String):String {
			//when you're moving between locations, this pumps out the formatted text
			if(!location) return 'somewhere';
			
			var label:String = location.label;
			if(location.is_pol){
				//is this ours?
				if(model.worldModel.pc.home_info.isTsidInHome(location.tsid)){
					label = 'your';
				}
				else {
					//link to their info dialog, but just the name itself
					const pc:PC = model.worldModel.getPCByTsid(pc_tsid);
					if(pc) label = '<a href="event:'+TSLinkedTextField.LINK_PLAYER_INFO+'|'+pc.tsid+'">'+pc.label+'</a>'+StringUtil.nameApostrophe(pc.label, false);
				}
				
				//this might be a tower
				if(location.home_type == LoadingInfo.POL_TYPE_TOWER){
					label += ' Tower';
				}
				else {
					label += (location.home_type == LoadingInfo.POL_TYPE_EXTERIOR ? ' Home Street' : ' House');
				}
			}
			else if(!location.is_instance && model.worldModel.getHubByTsid(location.hub_id) && !location.is_pol){
				label = '<a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+location.hub_id+'#'+location.tsid+'">'+label+'</a>';
			}
			
			return label;
		}
		
		/**
		 * Toggles the contact list
		 * @param is_open true opens it, false closes it no matter what state it's in
		 */		
		public function contactListToggle(is_open:Boolean):void {
			right_view.contactListToggle(is_open);
		}
		
		public function onEnterFrame(ms_elapsed:int):void {
			updateYouOnMap();
		}
		
		public function updateYouOnMap():void {
			if(right_view) right_view.updateYouOnMap();
		}
		
		public function setChatMapTab(tab_name:String = ''):void {
			if(!tab_name) tab_name = MapChatArea.TAB_MAP;
			if(right_view) right_view.setChatMapTab(tab_name);
		}
		
		public function get global_chat_tsid():String { 
			return _global_chat_tsid ? _global_chat_tsid : '';
		}
		
		public function set global_chat_tsid(value:String):void {
			//set the world to having a global chat group
			var group:Group = model.worldModel.getGroupByTsid(_global_chat_tsid);
			
			if(group){
				//replace the old one with a new one
				delete model.worldModel.groups[group.tsid];
				
				group.tsid = value;
				model.worldModel.groups[group.tsid] = group;
			}
			else {
				//make a new one and shove it into the world
				group = new Group(value);
				group.tsid = value;
				group.label = 'Global Chat';
				model.worldModel.groups[value] = group;
			}
			
			_global_chat_tsid = value;
		}
		
		public function get live_help_tsid():String { 
			return _live_help_tsid ? _live_help_tsid : '';
		}
		
		public function set live_help_tsid(value:String):void {
			//set the world to having a live help group
			var group:Group = model.worldModel.getGroupByTsid(_live_help_tsid);
			
			if(group){
				//replace the old one with a new one
				delete model.worldModel.groups[group.tsid];
				
				group.tsid = value;
				model.worldModel.groups[group.tsid] = group;
			}
			else {
				//make a new one and shove it into the world
				group = new Group(value);
				group.tsid = value;
				group.label = 'Live Help';
				model.worldModel.groups[value] = group;
			}
			
			_live_help_tsid = value;
		}
		
		public function get trade_chat_tsid():String { 
			return _trade_chat_tsid ? _trade_chat_tsid : '';
		}
		
		public function set trade_chat_tsid(value:String):void {
			//set the world to having a trade channel
			var group:Group = model.worldModel.getGroupByTsid(_trade_chat_tsid);
			
			if(group){
				//replace the old one with a new one
				delete model.worldModel.groups[group.tsid];
				
				if(value){
					group.tsid = value;
					model.worldModel.groups[group.tsid] = group;
				}
			}
			else if(value){
				//make a new one and shove it into the world
				group = new Group(value);
				group.tsid = value;
				group.label = 'Trade Channel';
				model.worldModel.groups[value] = group;
			}
			
			const prev_chat_tsid:String = _trade_chat_tsid;
			_trade_chat_tsid = value;
			
			//update the contact list
			right_view.groupManage(value != '' ? value : prev_chat_tsid, value != '');
		}
		
		public function get request_event_type():String { return _request_event_type; }
		public function get request_event_tsid():String { return _request_event_tsid; }
		
		/******************************************************************
		 * IMoveListener
		 *****************************************************************/
		public function moveLocationHasChanged():void {}
		public function moveLocationAssetsAreReady():void {}
		public function moveMoveStarted():void {}
		public function moveMoveEnded():void {
			if(last_loc_tsid != model.worldModel.location.tsid && !model.worldModel.location.no_imagination){
				const current_loc:Location = model.worldModel.location;
				const loading_info:LoadingInfo = model.moveModel.loading_info;
				
				if(last_loc_tsid){
					//place a line in chat saying where you were to where you are going
					const prev_loc:Location = model.worldModel.getLocationByTsid(last_loc_tsid);
					if(prev_loc){
						const prev_label:String = locationLink(prev_loc, last_loc_pc_tsid);
						const current_label:String = locationLink(current_loc, loading_info.owner_tsid);
												
						const chat_txt:String = '<p class="chat_element_move">You left '+prev_label+' for '+current_label+'</p>';
						chatUpdate(ChatArea.NAME_LOCAL, model.worldModel.pc.tsid, chat_txt, ChatElement.TYPE_MOVE);
					}
				}
				last_loc_tsid = current_loc.tsid;
				
				//if this is a pol street get the tsid of the owner from the loading_info
				last_loc_pc_tsid = current_loc.is_pol && loading_info.owner_tsid != model.worldModel.pc.tsid ? loading_info.owner_tsid : null;
			}
			
			//update the map in the chat area
			right_view.updateMap();
		}
	}
}