package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.net.NetOutgoingContactListOpenedVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.RightSideView;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.UICalloutView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class ContactList extends TSSpriteWithModel
	{
		public static const MIN_WIDTH:uint = 48;
		public static const MAX_WIDTH:uint = 165;
		
		private static const TOGGLE_BUTTON_HIT_AREA:uint = 6; //how many extra px around the outside of the toggle button
		private static const TOGGLE_BUTTON_W:uint = 12;
		private static const TOGGLE_BUTTON_H:uint = 60;
		private static const PADD:uint = 8;
		private static const ADD_FRIENDS:String = 'Add Friends';
		private static const FIND_GROUPS:String = 'Find Groups';
		private static const CURVE_WIDTH:uint = 5;
		
		public static const BUTTON_W:uint = TOGGLE_BUTTON_W + TOGGLE_BUTTON_HIT_AREA;
		
		private var add_friends_bt:Button;
		private var find_groups_bt:Button;
		private var scroll_up_bt:Button;
		private var scroll_down_bt:Button;
		private var scroll_up_active_bt:Button;
		private var scroll_down_active_bt:Button;
		private var active_contacts:ActiveContacts;
		private var online_contacts:OnlineContacts;
		private var offline_contacts:OfflineContacts;
		private var group_contacts:GroupContacts;
		private var perma_group_contacts:PermaGroupContacts;
		
		private var scroll_timer:Timer = new Timer(20);
		
		private var toggle_bt:Sprite = new Sprite();
		private var arrow_holder:Sprite = new Sprite();
		private var bg:Sprite = new Sprite();
		private var bg_vp_h:Sprite = new Sprite();
		private var masker:Sprite = new Sprite();
		private var all_masker:Sprite = new Sprite();
		private var active_masker:Sprite = new Sprite();
		private var contacts_holder:Sprite = new Sprite();
		private var all_holder:Sprite = new Sprite();
		private var no_friends:Sprite;
		private var scrolling_holder:Sprite;
		
		private var toggle_local:Point;
		private var toggle_global:Point;
		private var contact_local:Point = new Point();
		private var contact_global:Point;
		
		private var _is_open:Boolean;
		private var is_built:Boolean;
		private var scrolling_down:Boolean;
		private var friends_bt_visible:Boolean = true;
		
		public function ContactList(){
			//bg
			bg.filters = StaticFilters.chat_left_shadow_innerA;
			addChild(bg);
			masker.mouseEnabled = false;
			contacts_holder.mask = masker;
			all_holder.addChild(masker);
			
			//holds all of the contacts
			all_holder.addChild(contacts_holder);
			all_holder.mask = all_masker;
			addChild(all_holder);
			addChild(all_masker);
			
			//masker for the active contacts
			active_masker.y = PADD + 3;
			addChild(active_masker);
			
			//watch for the mouse to know when to listen to the wheel
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			
			//toggle button			
			var arrow:DisplayObject = new AssetManager.instance.assets.chat_toggle_arrow();
			SpriteUtil.setRegistrationPoint(arrow);
			arrow_holder.addChild(arrow);
			arrow_holder.x = int(TOGGLE_BUTTON_W/2 + 1);
			arrow_holder.y = int(TOGGLE_BUTTON_H/2 + TOGGLE_BUTTON_HIT_AREA - arrow.height/2);
			toggle_bt.addChild(arrow_holder);
			
			toggle_bt.x = -TOGGLE_BUTTON_W;
			toggle_bt.mouseChildren = false;
			toggle_bt.useHandCursor = toggle_bt.buttonMode = true;
			toggle_bt.addEventListener(MouseEvent.CLICK, onToggleClick, false, 0, true);
			
			addChildAt(toggle_bt, 0);
			
			//friends bt
			add_friends_bt = new Button({
				name: 'add_friends',
				x: 5,
				draw_alpha: 0,
				disabled: true,
				label_bold: true,
				label_c: 0x205c76,
				label_hover_c: 0xd79035,
				label_size: 13,
				label_offset: 1,
				graphic_padd_r: 2,
				//graphic: new AssetManager.instance.assets.contact_plus(),
				graphic: new AssetManager.instance.assets.contact_add_friend(),
				graphic_placement: 'left',
				use_hand_cursor_always: true,
				tip: { txt: ADD_FRIENDS, pointer: WindowBorder.POINTER_BOTTOM_CENTER }
			});
			add_friends_bt.addEventListener(TSEvent.CHANGED, TSFrontController.instance.openFriendsPage, false, 0, true);
			addChild(add_friends_bt);
			
			//groups button
			find_groups_bt = new Button({
				name: 'find_groups',
				x: 5,
				draw_alpha: 0,
				disabled: true,
				label_bold: true,
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				label_offset: 2,
				graphic_padd_r: 0,
				graphic: new AssetManager.instance.assets.contact_plus(),
				graphic_disabled: new AssetManager.instance.assets.contact_add_group(),
				graphic_placement: 'left',
				use_hand_cursor_always: true,
				tip: { txt: FIND_GROUPS, pointer: WindowBorder.POINTER_BOTTOM_CENTER }
			});
			find_groups_bt.addEventListener(TSEvent.CHANGED, TSFrontController.instance.openGroupsPage, false, 0, true);
			//addChild(find_groups_bt);
			
			//scroll up/down			
			scroll_up_bt = buildScrollButton('up', 'contacts_holder');
			scroll_down_bt = buildScrollButton('down', 'contacts_holder');
			scroll_up_active_bt = buildScrollButton('up', 'active_contacts');
			scroll_down_active_bt = buildScrollButton('down', 'active_contacts');
			scroll_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			
			addChildAt(bg_vp_h, 0);
			
			refresh();
		}
		
		private function buildScrollButton(direction:String, scroll_target:String):Button {
			var holder:Sprite = new Sprite();
			var arrow:DisplayObject = new AssetManager.instance.assets.contact_arrow();
			SpriteUtil.setRegistrationPoint(arrow);
			arrow.y = direction == 'up' ? 0 : -10;
			holder.addChild(arrow);
			holder.rotation = direction == 'up' ? -90 : 90;
			
			var bt:Button = new Button({
				name: direction,
				c: model.layoutModel.bg_color,
				value: scroll_target,
				focused_c: 0xd4d9db,
				graphic: holder,
				graphic_padd_t: direction == 'up' ? 8 : 5,
				y: -1,
				x: -1,
				size: Button.SIZE_ELEVATOR_GRODDLE //just a square button, TEMP until burka is back
			});
			bt.h = holder.height + 5;
			bt.filters = StaticFilters.chat_left_shadow_innerA;
			bt.visible = false;
			bt.addEventListener(MouseEvent.MOUSE_DOWN, direction == 'up' ? onScrollUpDown : onScrollDownDown, false, 0, true);
			
			return bt;
		}
		
		private function buildNoFriends():void {
			no_friends = new Sprite();
			
			var tf:TextField = new TextField();
			TFUtil.prepTF(tf);
			tf.htmlText = '<p class="contact_list_no_friends">Playing with friends is much more fun.</p>';
			tf.width = MAX_WIDTH - 30;
			no_friends.addChild(tf);
			
			var bt:Button = new Button({
				name: 'no friends',
				label: 'Find your friends',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				y: tf.height + 7
			});
			bt.x = int(tf.width/2 - bt.width/2);
			bt.addEventListener(TSEvent.CHANGED, TSFrontController.instance.openFriendsPage, false, 0, true);
			no_friends.addChild(bt);
			
			no_friends.x = int(MAX_WIDTH/2 - no_friends.width/2);
			
			addChild(no_friends);
		}
		
		private function hasFriends():Boolean {
			if(!online_contacts.height && !offline_contacts.height && model.worldModel.getGroupsTsids().length == 1) return false;
			return true;
		}
		
		public function start():void {
			//called from RightSideView.init
			if(is_built) return;
						
			//active contacts
			active_contacts = new ActiveContacts(MAX_WIDTH - 2);
			active_contacts.x = PADD-5; //gives a little room for icons and alerts
			active_contacts.y = PADD+3;
			active_contacts.mask = active_masker;
			all_holder.addChild(active_contacts);
			
			//online contacts
			online_contacts = new OnlineContacts(model.worldModel.getBuddiesTsids(true), MAX_WIDTH - PADD*2);
			contacts_holder.addChild(online_contacts);
			
			//perma groups (live help, global etc)
			perma_group_contacts = new PermaGroupContacts(model.worldModel.getGroupsTsids(true, !model.worldModel.pc.needs_account, true), MAX_WIDTH - PADD*2);
			contacts_holder.addChild(perma_group_contacts);
			
			//groups
			group_contacts = new GroupContacts(model.worldModel.getGroupsTsids(false, false), MAX_WIDTH - PADD*2);
			group_contacts.addEventListener(TSEvent.TOGGLE, refresh, false, 0, true);
			group_contacts.addEventListener(TSEvent.CHANGED, refresh, false, 0, true);
			contacts_holder.addChild(group_contacts);
			
			//offline contacts
			offline_contacts = new OfflineContacts(model.worldModel.getBuddiesTsids(false), MAX_WIDTH - PADD*2);
			offline_contacts.addEventListener(TSEvent.TOGGLE, refresh, false, 0, true);
			offline_contacts.addEventListener(TSEvent.CHANGED, refresh, false, 0, true);
			contacts_holder.addChild(offline_contacts);
			
			//if this player doesn't have any friends and not a member of any groups, put a little find friend thing in the contact list
			if(!hasFriends()) buildNoFriends();
			
			contacts_holder.x = PADD;
			contacts_holder.y = PADD + 13;
			
			//scroll buttons
			addChild(scroll_up_bt);
			addChild(scroll_down_bt);
			addChild(scroll_up_active_bt);
			addChild(scroll_down_active_bt);
			
			is_built = true;
			
			refresh();
		}
		
		public function refresh(event:Event = null, draw_h:int = 0):void {			
			//draw_h will be 0 when it's closed because of the need for the workaround
			if(draw_h) draw(draw_h);
			
			if(parent) toggle_bt.y = int(model.layoutModel.loc_vp_h/2 - TOGGLE_BUTTON_H/2 - parent.y - y);
			//find_groups_bt.y = int(bg.height - find_groups_bt.height - PADD);
			add_friends_bt.y = int(bg.height - add_friends_bt.height - PADD + 3); //little visual gap
			//add_friends_bt.y = int(find_groups_bt.y - add_friends_bt.height);
			scroll_up_bt.y = masker.y - scroll_up_bt.height - 2;
			scroll_down_bt.y = int(bg.height - scroll_down_bt.height - PADD + 3); //little visual gap
			scroll_down_active_bt.y = int(active_masker.y + active_masker.height - 1);
			
			scroll_up_bt.w = scroll_down_bt.w = masker.width + 2;
			scroll_up_active_bt.w = scroll_down_active_bt.w = masker.width + 2;
			
			if(is_built){
				var next_y:int = PADD + 3; //lets the scroll button sneak in there
				
				next_y += active_contacts.element_count > 0 ? active_masker.height + 5 : -PADD-13;
				
				perma_group_contacts.y = next_y;
				next_y += perma_group_contacts.height;
				
				group_contacts.y = next_y;
				next_y += group_contacts.height;
				
				online_contacts.y = next_y;
				next_y += online_contacts.height + 1;
				
				offline_contacts.y = next_y;
				next_y += offline_contacts.height;
				
				//if the next Y is higher than the mask, we know we need some scroll down action
				if(!event || (event && event.type != 'FUCKING_WORK_AROUND')){
					checkScrolling();
					checkActiveScrolling();
				} 
				
				//if they had no friends, and they do now, kill it
				if(no_friends && hasFriends()){
					SpriteUtil.clean(no_friends);
					if(contains(no_friends)) removeChild(no_friends);
					no_friends = null;
				}
				//if they no longer have friends, show the button
				else if(!no_friends && !hasFriends()){
					buildNoFriends();
				}
				
				//if they have no friends, center it vertically
				if(no_friends){
					no_friends.visible = is_open;
					no_friends.y = next_y + 80;
				} 
			}
		}
		
		private function checkScrolling():void {			
			if(!offline_contacts) return;
			
			var min_y:int = PADD + 13;
			var max_y:int = offline_contacts.y + offline_contacts.height + scroll_down_bt.height;
			var needs_up:Boolean = contacts_holder.y < min_y && max_y + min_y > masker.height;
			var needs_down:Boolean = contacts_holder.y + max_y > masker.height;
					
			scroll_up_bt.visible = needs_up;
			scroll_down_bt.visible = needs_down;
			add_friends_bt.visible = !scroll_down_bt.visible && friends_bt_visible;
			
			//reset just in case
			if(!needs_up){
				contacts_holder.y = min_y;
			}
			else if(!needs_down){
				contacts_holder.y = masker.height - max_y;
			}
			
			//flash chokes to shit when it's closed, so this way if it is closed it forces the UI to refresh...
			if(!is_open) refresh(new Event('FUCKING_WORK_AROUND'));
		}
		
		private function checkActiveScrolling():void {			
			var min_y:int = PADD + 3;
			var max_y:int = active_masker.y + active_masker.height - 2;
			var needs_up:Boolean = active_contacts.y < min_y;
			var needs_down:Boolean = active_masker.height && int(active_contacts.y + active_contacts.height) > max_y;
									
			scroll_up_active_bt.visible = needs_up;
			scroll_down_active_bt.visible = needs_down;
			
			//reset just in case
			if(!needs_up){
				active_contacts.y = min_y;
			}
			else if(!needs_down){
				active_contacts.y = int(max_y - active_contacts.height + 1);
			}
			
			//flash chokes to shit when it's closed, so this way if it is closed it forces the UI to refresh...
			if(!is_open) refresh(new Event('FUCKING_WORK_AROUND'));
		}
		
		public function toggle(force_open:Boolean = false):void {
			if(force_open && _is_open) return;
			
			_is_open = !_is_open;
			if(force_open) _is_open = true;
			
			arrow_holder.rotation = is_open ? 180 : 0;
			
			add_friends_bt.disabled = !is_open;
			add_friends_bt.tip = is_open ? null : { txt: ADD_FRIENDS, pointer: WindowBorder.POINTER_BOTTOM_CENTER };
			add_friends_bt.label = is_open ? ADD_FRIENDS : '';
			find_groups_bt.disabled = !is_open;
			find_groups_bt.tip = is_open ? null : { txt: FIND_GROUPS, pointer: WindowBorder.POINTER_BOTTOM_CENTER };
			find_groups_bt.label = is_open ? FIND_GROUPS : '';
			
			//make sure the scroll buttons have the right bg color
			scroll_up_bt.color = is_open ? 0xffffff : model.layoutModel.bg_color;
			scroll_down_bt.color = is_open ? 0xffffff : model.layoutModel.bg_color;
			scroll_up_active_bt.color = is_open ? 0xffffff : model.layoutModel.bg_color;
			scroll_down_active_bt.color = is_open ? 0xffffff : model.layoutModel.bg_color;
			
			//set the width of the active contacts so the shadow looks proper
			if(active_contacts) active_contacts.refresh();
			dispatchEvent(new TSEvent(TSEvent.TOGGLE, this));
			
			//if we have a callout still showing, make sure we hide it
			if(is_open && UICalloutView.instance.parent && UICalloutView.instance.current_section == UICalloutView.CONTACTS){
				UICalloutView.instance.hide();
				TSFrontController.instance.genericSend(new NetOutgoingContactListOpenedVO());
			}
		}
		
		/**
		 * Forces the contact list open or closed 
		 * @param is_open
		 */		
		public function toggleForce(is_force_open:Boolean):void {
			if(is_force_open && _is_open) return;
			if(!is_force_open && !_is_open) return;
			
			//nothing left but to toggle
			toggle();
		}
		
		public function getToggleButtonPt():Point {
			if(!toggle_bt) return new Point(0,0);
			if(!toggle_local) toggle_local = new Point(0, TOGGLE_BUTTON_H/2);
			toggle_global = toggle_bt.localToGlobal(toggle_local);
			
			return toggle_global;
		}
		
		public function chatOpen(tsid:String):void {
			//if in the PCs, remove from list and add it to the active contacts
			if(online_contacts.getElement(tsid)){
				//online_contacts.removeContact(tsid);
				active_contacts.addContact(tsid);
			}
			//perma group?
			else if(perma_group_contacts.getElement(tsid)){
				perma_group_contacts.removeContact(tsid);
				active_contacts.addContact(null, tsid);
			}
			//if in the groups, remove from list and add it to the active contacts
			else if(group_contacts.getElement(tsid)){
				group_contacts.removeContact(tsid);
				active_contacts.addContact(null, tsid);
			}
			//party chat, add it to the active stuff
			else if(tsid == ChatArea.NAME_PARTY && !active_contacts.getElement(tsid)){
				active_contacts.addContact(null, tsid);
			}
			//don't know about this person, so it's a new chat!
			else if(!active_contacts.getElement(tsid)){
				active_contacts.addContact(tsid, null);
			}
		}
		
		public function chatActive(tsid:String):void {
			//set the active contact to be the tsid
			active_contacts.setActive(tsid);
		}
		
		public function chatUpdate(tsid:String):void {
			var element:ContactElement = active_contacts.getElement(tsid);
			if(element && !element.enabled){
				element.incrementCounter();
			}
		}
		
		public function chatClose(tsid:String):void {
			var buddy:String = model.worldModel.getBuddyByTsid(tsid);
			var group:Group = model.worldModel.getGroupByTsid(tsid);
			
			//remove it from the active chat and put it back where it needs to go
			active_contacts.removeContact(tsid);
						
			if(buddy){
				var pc:PC = model.worldModel.getPCByTsid(buddy);
				
				if(pc && pc.online){
					//online_contacts.addContact(tsid);
				}
				else if(pc){
					//offline_contacts.addContact(tsid);
				}
			}
			else if(group) {
				if(isGroupPerma(tsid)){
					perma_group_contacts.addContact(null, tsid);
				}
				else {
					group_contacts.addContact(null, tsid);
				}
			}
			
			active_contacts.y = PADD + 3;
		}
		
		private function isGroupPerma(tsid:String):Boolean {
			return (tsid == ChatArea.NAME_GLOBAL ||
			   tsid == ChatArea.NAME_HELP ||
			   tsid == ChatArea.NAME_TRADE ||
			   tsid == ChatArea.NAME_UPDATE_FEED);
		}
		
		/**
		 * When you add/remove a buddy 
		 * @param pc_tsid
		 * @param is_online
		 * @param is_add
		 */		
		public function buddyManage(pc_tsid:String, is_online:Boolean, is_add:Boolean):void {
			//add them to the right group
			if(is_add){
				if(is_online){
					online_contacts.addContact(pc_tsid);
				}
				else {
					offline_contacts.addContact(pc_tsid);
				}
			}
			//remove them
			else {
				if(is_online){
					online_contacts.removeContact(pc_tsid);
				}
				else {
					offline_contacts.removeContact(pc_tsid);
				}
			}
			
			refresh();
		}
		
		/**
		 * Use this when a buddy comes online/offline
		 * @param pc_tsid
		 * @param is_online
		 */		
		public function buddyUpdate(pc_tsid:String, is_online:Boolean):void {
			//let's find this person
			var needs_refresh:Boolean;
			
			if(is_online){
				//were they and offline contact?
				if(offline_contacts.getElement(pc_tsid)){
					//pop them out of the offline and toss em online
					offline_contacts.removeContact(pc_tsid);
					online_contacts.addContact(pc_tsid);
					needs_refresh = true;
				}
			}
			else {
				//online contact going offline?
				if(online_contacts.getElement(pc_tsid)){
					//pop them out of the online and toss em offline
					online_contacts.removeContact(pc_tsid);
					offline_contacts.addContact(pc_tsid);
					needs_refresh = true;
				}
			}
			
			if(active_contacts.refresh(pc_tsid)) needs_refresh = true;
			
			if(needs_refresh) refresh();
		}
		
		public function addFriendsShowHide(is_showing:Boolean):void {
			friends_bt_visible = is_showing;
			if(add_friends_bt) add_friends_bt.visible = friends_bt_visible;
		}
		
		/**
		 * Group stuff join/leave.
		 * @param group_tsid
		 * @param is_join
		 * @param is_perma -- pretty much only used for updates, but it supports the others
		 */		
		public function groupManage(group_tsid:String, is_join:Boolean, is_perma:Boolean = false):void {
			if(group_contacts && !is_perma){
				if(is_join){
					group_contacts.addContact(null, group_tsid);
				}
				else {
					group_contacts.removeContact(group_tsid);
				}
				
				refresh();
			}
			else if(perma_group_contacts && is_perma){
				if(is_join){
					perma_group_contacts.addContact(null, group_tsid);
				}
				else {
					if(RightSideManager.instance.right_view.getChatArea(group_tsid)){
						//kill the chat if it's open
						RightSideManager.instance.chatEnd(group_tsid);
					}
					
					//make sure it doesn't end up back in the contacts
					perma_group_contacts.removeContact(group_tsid);
				}
				
				refresh();
			}
		}
		
		/**
		 * If a group TSID switches on the fly 
		 * @param old_tsid
		 * @param new_tsid
		 */		
		public function groupSwitch(old_tsid:String, new_tsid:String):void {
			if(perma_group_contacts) perma_group_contacts.switchContact(old_tsid, new_tsid);
			if(group_contacts) group_contacts.switchContact(old_tsid, new_tsid);
			if(active_contacts) active_contacts.switchContact(old_tsid, new_tsid);
		}
		
		/**
		 * Sometimes you may be chatting with someone who isn't your buddy
		 * make sure that they get updated and stuff 
		 * @param pc_tsid
		 */		
		public function contactUpdate(pc_tsid:String):void {
			if(active_contacts) active_contacts.refresh(pc_tsid);
			if(online_contacts) online_contacts.refresh(pc_tsid);
			if(offline_contacts) offline_contacts.refresh(pc_tsid);
			if(group_contacts) group_contacts.refresh();
		}
		
		private function onToggleClick(event:MouseEvent):void {
			toggle();
		}
		
		private function onScrollUpDown(event:MouseEvent):void {
			scrolling_down = false;
			scrolling_holder = this[Button(event.currentTarget).value];
			scroll_timer.start();
			StageBeacon.mouse_up_sig.add(onScrollStop);
		}
		
		private function onScrollDownDown(event:MouseEvent):void {
			scrolling_down = true;
			scrolling_holder = this[Button(event.currentTarget).value];
			scroll_timer.start();
			StageBeacon.mouse_up_sig.add(onScrollStop);
		}
		
		private function onScrollStop(event:MouseEvent = null):void {
			StageBeacon.mouse_up_sig.remove(onScrollStop);
			scroll_timer.stop();
			if(scrolling_holder == contacts_holder){
				checkScrolling();
			}
			else {
				checkActiveScrolling();
			}
		}
		
		private function onTimerTick(event:TimerEvent):void {
			const move_amount:uint = 5;
			
			if(scrolling_down){
				scrolling_holder.y -= move_amount;
			}
			else {
				scrolling_holder.y += move_amount;
			}
			
			if(scrolling_holder == contacts_holder){
				checkScrolling();
			}
			else {
				checkActiveScrolling();
			}
		}
		
		private function onRollOver(event:MouseEvent):void {
			//listen for the wheel
			StageBeacon.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onScrollWheel, false, 0, true);
		}
		
		private function onRollOut(event:MouseEvent):void {
			StageBeacon.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onScrollWheel);
		}
		
		private function onScrollWheel(event:MouseEvent):void {
			const speed_multiplyer:Number = 2;
			var holder:Sprite = active_contacts;
			var bt_up:Button = scroll_up_active_bt;
			var bt_down:Button = scroll_down_active_bt;
			var pt:Point = scroll_up_bt.localToGlobal(new Point(0,0));
			
			//if the mouse is below the scroll up button for regular contacts, then use that
			if(event.stageY >= pt.y){
				holder = contacts_holder;
				bt_up = scroll_up_bt;
				bt_down = scroll_down_bt;
			}
			
			if(bt_up.visible || bt_down.visible){
				holder.y += event.delta * speed_multiplyer;
			}
			
			scrolling_holder = holder;
			
			if(scrolling_holder == contacts_holder){
				checkScrolling();
			}
			else {
				checkActiveScrolling();
			}
			
			event.updateAfterEvent();
		}
		
		private function draw(draw_h:int):void {
			const lm:LayoutModel = model.layoutModel;
			const masker_height:int = draw_h - scroll_down_bt.height - PADD + 3;
			const current_width:int = is_open ? MAX_WIDTH : MIN_WIDTH;
						
			const all_g:Graphics = all_holder.graphics;
			all_g.clear();
			all_g.beginFill(lm.bg_color);
			all_g.drawRect(0, 0, current_width - 8, draw_h);
			
			//draw the bg
			var g:Graphics = bg.graphics;
			g.clear();
			g.beginFill(lm.bg_color);
			g.drawRect(0, 0, current_width, draw_h);
			
			//top right curve
			var y_pos:int;
			if(!RightSideView(parent).map_tab_h){
				g.moveTo(current_width, y_pos);
				g.lineTo(current_width + CURVE_WIDTH, y_pos);
				g.curveTo(current_width, y_pos + CURVE_WIDTH/2, current_width, y_pos + CURVE_WIDTH);
				g.lineTo(current_width, y_pos);
				
				all_g.moveTo(current_width, y_pos);
				all_g.lineTo(current_width + CURVE_WIDTH, y_pos);
				all_g.curveTo(current_width, y_pos + CURVE_WIDTH/2, current_width, y_pos + CURVE_WIDTH);
				all_g.lineTo(current_width, y_pos);
			}
			
			//bottom right curve
			y_pos = draw_h;
			g.moveTo(current_width, y_pos);
			g.lineTo(current_width + CURVE_WIDTH, y_pos);
			g.curveTo(current_width, y_pos - CURVE_WIDTH/2, current_width, y_pos - CURVE_WIDTH);
			g.lineTo(current_width, y_pos);
			
			all_g.moveTo(current_width, y_pos);
			all_g.lineTo(current_width + CURVE_WIDTH, y_pos);
			all_g.curveTo(current_width, y_pos - CURVE_WIDTH/2, current_width, y_pos - CURVE_WIDTH);
			all_g.lineTo(current_width, y_pos);
			
			g.endFill();
			all_g.endFill();
			
			//active contacts masker
			if(active_contacts && active_contacts.element_count){
				const active_w:int = current_width - toggle_bt.x;
				const active_h:int = Math.min(int(active_contacts.height + 2), int(bg.height/2 - TOGGLE_BUTTON_H + 19));
				
				g = active_masker.graphics;
				g.clear();
				g.beginFill(0,.5);
				g.drawRect(toggle_bt.x, 0, active_w, active_h);
			}
			
			//masker
			g = masker.graphics;
			g.clear();
			g.beginFill(0,.5);
			g.drawRect(0, 0, current_width, masker_height);
			masker.y = scroll_up_bt.height + (active_contacts && active_contacts.element_count > 0 ? int(active_masker.y + active_masker.height + 15) : 0);
			
			//all contacts masker
			g = all_masker.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(toggle_bt.x, 0, current_width - toggle_bt.x, masker_height);
			
			//handle the toggle button stuff
			g = toggle_bt.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(-TOGGLE_BUTTON_HIT_AREA, -TOGGLE_BUTTON_HIT_AREA, TOGGLE_BUTTON_W + TOGGLE_BUTTON_HIT_AREA, TOGGLE_BUTTON_H + TOGGLE_BUTTON_HIT_AREA*2);
			g.endFill();
			g.beginFill(lm.bg_color);
			g.drawRoundRectComplex(0, 0, TOGGLE_BUTTON_W, TOGGLE_BUTTON_H, lm.loc_vp_elipse_radius, 0, lm.loc_vp_elipse_radius, 0);
			
			//draw the divider bar
			if(active_contacts && active_contacts.element_count > 0){
				all_g.beginFill(0xcad6dc);
				all_g.drawRect(PADD, int(active_masker.y + active_masker.height + 12), current_width - PADD*2, 1);
			}
			
			//draw the viewport drop shadow thing
			g = bg_vp_h.graphics;
			g.clear();
			g.beginFill(lm.bg_color);
			g.drawRect(0, 0, current_width, lm.loc_vp_h);
		}
		
		public function getContactsPt(is_active:Boolean):Point {
			var pt:Point;
			if(is_active){
				pt = active_contacts.localToGlobal(new Point(-5,PADD));
			}
			else {
				pt = online_contacts.localToGlobal(new Point(-5,PADD));
			}
				
			pt.x -= model.layoutModel.gutter_w;
			pt.y -= model.layoutModel.header_h;
			
			return pt;
		}
		
		public function getContactPt(tsid:String):Point {
			//gotta find this sucker
			var element:ContactElement = active_contacts ? active_contacts.getElement(tsid) : null;
			if(!element) element = perma_group_contacts ? perma_group_contacts.getElement(tsid) : null;
			if(!element) element = group_contacts ? group_contacts.getElement(tsid) : null;
			if(!element) element = online_contacts ? online_contacts.getElement(tsid) : null;
			if(!element) element = offline_contacts ? offline_contacts.getElement(tsid) : null;
			
			if(element){
				contact_local.y = element.height/2;
				contact_global = element.localToGlobal(contact_local);
				return contact_global;
			}
			
			//nothing!
			return new Point(0,0);
		}
		
		public function get is_open():Boolean { return _is_open; }
		public function set is_open(value:Boolean):void {
			if(is_open && !value) toggle();
			if(!is_open && value) toggle(true);
		}
		
		override public function get width():Number {
			//only return the width of the background
			return bg.width - CURVE_WIDTH;
		}
	}
}