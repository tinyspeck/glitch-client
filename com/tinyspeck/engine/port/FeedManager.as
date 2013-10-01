package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.data.chat.Feed;
	import com.tinyspeck.engine.data.chat.FeedItem;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.chat.FeedChatArea;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	public class FeedManager
	{
		/* singleton boilerplate */
		public static const instance:FeedManager = new FeedManager();
		
		private static const MANUAL_REFRESH_SECS:uint = 5; //how fast are they allowed to force a refresh
		private static const AUTO_REFRESH_SECS:uint = 60; //auto refresh timer
		private static const MAX_TO_FETCH:uint = 15;
		
		private var api_call:APICall = new APICall();
		private var current_feed:Feed = new Feed();
		private var current_details:FeedItem;
		private var current_feed_tsid:String;
		
		private var auto_refresh_timer:Timer = new Timer(AUTO_REFRESH_SECS*1000);
		
		private var last_refresh:uint;
		private var last_timestamp:uint;
		
		private var is_setting_reply:Boolean;
		
		public function FeedManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			//setup the api
			api_call.addEventListener(TSEvent.COMPLETE, onAPIComplete, false, 0, true);
			api_call.addEventListener(TSEvent.ERROR, onAPIError, false, 0, true);
			//api_call.trace_output = true;
			
			//listen to the timer
			auto_refresh_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			
			//listen to when chats are closed
			RightSideManager.instance.right_view.addEventListener(TSEvent.CHAT_ENDED, onChatEnd, false, 0, true);
		}
		
		public function setStatus(txt:String):void {
			const chat_area:FeedChatArea = RightSideManager.instance.right_view.getChatArea(ChatArea.NAME_UPDATE_FEED) as FeedChatArea;
			if(chat_area) {
				chat_area.show_loader = true;
				
				if(api_call.loading) api_call.stopLoading();
				
				if(chat_area.reply_id){
					const feed_item:FeedItem = getFeedItem(chat_area.reply_id);
					if(!feed_item.photo_id){
						api_call.activityFeedSetStatusReply(chat_area.reply_id, txt);
					}
					else {
						//we are commenting on a photo
						api_call.snapsComment(feed_item.who_tsid, feed_item.photo_id, txt);
					}
					chat_area.replyClose();
					is_setting_reply = true;
				}
				else {
					api_call.activityFeedSetStatus(txt);
				}
				
				last_refresh = getTimer();
			}
		}
		
		public function getDetails(feed_id:String):void {
			const chat_area:FeedChatArea = RightSideManager.instance.right_view.getChatArea(ChatArea.NAME_UPDATE_FEED) as FeedChatArea;
			if(chat_area) {
				chat_area.show_loader = true;
				
				if(api_call.loading) api_call.stopLoading();
				api_call.activityFeedGetStatus(feed_id);
				is_setting_reply = false;
				
				last_refresh = getTimer();
			}
		}
		
		public function refreshFeed(feed_tsid:String, force:Boolean = false):Boolean {
			//load the feed if the last time it was refreshed allows it
			if((getTimer() - last_refresh > MANUAL_REFRESH_SECS*1000) || force){
				loadFeed(feed_tsid);
				auto_refresh_timer.reset();
				if(!auto_refresh_timer.running) auto_refresh_timer.start();
				return true;
			}
			else {
				//too fast! Show what we've got
				showFeed(current_feed);
				return false;
			}
		}
		
		private function loadFeed(feed_tsid:String):void {
			const chat_area:FeedChatArea = RightSideManager.instance.right_view.getChatArea(ChatArea.NAME_UPDATE_FEED) as FeedChatArea;
			
			var is_fetching:Boolean;
			
			switch(feed_tsid){
				case ChatArea.NAME_UPDATE_FEED:
					api_call.activityFeed(last_timestamp, MAX_TO_FETCH);
					is_fetching = true;
					break;
				default:
					CONFIG::debugging {
						Console.warn('Uknown feed type: '+feed_tsid);
					}
					break;
			}
			
			if(is_fetching){
				current_feed_tsid = feed_tsid;
				last_refresh = getTimer();
				if(chat_area) chat_area.show_loader = true;
			}
		}
		
		private function onAPIComplete(event:TSEvent):void {
			const chat_area:FeedChatArea = RightSideManager.instance.right_view.getChatArea(ChatArea.NAME_UPDATE_FEED) as FeedChatArea;
			if(chat_area) chat_area.show_loader = false;
			
			var item:FeedItem;
			
			//show the feed
			if(event.data is Feed){
				updateFeed(event.data as Feed);
				
				//set the SO with the data
				if(current_feed.items.length){
					item = current_feed.items[int(current_feed.items.length-1)];
					LocalStorage.instance.setUserData(LocalStorage.LAST_UPDATE_FEED_TIMESTAMP, item.when);
				}
				
				//show the feed
				showFeed(current_feed);
			}
			else if(event.data is FeedItem){
				item = event.data as FeedItem;
				
				if(chat_area) {
					//if we are doing a reply, let's update stuff
					if(is_setting_reply){
						is_setting_reply = false;
						
						//refresh the feed to snag up this update
						refreshFeed(current_feed_tsid, true);
					}
					else {
						//details call, go ahead and fire that off to the details pane
						chat_area.showDetails(item);
					}
				}
				current_details = item;
			}
			else {
				refreshFeed(current_feed_tsid, true);
			}
			
			//make sure no one is holding on to the event someplace
			event = null;
		}
		
		private function onAPIError(event:TSEvent):void {
			const chat_area:FeedChatArea = RightSideManager.instance.right_view.getChatArea(ChatArea.NAME_UPDATE_FEED) as FeedChatArea;
			if(chat_area) chat_area.show_loader = false;
		}
		
		private function onChatEnd(event:TSEvent):void {
			if(event.data == ChatArea.NAME_UPDATE_FEED){
				//kill the auto timer
				auto_refresh_timer.stop();
				
				//reset the last_update so we can get the latest when it opens again
				last_timestamp = 0;
				
				//kill the current feed
				current_feed.items.length = 0;
			}
		}
		
		private function showFeed(feed:Feed):void {
			const total:int = feed.items.length;
			
			var i:int;
			var j:int;
			var item:FeedItem;
			
			for(i; i < total; i++){
				item = feed.items[int(i)];
				
				//if this item is the latest, let's set our timestamp
				if(i == total-1){
					last_timestamp = item.when;
				}
			}
		}
		
		private function updateFeed(feed:Feed):void {
			//this will look through our current feed and update any of the items returned from the api
			if(!feed) return;
			const chat_area:FeedChatArea = RightSideManager.instance.right_view.getChatArea(ChatArea.NAME_UPDATE_FEED) as FeedChatArea;
			const last_saved_timestamp:uint = LocalStorage.instance.getUserData(LocalStorage.LAST_UPDATE_FEED_TIMESTAMP);
						
			var i:int;
			var total:int = feed.items.length;
			var item:FeedItem;
			var needs_refresh:Boolean;
			
			if(chat_area && total == 0){
				//let's put a little message in there for them
				needs_refresh = true;
			}
			
			for(i; i < total; i++){
				item = getFeedItem(feed.items[int(i)].id, false);
				
				if(!item){
					//new item, shove it into the feed
					current_feed.items.push(feed.items[int(i)]);
					
					//update the contact list
					if(feed.items[int(i)].when > last_saved_timestamp){
						RightSideManager.instance.right_view.contactUpdate(current_feed_tsid, false);
					}
					
					//if this is a feed refresh and we have new stuff, check to see if any of the old items need replies updated
					if(last_timestamp){
						item = feed.items[int(i)];
						const old_item:FeedItem = item.full_in_reply_to ? getFeedItem(item.full_in_reply_to.id, false) : null;
						
						//found an old item, let's update it to what the API says is good
						if(old_item){
							old_item.replies = item.full_in_reply_to.replies;
							
							if(!old_item.full_replies){
								old_item.full_replies = new Vector.<FeedItem>();
							}
							old_item.full_replies.push(item);
							
							SortTools.vectorSortOn(old_item.full_replies, ['when'], [Array.NUMERIC]);
							
							//if we are updating something old, check to see if we are viewing those details
							if(chat_area && chat_area.reply_id == old_item.id){
								chat_area.showDetails(old_item);
							}
						}
					}
					
					//fire this off to the right side
					RightSideManager.instance.feedUpdate(current_feed_tsid, feed.items[int(i)]);
					
					//mark this as needing a refresh
					needs_refresh = true;
				}
				else {
					//we've got new info about the item, replace it
					item = feed.items[int(i)];
				}
			}
			
			//refresh the chat area
			if(needs_refresh && chat_area){
				chat_area.refreshElements();
			} 
			
			//let's make sure our feed only has the amount of items the chat area can handle
			current_feed.items.splice(0, Math.max(0, current_feed.items.length - ChatArea.MAX_ELEMENTS));
		}
		
		private function onTimerTick(event:TimerEvent):void {
			refreshFeed(current_feed_tsid, true);
		}
		
		/**
		 * Search the current feed for a specific item 
		 * @param feed_id
		 * @return the item, or null if it can't find it :(
		 */		
		public function getFeedItem(feed_id:String, search_deep:Boolean = true):FeedItem {
			if(!current_feed) return null;
			
			var i:int;
			var j:int;
			var total:int = current_feed.items.length;
			var item:FeedItem;
			
			//loop through the feed
			for(i; i < total; i++){
				item = current_feed.items[int(i)];
				if(item.id == feed_id) return item;
			}
			
			//search deep
			if(search_deep){
				for(i = 0; i < total; i++){
					item = current_feed.items[int(i)];
					if(item.full_in_reply_to && item.full_in_reply_to.id == feed_id) return item.full_in_reply_to;
					if(item.replies){
						for(j = 0; j < item.full_replies.length; j++){
							if(item.full_replies[int(j)].id == feed_id) return item.full_replies[int(j)];
						}
					}
				}
				
				//maybe our details has it?!
				if(current_details){
					if(current_details.id == feed_id) return current_details;
					if(search_deep && current_details.full_in_reply_to && current_details.full_in_reply_to.id == feed_id) return current_details.full_in_reply_to;
					if(search_deep && current_details.replies){
						for(j = 0; j < current_details.full_replies.length; j++){
							if(current_details.full_replies[int(j)].id == feed_id) return current_details.full_replies[int(j)];
						}
					}
				}
			}
			
			return null;
		}
	}
}