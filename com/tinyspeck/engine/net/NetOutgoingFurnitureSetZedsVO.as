package com.tinyspeck.engine.net
{
	public class NetOutgoingFurnitureSetZedsVO extends NetOutgoingMessageVO
	{
		public var hash:Object;
		
		public function NetOutgoingFurnitureSetZedsVO(hash:Object) {
			super(MessageTypes.FURNITURE_SET_ZEDS);
			this.hash = hash;
		}
	}
}