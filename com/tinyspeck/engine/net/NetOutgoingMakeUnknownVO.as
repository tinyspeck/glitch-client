package com.tinyspeck.engine.net
{
	public class NetOutgoingMakeUnknownVO extends NetOutgoingMessageVO
	{
		
		public var itemstack_tsid:String;
		public var verb:String;
		public var inputs:Array;
		
		public function NetOutgoingMakeUnknownVO(itemstack_tsid:String, verb:String, inputs:Array)
		{
			super(MessageTypes.MAKE_UNKNOWN);
			this.itemstack_tsid = itemstack_tsid;
			this.verb = verb;
			this.inputs = inputs;
		}
	}
}

/*
var msg_id:String = SocketProxy.instance.socket.sendRequest({
type: 'make_unknown',
itemstack_tsid: current_ob.item_tsid,
verb: current_ob.verb,
inputs: inputs
});
*/