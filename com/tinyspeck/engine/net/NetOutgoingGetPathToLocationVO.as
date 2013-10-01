package com.tinyspeck.engine.net {
	public class NetOutgoingGetPathToLocationVO extends NetOutgoingMessageVO
	{
		
		public var loc_tsid:String;
		
		public function NetOutgoingGetPathToLocationVO(loc_tsid:String)
		{
			super(MessageTypes.GET_PATH_TO_LOCATION);
			this.loc_tsid = loc_tsid;
		}
	}
}