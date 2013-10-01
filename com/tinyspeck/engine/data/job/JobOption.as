package com.tinyspeck.engine.data.job
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class JobOption extends AbstractTSDataEntity
	{
		public var name:String;
		public var desc:String;
		public var perc:Number;
		public var image:String;
		public var tsid:String;
		
		public function JobOption(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):JobOption {
			var job_option:JobOption = new JobOption(hashName);
			
			for(var j:String in object){
				if(j in job_option){
					job_option[j] = object[j];
				}
				else{
					resolveError(job_option,object,j);
				}
			}
			
			return job_option;
		}
		
		public static function updateFromAnonymous(object:Object, job_option:JobOption):JobOption {
			job_option = fromAnonymous(object, job_option.hashName);
			
			return job_option;
		}
	}
}