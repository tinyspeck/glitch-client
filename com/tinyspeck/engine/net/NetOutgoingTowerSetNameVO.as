package com.tinyspeck.engine.net {
	public class NetOutgoingTowerSetNameVO extends NetOutgoingMessageVO {
		
		public var name:String;
		public var tower_tsid:String;
		
		public function NetOutgoingTowerSetNameVO(tower_tsid:String, name:String) 
		{
			super(MessageTypes.TOWER_SET_NAME);
			this.name = name;
			this.tower_tsid = tower_tsid;
		}
	}
}