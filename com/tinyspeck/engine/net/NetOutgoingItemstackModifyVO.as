package com.tinyspeck.engine.net
{
	public class NetOutgoingItemstackModifyVO extends NetOutgoingMessageVO
	{
		public var itemstack_tsid:String;
		public var x:int;
		public var y:int;
		public var s:String;
		public var props:*;
		public var no_merge:*;
		
		public function NetOutgoingItemstackModifyVO(itemstack_tsid:String, x:int, y:int, s:String = null, props:* = null, no_merge:Boolean=false)
		{
			super(MessageTypes.ITEMSTACK_MODIFY);
			this.itemstack_tsid = itemstack_tsid;
			this.x = x;
			this.y = y;
			this.s = s;
			if (props) this.props = props;
			if (no_merge) this.no_merge = true;
		}
	}
}