package com.tinyspeck.engine.view.ui.quest
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Rays;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class QuestConversationUI extends Sprite implements IFocusableComponent
	{
		private static const ROCK_WH:uint = 80;
		private static const BUBBLE_W:uint = 462;
		private static const BODY_PADD:uint = 20;
		
		private var close_bt:Button;
		private var current_quest:Quest;
		private var choices_buttons:Vector.<Button> = new Vector.<Button>();
		private var rays:Rays = new Rays(Rays.SCENE_THICK_SLOW, .3);
		
		private var rock_holder:Sprite = new Sprite();
		private var bg_holder:Sprite = new Sprite();
		private var button_holder:Sprite = new Sprite();
		private var pointer_holder:Sprite = new Sprite();
		private var title_line:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var current_chunks:Array;
		
		private var bg_color:uint = 0x0a181d;
		private var bg_alpha:Number = .9;
		private var current_index:int;
		private var choice_count:int;
		private var bt_index_to_focus:int;
		
		private var is_built:Boolean;
		private var has_focus:Boolean;
		
		public function QuestConversationUI(){
			registerSelfAsFocusableComponent();
		}
		
		private function buildBase():void {
			var g:Graphics;
			
			//the rays
			rays.x = -42;
			rays.y = -20;
			
			//the rock
			rock_holder.addChild(new ItemIconView('pet_rock', ROCK_WH));
			rock_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0xececec, alpha:.8, strength:20}, StaticFilters.white4px40AlphaGlowA);
			addChild(rock_holder);
			
			//little quest book thing
			const quest_book:DisplayObject = new AssetManager.instance.assets.familiar_dialog_quests_small();
			quest_book.x = 12;
			quest_book.y = 7;
			bg_holder.addChild(quest_book);
			
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="quest_conversation_title">New Quest</p>';
			title_tf.x = int(quest_book.x + quest_book.width + 10);
			title_tf.y = quest_book.y + int(quest_book.height/2 - title_tf.height/2);
			bg_holder.addChild(title_tf);
			
			g = title_line.graphics;
			g.beginFill(0xffffff, .4);
			g.drawRect(0, 0, BUBBLE_W, 1);
			title_line.y = int(quest_book.y + quest_book.height + 7);
			bg_holder.addChild(title_line);
			
			TFUtil.prepTF(body_tf);
			body_tf.x = BODY_PADD;
			body_tf.y = int(quest_book.y + quest_book.height + 20);
			body_tf.width = BUBBLE_W - BODY_PADD*2;
			bg_holder.addChild(body_tf);
			
			bg_holder.addChild(button_holder);
			
			bg_holder.x = ROCK_WH + 10;
			addChild(bg_holder);
			
			//build the left pointy thing
			const pointy_w:uint = 9;
			const pointy_h:uint = 16;
			g = pointer_holder.graphics;
			g.beginFill(bg_color, bg_alpha);
			g.lineTo(pointy_w, -pointy_h/2);
			g.lineTo(pointy_w, pointy_h/2);
			g.lineTo(0, 0);
			g.endFill();
			pointer_holder.x = -pointy_w;
			bg_holder.addChild(pointer_holder);
			
			//close button
			const bt_padd:uint = 7;
			close_bt = new Button({
				graphic: new AssetManager.instance.assets['close_x_small_gray'](),
				name: 'close',
				c: bg_color,
				high_c: bg_color,
				disabled_c: bg_color,
				shad_c: bg_color,
				inner_shad_c: 0xcccccc,
				h: 22,
				w: 22,
				disabled_graphic_alpha: .3,
				focus_shadow_distance: 1,
				graphic_padd_t: 0
			});
			close_bt.x = int(BUBBLE_W - close_bt.width - bt_padd);
			close_bt.y = bt_padd;
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			bg_holder.addChild(close_bt);
			
			is_built = true;
		}
		
		public function show(quest:Quest):void {
			if(!is_built) buildBase();
			
			//is this an emergency?
			if(rays.parent && !quest.is_emergency){
				removeChild(rays);
			}
			else if(!rays.parent && quest.is_emergency){
				addChildAt(rays, 0);
			}
			close_bt.disabled = quest.is_emergency;
			close_bt.visible = !quest.is_emergency;
			
			//take focus
			TSFrontController.instance.requestFocus(this);
			
			//we are active
			QuestManager.instance.setQuestConversationActive(quest.hashName, true);
			
			//Console.dir(quest.offer_conversation);
			current_quest = quest;
			
			//get the chunks out of the conversation
			current_chunks = ChoicesDialog.buildChunksA(quest.offer_conversation.txt);
			current_index = 0;
			
			//how many choices does that last option have?
			choice_count = 0;
			while(quest.offer_conversation.choices[choice_count+1]){
				choice_count++;
			}
			
			//show it
			setBodyAndButtons();
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			TSFrontController.instance.releaseFocus(this);
			dispatchEvent(new TSEvent(TSEvent.CLOSE, current_quest));
		}
		
		public function set hide_rays(value:Boolean):void {
			//this is used to force hide the rays even if the quest is_emergency
			if(rays.parent) removeChild(rays);
		}
		
		/**
		 * This will take care of showing the proper text and button(s) in the current chunk
		 * Each chunk has a "msg_str" and "button_label" param 
		 */
		private function setBodyAndButtons():void {
			if(!current_chunks || current_index >= current_chunks.length) return;
			
			//parse the body
			var msg_str:String = current_chunks[current_index].msg_str;
			msg_str = StringUtil.replaceHTMLTag(msg_str, 'b', 'span', 'choices_familiar_bold_replace');
			body_tf.htmlText = '<p class="quest_conversation">'+msg_str+'</p>';
			
			//parse the choices/buttons
			SpriteUtil.clean(button_holder, false);
						
			const bt_padd:uint = 8;
			const is_last_option:Boolean = current_index == current_chunks.length-1;
			var button_label:String = current_chunks[current_index].button_label;
			var bt:Button;
			var next_x:int;
			var i:int;
			var total:int = is_last_option ? choice_count : 1;
			var choice_ob:Object;
			
			for(i; i < total; i++){
				if(choices_buttons.length > i){
					bt = choices_buttons[int(i)];
				}
				else {
					bt = new Button({
						name: 'bt_'+i,
						size: Button.SIZE_CONVERSATION,
						type: Button.TYPE_DARK
					});
					bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
					bt.addEventListener(MouseEvent.ROLL_OVER, onButtonMouse, false, 0, true);
					bt.addEventListener(MouseEvent.ROLL_OUT, onButtonMouse, false, 0, true);
					choices_buttons.push(bt);
				}
				
				//reset
				bt.value = null;
				bt.tip = null;
				bt.disabled = false;
				bt.show_spinner = false;
				
				//if this is the last option, then the buttons can have more properties
				if(is_last_option){
					choice_ob = current_quest.offer_conversation.choices[i+1];
					button_label = choice_ob.txt;
					bt.value = choice_ob.value;
					bt.disabled = choice_ob.disabled;
					if(bt.disabled && 'disabled_reason' in choice_ob){
						bt.tip = {txt:choice_ob.disabled_reason, pointer:WindowBorder.POINTER_BOTTOM_CENTER};
					}
				}
				
				bt.label = button_label;
				bt.x = next_x;
				next_x += bt.width + bt_padd;
				button_holder.addChild(bt);
			}
			
			button_holder.x = int(BUBBLE_W/2 - button_holder.width/2);
			button_holder.y = int(body_tf.y + body_tf.height + 12);
			
			draw();
			
			//make the first selection the one we want
			bt_index_to_focus = 0;
			focusButton();
		}
		
		private function draw():void {
			const draw_h:int = button_holder.y + button_holder.height + 20;
			var g:Graphics = bg_holder.graphics;
			g.clear();
			g.beginFill(bg_color, bg_alpha);
			g.drawRoundRect(0, 0, BUBBLE_W, draw_h, 10);
			
			bg_holder.y = int(rock_holder.height/2 - draw_h/2);
			pointer_holder.y = int(draw_h/2);
		}
		
		private function handleButton(bt:Button):void {
			SoundMaster.instance.playSound(!bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(bt.disabled) return;
			if(!bt.value){
				//get the next chunk of the convo
				current_index++;
				setBodyAndButtons();
			}
			else {
				//tell the server we've accepted it
				bt.show_spinner = true;
				QuestManager.instance.acceptQuest(current_quest.hashName, bt.value);
				
				//disable all the buttons
				var i:int;
				var total:int = button_holder.numChildren;
				for(i; i < total; i++){
					(button_holder.getChildAt(i) as Button).disabled = true;
				}
			}
		}
		
		private function focusButton():void {
			//takes the current focus index and, well, focuses that button!
			var bt:Button = button_holder.numChildren > bt_index_to_focus ? button_holder.getChildAt(bt_index_to_focus) as Button : null;
			if(bt){
				bt.focus();
				
				//blur the rest of them
				const total:int = button_holder.numChildren;
				var i:int;
				
				for(i = 0; i < total; i++){
					bt = button_holder.getChildAt(i) as Button;
					if(i != bt_index_to_focus) bt.blur();
				}
				
				//play the clickie sound if we are changing buttons
				if(total > 1) SoundMaster.instance.playSound('CLICK_SUCCESS');
			}
		}
		
		private function onButtonMouse(event:MouseEvent):void {
			//if they hover or leave, make sure to focus/blur the others
			const is_over:Boolean = event.type == MouseEvent.ROLL_OVER;
			var bt:Button = event.currentTarget as Button;
			bt.focus();
			
			if(is_over){
				//set the index as the one we are hovered over
				bt_index_to_focus = button_holder.getChildIndex(bt);
				
				//blur the rest of them
				var i:int;
				var total:int = button_holder.numChildren;
				
				for(i = 0; i < total; i++){
					bt = button_holder.getChildAt(i) as Button;
					if(i != bt_index_to_focus) bt.blur();
				}
			}
		}
		
		private function onButtonClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			if(bt) handleButton(bt);
		}
		
		private function onCloseClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!close_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(close_bt.disabled) return;
			hide();
		}
		
		/*********************
		 * Overrides
		 ********************/
		override public function get width():Number {
			return bg_holder.x + bg_holder.width;
		}
		
		/***********************************************************
		 * Keyboard controls
		 **********************************************************/
		protected function startListeningToNavKeys():void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
		}
		
		protected function stopListeningToNavKeys():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
		}
		
		protected function rightArrowKeyHandler(e:KeyboardEvent):void {			
			//advance to the right or loop around
			if(bt_index_to_focus == button_holder.numChildren-1){
				bt_index_to_focus = 0;
			}
			else {
				bt_index_to_focus++;
			}
			
			focusButton();
		}
		
		protected function leftArrowKeyHandler(e:KeyboardEvent):void {
			//advance to the left or go to the end
			if(bt_index_to_focus == 0){
				bt_index_to_focus = button_holder.numChildren-1;
			}
			else {
				bt_index_to_focus--;
			}
			
			focusButton();
		}
		
		public function escKeyHandler(e:KeyboardEvent):void {
			SoundMaster.instance.playSound(!close_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(close_bt.disabled) return;
			hide();
		}
		
		protected function enterKeyHandler(e:KeyboardEvent):void {
			//figure out which button is focused and mash it
			var i:int;
			var total:int = button_holder.numChildren;
			var bt:Button;
			
			for(i; i < total; i++){
				bt = button_holder.getChildAt(i) as Button;
				if(bt.focused) handleButton(bt);
				break;
			}
		}
		
		/************************************************************
		 * IFocusableComponent Stuff
		 ***********************************************************/
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur')
			}
			has_focus = false;
			stopListeningToNavKeys();
		}
		
		public function registerSelfAsFocusableComponent():void {
			TSModelLocator.instance.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			TSModelLocator.instance.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus')
			}
			has_focus = true;
			startListeningToNavKeys();
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			//
		}
	}
}