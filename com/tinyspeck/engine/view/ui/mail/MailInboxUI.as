package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.mail.MailMessage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.MailDialog;
	import com.tinyspeck.engine.port.MailManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.ui.Toast;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class MailInboxUI extends TSSpriteWithModel
	{
		private static const SCROLL_HEIGHT:uint = 265;
		private static const TOAST_H:uint = 26;
		
		private var scroller:TSScroller;
		private var ok_bt:Button;
		private var mail_header:MailInboxHeaderUI;
		private var elements:Vector.<MailInboxElementUI> = new Vector.<MailInboxElementUI>();
		private var warning_toast:Toast;
		
		private var no_messages_tf:TextField = new TextField();
		private var archives_tf:TextField = new TextField();
		
		private var element_bumper:Sprite = new Sprite(); //scroller cuts off the bottom border
		private var archive_holder:Sprite = new Sprite();
		
		private var border_color:uint;
		private var bg_color:uint;
		private var hover_color:uint;
		
		public function MailInboxUI(w:int){
			_w = w;
			
			//header
			mail_header = new MailInboxHeaderUI(w);
			addChild(mail_header);
			
			//scroller
			scroller = new TSScroller({
				name: 'scroller',
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
				h: SCROLL_HEIGHT
			});
			scroller.y = mail_header.height + 2;
			addChild(scroller);
			
			//bumper
			scroller.body.addChild(element_bumper);
			
			//no messages
			TFUtil.prepTF(no_messages_tf);
			no_messages_tf.width = _w;
			no_messages_tf.htmlText = '<p class="mail_inbox_no_messages">You have no more messages.</p>';
			no_messages_tf.y = 70;
			addChild(no_messages_tf);
			
			//ok button
			ok_bt = new Button({
				name: 'ok',
				label: 'OK!',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				y: int(no_messages_tf.y + no_messages_tf.height + 30)
			});
			ok_bt.x = int(_w/2 - ok_bt.width/2);
			ok_bt.addEventListener(TSEvent.CHANGED, onOkClick, false, 0, true);
			addChild(ok_bt);
			
			//draw colors
			border_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox', 'borderColor', 0xcbcbcb);
			bg_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox', 'backgroundColor', 0xececec);
			hover_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_hover', 'backgroundColor', 0xdfdfdf);
			
			//toast
			const toast_x:int = 27;
			warning_toast = new Toast(_w - toast_x - 31, Toast.TYPE_WARNING, '', Toast.DIRECTION_DOWN);
			warning_toast.x = toast_x;
			warning_toast.y = int(mail_header.y + mail_header.height);
			warning_toast.h = TOAST_H;
			warning_toast.addEventListener(TSEvent.CHANGED, onToastChange, false, 0, true);
			addChild(warning_toast);
			
			//archive
			TFUtil.prepTF(archives_tf);
			archives_tf.width = _w;
			archives_tf.y = 7;
			archives_tf.htmlText = '<p class="mail_inbox_archive">View your archived messages</p>';
			archive_holder.addChild(archives_tf);
			archive_holder.mouseChildren = false;
			archive_holder.useHandCursor = archive_holder.buttonMode = true;
			archive_holder.addEventListener(MouseEvent.ROLL_OVER, onArchiveMouse, false, 0, true);
			archive_holder.addEventListener(MouseEvent.ROLL_OUT, onArchiveMouse, false, 0, true);
			archive_holder.addEventListener(MouseEvent.CLICK, TSFrontController.instance.openMailArchivePage, false, 0, true);
			onArchiveMouse();
		}
		
		public function show(reset_scroller:Boolean = false):void {
			update();
			
			//do we need the scroller to snap to the top?
			scroller.refreshAfterBodySizeChange(reset_scroller);
			
			visible = true;
		}
		
		public function showWarning(txt:String):void {
			//let the toast show the warning text
			warning_toast.show(txt, 5);
		}
		
		public function hideWarning():void {
			warning_toast.hide(0);
		}
		
		public function update():void {
			//build out the elements
			var i:int;
			var message:MailMessage;
			var messages:Vector.<MailMessage> = MailManager.instance.messages;
			var next_y:int;
			var element:MailInboxElementUI;
			var g:Graphics = element_bumper.graphics;
			
			//hide by default
			no_messages_tf.visible = false;
			ok_bt.visible = false;
			mail_header.visible = true;
			
			if(messages){				
				//make all the current elements invisible
				for(i = 0; i < elements.length; i++){
					element = elements[int(i)];
					element.hide();
					element.y = 0;
				}
				
				//place them in the scroller
				for(i = 0; i < messages.length; i++){
					//reuse
					if(elements.length > i){
						element = elements[int(i)];
					}
					//new one
					else {
						element = new MailInboxElementUI(_w);
						element.addEventListener(TSEvent.CHANGED, onElementClick, false, 0, true);
						elements.push(element);
						scroller.body.addChild(element);
					}
					
					element.show(messages[int(i)], i == 0);
					element.y = next_y;
					next_y += element.height - 1;
				}
				
				//add a little bit below the elements to make the scroller happy
				element_bumper.y = next_y;
				g.clear();
				g.beginFill(0, 0);
				g.drawRect(0, 0, 1, 1);
			}
			else {
				CONFIG::debugging {
					Console.warn('Update called with no messages in the mail!');
				}
			}
			
			//if we're scrollin', bring it in, otherwise let it grow full width
			scroller.wh = {w:_w - (scroller.bar.visible ? 7 : 4), h:SCROLL_HEIGHT};
			
			//put no messages
			if(!messages || messages.length == 0){
				no_messages_tf.visible = true;
				ok_bt.visible = true;
				mail_header.visible = false;
				next_y += ok_bt.y + ok_bt.height + 10;
			}
			
			//toss on the archive message thing
			archive_holder.y = next_y;
			scroller.body.addChild(archive_holder);
			
			//draw the BG if we have messages
			g = graphics;
			g.clear();
			if(messages && messages.length){
				g.beginFill(bg_color);
				g.drawRect(0, mail_header.height, _w, scroller.h + 5);
				g.beginFill(border_color);
				g.drawRect(0, scroller.y + scroller.h + 3, _w, 1);
			}
		}
		
		private function onElementClick(event:TSEvent):void {
			//send the message ID to whoever is listening
			dispatchEvent(new TSEvent(TSEvent.CHANGED, event.data));
		}
		
		private function onOkClick(event:TSEvent):void {
			MailDialog.instance.end(true);
		}
		
		private function onToastChange(event:TSEvent):void {
			//change the scroller while the toast animates
			//because flash measures shit masked as height, if we are 2x the height, that means it's fully invisible
			const y_offset:int = TOAST_H*2 - warning_toast.height;
			scroller.y = mail_header.height + 2 + y_offset;
			scroller.h = SCROLL_HEIGHT - y_offset;
			scroller.refreshAfterBodySizeChange();
		}
		
		private function onArchiveMouse(event:MouseEvent = null):void {
			const msg_length:int = MailManager.instance.messages ? MailManager.instance.messages.length : 0;
			const is_over:Boolean = event && event.type == MouseEvent.ROLL_OVER && msg_length > 0;
			const g:Graphics = archive_holder.graphics;
			g.clear();
			g.beginFill(hover_color, is_over ? 1 : 0);
			g.drawRect(0, 0, _w, int(archives_tf.height + archives_tf.y*2));
		}
		
		public function hide():void {
			visible = false;
		}
		
		override public function get height():Number {
			return mail_header.height + SCROLL_HEIGHT + 2;
		}
	}
}
