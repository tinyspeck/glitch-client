package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.mail.Mail;
	import com.tinyspeck.engine.data.mail.MailMessage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.mail.MailComposeUI;
	import com.tinyspeck.engine.view.ui.mail.MailDropdown;
	import com.tinyspeck.engine.view.ui.mail.MailInboxUI;
	import com.tinyspeck.engine.view.ui.mail.MailReadUI;
	import com.tinyspeck.engine.view.ui.mail.MailSentUI;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class MailDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:MailDialog = new MailDialog();
		
		public static const INBOX:String = 'inbox';
		public static const COMPOSE:String = 'compose';
		
		private static const UNREAD_RADIUS:Number = 8.5; //how big the circle is that shows unread messages
		
		private const receive_ids:Array = []; //allows us to receive multiple items from the dropdown
		private const delete_ids:Array = []; //allows us to delete multiple items from the dropdown
		
		private var compose_ui:MailComposeUI;
		private var sent_ui:MailSentUI;
		private var inbox_ui:MailInboxUI;
		private var read_ui:MailReadUI;
		private var back_bt:Button;
		private var compose_bt:Button;
		private var dropdown:MailDropdown = new MailDropdown();
		
		private var unread_holder:Sprite = new Sprite();
		private var compose_divider:Sprite = new Sprite();
		private var masker:Sprite = new Sprite();
		
		private var unread_tf:TextField = new TextField();
				
		private var is_built:Boolean;
		
		private var _current_state:String = INBOX;
		
		public function MailDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			_base_padd = 20;
			_head_min_h = 60;
			_body_min_h = 295;
			_body_max_h = 350;
			_body_border_c = 0xffffff;
			_body_fill_c = 0xffffff;
			_foot_min_h = 7;
			_w = 560;
			
			_draggable = true;
			
			_construct();
		}
		
		private function buildBase():void {
			//compose
			compose_ui = new MailComposeUI(_w);
			
			//sent success
			sent_ui = new MailSentUI(_w - _base_padd*4);
			sent_ui.x = _w*2 + _base_padd*2;
			sent_ui.y = _base_padd*3;
			sent_ui.addEventListener(TSEvent.CHANGED, onSentBackClick, false, 0, true);
			
			//inbox
			inbox_ui = new MailInboxUI(_w);
			inbox_ui.addEventListener(TSEvent.CHANGED, onMessageRead, false, 0, true);
			
			//read message
			read_ui = new MailReadUI(_w - _border_w*2, _body_min_h + _head_min_h + _foot_min_h - _base_padd);
			read_ui.y = 14;
			read_ui.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			
			//back button
			back_bt = makeBackBt();
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			
			var g:Graphics;
			
			//options dropdown
			dropdown.x = _base_padd;
			dropdown.y = _base_padd - 1;
			dropdown.addItem('Accept all items', onReceiveAllItems);
			dropdown.addItem('Delete all read messages', onDeleteAllRead);
			addChild(dropdown);
			
			//compose
			compose_bt = new Button({
				name: 'compose_bt',
				graphic: new AssetManager.instance.assets.mail_compose(),
				graphic_hover: new AssetManager.instance.assets.mail_compose_hover(),
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				w: 36,
				h: 28,
				tip: {txt:'Write a new message', pointer:WindowBorder.POINTER_BOTTOM_CENTER}
			});
			compose_bt.addEventListener(TSEvent.CHANGED, onComposeClick, false, 0, true);
			addChild(compose_bt);
			
			//listen for when it's closed
			compose_ui.addEventListener(TSEvent.CLOSE, onBackClick, false, 0, true);
			
			//draw the divider
			g = compose_divider.graphics;
			g.beginFill(0xdfdfdf);
			g.drawRect(0, 0, 1, 32);
			addChild(compose_divider);
			
			//put the read UI on the dialog instead of the scroll body
			addChild(read_ui);
			
			//add the mask
			g = masker.graphics;
			g.beginFill(0);
			g.drawRoundRect(_border_w, _border_w, _w - _border_w*2, _body_min_h + _head_min_h + _foot_min_h - _border_w*4, window_border.corner_rad);
			read_ui.mask = masker;
			addChild(masker);
			
			//hide the dialog scroller handle/bar
			_scroller.never_show_bars = true;
			
			//unread messages
			g = unread_holder.graphics;
			g.lineStyle(2, 0xffffff);
			g.beginFill(0xa8031d);
			g.drawCircle(UNREAD_RADIUS, UNREAD_RADIUS, UNREAD_RADIUS+1);
			
			TFUtil.prepTF(unread_tf);
			unread_tf.width = UNREAD_RADIUS*2;
			unread_holder.addChild(unread_tf);
			unread_holder.mouseEnabled = unread_holder.mouseChildren = false;
			addChildAt(unread_holder, getChildIndex(_head_sp));
			
			//keep the back button on top
			addChild(back_bt);
			
			is_built = true;
		}
		
		override public function start():void {
			//make sure we have mail to show
			if(current_state == INBOX && !MailManager.instance.mail){
				CONFIG::debugging {
					Console.warn('MailManager doesn\'t have any mail. WTF');
				}
				return;
			}
			
			if(!canStart(true)) return;
			if(!is_built) buildBase();

			super.start();
			
			//show the proper state
			showState();
			
			showWarning();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//if we are in read mode, make sure the current message gets archived/deleted if need be
			if(read_ui.visible && read_ui.message_id){
				const message:MailMessage = MailManager.instance.mail.getMessageById(read_ui.message_id);
				if(message && !read_ui.delete_bt.disabled){
					if(message.is_auction){
						//an auction, but we've already got the attachements. Pretty much junk now
						MailManager.instance.remove([message.message_id], false);
					}
					else {
						//archive it
						MailManager.instance.archive(message.message_id, false);
					}
				}
			}
			
			//archive any that we have sitting
			MailManager.instance.sendArchiveToServer();
			
			//let the server know we closed the window
			MailManager.instance.cancel();
			
			//reset the state back to the inbox
			current_state = INBOX;
			
			//clean up
			compose_ui.hide();
			inbox_ui.hide();
			read_ui.hide();
			sent_ui.hide();
		}
		
		public function update():void {
			if(!parent) return;
			if(!is_built) buildBase();
			
			//if we are in read mode
			if(current_state == INBOX){
				showUnreadCount();
				
				if(inbox_ui) inbox_ui.update();
			}
		}
		
		public function sendStatus(is_success:Boolean):void {
			if(!parent) return;
			if(!sent_ui) return;
			
			if(is_success){
				//animate the sent UI in
				TSTweener.addTween(_scroller.body, {x:-_w*2, time:.5});
				
				//zoom the read ui off to the left
				TSTweener.addTween(read_ui, {x:-_w, time:.5});
				
				//hide the title/dropdown
				_setTitle(' ');
				dropdown.visible = false;
				
				//the sent message
				sent_ui.show('Head back to your inbox, just click the button below.', 'Back to your inbox');
				
				unread_holder.visible = false;
				
				//back bt
				back_bt.disabled = false;
				back_bt.visible = true;
				
				_scroller.body.addChild(sent_ui);
			}
			else if(compose_ui){
				//re-enable the send button
				compose_ui.sendFail();
			}
		}
		
		public function receiveStatus(is_success:Boolean):void {
			if(!parent) return;
			if(read_ui) read_ui.receiveStatus(is_success);
			if(is_success) update();
		}
		
		public function removeStatus(is_success:Boolean):void {
			if(!parent) return;
			
			if(is_success){
				//show the inbox
				showInbox(true);
				
				//animate
				TSTweener.addTween(_scroller.body, {x:0, time:.5, onComplete:showWarning});
				
				//if we are in read mode, move that sucker outta there
				if(read_ui){
					TSTweener.addTween(read_ui, {x:_w + _base_padd, time:.5});
				}
				
				back_bt.visible = false;
			}
			else if(read_ui && read_ui.delete_bt){
				//re-enable the delete button
				read_ui.delete_bt.disabled = false;
			}
		}
		
		public function archiveStatus(is_success:Boolean, count:uint = 0):void {
			if(!parent) return;
			
			if(is_success){
				//show the inbox
				showInbox(true);
				
				//animate
				TSTweener.addTween(_scroller.body, 
					{
						x:0, 
						time:.5, 
						onComplete:inbox_ui.showWarning, 
						onCompleteParams:['Your '+(count > 1 ? 'messages have' : 'message has')+' been moved to the archives']
					}
				);
				
				//if we are in read mode, move that sucker outta there
				if(read_ui){
					TSTweener.addTween(read_ui, {x:_w + _base_padd, time:.5});
				}
				
				back_bt.visible = false;
			}
		}
		
		private function showState():void {
			//if we are here without being built somehow...
			if(!is_built) buildBase();
			
			//remove everything out of the scroller body
			//SpriteUtil.clean(_scroller.body, false);
			_scroller.body.x = 0;
			_scroller.bar.visible = false;
			back_bt.visible = false;
			
			if(current_state == INBOX){
				showInbox(false);
			}
			else if(current_state == COMPOSE){
				showCompose();
			}
			
			_scroller.refreshAfterBodySizeChange(true);
		}
		
		private function showInbox(animate:Boolean):void {
			_setTitle('Messages Inbox');
			//_setSubtitle('');
						
			//show
			inbox_ui.show(!animate);
			sent_ui.hide();
			if(!animate){
				read_ui.hide();
				read_ui.x = _w + _base_padd;
			}
			
			//set the tip
			back_bt.tip = { txt:'Back to messages', pointer:WindowBorder.POINTER_BOTTOM_CENTER };
			
			//place the indicator
			showUnreadCount();

			_scroller.body.addChild(inbox_ui);
			
			dropdown.visible = true;
			compose_bt.visible = true;
			compose_divider.visible = true;
			
			update();
			
			//see if we have any messages that need archiving
			MailManager.instance.sendArchiveToServer();
		}
		
		private function showCompose():void {
			_setTitle('New Message');
			//_setSubtitle('G.I.G.P.D.S. introductory special on standard delivery rates: only '+MailManager.instance.regular_cost+'₡!');
			
			//show
			compose_ui.show();
			read_ui.hide();
			
			//hide the indicator
			unread_holder.visible = false;
			
			//handle things different with the new UI
			compose_bt.visible = false;
			compose_divider.visible = false;
			dropdown.visible = false;
			back_bt.visible = true;
			back_bt.tip = { txt:'Inbox', pointer:WindowBorder.POINTER_BOTTOM_CENTER };
			compose_ui.x = _w;
			
			//animate
			TSTweener.addTween(_scroller.body, {x:-_w, time:.5});
			
			_scroller.body.addChild(compose_ui);
		}
		
		private function showUnreadCount():void {
			const unread_count:uint = MailManager.instance.mail ? MailManager.instance.mail.getUnreadCount() : 0;
			unread_holder.visible = unread_count > 0;
			
			//the read UI needs to know too!
			read_ui.unread_count = unread_count;
			
			if(unread_count){
				unread_tf.htmlText = '<p class="mail_inbox_unread">'+(unread_count <= 99 ? unread_count : '∞')+'</p>';
			}
		}
		
		private function showWarning():void {
			//show a warning if they have more messages than what is viewable
			if(current_state == INBOX){
				const mail:Mail = MailManager.instance.mail;
				const total:int = mail.message_count - mail.messages.length;
				if(total > 0){
					inbox_ui.showWarning(
						'You still have '+StringUtil.formatNumberWithCommas(total)+' more '+(total != 1 ? 'messages' : 'message')+'. '+
						'These are the latest '+StringUtil.formatNumberWithCommas(mail.messages.length)+'.'
					);
				}
			}
		}
		
		override protected function _jigger():void {
			//figure out if we need the gap or not
			_title_padd_left = dropdown && dropdown.visible ? 60 : 25;
			
			//do the jig
			super._jigger();
			
			//setup the sizes
			_title_tf.y += 1;
			_body_h = current_state == INBOX ? inbox_ui.height : _body_max_h;
			_h = _head_h + _body_h + _foot_h;
			_scroller.h = _body_h + _divider_h*4;
			_scroller.refreshAfterBodySizeChange();
			
			//move the unread indicator
			unread_holder.x = int(_title_tf.x + _title_tf.width + 6);
			unread_holder.y = int(_head_min_h/2 - UNREAD_RADIUS) + 3.5;
			
			compose_divider.x = _close_bt.x - 5;
			compose_divider.y = int(_close_bt.y + (_close_bt.height/2 - compose_divider.height/2) + 1);
			
			compose_bt.x = int(_close_bt.x - compose_bt.width - 17);
			compose_bt.y = int(_close_bt.y + (_close_bt.height/2 - compose_bt.height/2));
			
			_draw();
		}
		
		private function onSentBackClick(event:TSEvent):void {
			//back to the inbox
			back_bt.visible = false;
			
			onBackClick(event);
		}
		
		private function onMessageRead(event:TSEvent):void {
			var message:MailMessage = MailManager.instance.mail.getMessageById(event.data);
			
			//tell the server we are reading this message
			if(message && !message.is_read){
				MailManager.instance.read([message.message_id], false);
			}
			
			//animate and show
			if(message){
				sent_ui.hide();
				read_ui.show(message);
				TSTweener.addTween(_scroller.body, {x:-_w, time:.5});
				
				//hide it altogether because the new read UI has a different size, etc...
				unread_holder.visible = false;
				
				//hide the toast
				inbox_ui.hideWarning();
				
				//animate the message in
				read_ui.x = _w + _base_padd;
				TSTweener.addTween(read_ui, {x:_border_w, time:.5});
				
				//hide the dropdown
				dropdown.visible = false;
				
				//back bt
				back_bt.disabled = false;
				//back_bt.visible = true;
			}
		}
		
		private function onComposeClick(event:TSEvent):void {
			//show the compose screen
			current_state = COMPOSE;
			showState();
		}
		
		private function onBackClick(event:TSEvent):void {
			if(back_bt.disabled) return;
			back_bt.disabled = true;
			
			_current_state = INBOX;
			
			//reset the read_ui
			TSTweener.addTween(read_ui, {x:_w + _base_padd, time:.5});
			
			_jigger();
			
			showInbox(true);
			
			//animate
			TSTweener.addTween(_scroller.body, {x:0, time:.5, 
				onComplete:function():void {
					back_bt.disabled = false;
					back_bt.visible = false;
					
					compose_ui.hide();
					if(compose_ui.parent) compose_ui.parent.removeChild(compose_ui);
					_scroller.refreshAfterBodySizeChange();
					
					//see if we have any new messages
					MailManager.instance.check();
				}
			});
		}
		
		private function onReceiveAllItems():void {
			//tell the server we want the whole shabaz
			const messages:Vector.<MailMessage> = MailManager.instance.messages;
			if(!messages){
				CONFIG::debugging {
					Console.warn('No messages?! Not good.');
				}
				return;
			}
			
			var i:int;
			var total:int = messages.length;
			var message:MailMessage;
			
			receive_ids.length = 0;
			
			for(i; i < total; i++){
				message = messages[int(i)];
				if(message.item || message.currants){
					receive_ids.push(message.message_id);
				}
			}
			
			//off to the server you go!
			if(receive_ids.length){
				MailManager.instance.receiveAttachements(receive_ids);
			}
		}
		
		private function onDeleteAllRead():void {
			//confirm that this is what they want to do
			const messages:Vector.<MailMessage> = MailManager.instance.messages;
			if(!messages){
				CONFIG::debugging {
					Console.warn('No messages?! Not good.');
				}
				return;
			}
			
			//open a confirmation dialog
			TSFrontController.instance.confirm(
				new ConfirmationDialogVO(
					onDeleteAllConfirm,
					'Are you sure you want to delete all your read messages?',
					[
						{value: false, label: 'Never mind'},
						{value: true, label: 'Yes, I\'d like to delete them'}
					],
					false
				)
			);
		}
		
		private function onDeleteAllConfirm(value:*):void {
			if(value === true){
				const messages:Vector.<MailMessage> = MailManager.instance.messages;
				var i:int;
				var total:int = messages.length;
				var message:MailMessage;
				var attachment_count:int;
				
				delete_ids.length = 0;
				
				for(i; i < total; i++){
					message = messages[int(i)];
					if(message.is_read){
						//if we have an item or currants, we can't delete this yet
						if(message.item || message.currants){
							attachment_count++;
						}
						else {
							delete_ids.push(message.message_id);
						}
					}
				}
				
				//if there were any that still had attachements, throw up the toast
				if(attachment_count && inbox_ui){
					inbox_ui.showWarning(attachment_count+(attachment_count != 1 ? ' messages' : ' message')+' could not be deleted because '+(attachment_count != 1 ? 'they contain' : 'it contains')+' attachments!');
				}
				
				//off to the server you go!
				if(delete_ids.length){
					MailManager.instance.remove(delete_ids);
				}
			}
		}
		
		public function get current_state():String { return _current_state; }
		public function set current_state(value:String):void {
			_current_state = value;
			if(parent) showState();
		}
	}
}