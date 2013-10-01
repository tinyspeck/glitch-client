package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.engine.data.mail.MailMessage;
	
	import flash.display.Sprite;

	public class MailRepliesUI extends Sprite
	{
		private const INDENT_MAX:uint = 3; //how many times to indent before it just stays (if you have 50 replies you don't want it to indent 50 times)
		private const INDENT:uint = 10;
		private const BOTTOM_PADD:int = 5;
		
		private var elements:Vector.<MailReplyElementUI> = new Vector.<MailReplyElementUI>();
		private var _w:int;
		
		public function MailRepliesUI(w:int){
			_w = w;
		}
			
		public function show(message:MailMessage):void {
			if(!message) return;
			
			var i:int;
			var total:int = elements.length;
			var element:MailReplyElementUI;
			var next_x:int;
			var next_y:int;
			var next_message:MailMessage;
			var pool_id:int;
			
			//reset the pool
			for(i; i < total; i++){
				element = elements[int(i)];
				element.x = element.y = 0;
				element.hide();
				if(element.parent) element.parent.removeChild(element);
			}
			
			next_message = message.in_reply_to;
			
			//as long as we have a next message, let's keep on going!
			while(next_message){
				//create the element
				if(elements.length > pool_id){
					element = elements[int(pool_id)];
				}
				else {
					element = new MailReplyElementUI();
					elements.push(element);
				}
				element.show(next_message, _w - next_x);
				element.x = next_x;
				element.y = next_y;
				addChild(element);
				
				next_y += element.height + BOTTOM_PADD;
				
				//increment the pool
				pool_id++;
				
				//set the next X position
				if(pool_id < INDENT_MAX){
					next_x += INDENT;
				}
				
				//set the next message
				next_message = next_message.in_reply_to;
			}
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
		}
	}
}