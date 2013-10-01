package com.tinyspeck.engine.net
{
	public class NetOutgoingItemstackSetUserConfigVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var config:Object;
		
		public function NetOutgoingItemstackSetUserConfigVO(itemstack_tsid:String, config:Object) {
			super(MessageTypes.ITEMSTACK_SET_USER_CONFIG);
			this.itemstack_tsid = itemstack_tsid;
			this.config = config;
		}
	}
}