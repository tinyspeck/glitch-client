package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.Sprite;
	import flash.events.TextEvent;
	import flash.text.TextField;

	public class ACLStartMessageUI extends Sprite
	{
		private var new_pol_msg:String;
		private var new_key_msg:String;
		
		private var body_tf:TextField = new TextField();
		private var show_later_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var key_ring_bt:Button;
		
		private var is_built:Boolean;
		
		public function ACLStartMessageUI(){}
		
		private function buildBase():void {
			//new homeowner msg
			new_pol_msg =  '<span class="acl_start_message_title">Sweet! You’re a homeowner!<br><br></span>';
			new_pol_msg += 'Did you know that if you own a home, you can give keys to your friends? ' +
						   'House keys allow you to enter their house whenever you want, sorta like a roommate!<br><br>' +
						   'And if you ever get sick of your roommate, just press <b>“Revoke key”</b> next to their name and ' +
						   'your key will be returned.';
			
			//new key owner
			new_key_msg =  '<span class="acl_start_message_title">Sweet! You got a house key!<br><br></span>';
			new_key_msg += 'Did you know that if you own a home, you can give keys to your friends? ' +
				           'House keys allow you to enter their house whenever you want, sorta like a roommate!<br><br>'+
						   'And if you ever get sick of your roommate, just press <b>“Revoke key”</b> next to their name and ' +
						   'your key will be returned.';
			//tfs
			TFUtil.prepTF(body_tf);
			addChild(body_tf);
			
			TFUtil.prepTF(show_later_tf, false);
			show_later_tf.htmlText = '<p class="acl_start_message_later"><a href="event:acl_msg">Show me later</a></p>';
			show_later_tf.addEventListener(TextEvent.LINK, onLaterClick, false, 0, true);
			addChild(show_later_tf);
			
			//key ring button
			key_ring_bt = new Button({
				name: 'keyring',
				label: 'Take me to my keyring',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_DEFAULT
			});
			key_ring_bt.addEventListener(TSEvent.CHANGED, onKeyRingClick, false, 0, true);
			addChild(key_ring_bt);

			is_built = true;
		}
		
		public function show(w:int, is_new_pol:Boolean):void {
			if(!is_built) buildBase();
						
			body_tf.htmlText = '<p class="acl_start_message">'+(is_new_pol ? new_pol_msg : new_key_msg)+'</p>';
			body_tf.width = w;
			
			key_ring_bt.x = int(w/2 - key_ring_bt.width/2);
			key_ring_bt.y = int(body_tf.y + body_tf.height + 35);
			
			show_later_tf.x = int(w/2 - show_later_tf.width/2);
			show_later_tf.y = int(key_ring_bt.y + key_ring_bt.height + 8);
			
			visible = true;
		}
		
		public function hide():void {
			//remove it from whatever it was in
			if(parent) parent.removeChild(this);
			visible = false;
		}
		
		private function onKeyRingClick(event:TSEvent):void {
			//let the dialog know we got clicked to do fancy things
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
		
		private function onLaterClick(event:TextEvent):void {
			//just close the dialog
			dispatchEvent(new TSEvent(TSEvent.CLOSE));
		}
	}
}