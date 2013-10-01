package com.tinyspeck.engine.net
{
	public class NetOutgoingMakeKnownVO extends NetOutgoingMessageVO
	{
		
		public var itemstack_tsid:String;
		public var verb:String;
		public var count:int;
		public var recipe:String;
		
		public function NetOutgoingMakeKnownVO(itemstack_tsid:String, verb:String, count:int, recipe:String)
		{
			super(MessageTypes.MAKE_KNOWN);
			this.itemstack_tsid = itemstack_tsid;
			this.verb = verb;
			this.count = count;
			this.recipe = recipe;
		}
	}
}