package com.tinyspeck.engine.data.job
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.data.requirement.Requirements;

	public class JobGroup extends AbstractTSDataEntity
	{
		public var reqs:Vector.<Requirement>;
		
		public function JobGroup(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):JobGroup {
			var job_group:JobGroup = new JobGroup(hashName);
			job_group.reqs = Requirements.fromAnonymous(object);
			
			return job_group;
		}
		
		public static function updateFromAnonymous(object:Object, job_group:JobGroup):JobGroup {
			job_group = fromAnonymous(object, job_group.hashName);
			
			return job_group;
		}
	}
}