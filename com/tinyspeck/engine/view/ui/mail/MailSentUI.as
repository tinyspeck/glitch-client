package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.Sprite;

	public class MailSentUI extends Sprite
	{
		private var back_bt:Button;
		
		private var message_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var _w:int;
				
		public function MailSentUI(w:int){
			_w = w;
			
			//message
			TFUtil.prepTF(message_tf);
			message_tf.width = w;
			addChild(message_tf);
			
			//back bt
			back_bt = new Button({
				name: 'back',
				label: 'Send another message',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			addChild(back_bt);
			
			hide();
		}
		
		public function show(new_msg:String = '', new_bt_label:String = ''):void {
			//set the message
			if(!new_msg) new_msg = 'That was fun right?! If you want to send another one, just click the button below.';
			setMessage(new_msg);
			
			//set the label
			if(!new_bt_label) new_bt_label = 'Send another message';
			back_bt.label = new_bt_label;
			back_bt.y = int(message_tf.height + 20);
			back_bt.x = int((_w - back_bt.width)/2);
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
		}
		
		private function setMessage(txt:String):void {
			message_tf.htmlText = '<p class="mail_sent_success">Off it goes!<br>'+
								  '<span class="mail_sent_sub">'+txt+'</span></p>';
		}
		
		private function onBackClick(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
	}
}
