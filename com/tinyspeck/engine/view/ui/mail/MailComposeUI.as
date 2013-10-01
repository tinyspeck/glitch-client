package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.itemstack.ItemstackToolState;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.MailManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.ui.making.MakingSlot;
	import com.tinyspeck.engine.view.ui.making.MakingSlotEmpty;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;

	public class MailComposeUI extends AbstractMailUI
	{
		public static const INPUT_X:uint = 100;
		public static const TEXT_HEIGHT:uint = 100;
		public static const SLOT_WH:uint = 67;
		public static const MAX_CHARS:uint = 300;
		
		private const RESULTS_WIDTH:uint = 235;
		private const RESULTS_HEIGHT:uint = 100;
		private const CURRANTS_WIDTH:uint = 215;
		private const BT_WIDTH:uint = 70;
		
		private var item_slot:MakingSlot;
		private var empty_slot:MakingSlotEmpty;
		private var text_scroll:TSScroller;
		private var search_scroller:TSScroller;
		
		private var cancel_bt:Button;
		
		private var search_results_holder:Sprite = new Sprite();
		private var search_results_mask:Sprite = new Sprite();
		private var currants_holder:Sprite = new Sprite();
		
		private var sender_label:TextField = new TextField();
		private var sender_input:TSLinkedTextField = new TSLinkedTextField();
		private var message_label:TextField = new TextField();
		private var message_input:TSLinkedTextField = new TSLinkedTextField();
		private var attach_label:TextField = new TextField();
		private var search_results_tf:TSLinkedTextField = new TSLinkedTextField();
		private var currants_tf:TextField = new TextField();
		private var how_many_tf:TextField = new TextField();
		
		private var border_color:uint;
		private var bg_color:uint;
		
		private var _sender_tsid:String;
		
		public function MailComposeUI(w:int){
			super(w);
			const padd:int = 5;
			var g:Graphics;
			var input_bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('mail_body_background', 'backgroundEditColor', 0xf4f2b6);
			var input_border_color:uint = CSSManager.instance.getUintColorValueFromStyle('mail_body_background', 'borderEditColor', 0xc8c560);
			border_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_header', 'borderColor', 0xcbcbcb);
			bg_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_header', 'backgroundColor', 0xececec);
			
			
			//build out the compose screen
			TFUtil.prepTF(sender_label);
			sender_label.width = INPUT_X - 15;
			sender_label.htmlText = '<p class="mail_label" align="right">To</p>';
			sender_label.y = 30;
			addChild(sender_label);
			
			TFUtil.prepTF(sender_input);
			sender_input.type = TextFieldType.INPUT;
			sender_input.mouseEnabled = true;
			sender_input.selectable = true;
			sender_input.multiline = false;
			sender_input.styleSheet = null;
			sender_input.autoSize = TextFieldAutoSize.NONE;
			sender_input.defaultTextFormat = CSSManager.instance.getTextFormatFromStyle('mail_sender');
			sender_input.text = ' ';
			sender_input.x = INPUT_X;
			sender_input.y = sender_label.y + 2;
			sender_input.width = w - INPUT_X - 30;
			sender_input.height = sender_input.textHeight + 4;
			sender_input.text = ''; //put it back to nothing after setting the height
			sender_input.addEventListener(Event.CHANGE, onSenderChange, false, 0, true);
			addChild(sender_input);
			
			TFUtil.prepTF(message_label);
			message_label.width = INPUT_X - 15;
			message_label.y = int(sender_label.y + sender_label.height + 13);
			message_label.htmlText = '<p class="mail_label" align="right">Message</p>';
			addChild(message_label);
			
			//message scroll
			text_scroll = new TSScroller({
				name: 'text_scroll',
				bar_wh: 12,
				bar_color: 0,
				bar_alpha: .1,
				bar_handle_min_h: 36,
				scrolltrack_always: false,
				show_arrows: true,
				maintain_scrolling_at_max_y: true,
				w: sender_input.width,
				h: TEXT_HEIGHT
			});
			text_scroll.setHandleColors(0x75733d, 0x75733d, 0xacab8b);
			text_scroll.x = INPUT_X;
			text_scroll.y = int(message_label.y + 5);
			text_scroll.listen_to_arrow_keys = true;
			addChild(text_scroll);
			
			//message						
			TFUtil.prepTF(message_input);
			message_input.type = TextFieldType.INPUT;
			message_input.styleSheet = null;
			//message_input.border = true;
			message_input.selectable = true;
			message_input.mouseEnabled = true;
			message_input.defaultTextFormat = CSSManager.instance.getTextFormatFromStyle('mail_body');
			message_input.width = sender_input.width - 15;
			message_input.addEventListener(Event.CHANGE, onBodyChange, false, 0, true);
			message_input.maxChars = MAX_CHARS;
			text_scroll.body.addChild(message_input);
			onBodyChange();
			
			//attach label
			TFUtil.prepTF(attach_label);
			attach_label.width = INPUT_X - 15;
			attach_label.y = int(text_scroll.y + text_scroll.h + 28);
			attach_label.htmlText = '<p class="mail_label" align="right">Attach<br><span class="mail_optional">(Optional)</p>';
			addChild(attach_label);
			
			//put the drop slots
			empty_slot = new MakingSlotEmpty(true);
			empty_slot.arrow.x -= 22;
			empty_slot.tf.htmlText = '<span class="mail_slot_empty">Drag an item here from your pack</span>';
			empty_slot.tf.multiline = true;
			empty_slot.tf.wordWrap = true;
			empty_slot.tf.x = 15;
			empty_slot.tf.width = empty_slot.arrow.x - empty_slot.tf.x;
			empty_slot.tf.y = int(empty_slot.slot_height/2 - empty_slot.tf.height/2);
			empty_slot.x = INPUT_X - padd;
			empty_slot.y = attach_label.y - 6;
			addChild(empty_slot);
			
			item_slot = new MakingSlot(SLOT_WH, SLOT_WH);
			item_slot.x = empty_slot.x;
			item_slot.y = empty_slot.y;
			item_slot.visible = false;
			item_slot.qty_picker.x = SLOT_WH + 10;
			item_slot.qty_picker.y = SLOT_WH - item_slot.qty_picker.height - 10;
			item_slot.addEventListener(TSEvent.CLOSE, onSlotCancel, false, 0, true);
			addChild(item_slot);
			
			TFUtil.prepTF(how_many_tf, false);
			how_many_tf.htmlText = '<p class="mail_how_many">How many?</p>';
			how_many_tf.x = int(item_slot.qty_picker.x + (item_slot.qty_picker.width-how_many_tf.width)/2);
			how_many_tf.y = 10;
			item_slot.addChild(how_many_tf);
			
			//setup the scroller
			search_scroller = new TSScroller({
				name: 'search_scroller',
				w:RESULTS_WIDTH - 10,
				h:RESULTS_HEIGHT - 10,
				bar_wh: 12,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 36,
				scrolltrack_always: false,
				maintain_scrolling_at_max_y: true,
				use_auto_scroll: false,
				show_arrows: true
			});
			search_scroller.y = 2;
			search_results_holder.addChild(search_scroller);
			
			//throw the TF in the scroller
			TFUtil.prepTF(search_results_tf);
			search_results_tf.embedFonts = false;
			search_results_tf.x = 10;
			search_results_tf.width = RESULTS_WIDTH - 24;
			search_results_tf.addEventListener(TextEvent.LINK, onResultsClick, false, 0, true);
			search_scroller.body.addChild(search_results_tf);
			
			//make sure the results are available
			g = search_results_holder.graphics;
			g.lineStyle(1, input_border_color);
			g.beginFill(input_bg_color);
			g.drawRoundRectComplex(0, 0, RESULTS_WIDTH, RESULTS_HEIGHT, 0, 0, 5, 5);
			search_results_holder.x = INPUT_X + 2;
			search_results_holder.y = -RESULTS_HEIGHT-10;
			
			//draw the results mask
			search_results_holder.mask = search_results_mask;
			g = search_results_mask.graphics;
			g.beginFill(0);
			g.drawRect(0, 0, RESULTS_WIDTH + 2, RESULTS_HEIGHT + 2);
			search_results_mask.x = INPUT_X + 2;
			search_results_mask.y = int(sender_input.y + sender_input.height + padd);
			addChild(search_results_mask);
			
			//draw the bg
			g = graphics;
			g.beginFill(bg_color);
			g.drawRect(0, 0, _w, empty_slot.y + empty_slot.height + 20);
			g.beginFill(border_color);
			g.drawRect(0, 0, _w, 1);
			g.drawRect(0, empty_slot.y + empty_slot.height + 20, _w, 1);
			g.beginFill(0xffffff);
			g.drawRect(0, empty_slot.y + empty_slot.height + 21, _w, 62);
			
			//put backgrounds behind the inputs
			g.lineStyle(1, input_border_color);
			g.beginFill(input_bg_color);
			g.drawRoundRect(sender_input.x - padd, sender_input.y - padd, int(sender_input.width + padd*2), int(sender_input.height + padd*2), 10);
			g.drawRoundRect(text_scroll.x - padd, text_scroll.y - padd, int(text_scroll.w + padd*2), int(text_scroll.h + padd*2), 10);
			
			//currats tf
			TFUtil.prepTF(currants_tf, false);
			currants_tf.htmlText = '<p class="mail_attach_currants">Attach Currants</p>';
			currants_tf.x = int(CURRANTS_WIDTH/2 - currants_tf.width/2);
			currants_tf.y = int(-currants_tf.height/2);
			currants_holder.addChild(currants_tf);
			
			//currants
			g = currants_holder.graphics;
			g.lineStyle(1, border_color);
			g.beginFill(bg_color);
			g.drawRoundRect(0, 0, CURRANTS_WIDTH, empty_slot.slot_height - 1, 10);
			g.endFill();
			g.lineStyle(0,0,0);
			g.beginFill(bg_color);
			g.drawRect(currants_tf.x-5, -1, currants_tf.width+10, 2);
			currants_holder.x = INPUT_X + int(text_scroll.w + padd*2 - CURRANTS_WIDTH - padd);
			currants_holder.y = empty_slot.y;
			addChild(currants_holder);
			
			//currants q pick
			currants_qp.x = int(CURRANTS_WIDTH/2 - currants_qp.width/2 + 1);
			currants_qp.y = int(empty_slot.slot_height/2 - currants_qp.height/2 + 1);
			currants_qp.addEventListener(TSEvent.CHANGED, onCurrantsChange, false, 0, true);
			currants_qp.hide_save_button = true;
			currants_holder.addChild(currants_qp);

			//send button
			send_bt = new Button({
				name: 'send',
				label: 'Send',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: BT_WIDTH
			});
			send_bt.addEventListener(TSEvent.CHANGED, onSendClick, false, 0, true);
			send_bt.x = _w - send_bt.width - 25;
			send_bt.y = int(currants_holder.y + currants_holder.height + 23);
			addChild(send_bt);
			
			cancel_bt = new Button({
				name: 'cancel',
				label: 'Cancel',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR_INVIS,
				w: BT_WIDTH
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, onCancelClick, false, 0, true);
			cancel_bt.x = send_bt.x - cancel_bt.width - 5;
			cancel_bt.y = send_bt.y;
			addChild(cancel_bt);
			
			//cost to send
			TFUtil.prepTF(cost_tf, false);
			cost_tf.embedFonts = false;
			cost_tf.y = int(send_bt.y + send_bt.height + 3);
			addChild(cost_tf);
			
			//listen to changes to the slot
			item_slot.addEventListener(TSEvent.QUANTITY_CHANGE, onSlotQuantityChange, false, 0, true);
			
			onComposeChange(); //move them where they need to go
		}
		
		public function show():void {
			//clean stuff up
			empty_slot.visible = true;
			item_slot.update('', 0, false);
			item_slot.visible = false;
			item_slot.itemstack_tsid = null;
			_sender_tsid = null;
			sender_input.text = '';
			message_input.text = '';
			onBodyChange(); // needed to trigger autisize magic
			currants_qp.value = 0;
			currants_qp.visible = true;
			search_results_holder.y = -RESULTS_HEIGHT-10;
			if(cancel_bt) cancel_bt.disabled = false;
			
			//reset our cost to send
			MailManager.instance.resetCost();
			
			//reset the send button
			onComposeChange();
			
			//focus to:
			StageBeacon.stage.focus = sender_input;
			
			//don't let them drop things on the floor while this is up
			TSFrontController.instance.disableDropToFloor();
			
			listenToThings();
			
			visible = true;
		}
		
		public function hide():void {
			//put stuff back
			TSFrontController.instance.enableDropToFloor();
			
			
			dontListenToThings();
			
			visible = false;
		}
		
		public function sendFail():void {
			if(send_bt) send_bt.disabled = false;
			if(cancel_bt) cancel_bt.disabled = false;
		}
		
		private function onSlotCancel(event:TSEvent):void {
			empty_slot.visible = true;
			item_slot.visible = false;
			item_slot.itemstack_tsid = null;
			
			if(!visible) return;
			
			MailManager.instance.requestCost(item_slot.itemstack_tsid, item_slot.count, currants_qp.value);
		}
		
		private function onSlotQuantityChange(event:TSEvent):void {
			if(!visible) return;
			
			MailManager.instance.requestCost(item_slot.itemstack_tsid, item_slot.count, currants_qp.value);
		}
		
		private function onBodyChange(event:Event = null):void {
			message_input.autoSize = TextFieldAutoSize.LEFT;
			if(message_input.height < text_scroll.h){
				//turn off auto sizing and set the TF height
				message_input.autoSize = TextFieldAutoSize.NONE;
				message_input.height = TEXT_HEIGHT;
			}
			
			//this will make sure the caret is always in view while editing
			text_scroll.updateHandleWithInputText(message_input);
			text_scroll.refreshAfterBodySizeChange();
			
			updateSendButton();
		}
		
		private function onSenderChange(event:Event):void {
			//hunt through your buddy list
			var search_txt:String = sender_input.text;
			var start_y:int = sender_input.y + sender_input.height + 3;
			
			if(search_txt.length > 0){
				//legit search, let's go hunting!
				
				var search_results:Vector.<PC> = model.worldModel.searchBuddies(search_txt);
				showSearchResults(search_results);
				
				if(search_results_holder.y < start_y){
					if(TSTweener.isTweening(search_results_holder)) TSTweener.removeTweens(search_results_holder);
					TSTweener.addTween(search_results_holder, {y:start_y, time:.3});
				}
			}
			
			//if the search is nothing, hide the holder
			if(search_txt.length == 0){
				if(search_results_holder.y == start_y) closeResults();
				_sender_tsid = null;
				onComposeChange();
			} else if (search_results && search_results.length==1 && PC(search_results[0]).label.toLowerCase() == search_txt.toLowerCase()) {
				
				closeResults(PC(search_results[0]).tsid, PC(search_results[0]).label);
				onComposeChange();
			}
		}
		
		private function showSearchResults(search_results:Vector.<PC>):void {
			var i:int;
			var buddy:PC;
			var txt:String = '';
			
			//sort by name
			SortTools.vectorSortOn(search_results, ['label'], [Array.CASEINSENSITIVE]);
			
			for(i; i < search_results.length; i++){
				buddy = search_results[int(i)];
				txt += '<a href="event:'+buddy.tsid+'|'+buddy.label+'">'+buddy.label+'</a>';
				if(i < search_results.length-1) txt += '<br>';
			}
			
			if(!txt){
				txt = '<b>Aww, nothing found</b>';
				_sender_tsid = null;
				onComposeChange();
			}
			
			search_results_tf.htmlText = '<p class="mail_search">'+txt+'</p>';
			search_scroller.refreshAfterBodySizeChange(true);
			
			addChild(search_results_holder);
		}
		
		private function onResultsClick(event:TextEvent):void {
			var chunks:Array = event.text.split('|');
			if(chunks.length == 2){
				closeResults(chunks[0], chunks[1])
			}
		}
		
		private function closeResults(pc_tsid:String='', pc_label:String=''):void {
			if(TSTweener.isTweening(search_results_holder)) TSTweener.removeTweens(search_results_holder);
			TSTweener.addTween(search_results_holder, {y:-RESULTS_HEIGHT-10, time:.3});
			
			if(pc_tsid && pc_label){
				_sender_tsid = pc_tsid
				sender_input.text = pc_label;
				onComposeChange();
			} 
		}
		
		override protected function onPackDragMove(event:MouseEvent):void {
			if(empty_slot.hitTestObject(Cursor.instance.drag_DO)) {			
				if (dragVO.target != item_slot) {
					drag_good = false;
					if (dragVO.target) dragVO.target.unhighlightOnDragOut();
					dragVO.target = item_slot;
					
					if (isDroppable()) {
						if (item_slot.item_class) {
							item_slot.highlightOnDragOver();
							Cursor.instance.showTip('Change');
							drag_good = true;
						} 
						else {
							empty_slot.highlight();
							Cursor.instance.showTip('Add');
							drag_good = true;
						}
					}
				}
			} 
			else {
				if (dragVO.target is MakingSlot) {
					dragVO.target.unhighlightOnDragOut();
					dragVO.target = null;
					Cursor.instance.hideTip();
				}
				empty_slot.unhighlight();
			}
		}
		
		override protected function onPackDragComplete(event:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(onPackDragMove);
			
			if (dragVO.target && dragVO.target is MakingSlot && drag_good) {
				dragVO.target.unhighlightOnDragOut();
				
				//ask the server how much this is going to cost
				MailManager.instance.requestCost(dragVO.dragged_itemstack.tsid, dragVO.dragged_itemstack.count, currants_qp.value);
				
				//toss it into the slot
				item_slot.visible = true;
				item_slot.itemstack_tsid = dragVO.dragged_itemstack.tsid;
				item_slot.update(
					dragVO.dragged_itemstack.class_tsid,
					dragVO.dragged_itemstack.count,
					true,
					false,
					dragVO.dragged_itemstack.itemstack_state.furn_config,
					true
				);
				item_slot.close_button.visible = true;
				empty_slot.visible = false;
				
				//if it's a tool, show it
				const tool:ItemstackToolState = dragVO.dragged_itemstack.tool_state;
				if(tool){
					item_slot.update_tool(tool.points_capacity, tool.points_remaining, tool.is_broken);
				}
			}
			
			Cursor.instance.hideTip();
			empty_slot.unhighlight();
		}
		
		private function onSendClick(event:TSEvent):void {
			if(send_bt.disabled) return;
			
			//fire it off to the server
			if(sender_tsid){
				//how about checking something is in there
				if(!message && !itemstack_tsid && !currants){
					model.activityModel.activity_message = Activity.createFromCurrentPlayer('You need to put *something* in this message!');
				}
				else {
					//figure out if we are sending the itemstack or the class
					var itemstack:Itemstack = model.worldModel.getItemstackByTsid(itemstack_tsid);
					
					if (itemstack && itemstack.slots && model.worldModel.getItemstacksInContainerTsid(itemstack.tsid).length) {
						TSFrontController.instance.quickConfirm('Tricky! But you can\'t mail bags with stuff inside!');
						return;
					}
					
					var slot_tsid:String = '';
					var slot_class:String = '';
					var slot_count:int = 0;
					
					//only some
					if(itemstack && item_count != itemstack.count){
						slot_class = item_class;
						slot_count = item_count;
					}
					//whole thing
					else if(itemstack) {
						slot_tsid = itemstack_tsid;
					}
					
					//fire it off to the server
					MailManager.instance.send(
						sender_tsid, 
						message, 
						slot_tsid, 
						currants,
						slot_class, 
						slot_count
					);
					
					send_bt.disabled = true;
					cancel_bt.disabled = true;
				}
			}
		}
		
		private function onCancelClick(event:TSEvent):void {
			//we want to close this, let listeners know
			dispatchEvent(new TSEvent(TSEvent.CLOSE, this));
		}
		
		private function onComposeChange():void {
			//update the send button
			updateSendButton();
			
			//show how much it's gonna be
			updateCost();
		}
		
		/**
		 * updateSendButton and updateCost are copy/pasted from MailReplyUI 
		 * until we have a standard UI for writing mail instead of the 2
		 * very different ones.
		 */		
		
		override protected function updateSendButton():void {
			const stats:PCStats = model.worldModel.pc ? model.worldModel.pc.stats : null;
			var send_disabled:Boolean = true;
			var send_tip:Object;
			
			//any text
			if(message){
				send_disabled = false;
			}
			
			//any currants
			if(currants){
				send_disabled = false;
			}
			
			//any items
			if(itemstack_tsid){
				send_disabled = false;
			}
			
			//any person
			if(!sender_tsid){
				send_disabled = true;
				send_tip = { 
					txt:'You need someone in the "To" field!', 
					pointer:WindowBorder.POINTER_BOTTOM_CENTER 
				}
			}
			
			//can they afford to send it?
			if(!send_disabled && stats && stats.currants < cost_to_send){
				send_disabled = true;
				send_tip = { 
					txt:'You need more currants!', 
					pointer:WindowBorder.POINTER_BOTTOM_CENTER 
				}
			}
			
			//set the button
			if(send_bt){
				send_bt.disabled = send_disabled;
				send_bt.tip = send_tip;
			}
		}
		
		override protected function onStatsChanged(pc_stats:PCStats):void {
			//just re-check to see if we have enough monies
			onComposeChange();
		}
		
		private function onCurrantsChange(event:TSEvent):void {
			if(!visible) return;
			
			//recheck the send button
			updateSendButton();
			
			MailManager.instance.requestCost(item_slot.itemstack_tsid, item_slot.count, currants_qp.value);
		}
		
		public function get sender_tsid():String { return _sender_tsid; }
		public function get message():String { return message_input ? message_input.text : null; }
		public function get itemstack_tsid():String { return item_slot ? item_slot.itemstack_tsid : null; }
		public function get currants():uint { return currants_qp ? currants_qp.value : 0; }
		public function get item_class():String { return item_slot ? item_slot.item_class : null; }
		public function get item_count():uint { return item_slot ? item_slot.count : 0; }
	}
}
