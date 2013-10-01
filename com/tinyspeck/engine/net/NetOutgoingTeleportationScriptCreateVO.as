package com.tinyspeck.engine.net
{
	public class NetOutgoingTeleportationScriptCreateVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var body:String;
		public var is_imbued:Boolean;
		
		public function NetOutgoingTeleportationScriptCreateVO(itemstack_tsid:String, is_imbued:Boolean, body:String)
		{
			super(MessageTypes.TELEPORTATION_SCRIPT_CREATE);
			this.itemstack_tsid = itemstack_tsid;
			this.body = body;
			this.is_imbued = is_imbued;
		}
	}
}