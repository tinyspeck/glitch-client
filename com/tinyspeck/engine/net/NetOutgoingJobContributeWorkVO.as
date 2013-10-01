package com.tinyspeck.engine.net {
	public class NetOutgoingJobContributeWorkVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		public var tool_class_id:String;
		public var contribute_count:int;
		public var option:int;
		public var req_id:String;
		
		public function NetOutgoingJobContributeWorkVO(spirit_id:String, job_id:String, tool_class_id:String, contribute_count:int, option:int, req_id:String) {
			super(MessageTypes.JOB_CONTRIBUTE_WORK);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
			this.tool_class_id = tool_class_id;
			this.contribute_count = contribute_count;
			this.option = option;
			this.req_id = req_id;
		}
	}
}