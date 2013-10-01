package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.mail.MailMessage;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.MailDialog;
	import com.tinyspeck.engine.port.MailManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.ui.making.MakingSlot;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class MailReadUI extends TSSpriteWithModel
	{
		private static const SENDER_X:uint = 72;
		private static const HEADER_H:uint = 68;
		private static const ATTACHMENT_H:uint = 53;
		private static const AVATAR_H:uint = 100;
		private static const UNREAD_RADIUS:Number = 8.5;
		private static const OFFSET_X:uint = 113; //how far to indent things
		
		private var text_scroll:TSScroller;
		private var inbox_bt:Button;
		private var receive_bt:Button;
		private var prev_bt:Button;
		private var next_bt:Button;
		private var reply_bt:Button;
		private var close_bt:Button;
		private var item_slot:MakingSlot;
		private var currants_slot:MakingSlot;
		private var item:Item;
		private var frog_iiv:ItemIconView;
		private var reply_ui:MailReplyUI;
		private var replies_ui:MailRepliesUI;
		
		public var delete_bt:Button; //let's the button be enabled/disabled from the dialog
		
		private var attachment_holder:Sprite = new Sprite();
		private var avatar_holder:Sprite = new Sprite();
		private var unread_holder:Sprite = new Sprite();
		private var padder:Sprite = new Sprite();
		
		private var sender_label:TextField = new TextField();
		private var sender_tf:TSLinkedTextField = new TSLinkedTextField();
		private var received_label:TextField = new TextField();
		private var received_tf:TSLinkedTextField = new TSLinkedTextField();
		private var message_tf:TSLinkedTextField = new TSLinkedTextField();
		private var unread_tf:TextField = new TextField();
		private var archive_tf:TextField = new TextField();
		
		private var header_bg_color:uint = 0xe9f0f0;
		private var header_border_color:uint = 0xbfcccc;
		private var reply_border_color:uint = 0xdddddd;
		private var slot_wh:uint;
		
		private var current_message_id:String;
		
		private var can_reply:Boolean;
		
		public function MailReadUI(w:int, h:int){
			const cssm:CSSManager = CSSManager.instance;
			const corner_rad:int = cssm.getNumberValueFromStyle('button_default', 'cornerRadius', 4);
			var next_x:uint = 20;
			
			//setup the header/border colors
			header_bg_color = cssm.getUintColorValueFromStyle('mail_read_header', 'backgroundColor', header_bg_color);
			header_border_color = cssm.getUintColorValueFromStyle('mail_read_header', 'borderColor', header_border_color);
			reply_border_color = cssm.getUintColorValueFromStyle('mail_read_reply', 'borderColor', reply_border_color);
			
			_w = w;
			_h = h;
			
			//sender
			TFUtil.prepTF(sender_label, false);
			sender_label.htmlText = '<p class="mail_label">From</p>';
			sender_label.y = 8;
			addChild(sender_label);
			
			TFUtil.prepTF(sender_tf, false);
			sender_tf.x = SENDER_X;
			sender_tf.y = sender_label.y;
			addChild(sender_tf);
			
			//received
			TFUtil.prepTF(received_label);
			received_label.htmlText = '<p class="mail_label">Received</p>';
			received_label.y = int(sender_label.y + sender_label.height);
			addChild(received_label);
			
			TFUtil.prepTF(received_tf, false);
			received_tf.x = SENDER_X;
			received_tf.y = received_label.y;
			addChild(received_tf);
			
			//message scroll
			text_scroll = new TSScroller({
				name: 'text_scroll',
				bar_wh: 12,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 36,
				scrolltrack_always: false,
				use_auto_scroll: false,
				show_arrows: true,
				use_children_for_body_h: true,
				w: w - OFFSET_X - 4,
				h: MailComposeUI.TEXT_HEIGHT
			});
			text_scroll.x = OFFSET_X;
			text_scroll.y = HEADER_H + 4;
			addChild(text_scroll);
			
			TFUtil.prepTF(message_tf);
			message_tf.selectable = true;
			message_tf.width = text_scroll.w - 15;
			text_scroll.body.addChild(message_tf);
			
			//attachements
			addChild(attachment_holder);
			
			//item holder
			slot_wh = 35;
			item_slot = new MakingSlot(slot_wh, slot_wh);
			item_slot.qty_picker.y = 0;
			item_slot.x = OFFSET_X;
			item_slot.icon_padd = 7;
			
			attachment_holder.addChild(item_slot);
			
			//currants holder
			currants_slot = new MakingSlot(slot_wh, slot_wh);
			var icon:DisplayObject = new AssetManager.instance.assets.item_info_currants();
			
			if(icon){
				icon.x = -2;
				icon.y = -7;
				currants_slot.icon_sprite.addChild(icon);
			}
			currants_slot.close_button.visible = false;
			currants_slot.qty_picker.y = 0;
			
			attachment_holder.addChild(currants_slot);
			
			//inbox button
			inbox_bt = new Button({
				name: 'inbox',
				label: 'Inbox',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				graphic: new AssetManager.instance.assets.mail_inbox_back(),
				graphic_hover: new AssetManager.instance.assets.mail_inbox_back_hover(),
				graphic_placement: 'left',
				graphic_padd_l: 10,
				graphic_padd_r: 2,
				x: next_x
			});
			inbox_bt.y = int(HEADER_H/2 - inbox_bt.height/2);
			inbox_bt.addEventListener(TSEvent.CHANGED, onInboxClick, false, 0, true);
			next_x += inbox_bt.width + 10;
			addChild(inbox_bt);
			
			//receive button
			receive_bt = new Button({
				name: 'receive',
				label: 'Take Attachments',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			receive_bt.y = int(item_slot.y + (MailComposeUI.SLOT_WH-receive_bt.height)/2) - 1;
			receive_bt.addEventListener(TSEvent.CHANGED, onReceiveClick, false, 0, true);
			attachment_holder.addChild(receive_bt);
			
			//prev/next buttons
			var arrow:DisplayObject = new AssetManager.instance.assets.back_arrow();
			var arrow_hover:DisplayObject = new AssetManager.instance.assets.back_arrow_hover();
			var arrow_disabled:DisplayObject = new AssetManager.instance.assets.back_arrow_disabled();
			arrow.rotation = arrow_hover.rotation = arrow_disabled.rotation = -90;
			
			prev_bt = new Button({
				name: 'prev',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				graphic: arrow,
				graphic_hover: arrow_hover,
				graphic_disabled: arrow_disabled,
				graphic_padd_w: 7,
				graphic_padd_t: 25,
				w: 19,
				x: next_x,
				y: inbox_bt.y
			});
			prev_bt.setCornerRadius(corner_rad, 0, corner_rad, 0);
			prev_bt.addEventListener(MouseEvent.ROLL_OVER, onNavOver, false, 0, true);
			prev_bt.addEventListener(MouseEvent.CLICK, onNavClick, false, 0, true);
			next_x += prev_bt.width;
			addChild(prev_bt);
			
			arrow = new AssetManager.instance.assets.back_arrow();
			arrow_hover = new AssetManager.instance.assets.back_arrow_hover();
			arrow_disabled = new AssetManager.instance.assets.back_arrow_disabled();
			arrow.rotation = arrow_hover.rotation = arrow_disabled.rotation = 90;
			
			next_bt = new Button({
				name: 'next',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				graphic: arrow,
				graphic_hover: arrow_hover,
				graphic_disabled: arrow_disabled,
				graphic_padd_w: 13,
				graphic_padd_t: 15,
				w: 19,
				x: next_x - 1,
				y: inbox_bt.y
			});
			next_bt.setCornerRadius(0, corner_rad, 0, corner_rad);
			next_bt.addEventListener(MouseEvent.ROLL_OVER, onNavOver, false, 0, true);
			next_bt.addEventListener(MouseEvent.CLICK, onNavClick, false, 0, true);
			next_x += next_bt.width + 10;
			addChild(next_bt);
			
			//delete button
			delete_bt = new Button({
				name: 'delete',
				graphic: new AssetManager.instance.assets.mail_trash_read(),
				graphic_hover: new AssetManager.instance.assets.mail_trash_read_hover(),
				graphic_disabled: new AssetManager.instance.assets.mail_trash(),
				graphic_padd_w: 13,
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: 40,
				x: next_x,
				y: inbox_bt.y
			});
			delete_bt.addEventListener(TSEvent.CHANGED, onDeleteClick, false, 0, true);
			next_x += delete_bt.width + 10;
			addChild(delete_bt);
			
			//archive text
			TFUtil.prepTF(archive_tf);
			archive_tf.wordWrap = false;
			archive_tf.htmlText = '<p class="mail_read_archive">This message will be automatically archived<br>unless you delete it</p>';
			archive_tf.x = next_x;
			archive_tf.y = int(HEADER_H/2 - archive_tf.height/2 + 2);
			addChild(archive_tf);
			
			//let the background not be mouse enabled so we can drag the window better
			mouseEnabled = false;
			
			//draw the header
			var g:Graphics = graphics;
			g.beginFill(header_bg_color);
			g.drawRect(0, 0, _w, HEADER_H);
			g.beginFill(header_border_color);
			g.drawRect(0, 0, _w, 1);
			g.drawRect(0, HEADER_H-1, _w, 1);
			
			//draw the attachment holder
			g = attachment_holder.graphics;
			g.beginFill(0xffffff);
			g.drawRect(0, 0, _w, ATTACHMENT_H);
			g.beginFill(reply_border_color);
			g.drawRect(0, 0, _w, 1);
			attachment_holder.y = _h - attachment_holder.height;
			
			//center the item/currant holders
			item_slot.y = int(attachment_holder.height/2 - slot_wh/2);
			currants_slot.y = item_slot.y;
			receive_bt.h = slot_wh;
			receive_bt.y = item_slot.y;
			
			//place the text into the scroller
			text_scroll.body.addChild(sender_label);
			text_scroll.body.addChild(sender_tf);
			text_scroll.body.addChild(received_label);
			text_scroll.body.addChild(received_tf);
			
			//add the avatar holder
			avatar_holder.y = HEADER_H;
			addChild(avatar_holder);
			
			//move the message tf down
			message_tf.y = received_label.y + received_label.height + 2;
			
			//the reply UI
			reply_bt = new Button({
				name: 'reply',
				label: 'Reply',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			reply_bt.addEventListener(TSEvent.CHANGED, onReplyClick, false, 0, true);
			text_scroll.body.addChild(reply_bt);
			
			reply_ui = new MailReplyUI(message_tf.width - 10);
			reply_ui.addEventListener(TSEvent.CHANGED, onReplySizeChange, false, 0, true);
			reply_ui.x = 1;
			reply_ui.hide();
			text_scroll.body.addChild(reply_ui);
			
			//a padder for below the reply button
			g = padder.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, 10, 10);
			text_scroll.body.addChild(padder);
			
			//holder for any message replies
			replies_ui = new MailRepliesUI(message_tf.width - 10);
			text_scroll.body.addChild(replies_ui);
			
			//unread messages
			g = unread_holder.graphics;
			g.beginFill(0xa8031d);
			g.drawCircle(UNREAD_RADIUS, UNREAD_RADIUS, UNREAD_RADIUS+1);
			
			TFUtil.prepTF(unread_tf);
			unread_tf.width = UNREAD_RADIUS*2;
			//unread_tf.x = -1;
			unread_tf.y = .4;
			unread_holder.addChild(unread_tf);
			unread_holder.mouseEnabled = unread_holder.mouseChildren = false;
			unread_holder.x = int(inbox_bt.width - UNREAD_RADIUS -3);
			unread_holder.y = -3;
			inbox_bt.addChild(unread_holder);
			
			//close button (borrowed from Dialog.as)
			const close_wh:uint = 30;
			const nudge:int = 2 - (close_wh % 2);
			const leg:int = nudge+(close_wh-10)/2;
			var sp:Sprite = new Sprite();
			g = sp.graphics;
			g.lineStyle(3, 0xc33823, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			g.moveTo(nudge, nudge);
			g.lineTo(leg, leg);
			g.moveTo(nudge, leg);
			g.lineTo(leg, nudge);
			
			close_bt = new Button({
				graphic: sp,
				name: '_close_bt',
				draw_alpha: 0,
				h: close_wh,
				w: close_wh
			});
			close_bt.x = _w - 15 - close_wh;
			close_bt.y = int(HEADER_H/2 - close_wh/2 - 1); //-1 for the border
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			addChild(close_bt);
		}
		
		public function show(message:MailMessage):void {
			if(!message) return;
			
			current_message_id = message.message_id;
			can_reply = message.sender_tsid != null;
			
			const pc:PC = message.sender_tsid ? model.worldModel.getPCByTsid(message.sender_tsid) : null;
			
			//load the frog in the event we don't have a sender
			if(!pc){
				while(avatar_holder.numChildren) avatar_holder.removeChildAt(0);
				if(!frog_iiv) {
					frog_iiv = new ItemIconView('npc_yoga_frog', AVATAR_H, 'treePose');
					frog_iiv.x = 8;
					frog_iiv.y = 15;
				}
				avatar_holder.addChild(frog_iiv);
			}
			else {
				//remove the frog if he's there
				if(frog_iiv && avatar_holder.contains(frog_iiv)) avatar_holder.removeChild(frog_iiv);
				
				//load the sender's image
				SpriteUtil.clean(avatar_holder);
				if(pc.singles_url){
					AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_'+AVATAR_H+'.png', onAvatarComplete, 'Loading image for mail');
				}
			}
			
			//sender
			var sender_txt:String = 'G.I.G.P.D.S.';
			sender_tf.embedFonts = true;
			if(pc){
				sender_txt = pc.label;
				const vag_ok:Boolean = StringUtil.VagCanRender(sender_txt);
				if(!vag_ok){
					sender_txt = '<font face="Arial">'+sender_txt+'</font>';
					sender_tf.embedFonts = false;
				}
				sender_txt = '<a href="event:'+TSLinkedTextField.LINK_PC+'|'+pc.tsid+'">'+sender_txt+'</a>';
			}
			sender_tf.htmlText = '<p class="mail_label">'+sender_txt+'</p>';
			
			//received
			received_tf.text = '';
			if(message.received){
				received_tf.htmlText = '<p class="mail_body">'+StringUtil.getTimeFromUnixTimestamp(message.received, false, false)+'</p>';
			}
			
			//message text
			message_tf.text = '';
			if(message.text){
				var message_height:int;
				message_tf.autoSize = TextFieldAutoSize.LEFT;
				message_tf.htmlText = '<p class="mail_body">'+message.text+'</p>';
				message_height = message_tf.height;
				message_tf.autoSize = TextFieldAutoSize.NONE;
				message_tf.height = message_height + 6;
			}
			
			//place the reply button
			reply_bt.visible = message.sender_tsid != null;
			reply_ui.hide();
			
			//set the prev/next
			var index:int = MailManager.instance.messages.indexOf(message);
			
			prev_bt.disabled = index == 0;
			prev_bt.value = index;
			
			next_bt.disabled = index == MailManager.instance.messages.length-1;
			next_bt.value = index;
			
			//just in case the message is viewed via the arrows and is marked as not being read, let's do that
			if(!message.is_read){
				MailManager.instance.read([current_message_id], false);
			}
			
			//hide the archive text if this is an auction
			archive_tf.visible = !message.is_auction;
			
			jigger();
			
			visible = true;
		}
		
		private function jigger():void {
			const message:MailMessage = MailManager.instance.mail.getMessageById(current_message_id);
			if(!message) return;
			
			//place the reply button
			reply_bt.y = int(message_tf.y + message_tf.height + 3);
			reply_ui.y = reply_bt.y;
			
			//toss the padder in there
			padder.y = int(reply_bt.y + reply_bt.height);
			
			if(message.in_reply_to != null){
				replies_ui.show(message);
				replies_ui.y = reply_ui.y +(Math.max(reply_bt.height, reply_ui.height))+ 14;
			}
			else {
				replies_ui.hide();
				replies_ui.y = 0;
			}
			
			//item
			item_slot.visible = false;
			if(message.item){
				item = model.worldModel.getItemByTsid(message.item.class_tsid);
				if(item){
					var item_label:String = message.item.count != 1 ? item.label_plural : item.label;
					var furn_config:FurnitureConfig = (message.item.config && message.item.config.furniture) ? FurnitureConfig.fromAnonymous(message.item.config.furniture, '') : null
					item_slot.update(message.item.class_tsid, message.item.count, false, true, furn_config);
					
					//if the item has hit points, show it
					if(message.item.points_capacity > 0){
						item_slot.update_tool(message.item.points_capacity, message.item.points_remaining, message.item.is_broken);
						item_label += ' ('+message.item.points_remaining+'/'+message.item.points_capacity+')';
					}
					
					item_slot.item_label = item_label;
					item_slot.visible = true;
					item_slot.count_tf.htmlText = 
						message.item.count > 1 
						? '<p class="trade_slot_label"><span class="mail_read_slot">'+StringUtil.crunchNumber(message.item.count)+'</span></p>' 
						: '';
					item_slot.count_tf.x = int(slot_wh/2 - item_slot.count_tf.width/2);
					item_slot.count_tf.y = int(item_slot.h - item_slot.count_tf.height);
					
					if(message.item.count > 1 || message.item.points_capacity > 0){
						item_slot.icon_sprite.y = 3;
					}
					else {
						item_slot.icon_sprite.y = 6;
					}
				}
			}
			
			//currants
			currants_slot.visible = false;
			currants_slot.x = int(item_slot.visible && message.currants ? item_slot.x + slot_wh + 7 : item_slot.x);
			if(message.currants){
				currants_slot.visible = true;
				currants_slot.update(null, message.currants, false, true);
				currants_slot.item_label = message.currants != 1 ? 'Currants' : 'Currant';
				currants_slot.count_tf.htmlText = '<p class="trade_slot_label"><span class="mail_read_slot">'+
												  StringUtil.crunchNumber(message.currants)+'</span></p>';
				currants_slot.count_tf.x = int(slot_wh/2 - currants_slot.count_tf.width/2);
				currants_slot.count_tf.y = slot_wh - 13;
			}
			
			//do they have any attachments?
			receive_bt.x = int(currants_slot.x + slot_wh + 7);
			receive_bt.disabled = false;
			receive_bt.visible = message.currants || message.item ? true : false;
			attachment_holder.visible = receive_bt.visible;
			
			text_scroll.h = _h - text_scroll.y + (!attachment_holder.visible ? -4 : -attachment_holder.height-2);
			text_scroll.refreshAfterBodySizeChange(true);
			
			//set the delete button
			delete_bt.disabled = receive_bt.visible;
			delete_bt.tip = delete_bt.disabled ? { txt:'You still have attachments!', pointer:WindowBorder.POINTER_BOTTOM_CENTER } : null;
		}
		
		public function receiveStatus(is_success:Boolean):void {
			receive_bt.disabled = false;
			
			//move the delete button
			delete_bt.disabled = !is_success;
			delete_bt.tip = delete_bt.disabled ? { txt:'You still have attachments!', pointer:WindowBorder.POINTER_BOTTOM_CENTER } : null;
			
			//did they take em?
			attachment_holder.visible = !is_success;
			
			jigger();
		}
		
		public function hide():void {
			visible = false;
		}
		
		private function archiveCurrentMessage():void {
			//tell the server we want to archive/delete this message
			const message:MailMessage = MailManager.instance.mail.getMessageById(current_message_id);
			if(message && !delete_bt.disabled){
				if(message.is_auction){
					//an auction, but we've already got the attachements. Pretty much junk now
					onDeleteConfirm(true);
				}
				else {
					//archive it
					MailManager.instance.archive(current_message_id);
				}
			}
		}
		
		public function set unread_count(value:int):void {
			//used in the new UI since it has it's own
			const unread_count:uint = MailManager.instance.mail ? MailManager.instance.mail.getUnreadCount() : 0;
			unread_holder.visible = unread_count > 0;
			
			if(unread_count){
				unread_tf.htmlText = '<p class="mail_inbox_unread">'+(unread_count <= 99 ? unread_count : '8')+'</p>';
			}
		}
		
		private function onInboxClick(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
			
			archiveCurrentMessage();
		}
		
		private function onReceiveClick(event:TSEvent):void {
			if(receive_bt.disabled) return;
			receive_bt.disabled = true;
			
			//tell the server we wants our precious
			MailManager.instance.receiveAttachements([current_message_id]);
		}
		
		private function onDeleteClick(event:TSEvent):void {
			if(delete_bt.disabled) return;
			delete_bt.disabled = true;
			
			//confirm before deleting
			TSFrontController.instance.confirm(
				new ConfirmationDialogVO(
					onDeleteConfirm,
					'Are you sure you want to delete this message?',
					[
						{value: false, label: 'Never mind'},
						{value: true, label: 'Yes, I\'d like to delete it'}
					],
					false
				)
			);
		}
		
		private function onDeleteConfirm(value:*):void {
			if(value === true){
				MailManager.instance.remove([current_message_id]);
			}
			else {
				delete_bt.disabled = false;
			}
		}
		
		private function onNavOver(event:MouseEvent):void {
			//make sure it's on top of the other so the border doesn't look stupid
			if(prev_bt.parent){
				prev_bt.parent.setChildIndex(Button(event.currentTarget), prev_bt.parent.numChildren-1);
			}
		}
		
		private function onNavClick(event:MouseEvent):void {
			//load the next/prev message
			var bt:Button = event.currentTarget as Button;
			const messages:Vector.<MailMessage> = MailManager.instance.messages;
			if(!messages) return;
			if(!bt || (bt && bt.disabled)) return;
			
			//disable it for the nano-second it takes to render the message
			bt.disabled = true;
			
			//archive the current message if we can
			archiveCurrentMessage();
			
			//which button?
			show(messages[int(bt.value)+(bt == next_bt ? 1 : -1)]);
		}
		
		private function onReplyClick(event:TSEvent):void {
			//show the reply ui
			reply_ui.show(current_message_id);
			reply_bt.visible = false;
		}
		
		private function onReplySizeChange(event:TSEvent):void {
			text_scroll.refreshAfterBodySizeChange();
			
			//move the scroller to the reply ui after it's done animating
			text_scroll.scrollYToTop(reply_ui.y - 10);
			
			//move the message replies to where they need to go
			if(replies_ui.visible) replies_ui.y = reply_ui.y +(Math.max(reply_bt.height, reply_ui.height))+ 14;
			
			//if we are hiding the UI, let's make sure we can show the reply button
			if(can_reply && reply_ui.height < 1 && !reply_bt.visible){
				reply_bt.visible = true;
				reply_bt.alpha = 0;
				TSTweener.addTween(reply_bt, {alpha:1, time:.35, delay:.1, transition:'linear'});
			}
		}
		
		private function onAvatarComplete(filename:String, bm:Bitmap):void {
			//flip it and slap it in the holder
			bm.scaleX = -1;
			bm.x = bm.width;
			avatar_holder.addChild(bm);
		}
		
		private function onCloseClick(event:TSEvent):void {
			MailDialog.instance.end(true);
		}
		
		public function get message_id():String { return current_message_id; }
	}
}
