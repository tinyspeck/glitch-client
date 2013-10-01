package com.tinyspeck.engine.net
{
	public class NetOutgoingMailSendVO extends NetOutgoingMessageVO
	{
		public var station_tsid:String;
		public var recipient_tsid:String;
		public var text:String;
		public var itemstack_tsid:String;
		public var currants:uint;
		public var class_tsid:String;
		public var count:uint;
		public var reply_message_id:String;
		
		public function NetOutgoingMailSendVO(station_tsid:String, recipient_tsid:String, text:String = '', itemstack_tsid:String = '', 
											  currants:uint = 0, class_tsid:String = '', count:uint = 0, reply_message_id:String = '')
		{
			super(MessageTypes.MAIL_SEND);
			this.station_tsid = station_tsid;
			this.recipient_tsid = recipient_tsid;
			this.text = text;
			this.itemstack_tsid = itemstack_tsid;
			this.currants = currants;
			this.class_tsid = class_tsid;
			this.count = count;
			this.reply_message_id = reply_message_id;
		}
	}
}
