package com.tinyspeck.engine.data.mail
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class Mail extends AbstractTSDataEntity
	{
		public var message_count:uint; //total messages you have, server will truncate after 30
		public var messages:Vector.<MailMessage> = new Vector.<MailMessage>();
		public var itemstack_tsid:String; //mailbox tsid
		public var base_cost:int;
		
		public function Mail(){
			super('mail');
		}
		
		public static function fromAnonymous(object:Object):Mail {
			var mail:Mail = new Mail();
			return updateFromAnonymous(object, mail);
		}
		
		public static function updateFromAnonymous(object:Object, mail:Mail):Mail {
			var k:String;
			var val:*;
			var count:int;
			var message:MailMessage;
			
			for(k in object){
				val = object[k];
				
				if(k == 'messages'){
					count = 0;
					while(val && val[count]){
						if('message_id' in val[count]){
							message = mail.getMessageById(val[count].message_id);
							if(!message){
								message = MailMessage.fromAnonymous(val[count], val[count].message_id);
								mail.messages.push(message);
							}
							else {
								message = MailMessage.updateFromAnonymous(val[count], message);
							}
						}
						count++;
					}
				}
				else if(k in mail){
					mail[k] = object[k];
				}
				else {
					resolveError(mail,object,k);
				}
			}
			
			return mail;
		}
		
		public function getMessageById(message_id:String):MailMessage {
			var i:int;
			
			for(i; i < messages.length; i++){
				if(messages[int(i)].message_id == message_id) return messages[int(i)];
			}
			
			return null;
		}
		
		public function getUnreadCount():uint {
			var i:int;
			var count:uint;
			
			for(i; i < messages.length; i++){
				if(!messages[int(i)].is_read) count++;
			}
			
			return count;
		}
	}
}