package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;

	public class ContactElement extends TSSpriteWithModel implements ITipProvider
	{
		public static const TYPE_ACTIVE:String = 'active';
		public static const TYPE_ONLINE:String = 'online';
		public static const TYPE_OFFLINE:String = 'offline';
		public static const TYPE_GROUP:String = 'group';
		
		private static const MAX_LABEL_LENGTH:uint = 18;
		private static const ALERT_FLASH_COUNT:uint = 3;
		private static const ALERT_ANIMATION_TIME:Number = .3;
		
		private static var active_color:int = -1; //when the element has focus
		private static var inactive_color:int = -1; //when the element doesn't have focus
		private static var hover_color:int = -1;
		private static var offline_color:int = -1;
		private static var icon_color:int = -1; //circle icon beside a contact
		
		private var msg_counter:ContactListActivityCounter;
		
		private var alerter:Sprite;
		private var shadow_holder:Sprite = new Sprite();
		
		private var current_flash:uint;
		
		private var _type:String;
		private var _tip_text:String;
		
		public function ContactElement(type:String, pc_tsid:String, group_tsid:String = null) {
			//if the colors haven't been set yet, do that
			if(active_color == -1){
				const cssm:CSSManager = CSSManager.instance;
				
				active_color = cssm.getUintColorValueFromStyle('button_chat_active_label', 'color', 0x548500);
				inactive_color = cssm.getUintColorValueFromStyle('button_chat_active_label', 'colorDisabled', 0x548500);
				hover_color = cssm.getUintColorValueFromStyle('button_chat_active_label', 'colorHover', 0xd79035);
				offline_color = cssm.getUintColorValueFromStyle('button_chat_active_label', 'colorOffline', 0x999999);
				icon_color = cssm.getUintColorValueFromStyle('button_chat_active_label', 'colorIcon', 0x97be00);
			}
			
			_type = type;
			name = pc_tsid ? pc_tsid : group_tsid;
			
			if(type == TYPE_ACTIVE){
				buildActive();
				
				shadow_holder.filters = StaticFilters.copyFilterArrayFromObject({knockout:true}, StaticFilters.chat_left_shadow_innerA);
				shadow_holder.x = shadow_holder.y = 1;
				shadow_holder.mouseEnabled = false;
				addChild(shadow_holder);
			}
			else if((type == TYPE_ONLINE || type == TYPE_OFFLINE) && contact){
				buildPerson();
			}
			else if(type == TYPE_GROUP && group){
				buildGroup();
			}
			else {
				CONFIG::debugging {
					Console.warn('Contact element missing something. type: '+type+' contact: '+contact+' group: '+group);
				}
				return;
			}
			
			//register the tooltips
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false, 0, true);
		}
		
		private function onAddedToStage(event:Event):void {
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		private function onRemovedFromStage(event:Event):void {
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		private function buildPerson():void {
			var bt:Button = new Button({
				name: name,
				label: StringUtil.truncate(contact.label, MAX_LABEL_LENGTH),
				label_face: 'Arial',
				label_c: contact.online ? inactive_color : offline_color,
				label_bold: contact.online,
				label_hover_c: 0xd79035,
				text_align: 'left',
				graphic: contact.online ? createIcon() : null,
				graphic_hover: contact.online ? createIcon(true) : null,
				graphic_disabled_hover: contact.online ? createIcon(true) : null,
				graphic_placement: 'left',
				graphic_padd_r: 0,
				graphic_padd_t: 5,
				offset_x: contact.online ? 1 : 11,
				draw_alpha: 0,
				h: contact.online ? 18 : 15
			});
			bt.addEventListener(TSEvent.CHANGED, onPersonClick, false, 0, true);
			addChild(bt);
		}
				
		private function buildGroup():void {			
			var bt:Button = new Button({
				name: name,
				label: StringUtil.truncate(group.label, MAX_LABEL_LENGTH),
				label_face: 'Arial',
				label_c: inactive_color,
				label_bold: true,
				label_hover_c: 0xd79035,
				text_align: 'left',
				graphic: createIcon(),
				graphic_hover: createIcon(true),
				graphic_disabled_hover: createIcon(true),
				graphic_placement: 'left',
				graphic_padd_r: group.tsid != ChatArea.NAME_GLOBAL && group.tsid != ChatArea.NAME_TRADE ? 2 : 1,
				graphic_padd_l: 1,
				graphic_padd_t: 4,
				draw_alpha: 0,
				h: 18
			});
			bt.addEventListener(TSEvent.CHANGED, onGroupClick, false, 0, true);
			addChild(bt);
		}
		
		private function buildActive():void {
			//let's see what we are dealing with first
			var label:String;
			
			if(contact){
				label = StringUtil.truncate(contact.label, MAX_LABEL_LENGTH);
			}
			else if(group) {
				label = StringUtil.truncate(group.label, MAX_LABEL_LENGTH);
			}
			else if(name == ChatArea.NAME_PARTY){
				label = 'Party Chat';
			}
			else if(model.worldModel.getItemstackByTsid(name)){
				//maybe this is an itemstack talking
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(name);
				label = itemstack.label || itemstack.item.label;
			}
			else {
				//nothing else, throw the name in there
				label = name;
			}
			
			//create the person/group icon
			var bt:Button = new Button({
				name: name,
				label: label,
				graphic: createIcon(false),
				graphic_hover: createIcon(true),
				graphic_disabled: createIcon(false),
				graphic_disabled_hover: createIcon(true),
				graphic_placement: 'left',
				graphic_padd_r: contact ? 0 : 2,
				graphic_padd_l: contact ? 9 : 6,
				graphic_padd_t: contact ? 7 : 6,
				size: Button.SIZE_CHAT,
				type: Button.TYPE_CHAT_ACTIVE,
				use_hand_cursor_always: true
			});
			
			//if this is party chat, color the label differently
			if(name == ChatArea.NAME_PARTY){
				bt.label_color = CSSManager.instance.getUintColorValueFromStyle('contact_element_party', 'color', 0x390784);
				bt.label_color_disabled = CSSManager.instance.getUintColorValueFromStyle('contact_element_party', 'color', 0x390784);
			}
			bt.addEventListener(MouseEvent.CLICK, onActiveClick, false, 0, true);
			addChild(bt);
			
			//create the message counter
			msg_counter = new ContactListActivityCounter();
			msg_counter.x = -msg_counter.width + 22;
			msg_counter.y = int(bt.height/2 - msg_counter.height/2) + 1;
			msg_counter.addEventListener(MouseEvent.CLICK, onActiveClick, false, 0, true);
			addChild(msg_counter);
		}
		
		private function createIcon(is_hover:Boolean = false):Sprite {
			const sp:Sprite = new Sprite();
			const color:uint = is_hover ? hover_color : icon_color;
			const g:Graphics = sp.graphics;
			var DO:DisplayObject;
			
			if(contact){
				g.beginFill(color);
				g.drawCircle(2, 4, 4);
			}
			else {
				//help channel icon
				if(name == ChatArea.NAME_HELP) {
					DO = new AssetManager.instance.assets['contact_help'+(is_hover ? '_hover' : '')]();
				}
				//global chat icon
				else if(name == ChatArea.NAME_GLOBAL || name == ChatArea.NAME_UPDATE_FEED) {
					DO = new AssetManager.instance.assets['contact_global'+(is_hover ? '_hover' : '')]();
				}
				//party chat icon
				else if(name == ChatArea.NAME_PARTY){
					DO = new AssetManager.instance.assets['contact_'+(is_hover ? 'group_hover' : 'party')]();
				}
				//trade icon
				else if(name == ChatArea.NAME_TRADE){
					DO = new AssetManager.instance.assets['contact_trade'+(is_hover ? '_hover' : '')]();
				}
				//this is either an itemstack or a regular group
				else {
					const itemstack:Itemstack = model.worldModel.getItemstackByTsid(name);
					if(!itemstack){
						DO = new AssetManager.instance.assets['contact_group'+(is_hover ? '_hover' : '')]();
					}
					else {
						//draw a square
						const icon_padd:uint = 2;
						const icon_w:uint = 7;
						g.beginFill(color);
						g.drawRect(icon_padd, icon_padd, icon_w, icon_w);
						g.beginFill(0,0); //litte padding on the right
						g.drawRect(icon_w + icon_padd, icon_padd, icon_padd, 1);
					}
				}
				
				if(DO) sp.addChild(DO);
			}
			
			return sp;
		}
		
		public function setIcon(graphic:DisplayObject, is_hover:Boolean, is_disabled:Boolean):void {
			const bt:Button = getChildByName(name) as Button;
			if(bt){
				bt.setGraphic(graphic, is_hover, is_disabled);
			}
		}
		
		private function onPersonClick(event:TSEvent = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			if(name == model.worldModel.pc.tsid) return;
			TSFrontController.instance.startPcMenuFromList(name);
		}
		
		private function onGroupClick(event:TSEvent = null, is_active:Boolean = false):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			const group:Group = model.worldModel.getGroupByTsid(name, false);
			if(group){
				TSFrontController.instance.startGroupMenu(name, is_active);
			}
			else {
				//perma group, just open it up
				RightSideManager.instance.groupStart(name);
			}
		}
		
		private function onActiveClick(event:Event):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			var bt:Button = getChildByName(name) as Button;
			if(!bt) return;
			
			//clear the message throbber
			msg_counter.clear();
			
			if(bt.disabled){
				//let things that have been listening know that we are changing active contacts
				dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
				SoundMaster.instance.playSound('CLICK_SUCCESS');
			}
			else {
				//only want to know about groups that are user created
				const group:Group = model.worldModel.getGroupByTsid(name, false);
				
				//if this was already enabled, let's open the PC menu
				if(model.worldModel.getPCByTsid(name)){
					onPersonClick();
				} 
				else if(group){
					onGroupClick(null, true);
				} 
				else {
					//we're not opening a menu, so fire this event to give focus to the chat
					dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
				}
			}
		}
		
		/**
		 * When the contact element isn't active it'll increment it's msg_counter to show
		 * how many messages are new since you last viewed the chat
		 */		
		public function incrementCounter():void {
			if(!enabled) msg_counter.increment();
		}
		
		/*********************************************
		 * use this when you want the contact to flash
		 *********************************************/
		public function alert():void {
			if(!alerter) {
				alerter = new Sprite();
				addChildAt(alerter, 0);
				
				var g:Graphics = alerter.graphics;
				g.clear();
				g.beginFill(0xffffba);
				g.drawRoundRect(0, 0, _w, height, 8);
			}

			//tween it
			alerter.alpha = 0;
			TSTweener.removeTweens(alerter);
			current_flash = 0;
			alertFadeIn();
		}
		
		private function alertFadeIn():void {
			TSTweener.addTween(alerter, {alpha:1, time:ALERT_ANIMATION_TIME, onComplete:alertFadeOut});
		}
		
		private function alertFadeOut():void {
			TSTweener.addTween(alerter, {alpha:0, time:ALERT_ANIMATION_TIME, 
				onComplete:function():void {
					current_flash++;
					if(current_flash < ALERT_FLASH_COUNT) alertFadeIn();
				}
			});
		}
		
		/**
		 * change the state (false will put the button in the disabled state) 
		 * @param value
		 */
		public function set enabled(value:Boolean):void {
			var bt:Button = getChildByName(name) as Button;
			if(bt) bt.disabled = !value;
			
			//clear out the msg counter
			if(value) msg_counter.clear();
			
			refresh();
		}
		public function get enabled():Boolean {
			var bt:Button = getChildByName(name) as Button;
			if(bt) return !bt.disabled;
			return false;
		}
		
		public function get type():String { return _type; }
		
		public function get contact():PC { 
			return model.worldModel.getPCByTsid(name);
		}
		
		public function get group():Group { 
			return model.worldModel.getGroupByTsid(name);
		}
		
		public function set w(value:int):void {
			_w = value;
			
			//resize the button
			var bt:Button = getChildByName(name) as Button;
			if(bt) bt.w = value;
		}
		
		/**
		 * We need to set the name of the button that's doing all the work :D
		 * @param value
		 */		
		override public function set name(value:String):void {
			var bt:Button = getChildByName(name) as Button;
			if(bt) bt.name = value;
			
			super.name = value;
		}
		
		/**
		 * This will override any tooltip text that would normally be displayed 
		 * @param value
		 */		
		public function set tip_text(value:String):void {
			_tip_text = value;
		}
		
		public function refresh():void {
			const bt:Button = getChildByName(name) as Button;
			if(bt){
				if(contact){
					//change the label if need be
					bt.label = StringUtil.truncate(contact.label, MAX_LABEL_LENGTH);
					
					//not active
					if(bt.disabled){
						bt.label_color_disabled = contact.online ? inactive_color : offline_color;
					}
					//active contact
					else {
						bt.label_color = contact.online ? active_color : offline_color;
					}
					
					//color the icons
					if(bt.graphic) {
						bt.graphic.transform.colorTransform = contact.online ? new ColorTransform() : ColorUtil.getColorTransform(offline_color);
					}
					
					if(bt.graphic_disabled) {
						bt.graphic_disabled.transform.colorTransform = contact.online ? new ColorTransform() : ColorUtil.getColorTransform(offline_color);
					}
				}
				else if(group){
					bt.label = StringUtil.truncate(group.label, MAX_LABEL_LENGTH);
				}
				
				//draw the shadow
				if(type == TYPE_ACTIVE){
					const draw_w:uint = (RightSideManager.instance.right_view.contactListOpen() ? ContactList.MAX_WIDTH : ContactList.MIN_WIDTH) - 4;
					const g:Graphics = shadow_holder.graphics;
					g.clear();
					g.beginFill(0);
					g.drawRect(0, 0, draw_w, bt.height);
				}
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			var txt:String;
			var pt:Point = localToGlobal(new Point(0,0));
			
			if(_tip_text){
				//manual tip
				txt = _tip_text;
			}
			else if(contact){
				txt = '<span class="contact_element_name_tip">'+contact.label+(contact.level > 0 ? ' - Level ' + contact.level : '' )+'</span>'+
					  '<br>'+
					  '<span class="contact_element_location_tip">'+
					  (contact.online ? (contact.location && contact.location.label ? StringUtil.encodeHTMLUnsafeChars(contact.location.label) : 'online') : 'offline')+
					  '</span>';
				
				//push the point over if this is an offline contact
				if(type == TYPE_OFFLINE){
					pt.x += 11;
				}
			} 
			else if(group){
				txt = group.label;
			}
			else if(name == ChatArea.NAME_PARTY){
				txt = 'Party Chat';
			}
			else if(model.worldModel.getItemstackByTsid(name)){
				//check if it's an itemstack
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(name);
				txt = itemstack.label || itemstack.item.label;
			}
			else if(name){
				//throw the name on there
				txt = name;
			}
			
			if(!txt) return null;
			
			return {
				txt: txt,
				placement: { x:pt.x + 6 + (type != ContactElement.TYPE_ACTIVE ? 0 : 5), y:pt.y - 2 },
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
	}
}