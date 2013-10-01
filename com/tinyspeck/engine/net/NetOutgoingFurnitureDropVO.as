package com.tinyspeck.engine.net
{
	public class NetOutgoingFurnitureDropVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var x:int;
		public var y:int;
		public var z:int;
		
		public function NetOutgoingFurnitureDropVO(itemstack_tsid:String, x:int, y:int, z:uint) {
			super(MessageTypes.FURNITURE_DROP);
			this.itemstack_tsid = itemstack_tsid;
			this.x = x;
			this.y = y;
			this.z = z;
		}
	}
}