
package com.tinyspeck.engine.net
{
	public class NetOutgoingItemstackMenuUpVO extends NetOutgoingMessageVO
	{
		
		public var itemstack_tsid:String;
		
		public function NetOutgoingItemstackMenuUpVO(itemstack_tsid:String = '')
		{
			super(MessageTypes.ITEMSTACK_MENU_UP);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}