package com.tinyspeck.engine.net
{
	

	public class NetOutgoingGetItemAsset extends NetOutgoingMessageVO
	{
		public var item_class:String;
		
		public function NetOutgoingGetItemAsset(item_class:String){
			super(MessageTypes.GET_ITEM_ASSET);
			this.item_class = item_class;
		}
	}
}
