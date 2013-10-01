package com.tinyspeck.engine.net {
	public class NetOutgoingJobContributeCurrantsVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		public var currants:int;
		public var option:int;
		public var req_id:String;
		
		public function NetOutgoingJobContributeCurrantsVO(spirit_id:String, job_id:String, currants:int, option:int, req_id:String) {
			super(MessageTypes.JOB_CONTRIBUTE_CURRANTS);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
			this.currants = currants;
			this.option = option;
			this.req_id = req_id;
		}
	}
}