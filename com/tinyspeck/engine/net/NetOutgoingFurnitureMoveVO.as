package com.tinyspeck.engine.net
{
	public class NetOutgoingFurnitureMoveVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var x:int;
		public var y:int;
		public var diff_x:int;
		public var diff_y:int;
		public var also_tsids:Array;
		
		public function NetOutgoingFurnitureMoveVO(itemstack_tsid:String, x:int, y:int, diff_x:int, diff_y:int, also_tsids:Array=null) {
			super(MessageTypes.FURNITURE_MOVE);
			this.itemstack_tsid = itemstack_tsid;
			this.x = x;
			this.y = y;
			this.diff_x = diff_x;
			this.diff_y = diff_y;
			if (also_tsids && also_tsids.length) {
				this.also_tsids = also_tsids;
			}
		}
	}
}