package com.tinyspeck.engine.net
{
	public class NetOutgoingFurnitureUpgradePurchaseVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var upgrade_id:String;
		public var config:Object;
		public var facing_right:Boolean;
		
		public function NetOutgoingFurnitureUpgradePurchaseVO(itemstack_tsid:String, upgrade_id:String, config:Object, facing_right:Boolean) {
			super(MessageTypes.FURNITURE_UPGRADE_PURCHASE);
			this.itemstack_tsid = itemstack_tsid;
			this.upgrade_id = upgrade_id;
			this.facing_right = facing_right;
			if (config) {
				this.config = config;
			}
		}
	}
}