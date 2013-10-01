package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.mail.MailMessage;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.MailManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;

	public class MailReplyUI extends AbstractMailUI
	{
		private static const INPUT_H:uint = 75;
		private static const PADD:uint = 12;
		private static const BT_WIDTH:uint = 70;
		
		private var text_scroll:TSScroller;
		private var cancel_bt:Button;
		private var current_message:MailMessage;
		private var item_slot:MailItemSlot = new MailItemSlot();
		
		private var scroll_holder:Sprite = new Sprite();
		private var currants_holder:Sprite = new Sprite();
		private var masker:Sprite = new Sprite();
		
		private var input_tf:TSLinkedTextField = new TSLinkedTextField();
		private var currants_attach_tf:TextField = new TextField();
		
		private var input_bg_color:uint = 0xf4f2b6;
		private var input_border_color:uint = 0xc8c560;
		
		public function MailReplyUI(w:int){
			super(w);
			
			//get the colors from css
			input_bg_color = CSSManager.instance.getUintColorValueFromStyle('mail_reply', 'backgroundColor', input_bg_color);
			input_border_color = CSSManager.instance.getUintColorValueFromStyle('mail_reply', 'borderColor', input_border_color);
			
			//the holder for scroller
			const point_start_x:uint = 25;
			const pointy_width:uint = 6;
			var g:Graphics = scroll_holder.graphics;
			g.beginFill(input_bg_color);
			g.drawRoundRect(0, pointy_width, _w, INPUT_H, 6);
			g.moveTo(point_start_x - pointy_width/2, pointy_width);
			g.lineTo(point_start_x + 1, 0);
			g.lineTo(point_start_x + pointy_width, pointy_width);
			g.lineTo(point_start_x - pointy_width/2, pointy_width);
			addChild(scroll_holder);
			
			//border
			const bg_glow:GlowFilter = new GlowFilter();
			bg_glow.color = input_border_color;
			bg_glow.blurX = bg_glow.blurY = 2;
			bg_glow.strength = 15;
			scroll_holder.filters = [bg_glow];
			
			//setup the scroller
			text_scroll = new TSScroller({
				name: 'text_scroll',
				bar_wh: 12,
				bar_color: 0,
				bar_alpha: .1,
				bar_handle_min_h: 36,
				w: scroll_holder.width - PADD - 4,
				scrolltrack_always: false,
				show_arrows: true,
				maintain_scrolling_at_max_y: true
			});
			text_scroll.x = PADD - 4;
			text_scroll.y = PADD;
			text_scroll.h = INPUT_H - PADD;
			text_scroll.setHandleColors(0x75733d, 0x75733d, 0xacab8b);
			text_scroll.listen_to_arrow_keys = true;
			scroll_holder.addChild(text_scroll);
			
			//input
			TFUtil.prepTF(input_tf);
			TFUtil.setTextFormatFromStyle(input_tf, 'mail_reply');
			input_tf.type = TextFieldType.INPUT;
			input_tf.selectable = true;
			input_tf.width = text_scroll.w - 15;
			input_tf.addEventListener(Event.CHANGE, onInputChange, false, 0, true);
			input_tf.maxChars = MailComposeUI.MAX_CHARS;
			text_scroll.body.addChild(input_tf);
			
			//buttons
			send_bt = new Button({
				name: 'send',
				label: 'Send',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: BT_WIDTH
			});
			send_bt.addEventListener(TSEvent.CHANGED, onSendClick, false, 0, true);
			send_bt.x = _w - send_bt.width;
			send_bt.y = INPUT_H + pointy_width + 20;
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
			
			//item drop slot
			item_slot.y = int(send_bt.y + 3);
			item_slot.addEventListener(TSEvent.CHANGED, onSlotChange, false, 0, true);
			item_slot.addEventListener(TSEvent.QUANTITY_CHANGE, onSlotChange, false, 0, true);
			addChild(item_slot);
			
			//currants
			TFUtil.prepTF(currants_attach_tf, false);
			currants_attach_tf.htmlText = '<p class="mail_reply_attach">Attach Currants</p>';
			currants_holder.addChild(currants_attach_tf);
			
			currants_qp.y = int(currants_attach_tf.height);
			currants_qp.width = int(currants_attach_tf.width);
			currants_qp.hide_save_button = true;
			currants_qp.addEventListener(TSEvent.FOCUS_OUT, onCurrantsFocusOut, false, 0, true);
			currants_qp.addEventListener(TSEvent.CHANGED, onCurrantsChange, false, 0, true);
			currants_holder.addChild(currants_qp);
			
			currants_attach_tf.x = int(currants_qp.x/2 + (currants_qp.width/2 - currants_attach_tf.width/2));
			
			currants_holder.x = int(item_slot.width + 12);
			currants_holder.y = int(send_bt.y - currants_attach_tf.height + 6);
			addChild(currants_holder);
			
			//cost
			TFUtil.prepTF(cost_tf, false);
			cost_tf.embedFonts = false;
			cost_tf.y = int(send_bt.y + send_bt.height + 5);
			addChild(cost_tf);
			updateCost();
			
			//mask
			g = masker.graphics;
			g.beginFill(0);
			g.drawRect(-1, -1, _w + 2, int(cost_tf.y + cost_tf.height + 2)); //+2 for the border
			mask = masker;
			addChild(masker);
		}
		
		public function show(message_id:String):void {
			if(!message_id) return;
			
			current_message = MailManager.instance.mail.getMessageById(message_id);
			
			//reset stuff
			input_tf.text = '';
			StageBeacon.stage.focus = input_tf;
			currants_qp.value = 0;
			currants_qp.visible = true;
			item_slot.itemstack_tsid = null;
			
			//reset our cost to send
			MailManager.instance.resetCost();
			
			onInputChange();
			updateCost();
			
			send_bt.disabled = true;
			
			//animate
			masker.y = -masker.height;
			TSTweener.removeTweens(masker);
			TSTweener.addTween(masker, {y:0, time:.5, onUpdate:onSizeChange});
			
			listenToThings();
			
			//let the item slot have some tooltip action
			TipDisplayManager.instance.registerTipTrigger(item_slot);
			
			//don't let them drop things on the floor while this is up
			TSFrontController.instance.disableDropToFloor();
			
			visible = true;
		}
		
		public function hide(animate:Boolean = false):void {
			//animate
			TSTweener.removeTweens(masker);
			if(animate){
				const self:MailReplyUI = this;
				TSTweener.addTween(masker, {y:-masker.height, time:.5, onUpdate:onSizeChange,
					onComplete:function():void {
						self.visible = false;
						currants_qp.visible = false;
						item_slot.itemstack_tsid = null;
					}
				});
			}
			else {
				masker.y = -masker.height;
				visible = false;
				currants_qp.visible = false;
				item_slot.itemstack_tsid = null;
			}
			
			dontListenToThings();
			
			//no more tooltip action
			TipDisplayManager.instance.unRegisterTipTrigger(item_slot);
			
			//drop stuff all you want
			TSFrontController.instance.enableDropToFloor();
		}
		
		override protected function onStatsChanged(pc_stats:PCStats):void {
			updateCost();
		}
		
		override protected function updateSendButton():void {
			const stats:PCStats = model.worldModel.pc.stats;
			var send_disabled:Boolean = true;
			var send_tip:Object;
			
			//any text
			if(input_tf.text.length != 0){
				send_disabled = false;
			}
			
			//any currants
			if(currants_qp.value != 0){
				send_disabled = false;
			}
			
			//any items
			if(item_slot.itemstack_tsid){
				send_disabled = false;
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
			send_bt.disabled = send_disabled;
			send_bt.tip = send_tip;
		}
		
		override public function onPackChange():void {
			//update the qty picker if it has an item, and make sure the amount they have lines up with what they have
			item_slot.itemstack_tsid = item_slot.itemstack_tsid;
		}
		
		private function onSizeChange():void {
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		private function onInputChange(event:Event = null):void {
			input_tf.autoSize = TextFieldAutoSize.LEFT;
			if(input_tf.height < text_scroll.h){
				//turn off auto sizing and set the TF height
				input_tf.autoSize = TextFieldAutoSize.NONE;
				input_tf.height = INPUT_H - PADD;
			}
			
			updateSendButton();
			
			//this will make sure the caret is always in view while editing
			text_scroll.updateHandleWithInputText(input_tf);
			text_scroll.refreshAfterBodySizeChange();
		}
		
		private function onSendClick(event:TSEvent):void {
			if(send_bt.disabled) return;
			
			//figure out if we are sending the itemstack or the class
			const itemstack:Itemstack = model.worldModel.getItemstackByTsid(item_slot.itemstack_tsid);
			
			var item_class:String = '';
			var itemstack_tsid:String = '';
			
			if (itemstack && itemstack.slots && model.worldModel.getItemstacksInContainerTsid(itemstack.tsid).length) {
				TSFrontController.instance.quickConfirm('Tricky! But you can\'t mail bags with stuff inside!');
				return;
			}
			
			send_bt.disabled = true;
			
			//only some
			if(itemstack && item_slot.count != itemstack.count){
				item_class = itemstack.class_tsid;
			}
			//whole thing
			else if(itemstack) {
				itemstack_tsid = item_slot.itemstack_tsid;
			}
			
			//fire it off to the server
			MailManager.instance.send(
				current_message.sender_tsid, 
				input_tf.text, 
				itemstack_tsid, 
				currants_qp.value,
				item_class, 
				item_slot.count, 
				current_message.message_id
			);
		}
		
		private function onCancelClick(event:TSEvent):void {
			if(cancel_bt.disabled) return;
			
			hide(true);
		}
		
		private function onCurrantsChange(event:TSEvent):void {
			if(!visible) return;
			
			updateSendButton();
			
			//let the server know
			MailManager.instance.requestCost(item_slot.itemstack_tsid, item_slot.count, currants_qp.value);
		}
		
		private function onCurrantsFocusOut(event:TSEvent = null):void {
			//check to make sure we still have the right amount of currants
			const pc:PC = model.worldModel.pc;
			var max_value:int = 999999;
			
			if(pc && pc.stats && pc.stats.currants < max_value){
				max_value = pc.stats.currants;
			}
			
			//set the max
			currants_qp.max_value = max_value;
			
			//do a check
			if(currants_qp.value > max_value) currants_qp.value = max_value;
			
			//see if we can send stuff
			updateSendButton();
		}
		
		override protected function onPackDragMove(event:MouseEvent):void {
			if(item_slot.hitTestObject(Cursor.instance.drag_DO)) {
				if(dragVO.target != item_slot) {
					drag_good = false;
					if(dragVO.target) dragVO.target.unhighlightOnDragOut();
					
					if (isDroppable()) {
						if (item_slot.itemstack_tsid){
							//we are replacing what is there with something else
							Cursor.instance.showTip('Change');
							drag_good = true;
						}
						else {
							//we are adding something new
							Cursor.instance.showTip('Add');
							drag_good = true;
							
							//light up the slot
							item_slot.highlightOnDragOver();
						}
					}
					
					//add a ref to the item slot in the target so we can check for it when we are done dragging
					dragVO.target = item_slot;
				}
			} 
			else if(dragVO.target == item_slot){
				//clear stuff out
				item_slot.unhighlightOnDragOut();
				dragVO.target = null;
				Cursor.instance.hideTip();
			}
		}
		
		override protected function onPackDragComplete(event:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(onPackDragMove);
			
			if(dragVO.target && dragVO.target is MailItemSlot && drag_good){
				//ask the server how much this is going to cost
				MailManager.instance.requestCost(dragVO.dragged_itemstack.tsid, dragVO.dragged_itemstack.count, currants_qp.value);
				
				//add this to the item slot
				item_slot.itemstack_tsid = dragVO.dragged_itemstack.tsid;
			}
			
			Cursor.instance.hideTip();
			item_slot.unhighlightOnDragOut();
		}
		
		private function onSlotChange(event:TSEvent):void {
			if(!visible) return;
			
			MailManager.instance.requestCost(item_slot.itemstack_tsid, item_slot.count, currants_qp.value);
		}
		
		override public function get height():Number {
			return masker.y + masker.height;
		}
	}
}