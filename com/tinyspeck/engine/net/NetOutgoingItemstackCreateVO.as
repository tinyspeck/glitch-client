package com.tinyspeck.engine.net
{
	public class NetOutgoingItemstackCreateVO extends NetOutgoingMessageVO
	{
		public var item_class:String;
		public var x:int;
		public var y:int;
		public var props:*;
		public var count:*;
		
		public function NetOutgoingItemstackCreateVO(item_class:String, x:int, y:int, props:*=null, count:*=null)
		{
			super(MessageTypes.ITEMSTACK_CREATE);
			this.item_class = item_class;
			this.x = x;
			this.y = y;
			if (props) this.props = props;
			if (count) this.count = count;
		}
	}
}