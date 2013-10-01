package com.tinyspeck.engine.net {
	public class NetOutgoingJobStopWorkVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		public var tool_class_id:String;
		
		public function NetOutgoingJobStopWorkVO(spirit_id:String, job_id:String, tool_class_id:String) {
			super(MessageTypes.JOB_STOP_WORK);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
			this.tool_class_id = tool_class_id;
		}
	}
}