package com.tinyspeck.engine.net {
	public class NetOutgoingJobApplyWorkVO extends NetOutgoingMessageVO {
		
		public var itemstack_tsid:String;
		public var job_id:String;
		public var tool_class_id:String;
		public var work_percentage:int;
		public var option:int;
		//public var req_id:String;
		
		public function NetOutgoingJobApplyWorkVO(spirit_id:String, job_id:String, tool_class_id:String, work_percentage:int, option:int/*, req_id:String*/) {
			super(MessageTypes.JOB_APPLY_WORK);
			
			this.itemstack_tsid = spirit_id;
			this.job_id = job_id;
			this.tool_class_id = tool_class_id;
			this.work_percentage = work_percentage;
			this.option = option;
			//this.req_id = req_id;
		}
	}
}


/*
{
	type: 'job_apply_work'
	itemstack_tsid: [tsid of the street spirit the player is interacting with],
	job_id: [id of the job],
	tool_class_id: [class_tsid of the tool required],
	work_percentage: [percentage of the work to complete],
	option: [option number to put work towards]
}
*/