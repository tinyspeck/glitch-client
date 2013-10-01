package com.tinyspeck.engine.net
{
	

	public class NetOutgoingGetItemPlacement extends NetOutgoingMessageVO
	{
		public var item_class:String;
		
		public function NetOutgoingGetItemPlacement(item_class:String){
			super(MessageTypes.GET_ITEM_PLACEMENT);
			this.item_class = item_class;
		}
	}
}
