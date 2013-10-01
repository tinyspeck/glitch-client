package com.tinyspeck.engine.net {
	public class NetOutgoingJobCreateNameVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		public var name:String;
		
		public function NetOutgoingJobCreateNameVO(spirit_id:String, job_id:String, name:String) {
			super(MessageTypes.JOB_CREATE_NAME);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
			this.name = name;
		}
	}
}