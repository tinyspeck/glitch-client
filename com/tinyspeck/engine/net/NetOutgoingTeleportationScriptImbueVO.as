package com.tinyspeck.engine.net
{
	public class NetOutgoingTeleportationScriptImbueVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		
		public function NetOutgoingTeleportationScriptImbueVO(itemstack_tsid:String)
		{
			super(MessageTypes.TELEPORTATION_SCRIPT_IMBUE);
			this.itemstack_tsid = itemstack_tsid;
		}
	}
}