package com.tinyspeck.engine.net {
	public class NetOutgoingGardenActionVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var plot_id:int;
		public var action:String;
		public var class_tsid:String;
		public var check_for_proximity:Boolean;
		
		public function NetOutgoingGardenActionVO(itemstack_tsid:String, plot_id:int, action:String, class_tsid:String = '') {
			super(MessageTypes.GARDEN_ACTION);
			
			this.itemstack_tsid = itemstack_tsid;
			this.plot_id = plot_id;
			this.action = action;
			this.class_tsid = class_tsid;
		}
	}
}