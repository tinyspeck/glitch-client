package com.tinyspeck.engine.net
{
	public class NetOutgoingItemstackVerbMenuVO extends NetOutgoingMessageVO
	{
		
		public var target_itemstack_tsid:String;
		public var itemstack_tsid:String;
		public var starting_menu:Boolean;
		
		public function NetOutgoingItemstackVerbMenuVO(itemstack_tsid:String, starting_menu:Boolean = false, target_itemstack_tsid:String='')
		{
			super(MessageTypes.ITEMSTACK_VERB_MENU);
			this.itemstack_tsid = itemstack_tsid;
			this.starting_menu = starting_menu;
			this.target_itemstack_tsid = target_itemstack_tsid;
		}
	}
}