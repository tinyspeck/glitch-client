package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class MailInboxHeaderUI extends Sprite
	{
		public static const READ_X:int = 33;
		public static const SENDER_X:int = 60;
		public static const ATTACHED_X:int = 425;
		public static const RECEIVED_X:int = 475;
		
		private static const HEIGHT:uint = 22;
		private static const Y_PADD:int = 1;
		
		private var sender_tf:TextField = new TextField();
		private var attached_tf:TextField = new TextField();
		private var received_tf:TextField = new TextField();
				
		public function MailInboxHeaderUI(w:int){			
			//tfs			
			TFUtil.prepTF(sender_tf, false);
			sender_tf.htmlText = '<p class="mail_inbox_header">Sender/Message</p>';
			sender_tf.x = SENDER_X;
			sender_tf.y = Y_PADD;
			addChild(sender_tf);
			
			TFUtil.prepTF(attached_tf, false);
			attached_tf.htmlText = '<p class="mail_inbox_header">Attached</p>';
			attached_tf.x = int(ATTACHED_X - attached_tf.width/2);
			attached_tf.y = Y_PADD;
			addChild(attached_tf);
			
			TFUtil.prepTF(received_tf, false);
			received_tf.htmlText = '<p class="mail_inbox_header">Received</p>';
			received_tf.x = RECEIVED_X;
			received_tf.y = Y_PADD;
			addChild(received_tf);
			
			//draw the line
			var bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_header', 'backgroundColor', 0xececec);
			var border_color:uint = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_header', 'borderColor', 0xcbcbcb);
			var g:Graphics = graphics;
			g.beginFill(bg_color);
			g.drawRect(0, 0, w, HEIGHT);
			g.beginFill(border_color);
			g.drawRect(0, 0, w, 1);
			g.drawRect(0, HEIGHT-1, w, 1);
		}
	}
}