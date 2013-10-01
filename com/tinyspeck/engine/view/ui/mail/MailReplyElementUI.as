package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.engine.data.mail.MailMessage;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.text.TextField;

	public class MailReplyElementUI extends TSSpriteWithModel
	{
		private static const BODY_INDENT:uint = 14;
		private static const BORDER_INDENT:uint = 6;
		
		private static var border_color:uint;
		private static var border_width:int = -1;
		
		private var title_tf:TextField = new TextField();
		private var body_tf:TextField = new TextField();
		
		public function MailReplyElementUI(){
			//tfs
			TFUtil.prepTF(title_tf);
			addChild(title_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.x = BODY_INDENT;
			addChild(body_tf);
			
			//set the styles if this is the first time it's being called
			if(border_width == -1){
				border_color = CSSManager.instance.getUintColorValueFromStyle('mail_reply_element', 'borderColor', 0xd2d2d2);
				border_width = CSSManager.instance.getNumberValueFromStyle('mail_reply_element', 'borderWidth', 1);
			}
		}
		
		public function show(message:MailMessage, w:int):void {
			const pc:PC = message.sender_tsid ? model.worldModel.getPCByTsid(message.sender_tsid) : null;
			var label:String = pc ? pc.label : 'G.I.G.P.D.S.';
			if(pc && pc.tsid == model.worldModel.pc.tsid) label = 'You';
			var title_txt:String = 'On '+StringUtil.getTimeFromUnixTimestamp(message.received, false, false);
			title_txt += ', '+label+' wrote:';
			
			title_tf.width = w;
			title_tf.htmlText = '<p class="mail_reply_element_title">'+title_txt+'</p>';
			
			body_tf.y = title_tf.y + title_tf.height;
			body_tf.width = w - BODY_INDENT;
			body_tf.htmlText = '<p class="mail_reply_element_body">'+message.text+'</p>';
			
			//draw the border
			const g:Graphics = graphics;
			g.clear();
			g.beginFill(border_color);
			g.drawRect(BORDER_INDENT, int(title_tf.y + title_tf.height), 1, int(body_tf.height));
			
			visible = true;
		}
		
		public function hide():void {
			title_tf.text = '';
			body_tf.y = 0;
			body_tf.text = '';
			graphics.clear();
			
			visible = false;
		}
	}
}