package com.tinyspeck.engine.net {
	public class NetOutgoingJobClaimVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		public var group_tsid:String;
		
		public function NetOutgoingJobClaimVO(spirit_id:String, job_id:String, group_tsid:String = '') {
			super(MessageTypes.JOB_CLAIM);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
			this.group_tsid = group_tsid;
		}
	}
}