package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.Achievement;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingBuddyAddVO;
	import com.tinyspeck.engine.net.NetOutgoingBuddyRemoveVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesVisitVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.AchievementIcon;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.net.URLRequest;
	import flash.text.TextField;

	public class PlayerInfoDialog extends BigDialog implements ITipProvider
	{
		/* singleton boilerplate */
		public static const instance:PlayerInfoDialog = new PlayerInfoDialog();
		
		private const OFFSET_X:uint = 170;
		private const AVATAR_SIZE:uint = 172; //must match a size that the API returns  (50, 100, 172 as of April 18, 2011)
		private const MAX_UPDATE_CHARS:uint = 180;
		
		private var online_circle:Sprite = new Sprite();
		private var module_holder:Sprite = new Sprite();
		private var avatar_holder:Sprite = new Sprite();
		
		private var location_tf:TSLinkedTextField = new TSLinkedTextField();
		private var update_tf:TSLinkedTextField = new TSLinkedTextField();
		private var api_call:APICall = new APICall();
		private var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
		
		private var req:URLRequest = new URLRequest();
		private var loader:Loader = new Loader();
		
		private var add_buddy_bt:Button;
		private var remove_buddy_bt:Button;
		private var profile_bt:Button;
		private var visit_bt:Button;
		private var send_im_bt:Button;
		
		private var player_tsid:String;
		
		private var is_built:Boolean;
		
		public function PlayerInfoDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 510;
			_body_min_h = 265;
			_head_min_h = 59;
			_foot_min_h = 0;
			_base_padd = 20;
			_draggable = true;
			_title_padd_left = OFFSET_X;
			
			_construct();
		}
		
		private function buildBase():void {			
			//profile button
			profile_bt = new Button({
				name: 'profile',
				label: 'Profile page',
				graphic: new AssetManager.instance.assets.encyclopedia_link(),
				graphic_hover: new AssetManager.instance.assets.encyclopedia_link_hover(),
				graphic_placement: 'left',
				graphic_padd_l: 19,
				graphic_padd_r: 3,
				graphic_padd_t: 6,
				type: Button.TYPE_MINOR,
				size: Button.SIZE_TINY,
				w: 122,
				y: 185,
				tip: {
					txt: 'Opens in a new window',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			});
			profile_bt.x = int(OFFSET_X/2 - profile_bt.width/2);
			profile_bt.addEventListener(TSEvent.CHANGED, onProfileClick, false, 0, true);
			_scroller.body.addChild(profile_bt);
			
			//buddy add/remove button
			add_buddy_bt = new Button({
				name: 'add_buddy',
				label: 'Add to contacts',
				size: Button.SIZE_TINY,
				type: Button.TYPE_DEFAULT,
				value: false,
				w: 122
			});
			add_buddy_bt.x = int(OFFSET_X/2 - add_buddy_bt.width/2);
			add_buddy_bt.y = int(profile_bt.y + profile_bt.height + 5);
			add_buddy_bt.label_y_offset = 1;
			add_buddy_bt.addEventListener(TSEvent.CHANGED, onBuddyClick, false, 0, true);
			_scroller.body.addChild(add_buddy_bt);
			
			remove_buddy_bt = new Button({
				name: 'remove_buddy',
				label: 'Remove from contacts',
				label_c: 0x7e0f00,
				label_size: 11,
				label_bold: true,
				label_alpha: .6,
				focus_label_alpha: 1,
				draw_alpha: 0,
				value: true
			});
			remove_buddy_bt.x = int(OFFSET_X/2 - remove_buddy_bt.width/2);
			remove_buddy_bt.y = int(profile_bt.y + profile_bt.height + 10);
			remove_buddy_bt.addEventListener(TSEvent.CHANGED, onBuddyClick, false, 0, true);
			_scroller.body.addChild(remove_buddy_bt);
			
			//location tf
			TFUtil.prepTF(location_tf);
			location_tf.embedFonts = false;
			location_tf.x = OFFSET_X;
			location_tf.y = _base_padd - 4;
			location_tf.width = _w - OFFSET_X - _border_w*2 - _base_padd;
			location_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			_scroller.body.addChild(location_tf);
			
			//visit button
			visit_bt = new Button({
				name: 'visit',
				label: 'Visit their home street',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				graphic: new AssetManager.instance.assets.visit_home(),
				graphic_hover: new AssetManager.instance.assets.visit_home_hover(),
				graphic_disabled: new AssetManager.instance.assets.visit_home_disabled(),
				graphic_placement: 'left',
				graphic_padd_l: 10,
				graphic_padd_r: 2
			});
			visit_bt.x = OFFSET_X;
			visit_bt.addEventListener(TSEvent.CHANGED, onVisitClick, false, 0, true);
			_scroller.body.addChild(visit_bt);
			
			//send IM button
			send_im_bt = new Button({
				name: 'send_im',
				label: 'Send them an IM',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			send_im_bt.x = int(visit_bt.x + visit_bt.width + 10);
			send_im_bt.addEventListener(TSEvent.CHANGED, onSendIMClick, false, 0, true);
			_scroller.body.addChild(send_im_bt);
			
			//the online/offline circle
			const online_rad:uint = 4;
			
			var g:Graphics = online_circle.graphics;
			g.beginFill(0x95bc09);
			g.drawCircle(0, 0, online_rad);
			online_circle.x = location_tf.x - online_rad*2 + 2;
			online_circle.y = location_tf.y + online_rad*2 + 2;
			online_circle.mouseEnabled = false;
			_scroller.body.addChild(online_circle);
			
			//update tf
			TFUtil.prepTF(update_tf);
			update_tf.embedFonts = false;
			update_tf.x = OFFSET_X;
			update_tf.width = _w - OFFSET_X - _border_w*2 - _base_padd;
			update_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			_scroller.body.addChild(update_tf);
			
			//modules
			_scroller.body.addChild(module_holder);
			
			//api stuff
			api_call.addEventListener(TSEvent.COMPLETE, reload, false, 0, true);
			api_call.addEventListener(TSEvent.ERROR, onAPIError, false, 0, true);
			//api_call.trace_output = true;
			
			//avatar holder
			avatar_holder.scaleX = -1; //flip the png
			avatar_holder.x = AVATAR_SIZE - 20;
			avatar_holder.y = -20;
			avatar_holder.mouseEnabled = avatar_holder.mouseChildren = false;
			addChild(avatar_holder);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onAvatarLoad, false, 0, true);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError, false, 0, true);
			
			//confirmation
			cdVO.txt = 'Are you sure you want to remove this person?'
			cdVO.choices = [
				{value: false, label: 'Never mind'},
				{value: true, label: 'Yes, go ahead and remove them'}
			];
			cdVO.escape_value = false;
			cdVO.callback = onRemoveConfirm;
			
			is_built = true;
		}
		
		public function startWithTsid(tsid:String):void {
			if(tsid){
				if(!is_built) buildBase();
				
				//clear stuff
				_setTitle('Player Info');
				online_circle.visible = false;
				add_buddy_bt.visible = false;
				remove_buddy_bt.visible = false;
				profile_bt.visible = false;
				avatar_holder.visible = false;
				module_holder.visible = false;
				visit_bt.visible = false;
				send_im_bt.visible = false;
				
				location_tf.htmlText = '<p class="player_info">Loading info...</p>';
				update_tf.text = '';
				player_tsid = tsid;
				
				api_call.playersFullInfo(player_tsid);
				start();
				
				//listen to buddy events to see if it's this person
				RightSideManager.instance.addEventListener(TSEvent.BUDDY_ADDED, updateLoc, false, 0, true);
				RightSideManager.instance.addEventListener(TSEvent.BUDDY_REMOVED, updateLoc, false, 0, true);
				RightSideManager.instance.addEventListener(TSEvent.BUDDY_ONLINE, updateLoc, false, 0, true);
				RightSideManager.instance.addEventListener(TSEvent.BUDDY_OFFLINE, updateLoc, false, 0, true);
			}
			else {
				CONFIG::debugging {
					Console.warn('You need to pass a PC TSID!!');
				}
			}
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//kill the listeners
			RightSideManager.instance.removeEventListener(TSEvent.BUDDY_ADDED, updateLoc);
			RightSideManager.instance.removeEventListener(TSEvent.BUDDY_REMOVED, updateLoc);
			RightSideManager.instance.removeEventListener(TSEvent.BUDDY_ONLINE, updateLoc);
			RightSideManager.instance.removeEventListener(TSEvent.BUDDY_OFFLINE, updateLoc);
		}
		
		public function playerUpdate(tsid:String):void {
			if(!parent || tsid != player_tsid) return;
			
			//player went online or offline
			updateLoc(new TSEvent(TSEvent.CHANGED, tsid));
		}
		
		public function reloadIfOpen():void {
			if (parent) {
				reload();
			}
		}
		
		private function reload(event:TSEvent = null):void {
			if(event){ 				
				//player tsid passed, will ALWAYS be this in the future, but for now the API returns an object
				if(event.data is String && event.data != player_tsid){
					return;
				} 
				else if(event.data is Object && event.data.hasOwnProperty('player_tsid') && event.data.player_tsid != player_tsid){
					return;
				} 
			}
			
			const pc:PC = model.worldModel.getPCByTsid(player_tsid);
			if(pc){
				//title
				_setTitle(pc.label);
				
				//load the avatar
				avatar_holder.visible = true;
				if(pc.singles_url && avatar_holder.name != pc.singles_url){
					showAvatar(pc.singles_url);
				}
				
				//show the buttons
				const buddy_tsid:String = model.worldModel.getBuddyByTsid(player_tsid);
				add_buddy_bt.visible = pc.can_contact && !buddy_tsid;
				remove_buddy_bt.visible = buddy_tsid != null;
				profile_bt.visible = true;
				
				//show the circle
				online_circle.visible = true;
				
				//visit them
				visit_bt.visible = true;
				
				if (!event.data.hasOwnProperty('pol') || !event.data.pol.tsid) {
					visit_bt.disabled = true;
					visit_bt.tip = {txt:"This user doesn't have a home street yet", pointer:WindowBorder.POINTER_BOTTOM_CENTER};
				} else if (event.data.relationship.is_blocking_me === true) {
					visit_bt.disabled = true;
					visit_bt.tip = {txt:'This location cannot be visited by you', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
				} else if (model.worldModel.location.no_home_street_visiting) {
					visit_bt.disabled = true;
					visit_bt.tip = {txt:'Wait a bit before you try visiting home streets!', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
				} else if ('street_tsid' in event.data.pol && model.worldModel.location.tsid == event.data.pol.street_tsid){
					visit_bt.disabled = true;
					visit_bt.tip = {txt:'You are already here!', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
				} else {
					visit_bt.disabled = false;
					visit_bt.tip = null;
				}
				
				//send an IM if they are online
				send_im_bt.visible = true;
				
				if(!pc.online){
					//player offline
					send_im_bt.disabled = true;
					send_im_bt.tip = {txt:'This player is offline', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
				}
				else if('relationship' in event.data && event.data.relationship.can_contact === false){
					//this person has blocked you
					send_im_bt.visible = false;
				}
				else {
					send_im_bt.disabled = false;
					send_im_bt.tip = null;
				}
				
				//3 modules - level, skills, badge
				var skill_tsid:String = event.data.hasOwnProperty('latest_skill') && event.data.latest_skill.id ? event.data.latest_skill.id : '';
				var badge_tsid:String = event.data.hasOwnProperty('latest_achievement') && event.data.latest_achievement.id ? event.data.latest_achievement.id : '';
				showModules(pc.level, skill_tsid, badge_tsid);
				module_holder.x = OFFSET_X + int((_w - OFFSET_X - _base_padd)/2 - module_holder.width/2);
				module_holder.visible = true;
				
				//update text
				var update_txt:String = '';
				if(event.data.hasOwnProperty('last_update') && event.data.last_update.text){
					var update_time:String = StringUtil.formatTime(event.data.last_update.time_ago, false).split(' ').join('&nbsp;');
					update_txt = '<b>Latest update:</b> '+StringUtil.linkify(StringUtil.encodeHTMLUnsafeChars(StringUtil.truncate(event.data.last_update.text, MAX_UPDATE_CHARS)), 'chat_element_url');
					
					//add a link to go right to the status
					update_txt += '&nbsp;&nbsp;<a href="event:'+TSLinkedTextField.LINK_EXTERNAL+'|'+model.flashVarModel.root_url+'status/'+pc.tsid+'/'+event.data.last_update.id+'/'+'">[more]</a>';
					
					//then the update time
					update_txt += '  <span class="player_info_time">'+(update_time ? update_time : 'moments')+'&nbsp;ago</span>';
				}
				//update_txt = '<&nbsp;'
				//Console.warn(update_txt);
				update_tf.htmlText = '<p class="player_info">'+update_txt+'</p>';
				
				//where are they?
				updateLoc();
			}
			else {
				CONFIG::debugging {
					Console.warn('PC TSID not found: '+player_tsid);
				}
			}
		}
		
		private function updateLoc(event:TSEvent = null):void {
			if(event && event.data != player_tsid) return;
			
			var pc:PC = model.worldModel.getPCByTsid(player_tsid);
			
			if(pc){
				//online or offline?
				online_circle.transform.colorTransform = pc.online ? new ColorTransform() : ColorUtil.getColorTransform(0x999999);
				
				var loc_txt:String = (pc.online ? 'Online' : 'Last seen');
				var location:Location;
				
				if(pc.location && pc.location.tsid){
					location = model.worldModel.getLocationByTsid(pc.location.tsid);
					if(location){
						if(!location.is_pol){
							loc_txt += ' running around in <b><a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+location.hub_id+'#'+location.tsid+'">'+location.label+'</a></b>.';
						}
						else {
							loc_txt += ' running around in <b>'+location.label+'</b>.';
						}
					}
					else {
						loc_txt += (pc.online ? ', but': '')+' in an unknown location.';
					}
				}
				//who knows?!
				else {
					loc_txt += (pc.online ? ', but': '')+' in an unknown location.';
				}
				
				location_tf.htmlText = '<p class="player_info">'+loc_txt+'</p>';
				
				//shuffle things around
				visit_bt.y = int(location_tf.y + location_tf.height + 2);
				send_im_bt.y = visit_bt.y;
				var next_y:int = 25 + int(visit_bt.y + visit_bt.height);
				module_holder.y = next_y;
				next_y += module_holder.height + 10;
				
				update_tf.y = next_y;
			}
		}
		
		private function showModules(level:int, skill_tsid:String, badge_tsid:String):void {
			const sections:Array = ['Level', 'Latest skill', 'Latest badge'];
			const offset_y:uint = 3;
			var i:int;
			var tf:TextField;
			var sp:Sprite;
			var next_x:int;
			var skill_icon:SkillIcon;
			var badge_icon:AchievementIcon;
			
			for(i; i < sections.length; i++){
				sp = module_holder.getChildByName(sections[int(i)]) as Sprite;
				if(!sp){
					//holder
					sp = new Sprite();
					sp.name = sections[int(i)];
					module_holder.addChild(sp);
					
					if(i > 0){
						TipDisplayManager.instance.registerTipTrigger(sp);
					}
					
					//title
					tf = new TextField();
					TFUtil.prepTF(tf, false);
					tf.htmlText = '<p class="player_info_module">'+sections[int(i)]+'</p>';
					sp.addChild(tf);
				}
				
				//handle the different types
				switch(sections[int(i)]){
					case 'Level':
						tf = sp.getChildByName('level_tf') as TextField;
						if(!tf){
							tf = new TextField();
							TFUtil.prepTF(tf, false);
							tf.y = int(sp.height) + offset_y - 10; //fucking flash TFs and big fonts
							tf.name = 'level_tf';
							sp.addChild(tf);
						}
						
						tf.htmlText = '<p class="player_info_level">'+level+'</p>';
						tf.x = int(sp.getChildAt(0).width/2 - tf.width/2);
						break;
					case 'Latest skill':
						if(skill_tsid){
							skill_icon = sp.getChildByName(skill_tsid) as SkillIcon;
							if(!skill_icon){
								SpriteUtil.clean(sp, true, 1);
								skill_icon = new SkillIcon(skill_tsid);
								skill_icon.x = int(sp.width/2 - SkillIcon.SIZE_DEFAULT/2) + 1;
								skill_icon.y = int(sp.height) + offset_y;
								skill_icon.addEventListener(MouseEvent.CLICK, onSkillClick, false, 0, true);
								skill_icon.buttonMode = skill_icon.useHandCursor = true;
								sp.addChild(skill_icon);
							}
						}
						else {
							sp.x = 0;
							sp.visible = false;
						}
						break;
					case 'Latest badge':
						if(badge_tsid){
							badge_icon = sp.getChildByName(badge_tsid) as AchievementIcon;
							if(!badge_icon){
								SpriteUtil.clean(sp, true, 1);
								badge_icon = new AchievementIcon(badge_tsid, AchievementIcon.SIZE_40);
								badge_icon.x = int(sp.width/2 - badge_icon.width/2) + 1;
								badge_icon.y = int(sp.height) + offset_y + 1;
								sp.addChild(badge_icon);
							}
						}
						else {
							sp.x = 0;
							sp.visible = false;
						}
						break;
				}
				
				sp.x = next_x;
				if(sp.visible) next_x += sp.width + 30;
			}
		}
		
		private function showAvatar(url:String):void {
			SpriteUtil.clean(avatar_holder);
			req.url = url+'_'+AVATAR_SIZE+'.png';
			avatar_holder.name = url;
			loader.load(req);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			var tip_txt:String = '';
			
			if(tip_target.name == 'Latest skill'){
				var skill:SkillDetails = model.worldModel.getSkillDetailsByTsid(Sprite(tip_target).getChildAt(1).name);
				tip_txt = skill.name;
			}
			else if(tip_target.name == 'Latest badge'){
				var achievement:Achievement = model.worldModel.getAchievementByTsid(Sprite(tip_target).getChildAt(1).name);
				tip_txt = achievement ? achievement.name : 'Unknown';
			}
			
			return {
				txt: tip_txt,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER	
			}
		}
		
		private function onAvatarLoad(event:Event):void {
			var avatar:DisplayObject = LoaderInfo(event.currentTarget).content;
			if(avatar){
				avatar_holder.addChild(avatar);
			}
		}
		
		private function onError(event:IOErrorEvent):void {
			//S3 shitting the bed again?
			BootError.handleError('Trying to load an avatar from: '+req.url, new Error('Loading the avatar failed'), ['loader'], !CONFIG::god);
			CONFIG::debugging {
				Console.warn('Looks like an issue with our CDN not giving us the file: '+req.url);
			}
		}
		
		private function onBuddyClick(event:TSEvent):void {
			//add/remove this buddy
			const bt:Button = event.data as Button;
			SoundMaster.instance.playSound(!bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(bt.disabled) return;
			
			const is_buddy:Boolean = bt.value;
			bt.disabled = true;
			
			//remove them
			if(is_buddy){
				TSFrontController.instance.confirm(cdVO);
			}
			//add them
			else {
				TSFrontController.instance.genericSend(new NetOutgoingBuddyAddVO(player_tsid, 'group1'), onBuddyReply, onBuddyReply);
			}
		}
		
		private function onRemoveConfirm(value:Boolean):void {
			if(value){
				//tell the server to axe em
				TSFrontController.instance.genericSend(new NetOutgoingBuddyRemoveVO(player_tsid, 'group1'), onBuddyReply, onBuddyReply);
			}
			else {
				//reset the buttons
				add_buddy_bt.disabled = false;
				remove_buddy_bt.disabled = false;
			}
		}
		
		private function onBuddyReply(nrm:NetResponseMessageVO):void {
			//re-enable the buttons
			add_buddy_bt.disabled = false;
			remove_buddy_bt.disabled = false;
			
			//figure out what to show
			const pc:PC = model.worldModel.getPCByTsid(player_tsid);
			const buddy_tsid:String = model.worldModel.getBuddyByTsid(player_tsid);
			
			if(pc){
				add_buddy_bt.visible = pc.can_contact && !buddy_tsid;
				remove_buddy_bt.visible = buddy_tsid != null;
			}
		}
		
		private function onSkillClick(event:MouseEvent):void {
			//bring up the skill info
			TSFrontController.instance.showSkillInfo(event.currentTarget.name);
		}
		
		private function onProfileClick(event:TSEvent):void {
			TSFrontController.instance.openProfilePage(event, player_tsid);
		}
		
		private function onVisitClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!visit_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(visit_bt.disabled) return;
			
			//tell the server we wanna do this
			TSFrontController.instance.genericSend(new NetOutgoingHousesVisitVO(player_tsid), onVisitReply, onVisitReply);
		}
		
		private function onVisitReply(nrm:NetResponseMessageVO):void {
			//doesn't matter, just re-enable the button
			visit_bt.disabled = false;
		}
		
		private function onSendIMClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!send_im_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(send_im_bt.disabled) return;
			
			//open a chat with this person
			RightSideManager.instance.chatStart(player_tsid, true, true);
		}
		
		private function onAPIError(event:TSEvent):void {
			location_tf.htmlText = '<p class="player_info">There was an error showing this player for some reason, you should try again!</p>';
		}
	}
}
