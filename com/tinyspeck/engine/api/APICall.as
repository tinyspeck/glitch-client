package com.tinyspeck.engine.api
{
	import com.adobe.serialization.json.JSON;
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.Achievement;
	import com.tinyspeck.engine.data.SDBItemInfo;
	import com.tinyspeck.engine.data.chat.Feed;
	import com.tinyspeck.engine.data.chat.FeedItem;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.ItemDetails;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.AvatarLook;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.SmartURLLoader;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;

	public class APICall extends EventDispatcher
	{			
		protected static const TYPE_ITEM:String = 'item';
		protected static const TYPE_ITEMSTACK:String = 'itemstack';
		protected static const TYPE_SKILL:String = 'skill';
		protected static const TYPE_SKILL_LEARN:String = 'skill_learn';
		protected static const TYPE_SKILL_LEARNING:String = 'skill_learning';
		protected static const TYPE_SKILL_LEARNED:String = 'skill_learned';
		protected static const TYPE_SKILL_ALL:String = 'skill_all';
		protected static const TYPE_SKILL_AVAILABLE:String = 'skill_available';
		protected static const TYPE_LOADING_IMAGE:String = 'loading_image';
		protected static const TYPE_LOCATION_IMAGE:String = 'location_image';
		protected static const TYPE_PLAYER_INFO:String = 'player_info';
		protected static const TYPE_ACTIVITY_FEED:String = 'activity_feed';
		protected static const TYPE_ACTIVITY_FEED_ITEM:String = 'activity_feed_item';
		protected static const TYPE_ACTIVITY_FEED_REPLY:String = 'activity_feed_reply';
		protected static const TYPE_ACTIVITY_FEED_DETAILS:String = 'activity_feed_details';
		protected static const TYPE_AVATAR_GET_HISTORY:String = 'avatar_get_history';
		protected static const TYPE_AVATAR_DELETE_OUTFIT:String = 'avatar_delete_outfit';
		protected static const TYPE_ECONOMY_RECENT_SDBS:String = 'economy_recent_sdbs';
		
		protected static var model:TSModelLocator;
		
		protected var req:URLRequest;
		protected var api_loader:SmartURLLoader;
		
		private var cache_breaker:String;
		private var type:String;
		private var json_str:String;
		private var delete_outfit_id:String;
		
		private var rsp:Object;
		
		private var _loading:Boolean;
		private var _trace_output:Boolean;
		
		public function APICall(){
			model = TSModelLocator.instance;
		}
		
		/**
		 * Get info on an item 
		 * @param item_tsids
		 */		
		public function itemsInfo(item_tsids:Array):void {
			if(!item_tsids){
				CONFIG::debugging {
					Console.warn('Missing item_tsids!');
				}
				return;
			}
			
			type = TYPE_ITEM;
			if (item_tsids.length > 30) {
				// for lots, we must post, else exceed querystring length restriction
				urlLoad('items.info', 'item_classes', item_tsids.toString());
			} else {
				urlLoad('items.info?item_classes='+item_tsids.toString());
			}
		}
		
		protected function itemsParse(rsp:Object):void {
			//parse multiple items
			var i:int;
			var item_details:Vector.<ItemDetails> = ItemDetails.parseMultiple(rsp);
			var item:Item;
			
			for(i; i < item_details.length; i++){
				//update the worldmodel to populate the details of the items
				item = model.worldModel.getItemByTsid(item_details[int(i)].item_class);
				if(item) item.details = item_details[int(i)];
			}
			
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, item_details));
		}
		
		/**
		 * Get info on an itemstack 
		 * @param itemstack_tsid
		 */		
		public function itemstackInfo(itemstack_tsid:String):void {
			if(!itemstack_tsid){
				CONFIG::debugging {
					Console.warn('Missing itemstack_tsid!');
				}
				return;
			}
			
			type = TYPE_ITEMSTACK;
			urlLoad('items.stackInfo?item_stack='+itemstack_tsid);
		}
		
		protected function itemstackParse(rsp:Object):void {
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(rsp.tsid);
			
			//translate API returns to be what the client is expecting
			if(rsp.status){
				rsp.date_aquired = rsp.status;
				delete rsp.status;
			}
			
			if(rsp.container){
				rsp.path_tsid = rsp.container;
				delete rsp.container;
			}
			
			if(rsp.item_class){
				rsp.class_tsid = rsp.item_class;
				delete rsp.item_class;
			}  
			
			//shove it in the world
			if(!itemstack){
				if (!Item.confirmValidClass(rsp.class_tsid, rsp.tsid)) {
					return;
				}
				model.worldModel.itemstacks[rsp.tsid] = Itemstack.fromAnonymous(rsp, rsp.tsid);
			}
			else {
				model.worldModel.itemstacks[itemstack.tsid] = Itemstack.updateFromAnonymous(rsp, itemstack);
			}
			
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, itemstack.tsid));
		}
		
		/**
		 * Get info on a skill 
		 * @param class_tsid
		 */		
		public function skillsInfo(class_tsid:String):void {
			if(!class_tsid){
				CONFIG::debugging {
					Console.warn('Missing class_tsid!');
				}
				return;
			}
			
			type = TYPE_SKILL;
			urlLoad('skills.getInfo?skill_class='+class_tsid);
		}
		
		protected function skillsParse(rsp:Object, is_learning:Boolean = false):void {						
			//get data and add/update the world model
			var class_tsid:String = rsp.class_tsid;
			
			//if we don't have a class_tsid then just dispatch an empty vector (probably not learning anything)
			if(!class_tsid){
				dispatchEvent(new TSEvent(TSEvent.COMPLETE, new Vector.<SkillDetails>));
				return;
			}
			
			var skill_details:SkillDetails = model.worldModel.getSkillDetailsByTsid(class_tsid);
			
			if(!skill_details){
				skill_details = SkillDetails.fromAnonymous(rsp, class_tsid);
			}
			else {
				skill_details = SkillDetails.updateFromAnonymous(rsp, skill_details);
			}
			
			//because the learning api return doesn't set this flag, we should!
			if(is_learning) skill_details.learning = true;
			
			model.worldModel.skill_details[class_tsid] = skill_details;
			
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, skill_details));
		}
		
		/**
		 * This will call the skill API .listAll and load it all into the world
		 */		
		public function skillsAll():void {
			type = TYPE_SKILL_ALL;
			urlLoad('skills.listAll?per_page=100000');
		}
		
		public function skillsAvailable():void {
			type = TYPE_SKILL_AVAILABLE;
			urlLoad('skills.listAvailable');
		}
		
		public function skillsLearned():void {
			type = TYPE_SKILL_LEARNED;
			urlLoad('skills.listLearned');
		}
		
		public function skillsLearning():void {
			type = TYPE_SKILL_LEARNING;
			urlLoad('skills.listLearning');
		}
		
		protected function skillAllParse(rsp:Object, can_learn:Boolean = false, got:Boolean = false):void {
			var i:int;
			var all_skills:Vector.<SkillDetails> = SkillDetails.parseMultiple(rsp);
			var skill_details:SkillDetails;
			
			for(i; i < all_skills.length; i++){
				//update the worldmodel to populate the details of the items
				skill_details = model.worldModel.getSkillDetailsByTsid(all_skills[int(i)].class_tsid);
				if(!skill_details){
					skill_details = all_skills[int(i)];
				}
				
				//only set them if we have one of them to be true
				//this way getting them all AFTER getting them all should work
				if(can_learn || got){
					skill_details.got = got;
					skill_details.can_learn = can_learn;
				}
				
				//force the world/return to have the updated stuff
				all_skills[int(i)] = skill_details;
				model.worldModel.skill_details[all_skills[int(i)].class_tsid] = skill_details;
			}
			
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, all_skills));
		}

		/**
		 * Learn a skill 
		 * @param class_tsid
		 */		
		public function skillsLearn(class_tsid:String):void {
			if(!class_tsid){
				CONFIG::debugging {
					Console.warn('Missing class_tsid!');
				}
				return;
			}
			
			type = TYPE_SKILL_LEARN;
			urlLoad('skills.learn?skill_id='+class_tsid);
		}
		
		/**
		 * Loading screen image 
		 * @param bitmap_data
		 */		
		public function loadingImage(bitmap_data:BitmapData, callback:Function=null):void {
			//NOTE: THIS METHOD DOES NOT CALL urlLoad()!!
			if(!model) model = TSModelLocator.instance;
			
			var img:BitmapSnapshot = new BitmapSnapshot(null, 'loc_img.png', 0, 0, bitmap_data);
			img.saveOnServerMultiPart(
				'image',
				{
					ctoken: model.flashVarModel.api_token,
					tsid: model.worldModel.location.tsid
				},
				model.flashVarModel.api_url+'simple/god.streets.setLoadingImage',
				null,
				function(ok:Boolean, txt:String):void {
					loadingImageParse(ok, txt, callback);
				}
			);
		}
		
		protected function loadingImageParse(ok:Boolean, txt:String = '', callback:Function = null):void {
			//model.activityModel.growl_message = 'ADMIN: loading img saving complete, ok:' + ok + ' ' + txt;
			
			try {
				var json:Object = com.adobe.serialization.json.JSON.decode(txt);
				if (json.url) {
					navigateToURL(new URLRequest(json.url), 'snapshot');
					model.moveModel.loading_info.loading_img_url = json.url;
					model.moveModel.triggerCBProp(false, false, 'loading_img_url');
				}
			} 
			catch(err:Error) {
				CONFIG::debugging {
					Console.warn(txt+' NOT JSON');
				}
			}
			
			//save the location image
			TSFrontController.instance.saveLocationImg(callback);
		}
		
		/**
		 * Location image 
		 * @param bitmap_data
		 */		
		public function locationImage(bitmap_data:BitmapData, callback:Function=null):void {
			//NOTE: THIS METHOD DOES NOT CALL urlLoad()!!
			if(!model) model = TSModelLocator.instance;
			
			var img:BitmapSnapshot = new BitmapSnapshot(null, 'loc_img.png', 0, 0, bitmap_data);
			img.saveOnServerMultiPart(
				'image',
				{
					ctoken: model.flashVarModel.api_token,
					tsid: model.worldModel.location.tsid
				},
				model.flashVarModel.api_url+'simple/god.streets.setImage',
				null,
				function(ok:Boolean, txt:String):void {
					locationImageParse(ok, txt, callback);
				}
			);
		}
		
		protected function locationImageParse(ok:Boolean, txt:String = '', callback:Function = null):void {
			//model.activityModel.growl_message = 'ADMIN: normal img saving complete, ok:' + ok + ' ' + txt;
			
			try {
				var json:Object = com.adobe.serialization.json.JSON.decode(txt);
				if (json.url) {
					navigateToURL(new URLRequest(json.url), 'snapshot_normal');
				}
				if (callback != null) callback();
			} catch(err:Error) {
				CONFIG::debugging {
					Console.warn(txt+' NOT JSON');
				}
			}
		}
		
		/**
		 * Location image 
		 * @param bitmap_data
		 */		
		public function homeImage(bitmap_data:BitmapData, callback:Function=null):void {
			//NOTE: THIS METHOD DOES NOT CALL urlLoad()!!
			if(!model) model = TSModelLocator.instance;
			
			var img:BitmapSnapshot = new BitmapSnapshot(null, 'home_img.png', 720, 0, bitmap_data);
			img.saveOnServerMultiPart(
				'image',
				{
					ctoken: model.flashVarModel.api_token,
					tsid: model.worldModel.location.tsid
				},
				model.flashVarModel.api_url+'simple/homes.setImage',
				null,
				function(ok:Boolean, txt:String):void {
					homeImageParse(ok, txt, callback);
				}
			);
		}
		
		protected function homeImageParse(ok:Boolean, txt:String = '', callback:Function = null):void {
			
			try {
				var json:Object = com.adobe.serialization.json.JSON.decode(txt);
				CONFIG::debugging {
					Console.dir(json);
				}
				if (callback != null) callback();
			} catch(err:Error) {
				CONFIG::debugging {
					Console.warn(txt+' NOT JSON');
				}
			}
		}
		/**
		 * Get full information about a player 
		 * @param player_tsid
		 */		
		public function playersFullInfo(player_tsid:String):void {
			if(!player_tsid){
				CONFIG::debugging {
					Console.warn('Missing player_tsid!');
				}
				return;
			}
			
			type = TYPE_PLAYER_INFO;
			if(!model) model = TSModelLocator.instance;
			urlLoad('players.fullInfo?player_tsid='+player_tsid+'&viewer_tsid='+model.worldModel.pc.tsid);
		}
		
		protected function playerParse(rsp:Object):void {
			if(!rsp.player_tsid){
				CONFIG::debugging {
					Console.warn('Missing player_tsid!');
				}
				dispatchEvent(new TSEvent(TSEvent.ERROR, 'Missing player_tsid!'));
				return;
			}
			
			//update the world with this player
			var pc:PC = model.worldModel.getPCByTsid(rsp.player_tsid);
			if(!pc){
				pc = new PC(rsp.player_tsid);
				pc.tsid = rsp.player_tsid;
				model.worldModel.pcs[rsp.player_tsid] = pc;
			}
			
			pc.label = rsp.player_name;
			if(pc.label.indexOf('<') != -1 || pc.label.indexOf('>') != -1){
				//make sure a PCs label doesn't have any fucking HTML garbage in it
				pc.label = StringUtil.encodeHTMLUnsafeChars(pc.label, false);
			}
			
			//get the avatar URL
			if(rsp.avatar['50']){
				var index:int = rsp.avatar['50'].indexOf('_50.png');
				pc.singles_url = rsp.avatar['50'].substr(0, index);
			}
			
			//update the level
			if(rsp.stats.hasOwnProperty('level')){
				pc.level = rsp.stats['level'];
			}
			
			//where they at?
			if(rsp.location){
				pc.location = rsp.location;
				
				//see if this is in the model yet
				var loc:Location = model.worldModel.getLocationByTsid(rsp.location.tsid);
				if('tsid' in rsp.location && !loc){
					loc = Location.fromAnonymous(rsp.location, rsp.location.tsid);
					loc.label = rsp.location.name;
					model.worldModel.locations[loc.tsid] = loc;
				}
				else if(loc){
					loc = Location.updateFromAnonymous(rsp.location, loc);
				}
			}
			
			// can_contact is used by PlayerInfoDialog to hide the contact button
			if(rsp.relationship){
				pc.can_contact = rsp.relationship.can_contact;
			}
			
			//POL data
			if(rsp.pol && rsp.pol.tsid){
				pc.pol_tsid = rsp.pol.tsid;
			}
			
			//skill data
			if(rsp.latest_skill && rsp.latest_skill.id){
				var skill:SkillDetails = model.worldModel.getSkillDetailsByTsid(rsp.latest_skill.id);
				if(!skill){
					skill = new SkillDetails(rsp.latest_skill.id);
					skill.name = rsp.latest_skill.name;
					model.worldModel.skill_details[rsp.latest_skill.id] = skill;
				}
			}
			
			//badge data
			if(rsp.latest_achievement && rsp.latest_achievement.id){
				var achievement:Achievement = model.worldModel.getAchievementByTsid(rsp.latest_achievement.id);
				if(!achievement){
					achievement = Achievement.fromAnonymous(rsp.latest_achievement, rsp.latest_achievement.id);
					model.worldModel.achievements[rsp.latest_achievement.id] = achievement;
				}
			}
			
			//send the whole rsp back
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, rsp));
		}
		
		/**
		 * Get your status feed. Passing a blank category will get all feed's elements
		 * @param last - optional - if value is passed it gets the next set based on the previous "last" value returned
		 * @param category - optional
		 * Options are:
		 * notes - gets your status updates and replies
		 * requests - gets your requests
		 * blog - not used at this time
		 */		
		public function activityFeed(since:uint, limit:uint = 15, category:String = 'notes'):void {
			type = TYPE_ACTIVITY_FEED;
			urlLoad('activity.feed?buddy_replies_only=1&full_replies=1&since='+since+'&limit='+limit+'&cat='+category);
		}
		
		protected function activityParse(rsp:Object):void {
			//parse and fire off
			const feed:Feed = Feed.fromAnonymous(rsp);
			var i:int;
			var total:int = feed.items.length;
			
			//sort by "when"
			if(total){
				SortTools.vectorSortOn(feed.items, ['when'], [Array.NUMERIC]);
			}
			
			//see if we have to sort any of the full replies
			for(i; i < total; i++){
				if(feed.items[int(i)].full_replies){
					SortTools.vectorSortOn(feed.items[int(i)].full_replies, ['when'], [Array.NUMERIC]);
				}
			}
			
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, feed));
		}
		
		/**
		 * Set's the curent players status 
		 * @param txt
		 */		
		public function activityFeedSetStatus(txt:String):void {
			type = TYPE_ACTIVITY_FEED_ITEM;
			urlLoad('activity.setStatus?txt='+encodeURIComponent(txt));
		}
		
		/**
		 * Set a reply to a status update 
		 * @param feed_item_id - the ID of the update the player is replying to
		 * @param txt
		 */		
		public function activityFeedSetStatusReply(feed_item_id:String, txt:String):void {
			type = TYPE_ACTIVITY_FEED_REPLY;
			urlLoad('activity.setStatusReply?reply_to_id='+feed_item_id+'&txt='+encodeURIComponent(txt));
		}
		
		protected function activityReplyParse(rsp:Object):void {
			//when you reply, the API fires back the message, we should take this, and send it to things who want it
			if('item' in rsp && 'id' in rsp){
				const item:FeedItem = FeedItem.fromAnonymous(rsp.item, rsp.id);
				
				dispatchEvent(new TSEvent(TSEvent.COMPLETE, item));
			}
			else {
				CONFIG::debugging {
					Console.warn('Missing the item or id param from the API');
				}
			}
		}
		
		/**
		 * Get the entire thread of a given feed element ID 
		 * @param feed_item_id
		 */		
		public function activityFeedGetStatus(feed_item_id:String):void {
			type = TYPE_ACTIVITY_FEED_DETAILS;
			urlLoad('activity.getStatus?status_id='+feed_item_id);
		}
		
		protected function activityDetailsParse(rsp:Object):void {
			if('item' in rsp && 'id' in rsp.item){
				const item:FeedItem = FeedItem.fromAnonymous(rsp.item, rsp.item.id);
				
				//the api gives full details in the short param, so let's fucking copy them
				item.full_in_reply_to = item.in_reply_to;
				
				if(rsp.replies){
					//we have replies, add them to the item
					item.full_replies = FeedItem.parseMultiple(rsp.replies);
					
					//sort them
					SortTools.vectorSortOn(item.full_replies, ['when'], [Array.NUMERIC]);
				}
					
				dispatchEvent(new TSEvent(TSEvent.COMPLETE, item));
			}
			else {
				CONFIG::debugging {
					Console.warn('Missing the item or id param from the API');
				}
			}
		}
		
		public function snapsComment(owner_tsid:String, snap_id:String, comment_text:String):void {
			//this works, but the server doesn't pass in comments with the main feed, so we can't see the reply :(
			urlLoad('snaps.comment?owner_tsid='+owner_tsid+'&snap_id='+snap_id+'&comment='+encodeURIComponent(comment_text));
		}
		
		public function snapsRandomForCamera():void {
			const loc_tsid:String = model.worldModel.location ? model.worldModel.location.tsid : '';
			urlLoad('snaps.randomForCamera?exclude_tsid='+loc_tsid);
		}
		
		public function avatarGetHistory(page_num:int = 1, per_page:int = 10):void {
			type = TYPE_AVATAR_GET_HISTORY;
			urlLoad('avatar.getHistory?page='+page_num+'&per_page='+per_page);
		}
		
		protected function avatarGetHistoryParse(rsp:Object):void {
			//puts the looks into the PC's model
			if('history' in rsp){
				AvatarLook.parseMultiple(rsp.history);
				dispatchEvent(new TSEvent(TSEvent.COMPLETE, rsp));
			}
		}
		
		public function avatarSwitchOutfit(outfit_id:String):void {
			urlLoad('avatar.switchOutfit?outfit_id='+outfit_id);
		}
		
		public function avatarDeleteOutfit(outfit_id:String):void {
			type = TYPE_AVATAR_DELETE_OUTFIT;
			delete_outfit_id = outfit_id;
			urlLoad('avatar.deleteOutfit?outfit_id='+outfit_id);
		}
		
		protected function avatarDeleteOutfitParse(rsp:Object):void {
			//remove the one we just deleted from the model
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			if(pc && pc.previous_looks){
				var look:AvatarLook = pc.getLookById(delete_outfit_id);
				if(look){
					const looks:Vector.<AvatarLook> = pc.previous_looks;
					looks.splice(looks.indexOf(look), 1);
					look = null;
					rsp.delete_outfit_id = delete_outfit_id;
					delete_outfit_id = null;
				}
			}
			
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, rsp));
		}
		
		/**
		 * When you need a short URL for things 
		 * @param short_url_type
		 * @param url
		 * @see ShortUrlType for available options
		 */		
		public function clientGetShortUrl(short_url_type:String, url:String):void {
			urlLoad('client.getShortUrl?class='+short_url_type+'&url='+encodeURIComponent(url));
		}
		
		public function economyRecentSDBs(class_tsid:String = '', location_type:String = 'tower', get_empty:Boolean = false):void {
			type = TYPE_ECONOMY_RECENT_SDBS;
			urlLoad('economy.recentSDBs?class_tsid='+class_tsid+'&location_type='+location_type+'&non_empty='+(get_empty ? 0 : 1));
		}
		
		public function economyBestSDBs(class_tsid:String):void {
			type = TYPE_ECONOMY_RECENT_SDBS;
			urlLoad('economy.bestSDBs?class_tsid='+class_tsid);
		}
		
		protected function economyRecentSDBsParse(rsp:Object):void {
			//parse the goods
			var sdb_items:Vector.<SDBItemInfo>;
			if(rsp && 'items' in rsp){
				sdb_items = SDBItemInfo.parseMultiple(rsp.items);
			}
			
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, sdb_items));
		}
		
		/**
		 * Load the API 
		 * @param api_url
		 * NOTE: you only need to pass the unique part of the URL
		 */		
		protected function urlLoad(api_url:String, var_name:String=null, var_value:String=''):void {			
			//set the model if we don't know it
			if(!model) model = TSModelLocator.instance;
			
			//setup if not already
			if(!req){
				req = new URLRequest();
				req.method = URLRequestMethod.POST;
			}
			
			var vars:URLVariables = new URLVariables();
			
			if (var_name) {
				vars[var_name] = var_value
			}
			
			cache_breaker = String(new Date().getTime());
			req.url = model.flashVarModel.api_url+'simple/' + api_url + '&pretty=1&cb='+cache_breaker;
			
			//pass the api_token
			vars.ctoken = model.flashVarModel.api_token;
			req.data = vars;
			
			//if we are already loading something else, kill it
			stopLoading();
			
			//load'r up
			CONFIG::debugging {
				var url:String = req.url.replace(/\&/g, ' \&');
				Console.priinfo(2, '\r'+url+'\r'+StringUtil.getCallerCodeLocation());
			}
			
			// build a new one each call, SmartURLLoaders cannot be reused
			api_loader = new SmartURLLoader(api_url);
			// these are automatically removed on complete or error:
			api_loader.complete_sig.add(onComplete);
			api_loader.error_sig.add(onError);
			api_loader.progress_sig.add(onProgress);
			api_loader.connectTimeout = 60000;
			api_loader.load(req);
			
			_loading = true;
		}
			
		protected function onProgress(loader:SmartURLLoader):void {
			// we never get prog reports until it is all loaded. maybe this is the way with URL loaders?
		}
		
		/**
		 * Responsible for handling the return of the API call 
		 * @param event
		 */		
		protected function onComplete(loader:SmartURLLoader):void {
			_loading = false;
			
			// we'll log it in any of these cases
			var do_log:Boolean = _trace_output || model.flashVarModel.view_api_output;
			
			CONFIG::debugging {
				do_log = do_log || Console.priOK('2');
				if (do_log) {
					// only in these legacy bit flips do we want to output the raw data
					if (_trace_output || model.flashVarModel.view_api_output) {
						Console.warn('RETURN FROM URL: '+req.url+'\nDATA: ' + loader.data);
					} else {
						Console.warn('RETURN FROM URL: '+req.url);
					}
				}
			}
			
			//parse the data
			json_str = loader.data;
			rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
			
			CONFIG::debugging {
				if (do_log) {
					Console.pridir(2, rsp);
				}
			}
			
			if (!rsp || (rsp && !rsp.ok)) {
				CONFIG::debugging {
					Console.warn('API return was NOT ok');
				}
				BootError.handleError('API return was NOT ok: URL->'+req.url+' DATA->'+loader.data, new Error('API response failure'), ['api'], true);
				dispatchEvent(new TSEvent(TSEvent.ERROR, loader.data));
				return;
			}
			
			//we know it was ok, so remove it
			delete rsp.ok;
			
			//figure out what we loaded and pass the data to the method that should get it
			switch(type){
				case TYPE_ITEM:
					itemsParse(rsp);
					break;
				case TYPE_ITEMSTACK:
					itemstackParse(rsp);
					break;
				case TYPE_SKILL:
					skillsParse(rsp);
					break;
				case TYPE_SKILL_LEARNING:
					skillsParse(rsp.learning, true);
					break;
				case TYPE_SKILL_ALL:
					//for some reason when calling the "listAll" method the hash comes back as "items"
					skillAllParse(rsp.items);
					break;
				case TYPE_SKILL_LEARNED:
					skillAllParse(rsp.skills, false, true);
					break;
				case TYPE_SKILL_AVAILABLE:
					skillAllParse(rsp.skills, true, false);
					break;
				case TYPE_PLAYER_INFO:
					playerParse(rsp);
					break;
				case TYPE_ACTIVITY_FEED:
					activityParse(rsp);
					break;
				case TYPE_ACTIVITY_FEED_DETAILS:
					activityDetailsParse(rsp);
					break;
				case TYPE_ACTIVITY_FEED_REPLY:
					activityReplyParse(rsp);
					break;
				case TYPE_AVATAR_GET_HISTORY:
					avatarGetHistoryParse(rsp);
					break;
				case TYPE_AVATAR_DELETE_OUTFIT:
					avatarDeleteOutfitParse(rsp);
					break;
				case TYPE_ECONOMY_RECENT_SDBS:
					economyRecentSDBsParse(rsp);
					break;
				default:
					dispatchEvent(new TSEvent(TSEvent.COMPLETE, rsp));
					break;
			}
			
			//dump the returned stuff
			json_str = null;
			rsp = null;
		}
		
		protected function onError(loader:SmartURLLoader):void {
			_loading = false;
			CONFIG::god {
				if (loader.eventLog.indexOf('auth.tinyspeck.com') > -1) {
					navigateToURL(new URLRequest(
						'http://auth.tinyspeck.com/login/?fail=old&ref='+encodeURIComponent(ExternalInterface.call('window.location.href.toString'))
					), '_self');
					return;
				}
			}
			
			CONFIG::debugging {
				Console.error('failed to load: '+loader.name);
			}
			dispatchEvent(new TSEvent(TSEvent.ERROR, loader.data));
			BootError.handleError('Error on an API call: '+loader.name + '\n' + loader, new Error('API load failure'), ['api','loader'], true);
		}
		
		public function stopLoading():void {
			if(loading){
				_loading = false;
				try {
					api_loader.close();
				}
				catch(error:Error) {
					//got into a funky state... Let's try and record some data
					BootError.handleError('API Loader couldn\'t close ::: loaded: '+api_loader.bytesLoaded+
																		 'total: '+api_loader.bytesTotal+
																		 'data: '+api_loader.data, error, ['api'], false);
				}
			}
		}
		
		public function get loading():Boolean { return _loading; }
		public function set trace_output(value:Boolean):void { _trace_output = value; }
	}
}