package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ActionRequest;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatStartVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.ui.localtrade.LocalTradeUI;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;

	public class ChatArea extends TSSpriteWithModel implements ITipProvider
	{
		/*********************************************
		 * Setup the names for global and help chats
		 *********************************************/
		
		public static function get NAME_GLOBAL():String { return RightSideManager.instance.global_chat_tsid; }
		public static function get NAME_HELP():String { return RightSideManager.instance.live_help_tsid; }
		public static function get NAME_TRADE():String { return RightSideManager.instance.trade_chat_tsid; }
		
		public static const NAME_LOCAL:String = 'local';
		public static const NAME_PARTY:String = 'party';
		public static const NAME_UPDATE_FEED:String = 'update_feed';
		public static const MAX_ELEMENTS:uint = 150;
		public static const SCROLL_BAR_W:uint = 12;
		public static const ELEMENT_PADD:int = 0;
		
		protected static const SCROLL_X_OFFSET:int = -3;
		protected static const MAX_TITLE_LENGTH:uint = 21;
		protected static const MAX_ELEMENTS_NOT_AT_BOTTOM:uint = 600;
		protected static const SHOW_TIME_MIN_BUFFER:uint = 5; //how many minutes between timestamps
		protected static const SCROLL_GAP_TOP:uint = 3;  //how many px between the divider and the scroller
		protected static const SCROLL_GAP_BOTTOM:uint = 5;  //how many px between the bottom and the input
		protected static const DIVIDER_Y:uint = 17;
		protected static const MIN_HEIGHT:uint = 100;
		protected static const ACTIVITY_TIMER:uint = 4000; //how many ms to wait before being able to send the message again
		
		public var input_field:InputField = new InputField(true);
		
		protected const ELEMENTS:Vector.<ChatElement> = new Vector.<ChatElement>();
		protected var close_bt:Button;
		protected var duty_bt:Button;
		protected var scroller:TSScroller;
		protected var counter:ActivityCounter = new ActivityCounter();
		protected var dropdown:ChatDropdown = new ChatDropdown();
		protected var local_trade_ui:LocalTradeUI;
		
		protected var title_tf:TextField = new TextField();
		
		protected var element_holder:Sprite = new Sprite();
		private var tip_hit_area:Sprite = new Sprite();
		
		private var is_mouse_down:Boolean;
		private var _online:Boolean = true;
		
		protected var element_count:uint;
		private var element_time_count:uint;
		private var element_unix_ts:uint;
		private var last_activity_time:uint;
		
		private var _title:String;
		private var _raw_title:String;
		private var _tip_text:String;
		private var do_fade_shit_annoyingly:Boolean;
		
		public function ChatArea(unique_id:String){
			name = unique_id;
			tsid = unique_id;
			
			TFUtil.prepTF(title_tf);
			addChild(title_tf);
			
			input_field.name = unique_id;
			input_field.addEventListener(KeyBeacon.KEY_DOWN_, onKeyDown, false, 0, true);
			input_field.addEventListener(TSEvent.FOCUS_IN, onInputFocus, false, 0, true);
			input_field.addEventListener(TSEvent.FOCUS_OUT, onInputBlur, false, 0, true);
			addChild(input_field);
			
			scroller = new TSScroller({
				name: 'scroller',
				bar_wh: SCROLL_BAR_W,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 10,
				scrolltrack_always: false,
				maintain_scrolling_at_max_y: true,
				start_scrolling_at_max_y: true,
				use_auto_scroll: false,
				show_arrows: true,
				use_refresh_timer: false
			});
			addChild(scroller);
			scroller.body.addChild(element_holder);
			
			//when the window isn't focused, show the amount of new activity since it last had focus
			addChild(counter);
			
			//to bring up tooltips
			addChild(tip_hit_area);
			
			//if it's not the local chat, add a close button
			if(name != NAME_LOCAL){
				var close:DisplayObject = new AssetManager.instance.assets.chat_close()
				close_bt = new Button({
					name: 'close',
					graphic: close,
					draw_alpha: 0,
					w: close.width + 4,
					h: close.height + 4,
					y: 5
				});
				close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
				close_bt.alpha = (do_fade_shit_annoyingly) ? .4 : 1;
				addChild(close_bt);
			}
			
			//if this is live help, and the player is a guide, let's add a button for duties
			if(name == NAME_HELP && model.worldModel.pc && model.worldModel.pc.is_guide){
				duty_bt = new Button({
					name: 'duty',
					type: Button.TYPE_CANCEL,
					size: Button.SIZE_TINY,
					h: 19
				});
				duty_bt.y = int(-duty_bt.height/2) + 2;
				duty_bt.addEventListener(TSEvent.CHANGED, onDutyClick, false, 0, true);
				addChild(duty_bt);
				
				//set them to the current duty
				on_duty = model.worldModel.pc.guide_on_duty;
			}
			
			//chat options dropdown
			if(name != ChatArea.NAME_UPDATE_FEED){
				dropdown.x = -3;
				dropdown.y = -6;
				dropdown.init(tsid);
				addChild(dropdown);
			}
			
			//move the title
			title_tf.x = name != ChatArea.NAME_UPDATE_FEED ? ChatDropdown.BT_WIDTH - 1 : 0;
			
			//when the chat area is hovered over, bring up the scroller and close button
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			addEventListener(MouseEvent.CLICK, counter.clear, false, 0, true);
			
			//handle the tooltips
			TipDisplayManager.instance.registerTipTrigger(tip_hit_area);
		}
		
		public function addElement(pc_tsid:String, txt:String, chat_element_type:String = '', chat_element_name:String = '', element_alpha:Number = 1, unix_created_ts:uint = 0):void {
			if (!chat_element_type) chat_element_type = ChatElement.TYPE_CHAT;
			if (!chat_element_name) chat_element_name = pc_tsid;
			var element:ChatElement;
			
			//make sure the title of the chat area is right
			updateTitle();
			
			//check the previous activity and if it was the same, flash the text
			if(chat_element_type == ChatElement.TYPE_ACTIVITY && ELEMENTS.length){
				element = ELEMENTS[ELEMENTS.length-1];
				if(element && element.type == ChatElement.TYPE_ACTIVITY && element.text == txt){
					//we found a match, flash it and get out of there
					element.alert();
					
					//show the time on this element
					element.show_time = true;
					element_unix_ts = element.unix_timestamp;
					scroller.refreshAfterBodySizeChange();
					return;
				}
			}
			
			element = new ChatElement();
			element.init(tsid, scroller.w - SCROLL_BAR_W, pc_tsid, txt, chat_element_type, unix_created_ts);
			element.y = scroller.body_h + ELEMENT_PADD;
			element.name = chat_element_name;
			element.alpha = element_alpha;
			element_time_count++;
			
			//should we show the timestamp?
			if(name != NAME_UPDATE_FEED && element.unix_timestamp - element_unix_ts > SHOW_TIME_MIN_BUFFER*60){
				element.show_time = true;
				element_unix_ts = element.unix_timestamp;
				element_time_count = 0;
			}
			
			ELEMENTS.push(element);
			element_holder.addChild(element);
			
			//refresh the scroller
			scroller.refreshAfterBodySizeChange();
			
			//we might have to truncate some old ones
			maybeTruncate();
			
			//if we don't have focus on this chat, increment the counter
			if(!hasFocus() && chat_element_type == ChatElement.TYPE_CHAT && unix_created_ts == 0) counter.increment();
		}
		
		protected function updateTitle():void {
			//if the name of this chat is a group, pc or itemstack, update the title if it's changed
			var label:String;
			
			if(model.worldModel.getPCByTsid(name)){
				const pc:PC = model.worldModel.getPCByTsid(name);
				label = pc.label;
			}
			else if(model.worldModel.getGroupByTsid(name)){
				const group:Group = model.worldModel.getGroupByTsid(name);
				label = group.label;
			}
			else if(model.worldModel.getItemstackByTsid(name)){
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(name);
				label = itemstack.label || itemstack.item.label;
			}
			
			//set the title if it needs to change
			if(label && raw_title != label){
				setTitle(label);
			}
		}
		
		protected function maybeTruncate():void {
			var overflow_elements:Vector.<ChatElement>;
			
			element_count++;
			if(element_count >= MAX_ELEMENTS && scroller.scroll_y == scroller.max_scroll_y){				
				//kill all the overflow
				overflow_elements = ELEMENTS.splice(0, ELEMENTS.length - MAX_ELEMENTS);
				element_count = MAX_ELEMENTS;
			}
			//crazy amount, truncate that shit
			else if(element_count >= MAX_ELEMENTS_NOT_AT_BOTTOM){
				//kill all the overflow
				overflow_elements = ELEMENTS.splice(0, ELEMENTS.length - MAX_ELEMENTS_NOT_AT_BOTTOM);
				element_count = MAX_ELEMENTS_NOT_AT_BOTTOM;
			}
			
			if(overflow_elements){
				const total:int = overflow_elements.length;
				var i:int;
				var next_y:int;
				var element:ChatElement;
				
				
				for(i = 0; i < total; i++){
					//dispose of the elements
					disposeOfElement(overflow_elements[int(i)]);
				}
				
				//reposition
				for(i = 0; i < element_holder.numChildren; i++){
					element = element_holder.getChildAt(i) as ChatElement;
					element.y = next_y;
					next_y += element.height + ELEMENT_PADD;
				}
			}
			
			//refresh the scroller
			scroller.refreshAfterBodySizeChange();
		}
		
		protected function disposeOfElement(el:DisplayObject):void {
			if (el.parent) el.parent.removeChild(el);
			if (el is DisposableSprite) DisposableSprite(el).dispose();
		}
		
		public function focus():Boolean {
			if (input_field) {
				input_field.focusOnInput();
			}
			
			return false;
		}
		
		public function blur():Boolean {
			if (input_field) {
				input_field.blurInput();
			}
			
			return false;
		}
		
		public function hasFocus():Boolean {
			return (input_field && input_field.hasFocus());
		}
		
		public function getElementsByName(chat_element_name:String):Vector.<ChatElement> {
			const chat_elements:Vector.<ChatElement> = new Vector.<ChatElement>();
			var i:int;
			var total:int = element_holder.numChildren;
			var element:ChatElement;
			
			for(i; i < total; i++){
				element = element_holder.getChildAt(i) as ChatElement;
				if(element.name == chat_element_name){
					chat_elements.push(element);
				}
			}
			
			return chat_elements;
		}
		
		public function disableElement(chat_element_name:String, text_to_remove:String = ''):void {
			if(!chat_element_name) return;
			
			const replace_pat:RegExp = text_to_remove ? new RegExp(StringUtil.escapeRegEx(text_to_remove), 'g') : null;
			const elements:Vector.<ChatElement> = getElementsByName(chat_element_name);
			var element:ChatElement;
			var i:int;
			var total:int = elements.length;
			var new_txt:String;
						
			for(i; i < total; i++){
				element = elements[int(i)];
				element.enabled = false;
				element.addEventListener(TSEvent.COMPLETE, onElementDisabled, false, 0, true);
				
				//if we have any text to remove, make sure we do that
				if(text_to_remove){
					new_txt = element.text;
					new_txt = new_txt.replace(replace_pat, '');
					element.htmlText = new_txt;
				}
			}
		}
		
		public function removeElement(chat_element_name:String, only_disabled:Boolean = false):void {
			if(!chat_element_name) return;
			
			const elements:Vector.<ChatElement> = getElementsByName(chat_element_name);
			var element:ChatElement;
			var i:int;
			var total:int = elements.length;
			var next_y:int;
			
			//find all the elements with the name and delete them
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				if(only_disabled && !element.enabled){
					disposeOfElement(element);
				}
				else if(!only_disabled){
					disposeOfElement(element);
				}
			}
			
			//put em back where they need to go
			total = element_holder.numChildren;
			for(i = 0; i < total; i++){
				element = element_holder.getChildAt(i) as ChatElement;
				element.y = next_y;
				next_y += element.height + ELEMENT_PADD;
			}
			
			scroller.refreshAfterBodySizeChange();
		}
		
		public function updateElement(chat_element_name:String, new_txt:String, text_to_remove:String = ''):void {
			if(!chat_element_name || !new_txt) return;
			
			const replace_pat:RegExp = text_to_remove ? new RegExp(StringUtil.escapeRegEx(text_to_remove), 'g') : null;
			const elements:Vector.<ChatElement> = getElementsByName(chat_element_name);
			var element:ChatElement;
			var i:int;
			var total:int = elements.length;
			var next_y:int;
			
			//find the element and update the text
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				if(text_to_remove) new_txt = new_txt.replace(replace_pat, '');
				element.htmlText = new_txt;
			}
			
			//put em back where they need to go
			total = element_holder.numChildren;
			for(i = 0; i < total; i++){
				element = element_holder.getChildAt(i) as ChatElement;
				element.y = next_y;
				next_y += element.height + ELEMENT_PADD;
			}
			
			scroller.refreshAfterBodySizeChange();
		}
		
		public function clearElements():void {
			//just empty everything out
			element_count = 0;
			ELEMENTS.length = 0;
			SpriteUtil.clean(element_holder);
			scroller.refreshAfterBodySizeChange();
		}
		
		public function getElements(extra_details:Boolean=false):String {
			var txt:String = '';
			var i:int;
			var element:ChatElement;
			var pc:PC;
			var staff_str:String;
			
			for(i; i < element_holder.numChildren; i++){
				staff_str = '';
				element = element_holder.getChildAt(i) as ChatElement;
				
				//we need to ignore the timestamp type since it's only for visual
				if(element.type == ChatElement.TYPE_TIMESTAMP) continue;
				
				if (element.getsSlug()) {
					pc = (element.pc_tsid) ? model.worldModel.getPCByTsid(element.pc_tsid) : null;
					if (pc ) {
						if (pc.is_admin) {
							staff_str = '[staff] ';
						} else if (pc.is_guide) {
							staff_str = '[guide] ';
						}
					}
				}
				
				if (extra_details) {
					txt += element.simple_timestamp+' '
						+(element.pc_tsid && element.pc_tsid != WorldModel.NO_ONE ? element.pc_tsid+' ' : '')
						+element.raw_text+'\n\n';
				} else {
					txt += element.simple_timestamp+' '+element.raw_text+'\n\n';
				}
			}
			
			return txt;
		}
		
		public function copyElements():void {	
			System.setClipboard(getElements());
			RightSideManager.instance.chatUpdate(tsid, WorldModel.NO_ONE, 'Chat copied to clipboard', ChatElement.TYPE_ACTIVITY);
		}
		
		protected function draw():void {			
			title_tf.width = _w - title_tf.x;
			
			//create a divider
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xc8d6dc);
			g.drawRect(0, DIVIDER_Y, _w, 1);
			
			//move/set the input
			input_field.width = _w;
			input_field.y = int(_h - input_field.height);
			
			//position the scroller
			scroller.x = SCROLL_X_OFFSET;
			scroller.y = DIVIDER_Y + SCROLL_GAP_TOP + (local_trade_ui && local_trade_ui.visible ? local_trade_ui.height + SCROLL_GAP_TOP*3 : 0);
			scroller.w = _w + SCROLL_BAR_W/2 - SCROLL_X_OFFSET;
			scroller.h = int(_h - scroller.y - input_field.height - SCROLL_GAP_TOP - SCROLL_GAP_BOTTOM);
			
			//close button
			if(close_bt){
				close_bt.x = _w - close_bt.width + 1;
				close_bt.y = -4;
			}
			
			//on duty button
			if(duty_bt){
				duty_bt.x = (close_bt ? close_bt.x - 10 : _w) - duty_bt.width;
			}
			
			//the tooltip hit area
			g = tip_hit_area.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(dropdown.x + ChatDropdown.BT_WIDTH, title_tf.y + 2, _w - (dropdown.x + ChatDropdown.BT_WIDTH), int(title_tf.y + title_tf.height + 2));
			
			//move the counter if need be
			var rect:Rectangle = title_tf.getCharBoundaries(title_tf.text.length-2);
			if(rect){
				counter.x = int(rect.x + rect.width + 10 + title_tf.x);
				counter.y = rect.y + int(rect.height/2 - counter.height/2) + title_tf.y + 1;
			}
		}
		
		private function onKeyDown(event:KeyboardEvent):void {
			//it's going to be an enter key or an arrow key since that's all input_field dispatches
			if(event.keyCode == Keyboard.ENTER && !event.ctrlKey){
				//tell whoever is listening that we have text to send
				dispatchEvent(new TSEvent(TSEvent.MSG_SENT, this));
				
				//also clear the activity time
				last_activity_time = 0;
			}
			else if(event.keyCode == Keyboard.UP || event.keyCode == Keyboard.DOWN) {
				//get the history of this particular pane
				handleHistory(event);
			}
			else if(name == NAME_LOCAL){
				//this is not a slash command, so let the server know we are typing
				const current_time:uint = getTimer();
				if(!last_activity_time && event.keyCode != Keyboard.SLASH && current_time-last_activity_time > ACTIVITY_TIMER){
					last_activity_time = current_time;
					TSFrontController.instance.genericSend(new NetOutgoingLocalChatStartVO());
				}
			}
		}
		
		protected function onInputFocus(event:TSEvent):void {
			//input text got focus, if something is listening, they should know
			dispatchEvent(new TSEvent(TSEvent.FOCUS_IN, this));
		}
		
		protected function onInputBlur(event:TSEvent):void {
			//input text lost focus, if something is listening, they should know
			dispatchEvent(new TSEvent(TSEvent.FOCUS_OUT, this));
		}
		
		protected function onCloseClick(event:TSEvent):void {
			if(close_bt.disabled) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//surely someone is listening for when this is closed
			dispatchEvent(new TSEvent(TSEvent.CLOSE, this));
		}
		
		private function onDutyClick(event:TSEvent):void {
			if(!duty_bt || (duty_bt && duty_bt.disabled)) return;
			
			//send it off to the server
			RightSideManager.instance.guideStatusChange(duty_bt.type == Button.TYPE_CANCEL);
			duty_bt.disabled = true;
		}
		
		private function onRollOver(event:MouseEvent):void {
			if (!do_fade_shit_annoyingly) return;
			if(!enabled) return;
			TSTweener.removeTweens(scroller.bar);
			TSTweener.addTween(scroller.bar, {alpha:1, time:.3, transition:'linear'});
			if(close_bt){
				TSTweener.removeTweens(close_bt);
				TSTweener.addTween(close_bt, {alpha:1, time:.3, transition:'linear'});
			}
		}
		
		private function onRollOut(event:MouseEvent):void {
			if (!do_fade_shit_annoyingly) return;
			if(is_mouse_down) return;
			TSTweener.removeTweens(scroller.bar);
			TSTweener.addTween(scroller.bar, {alpha:0, time:.3, transition:'linear'});
			if(close_bt){
				TSTweener.removeTweens(close_bt);
				TSTweener.addTween(close_bt, {alpha:.4, time:.3, transition:'linear'});
			}
		}
		
		private function onMouseDown(event:MouseEvent):void {
			is_mouse_down = true;
			StageBeacon.mouse_up_sig.add(onMouseUp);
		}
		
		private function onMouseUp(event:MouseEvent):void {
			is_mouse_down = false;
			StageBeacon.mouse_up_sig.remove(onMouseUp);
			if(!hitTestPoint(event.stageX, event.stageY, true)) onRollOut(event);
		}
		
		private function onElementDisabled(event:TSEvent):void {
			var element:ChatElement = event.data;
			if(element) removeElement(element.name, true);
		}
		
		private function onLocalTradeChange(event:TSEvent):void {
			//put the scroller Y in the right place
			draw();
			scroller.refreshAfterBodySizeChange();
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		private function handleHistory(event:KeyboardEvent):void {	
			//if they have typed something that isn't in the history, then don't change the textfield
			var txt:String = input_field.text;
			if(txt != '' && !RightSideManager.instance.stringInHistory(name, txt)) return;
			
			//let's see if we are going forward or back!
			if(event.keyCode == Keyboard.UP){
				input_field.text = RightSideManager.instance.getHistory(name);
			}
			//must want to move forward
			else if(event.keyCode == Keyboard.DOWN) {
				input_field.text = RightSideManager.instance.getHistory(name, RightSideManager.DIRECTION_FORWARD);
			}
		}
		
		/**
		 * After you remove the chat area from the stage, you should call this to clean up any 
		 * stuff that's hanging around.
		 */		
		override public function dispose():void {
			StageBeacon.mouse_up_sig.remove(onMouseUp);
			
			removeEventListener(MouseEvent.ROLL_OVER, onRollOver);
			removeEventListener(MouseEvent.ROLL_OUT, onRollOut);
			removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			removeEventListener(MouseEvent.CLICK, counter.clear);
			
			if(duty_bt) duty_bt.removeEventListener(TSEvent.CHANGED, onDutyClick);
			if(close_bt) close_bt.removeEventListener(TSEvent.CHANGED, onCloseClick);
			
			input_field.removeEventListener(KeyBeacon.KEY_DOWN_, onKeyDown, false);
			input_field.removeEventListener(TSEvent.FOCUS_IN, onInputFocus);
			input_field.removeEventListener(TSEvent.FOCUS_OUT, onInputBlur);
			
			TipDisplayManager.instance.unRegisterTipTrigger(tip_hit_area);
			
			ELEMENTS.length = 0;
			
			super.dispose();
		}
		
		/**
		 * Compare pc_tsid, text, timestamp to figure out if this is a match 
		 * @param chat_element
		 * @return The match otherwise null
		 */		
		public function getChatElementMatch(chat_element:ChatElement):ChatElement {
			if(!chat_element) return null;
			
			var element:ChatElement;
			var i:int;
			var total:int = elements.length;
			
			//loop through the current elements
			for(i; i < total; i++){
				element = elements[int(i)];
				if(element.pc_tsid == chat_element.pc_tsid && element.text == chat_element.text && element.unix_timestamp == chat_element.unix_timestamp){
					return element;
				}
			}
			
			return null;
		}
		
		public function getTitle():String { return title_tf.text; }
		public function setTitle(value:String):void {
			_raw_title = value;
			_title = StringUtil.truncate(value, MAX_TITLE_LENGTH + (close_bt ? 0 : 5));
			var title_txt:String = (!_online ? '<span class="chat_area_title_offline">' : '')+_title+(!_online ? '</span>' : '');
			
			const vag_ok:Boolean = StringUtil.VagCanRender(_title);
			if(!vag_ok) title_txt = '<font face="Arial">'+title_txt+'</font>';
			title_tf.embedFonts = vag_ok;
			title_tf.y = vag_ok ? -9 : -8;
			
			title_tf.htmlText = '<p class="chat_area_title">'+title_txt+'</p>';
			draw();
		}
		
		public function get raw_title():String { return _raw_title; }
		
		public function get enabled():Boolean { return input_field.enabled; }
		public function set enabled(value:Boolean):void {
			input_field.enabled = value;
		}
		
		public function get online():Boolean { return _online; }
		public function set online(value:Boolean):void {
			_online = value;
			if (!_online && hasFocus()) {
				input_field.blurInput();
			}
			input_field.enabled = value;
			setTitle(_title);
		}
		
		public function set tooltip_text(value:String):void {
			_tip_text = value;
		}
		
		override public function get height():Number {
			return _h;
		}
		
		public function set on_duty(value:Boolean):void {
			//if a guide toggles the duty and the server said it was a success
			if(duty_bt){
				duty_bt.disabled = false;
				duty_bt.label = value ? 'On Duty' : 'Off Duty';
				duty_bt.type = value ? Button.TYPE_DEFAULT : Button.TYPE_CANCEL;
				duty_bt.label_y_offset = 1; //fixes the offset set in the CSS for the larger button size
				duty_bt.tip = {txt:'Click to go '+(value ? 'Off Duty' : 'On Duty'), pointer:WindowBorder.POINTER_BOTTOM_CENTER};
			}
		}
		
		public function getMinHeight():int {
			return MIN_HEIGHT + (localTradeVisible() ? local_trade_ui.y + local_trade_ui.height - 23 : 0);
		}
		
		public function setWidthHeight(w:int, h:int):void {
			_w = w;
			_h = Math.max(h, getMinHeight());
			draw();
		}
		
		public function clearCounter():void {
			counter.clear();
		}
		
		public function localTradeStart(request:ActionRequest = null):void {
			if(!local_trade_ui){
				local_trade_ui = new LocalTradeUI();
				local_trade_ui.y = DIVIDER_Y + 5;
				local_trade_ui.addEventListener(TSEvent.CHANGED, onLocalTradeChange, false, 0, true);
				addChildAt(local_trade_ui, getChildIndex(dropdown));
			}
			
			local_trade_ui.w = _w;
			local_trade_ui.show();
			if(request) localTradeEdit();
		}
		
		public function localTradeEnd():void {
			if(local_trade_ui) local_trade_ui.hide();
		}
		
		public function localTradeEdit():void {
			if(local_trade_ui) local_trade_ui.edit();
		}
		
		public function localTradeVisible():Boolean {
			if(local_trade_ui) return local_trade_ui.visible;
			
			return false;
		}
		
		/**
		 * This is a replacement method for hitTestObject because the local trade UI
		 * needs to be able to accept drag/drop as well! 
		 * @param object
		 * @return
		 */		
		public function isHittingChatArea(object:DisplayObject):Boolean {
			if(local_trade_ui && local_trade_ui.hitTestObject(object)){
				return false;
			}
			
			return hitTestObject(object);
		}
		
		public function get elements():Vector.<ChatElement> {
			var elements:Vector.<ChatElement> = new Vector.<ChatElement>();
			var i:int;
			var element:ChatElement;
			
			for(i; i < element_holder.numChildren; i++){
				element = element_holder.getChildAt(i) as ChatElement;
				if(element) elements.push(element);
			}
			
			return elements;
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !enabled) return null;
			
			//different tooltips for different types (TEMP!)
			if(name == NAME_LOCAL){
				_tip_text = RightSideManager.instance.localTooltip();
			}
			else if(name == NAME_PARTY){
				_tip_text = RightSideManager.instance.partyTooltip();
			}
			else if(_title.indexOf('...') >= 0){
				//figure out what the full name is
				if(model.worldModel.getGroupByTsid(name)){
					_tip_text = model.worldModel.getGroupByTsid(name).label;
				}
				else if(model.worldModel.getPCByTsid(name)){
					_tip_text = model.worldModel.getPCByTsid(name).label;
				}
				else {
					//this an itemstack talking away?
					const itemstack:Itemstack = model.worldModel.getItemstackByTsid(name);
					if(itemstack){
						_tip_text = itemstack.label || itemstack.item.label;
					}
				}
			}
			
			if(!_tip_text) return null;
			
			return {
				txt: _tip_text,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
	}
}