package com.tinyspeck.engine.data.job {
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.data.requirement.Requirements;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	public class JobInfo extends AbstractTSDataEntity {
		public static const TYPE_REGULAR:String = 'regular';
		public static const TYPE_GROUP_HALL:String = 'group_hall';
		public static const TYPE_ADD_FLOOR:String = 'add_floor';
		public static const TYPE_RESTORE:String = 'restore';
		
		public var accepted:Boolean;
		public var complete:Boolean;
		public var desc:String;
		public var failed:Boolean;
		public var finished:Boolean;
		public var offered_time:uint;
		public var buckets:Vector.<JobBucket>;
		public var rewards:Vector.<Reward>;
		public var options:Vector.<JobOption> = new Vector.<JobOption>();
		public var startable:Boolean;
		public var started:Boolean;
		public var title:String;
		public var perc:Number;
		public var performance_percent:int;
		public var performance_cutoff:int;
		public var performance_rewards:Vector.<Reward>;
		public var has_contributed:Boolean;
		public var instance_id:int; //not sure what this is for, but hated seeing the errors
		public var is_available:Boolean;
		public var time_until_available:int;
		public var total_delay_time:int;
		public var phases:Vector.<JobPhase> = new Vector.<JobPhase>();
		public var delay_txt:String;
		public var ts_done:int;
		public var type:String;
		public var ts_first_contribution:uint; //used for the god page, client doesn't care
		public var owner_label:String;
		public var owner_tsid:String;
		public var duration:uint; //amount of time in minutes that the job is good for
		public var timeout:uint; //timestamp of when the job expires
		public var claim_reqs:Vector.<Requirement> = new Vector.<Requirement>();
		public var custom_name:String; //jobs that can be named will have this populated
		public var group_tsid:String; //the TSID of the group that owns this job
		
		public function JobInfo(hashName:String) {
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):JobInfo {
			var job_info:JobInfo = new JobInfo(hashName);
			var req:Requirement;
			var option:JobOption;
			var phase:JobPhase;
			var bucket:JobBucket;
			var val:*;
			var k:String;
			var count:int;
						
			for(var j:String in object){
				val = object[j];
				if(j == 'reqs'){
					job_info.buckets = new Vector.<JobBucket>();
					count = 1;
					while(val && val[count]){
						bucket = JobBucket.fromAnonymous(val[count], 'bucket'+count);
						job_info.buckets.push(bucket);
						count++;
					}
				}
				else if(j == 'rewards'){
					job_info.rewards = Rewards.fromAnonymous(val);
				}
				else if(j == 'performance_rewards'){
					job_info.performance_rewards = Rewards.fromAnonymous(val);
				}
				else if(j == 'options'){
					count = 0;
					while(val && val[count]){
						option = JobOption.fromAnonymous(val[count], count.toString());
						job_info.options.push(option);
						count++;
					}
				}
				else if(j == 'phases'){
					count = 0;
					while(val && val[count]){
						phase = JobPhase.fromAnonymous(val[count], count.toString());
						job_info.phases.push(phase);
						count++;
					}
				}
				else if(j == 'owner' && val){
					//just set the label and tsid
					job_info.owner_label = val['label'];
					job_info.owner_tsid = val['tsid'];
				}
				else if(j == 'claim_reqs' && val){
					job_info.claim_reqs = new Vector.<Requirement>();
					job_info.claim_reqs = Requirements.fromAnonymous(val);
				}
				else if(j == 'group' && 'tsid' in val){
					//group that we are not a member of, toss it in the world
					if(!TSModelLocator.instance.worldModel.getGroupByTsid(val.tsid)){
						TSModelLocator.instance.worldModel.groups[val.tsid] = Group.fromAnonymous(val, val.tsid);
					}
					job_info.group_tsid = val.tsid;
				}
				else if(j in job_info){
					job_info[j] = val;
				}
				else{
					resolveError(job_info,object,j);
				}
			}
			
			return job_info;
		}
		
		public static function updateFromAnonymous(object:Object, job_info:JobInfo):JobInfo {
			job_info = fromAnonymous(object, job_info.hashName);
			
			return job_info;
		}
		
		public function getCurrentPhaseIndex():int {
			var i:int;
			var total:int = phases.length;
			
			for(i; i < total; i++){
				if(!phases[int(i)].is_complete) return i;
			}
			
			return -1;
		}
	}
}