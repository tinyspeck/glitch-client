package com.tinyspeck.engine.net {
	public class NetOutgoingShrineFavorRequestVO extends NetOutgoingMessageVO {
		
		public var shrine_tsid:String;
		public var item_class:String;
		
		public function NetOutgoingShrineFavorRequestVO(shrine_tsid:String, item_class:String) 
		{
			super(MessageTypes.SHRINE_FAVOR_REQUEST);
			this.shrine_tsid = shrine_tsid;
			this.item_class = item_class;
		}
	}
}