package com.tinyspeck.engine.data.job
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class JobPhase extends AbstractTSDataEntity
	{
		public var name:String;
		public var is_complete:Boolean;
		
		public function JobPhase(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):JobPhase {
			var job_phase:JobPhase = new JobPhase(hashName);
			
			for(var j:String in object){
				if(j in job_phase){
					job_phase[j] = object[j];
				}
				else{
					resolveError(job_phase,object,j);
				}
			}
			
			return job_phase;
		}
		
		public static function updateFromAnonymous(object:Object, job_phase:JobPhase):JobPhase {
			job_phase = fromAnonymous(object, job_phase.hashName);
			
			return job_phase;
		}
	}
}