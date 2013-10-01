package com.tinyspeck.engine.net {
	public class NetOutgoingCraftybotLockVO extends NetOutgoingMessageVO {
		
		public var is_lock:Boolean;
		public var item_class:String;
		
		public function NetOutgoingCraftybotLockVO(is_lock:Boolean, item_class:String) 
		{
			super(MessageTypes.CRAFTYBOT_LOCK);
			this.is_lock = is_lock;
			this.item_class = item_class;
		}
	}
}