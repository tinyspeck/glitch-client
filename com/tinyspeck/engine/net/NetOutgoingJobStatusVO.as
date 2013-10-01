package com.tinyspeck.engine.net {
	public class NetOutgoingJobStatusVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		
		public function NetOutgoingJobStatusVO(spirit_id:String, job_id:String) {
			super(MessageTypes.JOB_STATUS);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
		}
	}
}