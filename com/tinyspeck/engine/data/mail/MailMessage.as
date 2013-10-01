package com.tinyspeck.engine.data.mail
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;

	public class MailMessage extends AbstractTSDataEntity
	{
		public var message_id:String;
		public var currants:uint;
		public var text:String;
		public var item:MailItem;
		public var sender_tsid:String;
		public var received:uint;
		public var replied:uint;
		public var is_read:Boolean;
		public var is_expedited:Boolean;
		public var in_reply_to:MailMessage;
		public var is_auction:Boolean;
		
		public function MailMessage(message_id:String){
			super(message_id);
			this.message_id = message_id;
		}
		
		public static function fromAnonymous(object:Object, message_id:String):MailMessage {
			var message:MailMessage = new MailMessage(message_id);
			return updateFromAnonymous(object, message);
		}
		
		public static function updateFromAnonymous(object:Object, message:MailMessage):MailMessage {
			var k:String;
			var val:*;
			
			for(k in object){
				val = object[k];
				if(k == 'item' && val){
					if(val.class_tsid && val.count){
						message.item = MailItem.fromAnonymous(val, val.class_tsid);
					}
					else {
						CONFIG::debugging {
							Console.warn('Item without a class_tsid and count');
						}
					}
				}
				else if (k == 'sender' && val){
					//make sure the sender is known in the world
					const world:WorldModel = TSModelLocator.instance.worldModel;
					var pc:PC = world.getPCByTsid(val.tsid);
					if(!pc){
						pc = PC.fromAnonymous(val, val.tsid);
					}
					else {
						pc = PC.updateFromAnonymous(val, pc);
					}
					
					world.pcs[pc.tsid] = pc;
					message.sender_tsid = pc.tsid;
				}
				else if(k == 'in_reply_to' && val && 'message_id' in val){
					//create the item
					message.in_reply_to = fromAnonymous(val, val.message_id);
				}
				else if(k in message){
					message[k] = val;
				}
				else {
					resolveError(message,object,k);
				}
			}
			
			return message;
		}
	}
}