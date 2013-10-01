package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.pack.FurnitureBagUI;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.InteractionMenu;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.chat.ChatElement;
	import com.tinyspeck.engine.view.ui.chat.InputField;
	import com.tinyspeck.engine.view.ui.making.MakingSlot;
	import com.tinyspeck.engine.view.ui.making.MakingSlotEmpty;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;

	public class TradeDialog extends BigDialog implements IFocusableComponent
	{
		public static const MAX_TRADE_SLOTS:uint = 6;
		
		private const NAME_TF_NAME:String = 'name';
		private const CONTENT_BODY_NAME:String = 'content_body';
		private const SLOT_NAME:String = 'slot';
		private const SLOT_WH:uint = 67;
		private const SLOT_PADDING:int = 12;
		private const SLOT_Y:int = 108;
		private const TITLE_X:int = 70;
		private const MAX_PER_ROW:uint = 3;
		private const LOCK_ICON_Y:int = 28;
		
		private var player_name:String;
		private var dragVO:DragVO = DragVO.vo;
		
		private var center_divider:Sprite;
		private var left_side:Sprite;
		private var right_side:Sprite;
		
		private var your_currency:CurrencyInput = new CurrencyInput();
		private var their_currency:CurrencyInput = new CurrencyInput();
		private var your_currency_amount:int;
		
		private var left_lock:Sprite = new Sprite();
		private var right_lock:Sprite = new Sprite();
		private var left_lock_icon:Sprite;
		private var right_lock_icon:Sprite;
		private var lock_color:uint = 0xf5ba56;
		private var lock_alpha:Number = .3;
		private var waiting_tf:TextField = new TextField();
		private var waiting_spinner:MovieClip;
		private var chat_input:InputField;
		private var chat_scroller:TSScroller;
		private var chat_line:Sprite = new Sprite();
		
		private var empty_slot:MakingSlotEmpty;
		private var left_slots:Sprite = new Sprite();
		private var right_slots:Sprite = new Sprite();
		
		private var content_body:Sprite = new Sprite();
		private var checkmark_icon:MovieClip;
		private var trade_icon:DisplayObject;
		private var complete_overlay:Sprite = new Sprite();
		private var complete_color:uint = 0x7ea200;
		private var complete_alpha:Number = .2;
		
		private var content_footer:Sprite = new Sprite();
		
		public var offer_bt:Button;
		private var edit_bt:Button;
		private var done_bt:Button;
		
		private var trade_complete:Boolean;
		private var auto_offer:Boolean;
		private var your_locked:Boolean;
		private var their_locked:Boolean;
		private var is_built:Boolean;
		
		public function TradeDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 574;
			_base_padd = 20;
			_head_min_h = 67;
			_body_min_h = 205;
			_foot_min_h = 190;
			_close_bt_padd_right = 10;
			_graphic_padd_side = 20;
			_draggable = true;
						
			_construct();
			
			//hide this thing
			visible = false;
		}
		
		private function buildBase():void {
			//set the left/right width
			var section_width:int = _body_sp.width/2;
			var css:CSSManager = CSSManager.instance;
			
			//common stuff
			center_divider = new Sprite();
			center_divider.x = section_width;
			
			//left and right
			left_side = new Sprite();
			right_side = new Sprite();
			right_side.x = center_divider.x + 1;
			
			_scroller.body.addChild(left_side);
			_scroller.body.addChild(right_side);
			_scroller.body.addChild(center_divider);
			
			addChild(_close_bt); //puts close button on the top
			
			//css stuff
			lock_color = css.getUintColorValueFromStyle('trade_lock_bg', 'color', lock_color);
			lock_alpha = css.getNumberValueFromStyle('trade_lock_bg', 'alpha', lock_alpha);
			complete_color = css.getUintColorValueFromStyle('trade_complete_bg', 'color', complete_color);
			complete_alpha = css.getNumberValueFromStyle('trade_complete_bg', 'alpha', complete_alpha);
			
			//left
			var g:Graphics = left_side.graphics;
			g.beginFill(0, 0);
			g.drawRect(0, 0, section_width, 5);
			
			//right
			g = right_side.graphics;
			g.beginFill(0, 0);
			g.drawRect(0, 0, section_width, 5);
			
			//create the name headers
			createTradeName('', 'left');
			createTradeName('', 'right');
			
			//currant inputs
			createCurrencyInput('left');
			createCurrencyInput('right');
			
			//create drop slots
			constructSlots();
			
			//create the locks
			//created here because they are never called but the full var name
			//ie. this[side+'_lock_icon']
			left_lock_icon = new Sprite();
			right_lock_icon = new Sprite();
			createLock('left');
			createLock('right');
			
			//buttons			
			constructButtons();
			
			//handle the sub-areas
			constructContent();
			
			//build out the chat area
			constructChat();
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			if(parent) end(false);
			
			visible = true;
			
			ChoicesDialog.instance.goAway();
			InteractionMenu.instance.goAway();
			
			//reset
			trade_complete = false;
			auto_offer = false;
			their_locked = false;
			your_locked = false;
			
			//get the player name we are trading with
			const pc:PC = model.worldModel.getPCByTsid(TradeManager.instance.player_tsid);
			player_name = pc.label;
						
			//icon
			_setGraphicContents(trade_icon);
			
			//set the title/sub-title
			_setTitle('<span class="trade_title">Trade with '+player_name+'</span>');
			_setSubtitle('<span class="trade_sub_title">Drag items from your pack to the left column. '+player_name+' will counter on the right.</span>');
			
			//set the name headers
			setTradeNameText("I'll trade:", 'left');
			setTradeNameText(player_name+' is offering:', 'right');
			
			//set the currency inputs
			your_currency.label_txt = 'Offer Currants';
			your_currency.max_value = TSModelLocator.instance.worldModel.pc.stats.currants;
			your_currency.value = 0;
			your_currency_amount = 0;
			your_currency.addEventListener(TSEvent.FOCUS_OUT, checkCurrency, false, 0, true);
			
			//are we offering any?
			your_currency.value = TradeManager.instance.currants;
			checkCurrency();
			
			//setup other player
			their_currency.label_txt = 'Currants';
			their_currency.is_input = false;
			their_currency.value = 0;
			
			//prepare the layout
			prepareBody(content_body);
			
			//hook up the buttons
			offer_bt.addEventListener(TSEvent.CHANGED, onOfferClick, false, 0, true);
			
			//set the footer
			waiting_tf.htmlText = '<p class="trade_waiting">Waiting for <span class="trade_waiting_name">'+player_name+'</span></p>';
			showChat();
			
			_setFootContents(content_footer);
			
			//listen to the pack
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete, false, 0, true);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, onPackDragStart, false, 0, true);
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete, false, 0, true);
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_STARTED, onPackDragStart, false, 0, true);
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			if(!is_built){
				visible = false;
				super.end(release);
				
				return;
			}
			
			//clean stuff up
			offer_bt.removeEventListener(TSEvent.CHANGED, onOfferClick);
			your_currency.removeEventListener(TSEvent.FOCUS_OUT, checkCurrency);
			done_bt.removeEventListener(TSEvent.CHANGED, closeFromUserInput);
			
			if(edit_bt.hasEventListener(TSEvent.CHANGED)){
				edit_bt.removeEventListener(TSEvent.CHANGED, onEditClick);
			}
			
			//this allows the focus to not be stolen on start
			your_currency.visible = false;
			their_currency.visible = false;
			
			//stop listening to the pack
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_STARTED, onPackDragStart);
			FurnitureBagUI.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			FurnitureBagUI.instance.removeEventListener(TSEvent.DRAG_STARTED, onPackDragStart);
			
			//give access to drags again
			TSFrontController.instance.tradeDialogEnded();
			
			//send the trade cancel message to the server if we are still trading
//			if(!trade_complete && TradeManager.instance.player_tsid){
//				TradeManager.instance.sendMessageToServer(MessageTypes.TRADE_CANCEL);
//				trade_complete = true;
//			}
			
			//send the trade cancel message to the server if we are still trading
			if(!trade_complete && TradeManager.instance.player_tsid){
				TradeManager.instance.clientCancel();
				trade_complete = true;
			}
			
			var trade_slot:MakingSlot;
			var i:int = 0;
			
			for(i; i < MAX_TRADE_SLOTS; i++){
				trade_slot = left_slots.getChildAt(i) as MakingSlot;
				trade_slot.removeEventListener(TSEvent.CLOSE, onSlotCloseClick);
				trade_slot.removeEventListener(TSEvent.CHANGED, onSlotChange);
				trade_slot.removeEventListener(TSEvent.QUANTITY_CHANGE, onSlotQuantityChange);
			}
			
			//clean out the chat area
			if(chat_scroller) SpriteUtil.clean(chat_scroller.body);
			
			visible = false;
			
			super.end(release);
		}
		
		public function lockSide(side:String):void {			
			//shows the lock icon and overlay (if other player)
			var lock:Sprite = this[side+'_lock'];
			var icon:Sprite = this[side+'_lock_icon'];
			
			if(!trade_complete) lock.visible = true;
			
			TSTweener.removeTweens(lock);
			lock.alpha = 1;
			
			TSTweener.removeTweens(icon);
			icon.y = LOCK_ICON_Y;

			//if it's our side, then we gotta hide some stuff and add the edit button
			if(side == 'left'){
				your_currency.is_input = false;
				your_currency.label_txt = 'Currants';
				empty_slot.visible = false;
				offer_bt.visible = false;
				your_locked = true;
				
				//handle the slots
				var trade_slot:MakingSlot;
				for(var i:int = 0; i < left_slots.numChildren; i++){
					trade_slot = left_slots.getChildAt(i) as MakingSlot;
					trade_slot.update(trade_slot.item_class, trade_slot.count, false, true);
				}
				
				if(!trade_complete){
					edit_bt.addEventListener(TSEvent.CHANGED, onEditClick, false, 0, true);
					waiting_tf.visible = true;
					waiting_spinner.visible = true;
					waiting_spinner.gotoAndPlay(2);
				}
			}else{
				//change the label to be confirm
				offer_bt.label = 'Confirm the trade';
				offer_bt.x = _w - offer_bt.width - _base_padd;
				their_locked = true;
			}
			
			//put it in the chat activity
			if(!trade_complete){
				const pc_tsid:String = side == 'right' ? TradeManager.instance.player_tsid : model.worldModel.pc.tsid;
				addChatElement(pc_tsid, 'confirmed the offer', ChatElement.TYPE_ACTIVITY);
			}
		}
		
		public function unlockSide(side:String, animate:Boolean = true):void {		
			offer_bt.label = 'Looks good. Make offer...';
			offer_bt.x = _w - offer_bt.width - _base_padd;
			offer_bt.disabled = false;
			
			var sp:Sprite = this[side+'_side'];
			var lock:Sprite = this[side+'_lock'];
			var icon:Sprite = this[side+'_lock_icon'];
			
			//different sides do different things when unlocked
			if(side == 'left'){
				your_currency.is_input = true;
				your_currency.label_txt = 'Offer Currants';
				empty_slot.visible = true;
				
				edit_bt.disabled = false;
				edit_bt.removeEventListener(TSEvent.CHANGED, onEditClick);
				
				offer_bt.visible = true;
				waiting_tf.visible = false;
				waiting_spinner.gotoAndStop(1);
				waiting_spinner.visible = false;
				
				//handle the slots
				var trade_slot:MakingSlot;
				for(var i:int = 0; i < left_slots.numChildren; i++){
					trade_slot = left_slots.getChildAt(i) as MakingSlot;
					trade_slot.update(trade_slot.item_class, trade_slot.count, true);
				}
				
				your_locked = false;
			}else{				
				their_locked = false;
			}
			
			//do a little shake before the overlay goes away
			if(animate){
				var end_x:int = sp.x;
				var lock_start_y:int = icon.y;
				var lock_end_y:int = icon.y + 100;
				
				sp.x -= 15;
				
				TSTweener.addTween(sp, {x:end_x, time:1, transition:'easeOutElastic'});
				TSTweener.addTween(lock, {alpha:0, time:1, delay:.5, onComplete:function():void { 
					lock.visible = false;
					lock.alpha = 1;
				}
				});
				TSTweener.addTween(icon, {y:lock_end_y, time:1.2, delay:.5, onComplete:function():void {
					icon.y = lock_start_y;
				}
				});
				
				//put it in the chat activity
				const pc_tsid:String = side == 'right' ? TradeManager.instance.player_tsid : model.worldModel.pc.tsid;
				addChatElement(pc_tsid, (side == 'right' ? 'is editing their offer' : 'are editing the offer'), ChatElement.TYPE_ACTIVITY);
			}else{
				lock.visible = false;
			}
		}
		
		public function addItem(side:String, class_tsid:String, amount:int, slot:int, item_label:String, tool_state:Object, furn_config:FurnitureConfig=null):void {
			//check if the right or left side. If it's our side (left) this is called only to add the line in chat
			if(side == 'right'){
				var trade_slot:MakingSlot = right_slots.getChildByName(SLOT_NAME+slot) as MakingSlot;
				var index:int = right_slots.numChildren;
				
				if(!trade_slot){
					//add
					trade_slot = new MakingSlot(SLOT_WH, SLOT_WH);
					trade_slot.name = SLOT_NAME+slot;
	
					right_slots.addChild(trade_slot);
				}
				
				index = right_slots.getChildIndex(trade_slot);
				trade_slot.x = (index % MAX_PER_ROW) * (SLOT_WH + SLOT_PADDING);
				trade_slot.y = (index >= MAX_PER_ROW) ? SLOT_WH + SLOT_PADDING : 0;
				
				trade_slot.update(class_tsid, amount, false, true, furn_config);
				trade_slot.item_label = item_label;
				trade_slot.close_button.visible = false;
				
				if(tool_state){
					//is the item has a tool state, show it on the slot
					trade_slot.update_tool(tool_state.points_capacity, tool_state.points_remaining, tool_state.is_broken);
				}
				
				_jigger();
				
				if(your_locked){
					//if you have a lock and they changed items, send an unlock request to the server
					onEditClick();
				}
			}
			
			//put it in the chat activity
			const item_link:String = RightSideManager.instance.createClientLink('', '', TSLinkedTextField.LINK_ITEM+'|'+class_tsid+'|'+item_label);
			const pc_tsid:String = side == 'right' ? TradeManager.instance.player_tsid : model.worldModel.pc.tsid;
			addChatElement(pc_tsid, 'added '+StringUtil.formatNumberWithCommas(amount)+'&nbsp;'+item_link, ChatElement.TYPE_ACTIVITY);
		}
		
		public function changeItem(side:String, class_tsid:String, amount:int, slot:int, item_label:String):void {
			//when the other player adds an item, let's handle that
			var old_amount:int = -1;
			var trade_slot:MakingSlot = this[side+'_slots'].getChildByName(SLOT_NAME+slot) as MakingSlot;
			
			if(side == 'right'){
				if(trade_slot){
					old_amount = trade_slot.count;
					trade_slot.update(class_tsid, amount, false, true);
					trade_slot.item_label = item_label;
				}
				else{
					CONFIG::debugging {
						Console.warn('Trying to change right slot '+slot+' and failed');
					}
				}
				
				_jigger();
				
				if(your_locked){
					//if you have a lock and they changed items, send an unlock request to the server
					onEditClick();
				}
			}
			else {
				//because the slot is updated on the fly, let's take what the itemstack count is to determine what it *used* to be
				old_amount = amount;
				
				if(trade_slot){
					amount = trade_slot.count;
				}
				else {
					CONFIG::debugging {
						Console.warn('Trying to change left slot '+slot+' and failed');
					}
				}
			}
			
			//put it in the chat activity
			const item_link:String = RightSideManager.instance.createClientLink('', '', TSLinkedTextField.LINK_ITEM+'|'+class_tsid+'|'+item_label);
			const pc_tsid:String = side == 'right' ? TradeManager.instance.player_tsid : model.worldModel.pc.tsid;
			addChatElement(pc_tsid, 'changed the amount from '+StringUtil.formatNumberWithCommas(old_amount)+
								    ' to '+StringUtil.formatNumberWithCommas(amount)+'&nbsp;'+item_link, 
								    ChatElement.TYPE_ACTIVITY);
		}
		
		public function removeItem(side:String, class_tsid:String, amount:int, slot:int, item_label:String):void {
			//reset it
			var trade_slot:MakingSlot = this[side+'_slots'].getChildByName(SLOT_NAME+slot) as MakingSlot;
			if(trade_slot) trade_slot.update('', 0, false);
			
			//the other player removed an item, so remove it and shuffle
			if(side == 'right'){				
				var i:int;
				
				if(trade_slot){
					right_slots.removeChild(trade_slot);
					
					for(i = 0; i < right_slots.numChildren; i++){
						trade_slot = right_slots.getChildAt(i) as MakingSlot;
						trade_slot.x = (i % MAX_PER_ROW) * (SLOT_WH + SLOT_PADDING);
						trade_slot.y = (i >= MAX_PER_ROW) ? SLOT_WH + SLOT_PADDING : 0;
						trade_slot.name = SLOT_NAME+i;
					}
				}
				else {
					CONFIG::debugging {
						Console.warn('Tried to remove slot '+slot+' and failed!');
					}
				}
				
				_jigger();
				
				if(your_locked){
					//if you have a lock and they changed items, send an unlock request to the server
					onEditClick();
				}
			}
			
			//put it in the chat activity
			const item_link:String = RightSideManager.instance.createClientLink('', '', TSLinkedTextField.LINK_ITEM+'|'+class_tsid+'|'+item_label);
			const pc_tsid:String = side == 'right' ? TradeManager.instance.player_tsid : model.worldModel.pc.tsid;
			addChatElement(pc_tsid, 'removed '+StringUtil.formatNumberWithCommas(amount)+'&nbsp;'+item_link, ChatElement.TYPE_ACTIVITY);
		}
		
		public function currants(side:String, amount:int):void {
			if(side != 'right' && amount > -1){
				//this means we had an error when sending our currant count to the server (probably too high)
				your_currency.value = model.worldModel.pc.stats.currants;
				offer_bt.disabled = false;
				return;
			}
			
			//put it in the chat activity
			const old_amount:int = side == 'right' ? their_currency.value : your_currency_amount;
			const new_amount:int = side == 'right' ? amount : your_currency.value;
			const pc_tsid:String = side == 'right' ? TradeManager.instance.player_tsid : model.worldModel.pc.tsid;
			
			var currant_str:String = old_amount == 0 
									? 'added '+StringUtil.formatNumberWithCommas(new_amount) 
									: 'changed the amount from '+StringUtil.formatNumberWithCommas(old_amount)+' to '+StringUtil.formatNumberWithCommas(new_amount);
			if(new_amount == 0) currant_str = 'removed all of the';
			currant_str += new_amount != 1 ? '&nbsp;currants' : '&nbsp;currant';
			
			addChatElement(pc_tsid, currant_str, ChatElement.TYPE_ACTIVITY);
			
			if(side == 'right'){
				their_currency.value = amount;
				
				if(your_locked){
					//if you have a lock and they changed money, send an unlock request to the server
					onEditClick();
				}
			}else{				
				your_currency_amount = your_currency.value;
				
				if(auto_offer && !their_locked && !your_locked){
					//if we pressed the offer button, but the server checked first, let's send the trade
					onOfferClick();
				}
			}
		}
		
		public function complete():void {
			//complete trade
			left_lock.visible = false;
			right_lock.visible = false;
			waiting_tf.visible = false;
			
			if(waiting_spinner){
				waiting_spinner.gotoAndStop(1);
				waiting_spinner.visible = false;
			}
			
			done_bt.visible = true;
			trade_complete = true;
			complete_overlay.visible = true;
			
			_setTitle('<span class="trade_title">The deal was sealed!</span>');
			_setSubtitle('<span class="trade_sub_title">You and '+player_name+' made the trade.</span>');
			_setGraphicContents(null);
			
			//set the name headers
			setTradeNameText("I traded:", 'left');
			setTradeNameText(player_name+' traded:', 'right');
			
			//play a sound
			SoundMaster.instance.playSound('TRADE_COMPLETED');
			
			//reusable stuff
			var trade_slot:MakingSlot;
			var i:int;
			var your_items:String = '';
			var their_items:String = '';
			var your_currants:String = '';
			var their_currants:String = '';
			var item:Item;
			var item_link:String;
			var item_label:String;
			
			//convert the slots on the left side to not have quantity pickers
			for(i; i < left_slots.numChildren; i++){
				trade_slot = left_slots.getChildAt(i) as MakingSlot;
				trade_slot.x = (i % MAX_PER_ROW) * (SLOT_WH + SLOT_PADDING);
				trade_slot.y = (i >= MAX_PER_ROW && trade_slot.visible) ? SLOT_WH + SLOT_PADDING : 0;
				
				//if we have an item here, let's add it to the stuff we traded away
				if(trade_slot.visible) {
					item = model.worldModel.getItemByTsid(trade_slot.item_class);
					item_label = trade_slot.count != 1 ? item.label_plural : item.label;
					item_link = RightSideManager.instance.createClientLink('', '', TSLinkedTextField.LINK_ITEM+'|'+trade_slot.item_class+'|'+item_label);
					your_items += trade_slot.count+'&nbsp;'+item_link+', ';
				}
			}

			for(i = 0; i < right_slots.numChildren; i++){
				trade_slot = right_slots.getChildAt(i) as MakingSlot;
				
				//add it to the things the other player traded
				if(trade_slot.visible){
					item_link = RightSideManager.instance.createClientLink('', '', TSLinkedTextField.LINK_ITEM+'|'+trade_slot.item_class+'|'+trade_slot.item_label);
					their_items += trade_slot.count+'&nbsp;'+item_link+', ';
				}
			}
						
			//move slots up if no money
			if(your_currency.value == 0){
				your_currency.visible = false;
				left_slots.y = your_currency.y;
			}
			else {
				your_currants = StringUtil.formatNumberWithCommas(your_currency.value)+'&nbsp;'+(your_currency.value != 1 ? 'currants' : 'currant');
			}
			
			if(their_currency.value == 0){
				their_currency.visible = false;
				right_slots.y = their_currency.y;
			}
			else {
				their_currants = StringUtil.formatNumberWithCommas(their_currency.value)+'&nbsp;'+(their_currency.value != 1 ? 'currants' : 'currant');
			}
			
			//clean up the last comma
			if(your_items != '' && your_currants == '') your_items = your_items.substr(0, -2);
			if(their_items != '' && their_currants == '') their_items = their_items.substr(0, -2);
			
			//animate the checkmark
			checkmark_icon.visible = true;
			checkmark_icon.x = int(_w/2 - checkmark_icon.width/2);
			checkmark_icon.y = _head_h + _outer_border_w + _border_w + int(_body_h/2 - checkmark_icon.height/2);
			checkmark_icon.scaleX = checkmark_icon.scaleY = 0;
			
			TSTweener.addTween(checkmark_icon, {scaleX:12, scaleY:12, time:.3, onUpdate:function():void {
				checkmark_icon.x = int(_w/2 - checkmark_icon.width/2);
				checkmark_icon.y = _head_h + _outer_border_w + _border_w + int(_body_h/2 - checkmark_icon.height/2);
			}});
			TSTweener.addTween(checkmark_icon, {scaleX:1, scaleY:1, x:_head_graphic.x, y:_head_graphic.y + 3, time:.5, delay:.8});
			
			//put it in the chat activity
			const pc:PC = model.worldModel.getPCByTsid(TradeManager.instance.player_tsid);
			
			if(pc){
				var complete_txt:String = 'You traded '+pc.label+' ';
				complete_txt += (your_items != '' || your_currants != '' ? your_items + your_currants : 'nothing at all');
				complete_txt += ' for ';
				complete_txt += (their_items != '' || their_currants != '' ? their_items + their_currants : 'nothing at all');
				
				RightSideManager.instance.chatUpdate(pc.tsid, model.worldModel.pc.tsid, complete_txt, ChatElement.TYPE_ACTIVITY);
			}
		}
		
		override protected function _jigger():void {						
			super._jigger();
			
			const padd:int = _base_padd - 3;
			
			//see how much to move things
			const has_vag:Boolean = _title_tf.htmlText.indexOf('_no_embed') == -1;			
			_title_tf.y = _base_padd - (has_vag ? 5 : 8);
			_title_tf.x = TITLE_X;
			_subtitle_tf.x = TITLE_X;
			_subtitle_tf.y = int(_title_tf.y + _title_tf.height + (has_vag ? 1 : -4));
			_subtitle_tf.width = _w - TITLE_X - _close_bt_padd_right*2;

			_close_bt.y = _close_bt_padd_right;
			done_bt.y = _foot_min_h - done_bt.height - padd;
			offer_bt.y = done_bt.y;
			
			//waiting
			waiting_tf.y = int(done_bt.y + (done_bt.height/2 - waiting_tf.height/2));
			if(waiting_spinner) waiting_spinner.y = waiting_tf.y - 3;
			
			//handle the chat area
			if(chat_scroller){
				chat_input.y = int(offer_bt.y - padd*2 - chat_input.height);
				
				chat_scroller.y = 10;
				chat_scroller.h = chat_input.y - chat_scroller.y - 6;
				
				chat_line.y = int(chat_input.y + chat_input.height + padd);
			}
			
			_body_sp.y = _head_h;
			_body_h = Math.max(left_slots.y + left_slots.height, right_slots.y + right_slots.height, _body_min_h);
			
			_foot_sp.y = _body_sp.y + _body_h;
			
			_h = _head_h + _body_h + _foot_h;
						
			_draw();
		}
		
		override protected function _draw():void {
			super._draw();
			
			//center
			var g:Graphics = center_divider.graphics;
			g.clear();
			g.beginFill(_body_border_c);
			g.drawRect(0, 0, 1, _body_h - 2);
			
			//complete trade overlay
			g = complete_overlay.graphics;
			g.clear();
			g.beginFill(complete_color, complete_alpha);
			g.drawRect(_border_w, 0, _w - _border_w*2, _body_h);
			
			//lock overlays
			g = left_lock.graphics;
			g.clear();
			g.beginFill(lock_color, lock_alpha);
			g.drawRect(0, 0, int(_w/2) - _border_w, _body_h);
			left_lock.x = _border_w;
			
			g = right_lock.graphics;
			g.clear();
			g.beginFill(lock_color, lock_alpha);
			g.drawRect(0, 0, int(_w/2) - _border_w - center_divider.width, _body_h);
			right_lock.x = center_divider.x + _border_w + center_divider.width;
			
			left_lock.y = right_lock.y = complete_overlay.y = _head_h;
			
			//edit button
			edit_bt.x = int(left_lock.width - edit_bt.width - 13);
			edit_bt.y = int(_body_h - edit_bt.height - 13);
		}
		
		private function createTradeName(name:String, side:String):void {
			//create the header name with the little line under it
			var margin:int = 19;
			var sp:Sprite = this[side+'_side'];
			var tf:TextField = new TextField();
			TFUtil.prepTF(tf, false);
			tf.name = NAME_TF_NAME;
			tf.x = tf.y = margin;
			tf.embedFonts = false;
			sp.addChild(tf);
			
			var div:Sprite = new Sprite();
			var g:Graphics = div.graphics;
			g.beginFill(_body_border_c);
			g.drawRect(margin, 40, sp.width - margin*2, 1);
			sp.addChild(div);
		}
		
		private function setTradeNameText(text:String, side:String):void {
			const name_tf:TextField = this[side+'_side'].getChildByName(NAME_TF_NAME) as TextField;
			if(name_tf) name_tf.htmlText = '<p class="trade_name">'+text+'</p>';
		}
		
		private function createCurrencyInput(side:String):void {
			var cur_input:CurrencyInput = (side == 'left') ? your_currency : their_currency;
			cur_input.x = 25;
			cur_input.y = 50;
			
			this[side+'_side'].addChild(cur_input);
		}
		
		private function createLock(side:String):void {
			//create the lock overlays
			var sp:Sprite = this[side+'_lock'];
			var lock_icon_holder:Sprite = this[side+'_lock_icon'];
			var lock_icon:DisplayObject = new AssetManager.instance.assets.trade_lock();
			lock_icon_holder.x = 205;
			lock_icon_holder.y = LOCK_ICON_Y;
			lock_icon_holder.addChild(lock_icon);
			
			sp.addChild(lock_icon_holder);
			sp.visible = false;
			sp.mouseEnabled = false;
			addChild(sp);
		}
		
		private function checkCurrency(event:TSEvent = null):void {
			if(your_currency.value != your_currency_amount){				
				//send it off to the server
				TradeManager.instance.clientCurrants(your_currency.value);
				
				//disable the button
				offer_bt.disabled = true;
			}
		}
		
		private function onOfferClick(event:TSEvent = null):void {
			// if the button is disabled then we were checking currants
			// at the same time as the button was pressed
			if(event && Button(event.data).disabled){
				auto_offer = true;
				return;
			} 
			
			//send the trade accept message to the server
			TradeManager.instance.clientAccept();
			
			offer_bt.disabled = true;
			auto_offer = false;
		}
		
		private function onEditClick(event:TSEvent = null):void {
			//send the server the request to unlock
			TradeManager.instance.clientUnlock();
			
			edit_bt.disabled = true;
			auto_offer = false;
		}		
		
		private function onSlotCloseClick(event:TSEvent):void {
			//just run the add slot thing again
			var trade_slot:MakingSlot = event.data as MakingSlot;
			var slots_visible:int;
			var i:int;
			
			//disable the offer button
			offer_bt.disabled = true;
			
			//tell the server we have removed an item
			TradeManager.instance.clientRemoveItem(trade_slot.itemstack_tsid, trade_slot.count);
			
			trade_slot.visible = false;
			trade_slot.itemstack_tsid = null;
			
			for(i; i < MAX_TRADE_SLOTS; i++){
				if(left_slots.getChildAt(i).visible) {
					slots_visible++;
				}
			}
			
			//if this was the last visible slot
			if(int(trade_slot.name.substr(SLOT_NAME.length)) == slots_visible){
				afterSlotChange(null);
			}
			
			
		}
		
		private function onSlotQuantityChange(event:TSEvent):void {
			var trade_slot:MakingSlot = event.data as MakingSlot;
			
			if(trade_slot){			
				TradeManager.instance.clientChangeItem(trade_slot.itemstack_tsid, trade_slot.count);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Can not find trade slot on quantity change');
				}
			}
		}
		
		private function onSlotChange(event:TSEvent):void {
			//anytime a change happens, disable the offer button
			offer_bt.disabled = true;
		}
		
		public function onPcItemstackAdds(tsids:Array):void {
			if(!parent && !visible) return;
						
			var i:int;
			var trade_slot:MakingSlot;
			var tsid:String;
			var itemstack:Itemstack;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if(itemstack.container_tsid != model.worldModel.pc.escrow_tsid){
					CONFIG::debugging {
						Console.warn('ITEM WTF NO ADD', itemstack.container_tsid, model.worldModel.pc.escrow_tsid);
					}
					continue;
				}
				
				//re-enable the offer button
				offer_bt.disabled = false;
				
				//add it to where it needs to go
				addItemToAvailableSlot(itemstack);
			}
		}
		
		public function onPcItemstackUpdates(tsids:Array):void {
			if(!parent && !visible) return;
						
			var i:int;
			var j:int;
			var trade_slot:MakingSlot;
			var tsid:String;
			var itemstack:Itemstack;
			var item_class:String;
			var updated_slots:Vector.<MakingSlot> = new Vector.<MakingSlot>();
			
			//if we have removed something from the trade window, move the rest to the left by 1
			for(i = 0; i < MAX_TRADE_SLOTS; i++){
				trade_slot = left_slots.getChildAt(i) as MakingSlot;
				if(trade_slot.itemstack_tsid){
					itemstack = model.worldModel.getItemstackByTsid(trade_slot.itemstack_tsid);
					if(itemstack.container_tsid != model.worldModel.pc.escrow_tsid) {						
						//remove all the ones after the getting rid slot. They will be coming in this update message
						for(j = i; j < MAX_TRADE_SLOTS; j++){
							trade_slot = left_slots.getChildAt(j) as MakingSlot;
							trade_slot.update('', 0, true);
						}
					}					
				}
			}
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if(itemstack.container_tsid != model.worldModel.pc.escrow_tsid){
					continue;
				}
				
				//update the slot
				trade_slot = getSlot(itemstack.slot);
				
				if(!trade_slot) {
					CONFIG::debugging {
						Console.warn('No trade slot on update, that is NOT good!');
					}
					return;
				}
								
				item_class = itemstack.class_tsid;
				trade_slot.itemstack_tsid = tsid;
				trade_slot.update(item_class, itemstack.count, true, false, itemstack.itemstack_state.furn_config);
				
				//check for tool updates
				if(itemstack.tool_state){
					trade_slot.update_tool(itemstack.tool_state.points_capacity, 
										   itemstack.tool_state.points_remaining, 
										   itemstack.tool_state.is_broken);
				}
				
				updated_slots.push(trade_slot);
				
				//close the bag
				PackDisplayManager.instance.closeContainer(tsid);
			}
			
			//if we've got slots to update, then update them!
			if(updated_slots.length > 0) afterSlotChange(updated_slots, false, false);
		}
		
		public function onPcItemstackDels(tsids:Array):void {
			if(!parent && !visible || trade_complete) return; //if trade done, don't remove from pack for presentation reasons
			
			
			/* Do we need to even do this?
			var i:int;
			var trade_slot:MakingSlot;
			var tsid:String;
			var itemstack:Itemstack;
			var item_class:String;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if(itemstack.container_tsid != model.worldModel.pc.escrow_tsid){
					Console.warn('ITEM WTF NO DELETE', itemstack.container_tsid, model.worldModel.pc.escrow_tsid);
					continue;
				}
				
				//re-enable the offer button
				offer_bt.disabled = false;
				
				//delete it from the trade window
				trade_slot = getSlot(itemstack.slot);
				
				//trade_slot = left_slots.getChildByName(SLOT_NAME+itemstack.slot) as MakingSlot;
				if(!trade_slot) return;
				
				trade_slot.update('', 0, false);
				afterSlotChange(null);
			}
			*/
		}
		
		private function onPackDragStart(event:TSEvent):void {
			if(your_locked) return;
			
			// we don't want no stinking bags with stuff in them
			//if(dragVO.dragged_itemstack.slots) return;
			
			StageBeacon.mouse_move_sig.add(onPackDragMove);
		}
		
		private function onPackDragMove(event:MouseEvent):void {
			if(empty_slot.hitTestObject(Cursor.instance.drag_DO)) {
				var trade_slot:MakingSlot = findEmptySlotOrSlotWithThisItem(dragVO.dragged_itemstack.item);
				if (dragVO.target != trade_slot) {
					if (dragVO.target) dragVO.target.unhighlightOnDragOut();
					dragVO.target = trade_slot; // tuck a reference to the trade slot in the dragVO
					if(dragVO.dragged_itemstack.slots && 
						TSModelLocator.instance.worldModel.getItemstacksInContainerTsid(dragVO.dragged_itemstack.tsid).length){
						//bag still has stuff in it
						Cursor.instance.showTip('There is still stuff in this!');
						empty_slot.unhighlight();
					}
					else if(!dragVO.dragged_itemstack.item.hasTags(TradeManager.TRADE_TAGS_TO_EXCLUDE) && !dragVO.dragged_itemstack.is_soulbound_to_me){
						Cursor.instance.showTip('Add');
						if(trade_slot.item_class) {
							trade_slot.highlightOnDragOver();
						} 
						else {
							empty_slot.highlight();
						}
					}
					else {
						Cursor.instance.showTip('<font color="#cc0000">You can\'t trade this item!</font>');
						dragVO.target.unhighlightOnDragOut();
					}
				}
			} else {
				if (dragVO.target && dragVO.target is MakingSlot) {
					dragVO.target.unhighlightOnDragOut();
					dragVO.target = null;
					Cursor.instance.hideTip();
				}
				empty_slot.unhighlight();
			}
		}
		
		private function onPackDragComplete(event:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(onPackDragMove);
			
			if (dragVO.target && dragVO.target is MakingSlot && !dragVO.dragged_itemstack.item.hasTags(TradeManager.TRADE_TAGS_TO_EXCLUDE) && !dragVO.dragged_itemstack.is_soulbound_to_me) {
				dragVO.target.unhighlightOnDragOut();
				
				var doIt:Function = function():void {
					//send it off to the server
					TradeManager.instance.clientAddItem(dragVO.dragged_itemstack.tsid, Math.min(dragVO.dragged_itemstack.count, MakingSlot.MAX_COUNT));
					//disable the offer button
					offer_bt.disabled = true;
				}
				
				if ((dragVO.dragged_itemstack.item.is_furniture || dragVO.dragged_itemstack.item.is_special_furniture) && dragVO.dragged_itemstack.furn_upgrade_id != '0') {
					TSFrontController.instance.confirmFurnitureTrade(function(value:*):void {
						if (value == true) {
							doIt();
						}
					});
				} else {
					doIt();
				}
			}
			
			Cursor.instance.hideTip();
			empty_slot.unhighlight();
		}
		
		public function translateSlotCenterToGlobal(slot:int, path:String):Point {			
			//check if we are coming from the player pack or the trade window			
			if(PackDisplayManager.instance.isContainerTsidPrivate(path)){
				return left_slots.localToGlobal(getCenterPtForSlot(slot));
			}else{
				return TSFrontController.instance.translatePackSlotToGlobal(slot, path);
			}
		}
		
		private function getCenterPtForSlot(slot_index:int):Point {
			var trade_slot:MakingSlot = getSlot(slot_index);
			if (trade_slot) {
				return new Point(trade_slot.x+(trade_slot.width/2), trade_slot.y+(trade_slot.width/2));
			} else {
				return new Point(0, 0);
			}
		}
		
		private function getSlot(slot:int):MakingSlot {
			return left_slots.getChildByName(SLOT_NAME+slot) as MakingSlot;
		}
		
		public function addItemToAvailableSlot(itemstack:Itemstack):void {
			if (!itemstack) return;
			addItemToSlot(itemstack);
		}
		
		private function addItemToSlot(itemstack:Itemstack):void {
			var item_class:String = itemstack.class_tsid;
			var trade_slot:MakingSlot = findEmptySlotOrSlotWithThisItem(model.worldModel.getItemByTsid(item_class));
			if (!trade_slot) return;
			
			trade_slot.itemstack_tsid = itemstack.tsid;
			
			trade_slot.update(item_class, itemstack.count, true, false, itemstack.itemstack_state.furn_config);
									
			afterSlotChange(new Vector.<MakingSlot>(trade_slot));
		}
		
		public function afterSlotChange(latest_slots:Vector.<MakingSlot>, reset:Boolean = false, dispatch_events:Boolean = true):void {
			var i:int = 0;
			var how_many_full:int = 0;
			var trade_slot:MakingSlot;
			var new_x:int;
			var new_y:int;
			var g:Graphics = left_slots.graphics;
			var itemstack:Itemstack;
			var item_totals:Object = {};
			var item:Item;
			
			for (i; i < MAX_TRADE_SLOTS; i++) {
				trade_slot = MakingSlot(left_slots.getChildAt(i));
				if(reset) trade_slot.update('', 0, true);
				if(trade_slot.itemstack_tsid){
					itemstack = model.worldModel.getItemstackByTsid(trade_slot.itemstack_tsid);
					if(itemstack.slot != i){
						trade_slot.update('', 0, true);
					} 
				}
				if(trade_slot.item_class) {
					how_many_full++;
					trade_slot.visible = true;
					item_totals[trade_slot.item_class] = int(item_totals[trade_slot.item_class]) + trade_slot.count;
					
					new_x = ((i % MAX_PER_ROW)*(SLOT_WH+SLOT_PADDING));
					new_y = ((how_many_full > MAX_PER_ROW) ? SLOT_WH+SLOT_PADDING*3 : 0);
				}else{
					trade_slot.visible = false;
					
					new_x = ((i % MAX_PER_ROW)*(SLOT_WH+SLOT_PADDING));
					new_y = ((how_many_full >= MAX_PER_ROW) ? SLOT_WH+SLOT_PADDING*3 : 0);
				}

				trade_slot.x = new_x;
				trade_slot.y = new_y;
			}
			
			//setup the +/- buttons
			var remainder:int;
			for (i = 0; i < MAX_TRADE_SLOTS; i++) {
				trade_slot = MakingSlot(left_slots.getChildAt(i));
				if(trade_slot.item_class){
					item = model.worldModel.getItemByTsid(trade_slot.item_class);
					remainder = model.worldModel.pc.hasHowManyItems(trade_slot.item_class) - item_totals[trade_slot.item_class];
										
					trade_slot.max_value = Math.min(item.stackmax, trade_slot.count + remainder);
				}
			}
			
			//tween the latest slot
			if(latest_slots && latest_slots.length == 1){
				new_y = ((int(latest_slots[0].name.substr(SLOT_NAME.length)) >= MAX_PER_ROW) ? SLOT_WH+SLOT_PADDING*3 : 0);
				latest_slots[0].y += 13;
				TSTweener.removeTweens(latest_slots[0]);
				TSTweener.addTween(latest_slots[0], {y: new_y, time: .6, transition: 'easeOutElastic'});
			}
			
			//move the empty slot 1 ahead of the one we just dropped
			new_x = left_slots.x + ((how_many_full % MAX_PER_ROW)*(SLOT_WH+SLOT_PADDING));
			if(how_many_full >= MAX_TRADE_SLOTS) new_x = left_slots.x + (5 % MAX_PER_ROW)*(SLOT_WH+SLOT_PADDING);
			new_y = left_slots.y + ((how_many_full >= MAX_PER_ROW) ? SLOT_WH+SLOT_PADDING*3 : 0);
			if (empty_slot.x != new_x || empty_slot.y != new_y) {
				if (reset) {
					empty_slot.x = new_x;
					empty_slot.y = new_y;
				} else {
					TSTweener.removeTweens(empty_slot);
					TSTweener.addTween(empty_slot, {x:new_x, y:new_y, time:.3});
				}
			}
			
			//how to display the empty slot
			if (how_many_full == 0) {
				empty_slot.visible = true;
				empty_slot.arrow.visible = true;
				empty_slot.tf.visible = true;
				left_slots.visible = false;
			} else {
				empty_slot.arrow.visible = false;
				empty_slot.tf.visible = false;
				left_slots.visible = true;
				if (how_many_full >= MAX_TRADE_SLOTS) {
					empty_slot.visible = false;
				} else {
					empty_slot.visible = true;
				}
			}
			
			//re-enable the offer button
			offer_bt.disabled = false;
			
			//give the thing a little push if it needs it
			g.clear();
			g.beginFill(0xffcc00, 0);
			i = int(trade_slot.height + SLOT_PADDING); //use i var to throw in a height
			
			if(how_many_full == MAX_PER_ROW) i = int(trade_slot.height*2 + SLOT_PADDING);
			if(how_many_full > MAX_PER_ROW) i = int(trade_slot.height*2 + SLOT_PADDING*2);
			g.drawRect(0, 0, 10, i);
			
			_jigger();
		}
		
		private function findEmptySlotOrSlotWithThisItem(item:Item, is_force_update:Boolean = false):MakingSlot {
			var trade_slot:MakingSlot;
			var first_empty_ms:MakingSlot;
			var already_ms:MakingSlot;
			var i:int = 0;
			
			for (i; i < MAX_TRADE_SLOTS; i++) {
				trade_slot = MakingSlot(left_slots.getChildAt(i));
				
				if (!trade_slot.item_class && !first_empty_ms) {
					first_empty_ms = trade_slot;
				} else if (trade_slot.item_class == item.tsid ) {
					if(is_force_update || (trade_slot.count < item.stackmax && trade_slot.count < MakingSlot.MAX_COUNT)){
						already_ms = trade_slot;
					}
				}
			}
			if (already_ms) return already_ms;
			if (first_empty_ms) return first_empty_ms;
			return null;
		}
		
		private function onKeyDown(event:KeyboardEvent):void {
			//did they mash enter? fire it off
			if(event.keyCode == Keyboard.ENTER && !event.ctrlKey){
				//tell whoever is listening that we have text to send
				dispatchEvent(new TSEvent(TSEvent.MSG_SENT, chat_input));
			}
		}
		
		private function prepareBody(content:Sprite):void {
			//remove the old one first
			var child:DisplayObject = _scroller.body.getChildByName(CONTENT_BODY_NAME);
			if(child) _scroller.body.removeChild(child);
			
			_scroller.body.addChild(content);
			
			//let the done button cancel a trade
			done_bt.addEventListener(TSEvent.CHANGED, closeFromUserInput, false, 0, true);
			done_bt.visible = false;
			offer_bt.disabled = false;
			
			//hide overlays
			unlockSide('left', false);
			unlockSide('right', false);
			complete_overlay.visible = false;
			
			//show currency input
			your_currency.visible = true;
			their_currency.visible = true;
			
			//hide checkmark
			checkmark_icon.visible = false;
			
			//reset the trade slots
			afterSlotChange(null, true);
			left_slots.y = right_slots.y = empty_slot.y = SLOT_Y;
			
			//reset left trade slots
			var trade_slot:MakingSlot;
			var i:int = 0;
			
			for(i; i < MAX_TRADE_SLOTS; i++){
				trade_slot = left_slots.getChildAt(i) as MakingSlot;
				trade_slot.addEventListener(TSEvent.CLOSE, onSlotCloseClick, false, 0, true);
				trade_slot.addEventListener(TSEvent.CHANGED, onSlotChange, false, 0, true);
				trade_slot.addEventListener(TSEvent.QUANTITY_CHANGE, onSlotQuantityChange, false, 0, true);
			}
			
			//reset right trade slots
			while(right_slots.numChildren > 0) right_slots.removeChildAt(0);
		}
		
		private function showChat():void {			
			const pc:PC = model.worldModel.getPCByTsid(TradeManager.instance.player_tsid);
			
			if(pc){				
				//see if we had any exisiting chats and add them
				const chat_area:ChatArea = RightSideManager.instance.right_view.getChatArea(pc.tsid);
				if(chat_area){
					var elements:Vector.<ChatElement> = chat_area.elements;
					var element:ChatElement;
					var i:int;
					var total:int = elements.length;
					
					for(i; i < total; i++){
						element = elements[int(i)];
						if(element.alpha == 1 && element.type == ChatElement.TYPE_CHAT){
							addChatElement(element.pc_tsid, element.text, element.type, element.unix_timestamp, true);
						}
					}
				}
				
				//add a line that says you have started the trade in both chat areas if applicable
				RightSideManager.instance.chatUpdate(pc.tsid, model.worldModel.pc.tsid, 'You and '+pc.label+' have begun a trade. You can chat about it here!', ChatElement.TYPE_ACTIVITY);
			}
		}
		
		public function addChatElement(pc_tsid:String, txt:String, type:String = '', timestamp:uint = 0, is_text_formatted:Boolean = false):void {
			if(!visible) return;
			if(type == '') type = ChatElement.TYPE_CHAT;
			
			//if this is an activity, let's be a little clever with the txt
			if(type == ChatElement.TYPE_ACTIVITY && !is_text_formatted){
				const pc:PC = model.worldModel.getPCByTsid(pc_tsid);
				if(pc && pc != model.worldModel.pc){
					txt = '<a href="event:'+TSLinkedTextField.LINK_PC+'|'+pc_tsid+'" class="'+RightSideManager.instance.getPCCSSClass(pc_tsid)+'">'+pc.label+'</a> '+txt;
				}
				else if(pc){
					txt = '<span class="'+RightSideManager.instance.getPCCSSClass(pc_tsid)+'">You</span> '+txt;
				}
			}
			
			//format the html if it's not already
			if(!is_text_formatted){
				txt = RightSideManager.instance.chatGetText('trade', pc_tsid, txt, type);
			}
			
			var element:ChatElement = new ChatElement();
			element.init(null, chat_scroller.w - ChatArea.SCROLL_BAR_W, pc_tsid, txt, type, timestamp);
			element.name = pc_tsid;
			element.y = chat_scroller.body.height + ChatArea.ELEMENT_PADD;
			chat_scroller.body.addChild(element);
			
			//kill all the overflow
			if(chat_scroller.body.numChildren > ChatArea.MAX_ELEMENTS){
				while(chat_scroller.body.numChildren > ChatArea.MAX_ELEMENTS) {
					element = chat_scroller.body.getChildAt(0) as ChatElement;
					if(element.parent) element.parent.removeChild(element);
					if(element is DisposableSprite) element.dispose();
				}
				
				//reposition
				var i:int;
				var next_y:int;
				
				for(i; i < chat_scroller.body.numChildren; i++){
					element = chat_scroller.body.getChildAt(i) as ChatElement;
					element.y = next_y;
					next_y += element.height + ChatArea.ELEMENT_PADD;
				}
			}
			
			chat_scroller.refreshAfterBodySizeChange();
		}
		
		public function getChatElements():Vector.<ChatElement> {
			var i:int;
			var total:int = chat_scroller.body.numChildren;
			var elements:Vector.<ChatElement> = new Vector.<ChatElement>();
			var child:DisplayObject;
			
			for(i; i < total; i++){
				child = chat_scroller.body.getChildAt(i);
				if(child is ChatElement){
					elements.push(child as ChatElement);
				}
			}
			
			return elements;
		}
		
		private function constructButtons():void {			
			edit_bt = new Button({
				label: 'Edit',
				name: 'edit_bt',
				value: 'edit',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			left_lock.addChild(edit_bt);
			
			offer_bt = new Button({
				label: 'Looks good. Make offer...',
				name: 'offer_bt',
				value: 'make_offer',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			offer_bt.x = _w - offer_bt.width - _base_padd;
			content_footer.addChild(offer_bt);
			
			done_bt = new Button({
				label: 'Ok, done!',
				name: 'done_bt',
				value: 'complete_trade',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			done_bt.x = _w - done_bt.width - _base_padd;
			content_footer.addChild(done_bt);
		}
		
		private function constructContent():void {						
			content_body.name = CONTENT_BODY_NAME;
			
			//waiting spinner
			waiting_spinner = new AssetManager.instance.assets.spinner();
			waiting_spinner.scaleX = waiting_spinner.scaleY = .6;
			waiting_spinner.x = int(_w - waiting_spinner.width - 10);
			waiting_spinner.gotoAndStop(1);
			waiting_spinner.visible = false;
			
			content_footer.addChild(waiting_spinner);
			
			//waiting for other player TF
			TFUtil.prepTF(waiting_tf, false);
			waiting_tf.autoSize = TextFieldAutoSize.RIGHT;
			waiting_tf.x = waiting_spinner.x - 5;
			waiting_tf.visible = false;
			
			content_footer.addChild(waiting_tf);
			
			//add the complete overlay to the mix
			complete_overlay.mouseEnabled = false;
			addChild(complete_overlay);
			
			//trade icon
			trade_icon = new AssetManager.instance.assets.trade_icon();
			
			//checkmark icon
			checkmark_icon = new AssetManager.instance.assets.checkmark();
			checkmark_icon.visible = false;
			addChild(checkmark_icon);
		}
		
		private function constructSlots():void {
			//place to drop items
			empty_slot = new MakingSlotEmpty();
			empty_slot.x = 30;
			empty_slot.y = SLOT_Y;
			empty_slot.tf.htmlText = '<span class="trade_slot_empty">Drag items here from your pack</span>';
			empty_slot.tf.multiline = true;
			empty_slot.tf.wordWrap = true;
			empty_slot.tf.width = 100;
			empty_slot.tf.y = int(empty_slot.height/2 - empty_slot.tf.height/2);
			content_body.addChild(empty_slot);
			
			var trade_slot:MakingSlot;
			var i:int = 0;
			for (i; i < MAX_TRADE_SLOTS; i++) {
				trade_slot = new MakingSlot(SLOT_WH, SLOT_WH);
				trade_slot.name = SLOT_NAME+i;
				left_slots.addChild(trade_slot);
			}
			
			//left slots for dropping items
			left_slots.visible = false;
			left_slots.x = empty_slot.x;
			left_slots.y = empty_slot.y;
			left_side.addChild(left_slots);
			
			//right slots for when other player drops items
			right_slots.x = left_slots.x;
			right_slots.y = left_slots.y;
			right_side.addChild(right_slots);
		}
		
		private function constructChat():void {			
			//divider line
			const line_drop:DropShadowFilter = new DropShadowFilter();
			line_drop.angle = -90;
			line_drop.distance = 6;
			line_drop.blurX = 0;
			line_drop.blurY = 10;
			line_drop.quality = 3;
			line_drop.alpha = .4;
			chat_line.filters = [line_drop];
			
			var g:Graphics = chat_line.graphics;
			g.beginFill(0xc2c2c2);
			g.drawRect(_border_w, 0, _w - _border_w*2, 1);
			content_footer.addChild(chat_line);
			
			//scroller
			chat_scroller = new TSScroller({
				name: 'scroller',
				bar_wh: ChatArea.SCROLL_BAR_W,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 20,
				scrolltrack_always: false,
				maintain_scrolling_at_max_y: true,
				start_scrolling_at_max_y: true,
				use_auto_scroll: false,
				show_arrows: true
			});
			chat_scroller.x = _base_padd;
			chat_scroller.w = _w - _base_padd*2;
			content_footer.addChild(chat_scroller);
			
			//input field
			chat_input = new InputField(true);
			chat_input.x = _base_padd;
			chat_input.width = _w - _base_padd*2;
			chat_input.addEventListener(KeyBeacon.KEY_DOWN_, onKeyDown, false, 0, true);
			content_footer.addChild(chat_input);
		}
		
		/* singleton boilerplate */
		public static const instance:TradeDialog = new TradeDialog();
	}
}