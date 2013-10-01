package com.tinyspeck.engine.net {
	public class NetOutgoingJobContributeItemVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		public var contribute_class_id:String;
		public var contribute_count:int;
		public var option:int;
		public var req_id:String;
		
		public function NetOutgoingJobContributeItemVO(spirit_id:String, job_id:String, class_tsid:String, amount:int, option:int, req_id:String) {
			super(MessageTypes.JOB_CONTRIBUTE_ITEM);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
			this.contribute_class_id = class_tsid;
			this.contribute_count = amount;
			this.option = option;
			this.req_id = req_id;
		}
	}
}