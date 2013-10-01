package com.tinyspeck.engine.net
{
	public class NetOutgoingEditLocationVO extends NetOutgoingMessageVO
	{
		public var location:Object;
		
		public function NetOutgoingEditLocationVO(location:Object)
		{
			super(MessageTypes.EDIT_LOCATION);
			this.location = location;
		}
	}
}