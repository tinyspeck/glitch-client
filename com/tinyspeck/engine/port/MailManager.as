package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.mail.Mail;
	import com.tinyspeck.engine.data.mail.MailMessage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingMailArchiveVO;
	import com.tinyspeck.engine.net.NetOutgoingMailCancelVO;
	import com.tinyspeck.engine.net.NetOutgoingMailCheckVO;
	import com.tinyspeck.engine.net.NetOutgoingMailCostVO;
	import com.tinyspeck.engine.net.NetOutgoingMailDeleteVO;
	import com.tinyspeck.engine.net.NetOutgoingMailReadVO;
	import com.tinyspeck.engine.net.NetOutgoingMailReceiveVO;
	import com.tinyspeck.engine.net.NetOutgoingMailSendVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.SortTools;
	
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;

	public class MailManager extends EventDispatcher
	{
		/* singleton boilerplate */
		public static const instance:MailManager = new MailManager();
		
		private const MIN_SECS_BETWEEN_CHECK:uint = 60;
		
		private var msgs_to_delete:Array;
		private var msgs_to_read:Array;
		private var msgs_to_receive:Array;
		private var msgs_to_archive:Array = new Array();
		private var msg_to_reply:String;  //when replying to a message, we hold on to the reference
		private var last_check:uint;
		private var now:uint;
		private var itemstack_tsid:String;  //the sending station's tsid (and if read mode, the mailbox itemstack_tsid)
		private var msgs_is_unread:Boolean;
		private var check_messages:Boolean;
		private var is_sending_archive:Boolean;
		
		private var _mail:Mail;
		private var _regular_cost:int;
		private var _expedited_cost:int;
		private var _cost_to_send:int;
		
		public function MailManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function start(payload:Object):void {
			itemstack_tsid = payload.station_tsid;
			_regular_cost = payload.hasOwnProperty('regular_cost') ? payload.regular_cost : 20; //asuming until server changes it
			_expedited_cost = payload.hasOwnProperty('expedited_cost') ? payload.expedited_cost : 100;
			
			//open the dialog
			MailDialog.instance.current_state = MailDialog.COMPOSE;
			MailDialog.instance.start();
		}
		
		public function parseMessages(payload:Object):void {
			//parse the messages and let the dialog know
			_mail = Mail.fromAnonymous(payload);
			
			sortMessages();
			
			//tell the dialog to update (or start if not open yet)
			if(!MailDialog.instance.parent){
				itemstack_tsid = mail.itemstack_tsid;
				MailDialog.instance.current_state = MailDialog.INBOX;
				MailDialog.instance.start();
			}
			else {
				MailDialog.instance.update();
			}
			
			//set the last check
			last_check = getTimer();
		}
		
		public function check(force:Boolean = false):void {
			if(!itemstack_tsid) return;
			
			now = getTimer();
			
			if(force || (now - last_check >= MIN_SECS_BETWEEN_CHECK*1000)){
				//net controller will call parseMessages when it gets the response
				TSFrontController.instance.genericSend(new NetOutgoingMailCheckVO());
			}
			/*
			else {
				var secs_left:uint = MIN_SECS_BETWEEN_CHECK - ((now - last_check)/1000)
				showError('Whoh speedy, wait about '+secs_left+(secs_left != 1 ? ' seconds' : ' second')+' before trying again!');
			}
			*/
		}
		
		public function send(recipient_tsid:String, text:String = '', itemstack_tsid:String = '', currants:uint = 0, 
							 item_class:String = '', count:uint = 0, reply_message_id:String = ''):void {
			if(!recipient_tsid){
				CONFIG::debugging {
					Console.warn('Missing the recipient in the send message');
				}
				showError('The recipient is missing!');
				return;
			}
			
			//send it off to the server
			if(this.itemstack_tsid){
				TSFrontController.instance.genericSend(
					new NetOutgoingMailSendVO(
						this.itemstack_tsid, 
						recipient_tsid, 
						text, 
						itemstack_tsid, 
						currants,
						item_class,
						count,
						reply_message_id
					), 
					onSend, onSend);
				
				msg_to_reply = reply_message_id;
			}
			else {
				CONFIG::debugging {
					Console.warn('No send itemstack tsid');
				}
				showError('You need to send this from a mail station!');
			}
		}
		
		private function onSend(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//if this was a reply, make sure we update the timestamp
				if(msg_to_reply){
					var message:MailMessage = mail.getMessageById(msg_to_reply);
					if(message) message.replied = TSFrontController.instance.getCurrentGameTimeInUnixTimestamp();
				}
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('message send error!');
				}
			}
			
			MailDialog.instance.sendStatus(nrm.success);
		}
		
		public function receiveAttachements(message_ids:Array):void {
			if(!message_ids || (message_ids && !message_ids.length)){
				CONFIG::debugging {
					Console.warn('Missing message ID');
				}
				showError('Can\'t seem to figure out which message we are working with.');
				return;
			}
			
			msgs_to_receive = message_ids;
			
			//send it off to the server
			TSFrontController.instance.genericSend(new NetOutgoingMailReceiveVO(message_ids), onReceiveAttachements, onReceiveAttachements);
		}
		
		private function onReceiveAttachements(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//remove the currants
				var i:int;
				var message:MailMessage;
				for(i; i < msgs_to_receive.length; i++){
					message = mail.getMessageById(msgs_to_receive[int(i)]);
					if(message) {
						message.currants = 0;
					}
				}
				
				//remove the items on the ones that were successful
				if('message_ids' in nrm.payload){
					const message_ids:Array = nrm.payload.message_ids as Array;
					for(i = 0; i < message_ids.length; i++){
						message = mail.getMessageById(message_ids[int(i)]);
						if(message){
							message.item = null;
						}
					}
				}
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('message attachement error!');
				}
			}
			
			MailDialog.instance.receiveStatus(nrm.success);
			check(true);
		}
		
		public function read(message_ids:Array, is_unread:Boolean):void {
			if(!message_ids || (message_ids && !message_ids.length)){
				CONFIG::debugging {
					Console.warn('Missing message IDs');
				}
				showError('Can\'t seem to figure out which messages we are working with.');
				return;
			}
			
			//hold a ref to this
			msgs_to_read = message_ids;
			msgs_is_unread = is_unread;
			
			//send it off to the server
			TSFrontController.instance.genericSend(new NetOutgoingMailReadVO(message_ids, is_unread), onRead, onRead);
		}
		
		private function onRead(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				var i:int;
				var message:MailMessage;
				
				//clean up the messages in the event a check message doesn't come in
				for(i; i < msgs_to_read.length; i++){
					message = mail.getMessageById(msgs_to_read[int(i)]);
					if(message) message.is_read = !msgs_is_unread;
				}
				
				sortMessages();
				
				//tell the dialog we read our messages
				MailDialog.instance.update();
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('message read error!');
				}
			}
		}
		
		public function remove(message_ids:Array, check_for_new:Boolean = true):void {
			if(!message_ids || (message_ids && !message_ids.length)){
				CONFIG::debugging {
					Console.warn('Missing message IDs');
				}
				showError('Can\'t seem to figure out which messages we are working with.');
				return;
			}
			
			check_messages = check_for_new;
			
			//hold a ref to this for removing from the _mail
			msgs_to_delete = message_ids;
			
			//send it off to the server
			TSFrontController.instance.genericSend(new NetOutgoingMailDeleteVO(message_ids), onRemove, onRemove);
		}
		
		private function onRemove(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				var i:int;
				var index:int;
				var message:MailMessage;
				
				//clean up the messages in the event a check message doesn't come in
				for(i; i < msgs_to_delete.length; i++){
					message = mail.getMessageById(msgs_to_delete[int(i)]);
					if(message){
						index = mail.messages.indexOf(message);
						if(index != -1){
							mail.messages.splice(index, 1);
						}
					}
				}
				
				sortMessages();
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('message delete error!');
				}
			}
			
			MailDialog.instance.removeStatus(nrm.success);
			if(nrm.success && check_messages) check(true);
		}
		
		public function archive(message_id:String, check_for_new:Boolean = true):void {
			if(!message_id){
				CONFIG::debugging {
					Console.warn('Missing message ID');
				}
				showError('Can\'t seem to figure out which messages we are working with.');
				return;
			}
			
			check_messages = check_for_new;
			
			//add it to the archive
			addMessageIdToArchive(message_id);
		}
		
		public function sendArchiveToServer():void {
			//takes the current messages that are flagged for archive, and sends them
			if(!msgs_to_archive.length || is_sending_archive) return;
			
			//send it off to the server
			is_sending_archive = true;
			TSFrontController.instance.genericSend(new NetOutgoingMailArchiveVO(msgs_to_archive), onArchive, onArchive);
		}
		
		private function onArchive(nrm:NetResponseMessageVO):void {
			is_sending_archive = false;
			
			if(nrm.success){
				var i:int;
				var index:int;
				var message:MailMessage;
				
				//clean up the messages in the event a check message doesn't come in
				for(i; i < msgs_to_archive.length; i++){
					message = mail.getMessageById(msgs_to_archive[int(i)]);
					if(message){
						index = mail.messages.indexOf(message);
						if(index != -1){
							mail.messages.splice(index, 1);
						}
					}
				}
				
				sortMessages();
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('message archive error!');
				}
			}
			
			MailDialog.instance.archiveStatus(nrm.success, msgs_to_archive.length);
			if(nrm.success && check_messages) check(true);
			
			//clean out the array
			if(nrm.success) msgs_to_archive.length = 0;
		}
		
		public function cancel():void {
			//they closed the window
			if(itemstack_tsid){
				TSFrontController.instance.genericSend(new NetOutgoingMailCancelVO(itemstack_tsid));
			}
			else {
				CONFIG::debugging {
					Console.warn('no itemstack_tsid!');
				}
			}
		}
		
		public function requestCost(itemstack_tsid:String, count:int, currants:int):void {
			_cost_to_send = base_cost;
			
			//ask the server what the new cost to send this message is going to be
			TSFrontController.instance.genericSend(new NetOutgoingMailCostVO(itemstack_tsid, count, currants), onCost, onCost);
		}
		
		private function onCost(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				_cost_to_send = 'amount' in nrm.payload ? nrm.payload.amount : base_cost;
			}
			else if(nrm.payload.error){
				_cost_to_send = base_cost;
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('cost check error!');
				}
			}
			
			//let the listeners know!
			dispatchEvent(new TSEvent(TSEvent.CHANGED, _cost_to_send));
		}
		
		public function resetCost():void {
			//make the sending cost the same as the base
			_cost_to_send = base_cost;
		}
		
		private function addMessageIdToArchive(message_id:String):void {
			const total:uint = msgs_to_archive.length;
			var i:int;
			
			for(i; i < total; i++){
				if(msgs_to_archive[int(i)] == message_id) return;
			}
			
			//add it
			msgs_to_archive.push(message_id);
		}
		
		private function sortMessages():void {
			//sort the messages by received
			SortTools.vectorSortOn(mail.messages, ['received'], [Array.DESCENDING]);
		}
		
		private function showError(txt:String):void {
			//TSModelLocator.instance.activityModel.growl_message = txt;
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
		
		public function get mail():Mail { return _mail; }
		public function get regular_cost():int { return _regular_cost; }
		public function get expedited_cost():int { return _expedited_cost; }
		public function get base_cost():int { return mail ? mail.base_cost : 0; }
		public function get cost_to_send():int { return _cost_to_send ? _cost_to_send : base_cost; }
		public function get messages():Vector.<MailMessage> { 
			if(!mail) return null;
			return mail.messages;
		}
	}
}