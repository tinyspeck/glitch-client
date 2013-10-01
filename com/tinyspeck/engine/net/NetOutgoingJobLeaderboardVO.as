package com.tinyspeck.engine.net {
	public class NetOutgoingJobLeaderboardVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		
		public function NetOutgoingJobLeaderboardVO(spirit_id:String, job_id:String) {
			super(MessageTypes.JOB_LEADERBOARD);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
		}
	}
}