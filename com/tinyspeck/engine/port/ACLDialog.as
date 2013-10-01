package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.acl.ACL;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.data.pc.PCTeleportation;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.acl.ACLCreateKeyUI;
	import com.tinyspeck.engine.view.ui.acl.ACLIcon;
	import com.tinyspeck.engine.view.ui.acl.ACLKeysReceivedUI;
	import com.tinyspeck.engine.view.ui.acl.ACLStartMessageUI;
	import com.tinyspeck.engine.view.ui.acl.ACLYourHouseUI;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;

	public class ACLDialog extends BigDialog implements IMoveListener
	{
		/* singleton boilerplate */
		public static const instance:ACLDialog = new ACLDialog();
		
		private static const TAB_X:uint = 13;
		private static const TAB_H:uint = 25;
		private static const CREATE_KEY_H:uint = 254;
		private static const YOUR_HOUSE:String = 'your_house';
		private static const CREATE_KEY:String = 'create_key';
		private static const RECEIVED_KEYS:String = 'received_keys';
		
		private var key_icon:ACLIcon = new ACLIcon(1);
		private var your_house_ui:ACLYourHouseUI;
		private var create_key_ui:ACLCreateKeyUI;
		private var received_keys_ui:ACLKeysReceivedUI;
		private var start_message_ui:ACLStartMessageUI;
		private var your_house_bt:Button;
		private var received_keys_bt:Button;
		private var back_bt:Button;
		private var send_key_bt:Button;
		private var done_bt:Button;
		private var back_keyring_bt:Button;
		
		private var tab_holder:Sprite = new Sprite();
		private var tab_line:Sprite = new Sprite();
		private var tab_masker:Sprite = new Sprite();
		
		private var line_color:uint;
		
		private var current_state:String;
		
		private var is_built:Boolean;
		private var is_showing_msg:Boolean;
		private var is_showing_msg_is_new_pol:Boolean;
		
		public function ACLDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_base_padd = 20;
			_title_padd_left = key_icon.width + 10;
			_head_min_h = 60;
			_body_min_h = 313;
			_body_max_h = 313;
			_body_border_c = 0xd6d6d6;
			_body_fill_c = 0xfafafa;
			_foot_min_h = 7;
			_foot_max_h = 64;
			_w = 343;
			
			_draggable = true;
			
			_construct();
			
			_scroller.never_show_bars = true;
			
			//dialog icon
			key_icon.mouseEnabled = false;
			key_icon.x = key_icon.y = 10;
			_head_sp.addChild(key_icon);
		}
		
		private function buildBase():void {			
			//back button
			back_bt = makeBackBt();
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			back_bt.visible = false;
			addChild(back_bt);
			
			//received keys
			received_keys_ui = new ACLKeysReceivedUI(_w - _border_w*2);
			_scroller.body.addChild(received_keys_ui);
			
			received_keys_bt = new Button({
				name: 'received_keys',
				label: 'Keys from friends',
				type: Button.TYPE_ACL_TAB,
				size: Button.SIZE_VERB,
				h: TAB_H
			});
			received_keys_bt.addEventListener(TSEvent.CHANGED, showBuddyKeys, false, 0, true);
			received_keys_bt.addEventListener(MouseEvent.MOUSE_OVER, onTabOver, false, 0, true);
			received_keys_bt.addEventListener(MouseEvent.MOUSE_OUT, onTabOut, false, 0, true);
			received_keys_bt.addEventListener(MouseEvent.MOUSE_DOWN, onTabOver, false, 0, true);
			tab_holder.addChild(received_keys_bt);
			
			//your house
			your_house_ui = new ACLYourHouseUI(_w - _border_w*2);
			your_house_ui.addEventListener(TSEvent.CHANGED, onCreateKeyClick, false, 0, true);
			_scroller.body.addChild(your_house_ui);
			
			your_house_bt = new Button({
				name: 'your_house',
				label: 'Your house',
				type: Button.TYPE_ACL_TAB,
				size: Button.SIZE_VERB,
				h: TAB_H
			});
			your_house_bt.addEventListener(TSEvent.CHANGED, showYourHouse, false, 0, true);
			your_house_bt.addEventListener(MouseEvent.MOUSE_OVER, onTabOver, false, 0, true);
			your_house_bt.addEventListener(MouseEvent.MOUSE_OUT, onTabOut, false, 0, true);
			your_house_bt.addEventListener(MouseEvent.MOUSE_DOWN, onTabOver, false, 0, true);
			your_house_bt.x = int(received_keys_bt.width + 3);
			tab_holder.addChild(your_house_bt);
			
			//the fake bottom line thing
			line_color = CSSManager.instance.getUintColorValueFromStyle('button_acl_tab_label', 'backgroundColor', 0xfafafa);
			tab_holder.addChild(tab_line);
			tab_holder.mask = tab_masker;
			
			var g:Graphics = tab_masker.graphics;
			g.beginFill(0);
			g.drawRect(0, 0, _w - _border_w*2, your_house_bt.height + 4);
			tab_masker.x = _border_w;
			_head_sp.addChild(tab_masker);
			
			//mask for the tabs
			_head_sp.addChild(tab_holder);
			
			//create key
			create_key_ui = new ACLCreateKeyUI(_w - _border_w*2, CREATE_KEY_H);
			create_key_ui.addEventListener(TSEvent.CHANGED, onCreateKeyChanged, false, 0, true);
			create_key_ui.addEventListener(TSEvent.CLOSE, onCreateKeyClose, false, 0, true);
			
			//buttons for create
			send_key_bt = new Button({
				name: 'send_key',
				label: 'Send them a key',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			send_key_bt.x = int(_w - _base_padd - send_key_bt.width);
			send_key_bt.y = int(_foot_max_h/2 - send_key_bt.height/2 - 1);
			send_key_bt.addEventListener(TSEvent.CHANGED, onSendClick, false, 0, true);
			_foot_sp.addChild(send_key_bt);
			
			done_bt = new Button({
				name: 'done',
				label: 'Done',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			done_bt.x = int(_w - _base_padd - done_bt.width);
			done_bt.y = send_key_bt.y;
			done_bt.addEventListener(TSEvent.CHANGED, closeFromUserInput, false, 0, true);
			_foot_sp.addChild(done_bt);
			
			back_keyring_bt = new Button({
				name: 'back_keyring',
				label: 'Back to your keyring',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			back_keyring_bt.x = _base_padd;
			back_keyring_bt.y = int(_foot_max_h/2 - back_keyring_bt.height/2 - 1);
			back_keyring_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			back_keyring_bt.addEventListener(MouseEvent.ROLL_OVER, onBackKeyringOver, false, 0, true);
			_foot_sp.addChild(back_keyring_bt);
			
			//build the message UI
			start_message_ui = new ACLStartMessageUI();
			start_message_ui.x = _base_padd*2;
			start_message_ui.y = _base_padd;
			start_message_ui.addEventListener(TSEvent.CHANGED, onStartMessageChange, false, 0, true);
			start_message_ui.addEventListener(TSEvent.CLOSE, onStartMessageClose, false, 0, true);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			//make sure the start message isn't showing
			start_message_ui.hide();
			
			//reset the position
			_scroller.body.x = 0;
			back_bt.visible = false;
			
			//reset the title (sometimes data loads and we don't get a title right away)
			setTitle('Manage your keyring');
			
			//show your received keys by default
			showBuddyKeys();
			
			//set the tabs
			tab_holder.x = TAB_X;
			tab_holder.visible = true;
			setTabs();
			
			//start listening
			ACLManager.instance.addEventListener(TSEvent.CHANGED, onKeyCountChange, false, 0, true);
			TeleportationDialog.instance.addEventListener(TSEvent.CHANGED, onTeleportationChange, false, 0, true);
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			
			//go ask the server for the latest and greatest
			ACLManager.instance.requestKeyInfo(true);
			
			//only call this if we aren't in the TSMainView, because it calls end() for some reason
			if(!parent) super.start();
			
			//set the last_x and last_y so this thing doesn't go all over the place
			last_x = x;
			last_y = y;
		}
		
		public function startWithMessage(is_new_pol:Boolean):void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			//subscribe to move messages
			is_showing_msg = true;
			is_showing_msg_is_new_pol = is_new_pol;
			TSFrontController.instance.registerMoveListener(this);
			
			//add it to the body
			start_message_ui.show(_w - _base_padd*4, is_new_pol);
			_scroller.body.addChild(start_message_ui);
			
			//reset the position
			_scroller.body.x = 0;
			back_bt.visible = false;
			
			//set the title and sub title
			setTitle('Manage your keyring');
			_setSubtitle(is_new_pol ? 'Give keys to your friends' : "View keys you've received");
			
			super.start();
			
			//set the last_x and last_y so this thing doesn't go all over the place
			last_x = x;
			last_y = y;
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//stop listening
			ACLManager.instance.removeEventListener(TSEvent.CHANGED, onKeyCountChange);
			TeleportationDialog.instance.removeEventListener(TSEvent.CHANGED, onTeleportationChange);
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
			
			current_state = '';
		}
		
		public function sendSuccess():void {
			//we've sent someone a key, show the success message in the create area
			if(create_key_ui.visible) create_key_ui.showSuccess();
			
			//swap the buttons at the bottom
			send_key_bt.disabled = false;
			send_key_bt.visible = false;
			back_keyring_bt.visible = true;
			done_bt.visible = true;
			done_bt.focus();
			
			//go ask the server for updated info
			ACLManager.instance.requestKeyInfo(true);
		}
		
		private function showYourHouse(event:TSEvent = null):void {
			if(event && event.data is Button && (your_house_bt.disabled || current_state == YOUR_HOUSE)) return;
			if(start_message_ui.visible) return;
			
			setTitle('Manage your keyring');
			_setSubtitle('Give keys to your friends');
			
			current_state = YOUR_HOUSE;
			
			your_house_ui.show();
			received_keys_ui.hide();
			
			setTabs();
			
			//_jigger();
		}
		
		private function showBuddyKeys(event:TSEvent = null):void {			
			if(event && event.data is Button && (received_keys_bt.disabled || current_state == RECEIVED_KEYS)) return;
			if(start_message_ui.visible) return;
			
			setTitle('Manage your keyring');
			_setSubtitle("View keys you've received");
			
			current_state = RECEIVED_KEYS;
			
			your_house_ui.hide();
			received_keys_ui.show();
			
			setTabs();
			
			//_jigger();
		}
		
		private function setTitle(txt:String):void {
			_setTitle('<span class="acl_dialog_title">'+txt+'</span>');
		}
		
		private function setTabs():void {
			const pc:PC = model.worldModel.pc;
			if(!pc) return;
			const pc_home_tsid:String = !pc.pol_tsid && pc.home_info ? pc.home_info.interior_tsid : pc.pol_tsid;
			
			//set the tabs
			your_house_bt.disabled = !pc_home_tsid;
			your_house_bt.tip = your_house_bt.disabled 
				? {txt:'<p align="center">When you own a home,<br>keys that you give out<br>will show up here</p>', pointer:WindowBorder.POINTER_BOTTOM_CENTER} 
				: null;
			received_keys_bt.disabled = ACLManager.instance.acl ? ACLManager.instance.acl.keys_received.length == 0 : true;
			received_keys_bt.tip = received_keys_bt.disabled 
				? {txt:'<p align="center">Keys that you receive<br>will show up here</p>', pointer:WindowBorder.POINTER_BOTTOM_CENTER} 
				: null;
			
			//set the proper button state based on what our current state is
			if(!your_house_bt.disabled && current_state != YOUR_HOUSE){
				your_house_bt.focus();
			}
			else {
				your_house_bt.blur();
			}
			
			if(!received_keys_bt.disabled && current_state != RECEIVED_KEYS){
				received_keys_bt.focus();
			}
			else {
				received_keys_bt.blur();
			}
		}
		
		private function onKeyCountChange(event:TSEvent = null):void {
			if(!is_built) buildBase();
			
			//check to see if we still have a home
			const pc:PC = model.worldModel.pc;
			const acl:ACL = ACLManager.instance.acl;
			if(!pc) return;
			const pc_home_tsid:String = !pc.pol_tsid && pc.home_info ? pc.home_info.interior_tsid : pc.pol_tsid;
			
			if(current_state == YOUR_HOUSE){
				//make sure the house data is up to snuff
				if(pc_home_tsid){
					showYourHouse();
				}
				else {
					//no more house!
					showBuddyKeys();
				}
			}
			else if(current_state == RECEIVED_KEYS){
				//show the received keys
				if(acl && acl.keys_received.length){
					showBuddyKeys();
				}
				else if(pc_home_tsid){
					//no more keys, but they still have a house!
					showYourHouse();
				}
			}
			
			//adjust the tabs
			setTabs();
			
			_jigger();
		}
		
		private function onCreateKeyClick(event:TSEvent):void {
			//animate things out and show the create ui
			setTitle('Create a new key');
			_setSubtitle('');
			current_state = CREATE_KEY;
			
			back_bt.visible = true;
			TSTweener.addTween([_scroller.body, tab_holder], {x:-_w, time:.3, onComplete:onCreateTweenComplete});
			
			//set the UI
			create_key_ui.x = _w;
			create_key_ui.show();
			_scroller.body.addChild(create_key_ui);
			
			//listen to Enter
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterDown, false, 0, true);
			
			//reset the buttons
			send_key_bt.visible = true;
			send_key_bt.disabled = true;
			done_bt.visible = false;
			back_keyring_bt.visible = false;
			tab_holder.visible = false;
			
			_jigger();
		}
		
		private function onCreateTweenComplete():void {
			your_house_ui.hide();
		}
		
		private function onCreateKeyChanged(event:TSEvent):void {
			//if we have data, that means we have a player, so enable the button
			send_key_bt.disabled = event.data == null;
			
			//focus the button so we can mash enter
			if(event.data){
				send_key_bt.focus();
			}
		}
		
		private function onCreateKeyClose(event:TSEvent):void {
			//we mashed undo in the create key thing, so we need to go back while the server does it's thing
			onBackClick(event);
		}
		
		private function onSendClick(event:TSEvent = null):void {
			if(send_key_bt.disabled || !create_key_ui.selected_pc_tsid) return;
			send_key_bt.disabled = true;
			
			//grant this player access
			ACLManager.instance.changeAccess(create_key_ui.selected_pc_tsid, true);
		}
		
		private function onBackClick(event:TSEvent):void {
			back_bt.visible = false;
			
			tab_holder.visible = true;
			
			TSTweener.addTween(_scroller.body, {x:0, time:.3, onComplete:onBackTweenComplete});
			TSTweener.addTween(tab_holder, {x:TAB_X, time:.3});
			
			//stop listening to enter
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterDown);
			
			const pc:PC = model.worldModel.pc;
			if(!pc) return;
			const pc_home_tsid:String = !pc.pol_tsid && pc.home_info ? pc.home_info.interior_tsid : pc.pol_tsid;
			
			//go back to where we were
			if(current_state == RECEIVED_KEYS){
				showBuddyKeys();
			}
			else if(pc_home_tsid){
				showYourHouse();
			}
			
			_jigger();
		}
		
		private function onBackTweenComplete():void {
			create_key_ui.hide();
			_jigger();
		}
		
		private function onEnterDown(event:KeyboardEvent):void {		
			if(send_key_bt.visible && !send_key_bt.disabled && send_key_bt.focused){
				//send key is enabled and in focus, do it!
				onSendClick();
			}
			else if(done_bt.visible && done_bt.focused){
				closeFromUserInput(event);
			}
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			//refresh whatever view we are in
			onKeyCountChange();
		}
		
		private function onTeleportationChange(event:TSEvent):void {
			//refresh whatever view we are in
			onKeyCountChange();
		}
		
		private function onStartMessageChange(event:TSEvent):void {
			//they want to view the keyring, show it to them!
			start();
		}
		
		private function onStartMessageClose(event:TSEvent):void {
			//they said they'll look later, so close the dialog
			end(true);
		}
		
		private function onBackKeyringOver(event:MouseEvent):void {
			//this will make sure the "Done" button doesn't have focus if it gets rolled over
			done_bt.blur();
		}
		
		private function onTabOver(event:MouseEvent):void {
			const bt:Button = event.currentTarget as Button;
			
			//if this is the button's section, don't show the hover state
			if(bt == your_house_bt && current_state == YOUR_HOUSE){
				your_house_bt.blur();
			}
			
			if(bt == received_keys_bt && current_state == RECEIVED_KEYS){
				received_keys_bt.blur();
			}
		}
		
		private function onTabOut(event:MouseEvent):void {
			const bt:Button = event.currentTarget as Button;
			
			//if we are NOT in that button's section, keep it in the hover state
			if(bt == your_house_bt && current_state != YOUR_HOUSE){
				your_house_bt.focus();
			}
			
			if(bt == received_keys_bt && current_state != RECEIVED_KEYS){
				received_keys_bt.focus();
			}
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			//how big the line needs to be in order to mask out the bottom button border
			const line_height:uint = 2;
			const active_bt:Button = current_state != RECEIVED_KEYS ? your_house_bt : received_keys_bt;
			var g:Graphics = tab_line.graphics;
			g.clear();
			g.beginFill(line_color);
			g.drawRect(0, 0, active_bt.width-line_height, line_height);
			tab_line.x = active_bt.x + line_height;
			tab_line.y = active_bt.height;
			
			//head
			_head_h = _head_min_h + (current_state != CREATE_KEY && !start_message_ui.visible ? TAB_H + line_height + 8 : 0);
			tab_holder.visible = current_state != CREATE_KEY && !start_message_ui.visible;
			tab_holder.y = int(_head_h - tab_holder.height + _divider_h);
			tab_masker.y = tab_holder.y - 1; //-1 allows the top border of the tabs to show
			
			//see if we need to hide any of the UI
			if(!tab_holder.visible && received_keys_ui.visible) received_keys_ui.hide();
			if(!tab_holder.visible && your_house_ui.visible) your_house_ui.hide();
			
			//body
			_body_sp.y = _head_h;
			switch(current_state){
				case YOUR_HOUSE:
					_body_h = your_house_ui.height;
					break;
				case CREATE_KEY:
					_body_h = create_key_ui.height;
					break;
				case RECEIVED_KEYS:
					_body_h = received_keys_ui.height;
					break;
			}
						
			_body_h += _divider_h*2;
			
			_foot_sp.y = _head_h + _body_h;
			_foot_sp.visible = current_state == CREATE_KEY;
			_foot_h = current_state != CREATE_KEY ? _foot_min_h : _foot_max_h;
			
			_h = _head_h + _body_h + _foot_h;
			
			_scroller.h = _body_h - _divider_h*2;
			_scroller.refreshAfterBodySizeChange();
			
			_draw();
		}
		
		override protected function closeFromUserInput(e:Event=null):void {
			//if they press esc/close button, make sure we don't show the message when they move again
			super.closeFromUserInput(e);
			is_showing_msg = false;
		}
		
		public function canTeleport(location_tsid:String):Boolean {
			//a way for the action links to know if they are able to teleport or not			
			if(TeleportationDialog.instance.cooldown_left > 0) return false;
			const location:Location = model.worldModel.getLocationByTsid(location_tsid);
			if(!location) return false;
			
			var can_teleport:Boolean;
			
			//if we are not already in the current location, let's see if they can teleport
			if(location.tsid != model.worldModel.location.tsid){
				const teleportation:PCTeleportation = model.worldModel.pc.teleportation;
				const current_energy:int = model.worldModel.pc.stats ? model.worldModel.pc.stats.energy.value : 0;
				if(teleportation && teleportation.skill_level){
					if(current_energy >= teleportation.energy_cost || teleportation.tokens_remaining){
						//say they can teleport. We'll give them choices in the confirmation dialog
						can_teleport = true;
					}
				}
			}
			
			return can_teleport;
		}
		
		/**********************
		* IMoveListener funcs
		**********************/
		public function moveLocationHasChanged():void {}
		public function moveLocationAssetsAreReady():void {}
		public function moveMoveStarted():void {}
		
		public function moveMoveEnded():void {
			//check to see if we were showing the start message
			if(is_showing_msg){
				startWithMessage(is_showing_msg_is_new_pol);
				is_showing_msg = false;
			}
		}
	}
}