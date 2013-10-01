package com.tinyspeck.engine.net
{
	public class NetOutgoingFurnitureSetUserConfigVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var config:Object;
		public var facing_right:Boolean;
		
		public function NetOutgoingFurnitureSetUserConfigVO(itemstack_tsid:String, config:Object, facing_right:Boolean) {
			super(MessageTypes.FURNITURE_SET_USER_CONFIG);
			this.itemstack_tsid = itemstack_tsid;
			this.config = config;
			this.facing_right = facing_right;
		}
	}
}