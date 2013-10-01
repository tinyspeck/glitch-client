package com.tinyspeck.engine.net
{
	public class NetOutgoingTeleportationScriptUseVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var use_token:Boolean;
		
		public function NetOutgoingTeleportationScriptUseVO(itemstack_tsid:String, use_token:Boolean)
		{
			super(MessageTypes.TELEPORTATION_SCRIPT_USE);
			this.itemstack_tsid = itemstack_tsid;
			this.use_token = use_token;
		}
	}
}