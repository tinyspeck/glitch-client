package com.tinyspeck.engine.data.job
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class JobBucket extends AbstractTSDataEntity
	{
		public var groups:Vector.<JobGroup>;
		
		public function JobBucket(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):JobBucket {
			var job_bucket:JobBucket = new JobBucket(hashName);
			var group:JobGroup;
			var count:int = 1;
						
			job_bucket.groups = new Vector.<JobGroup>();
			while(object[count]){
				group = JobGroup.fromAnonymous(object[count], 'group'+count);
				job_bucket.groups.push(group);
				count++;
			}
			
			return job_bucket;
		}
		
		public static function updateFromAnonymous(object:Object, job_bucket:JobBucket):JobBucket {
			job_bucket = fromAnonymous(object, job_bucket.hashName);
			
			return job_bucket;
		}
	}
}