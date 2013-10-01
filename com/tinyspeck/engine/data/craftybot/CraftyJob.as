package com.tinyspeck.engine.data.craftybot
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class CraftyJob extends AbstractTSDataEntity
	{
		public var item_class:String;
		public var done:uint;
		public var total:uint;
		public var craftable_count:uint;
		public var status:CraftyStatus;
		public var components:Vector.<CraftyComponent> = new Vector.<CraftyComponent>();
		public var fuel_cost:int;
		public var crystal_cost:int;
		
		public function CraftyJob(item_class:String){
			super(item_class);
			this.item_class = item_class;
		}
		
		public static function fromAnonymous(object:Object, item_class:String):CraftyJob {
			const job:CraftyJob = new CraftyJob(item_class);
			return updateFromAnonymous(object, job);
		}
		
		public static function updateFromAnonymous(object:Object, job:CraftyJob):CraftyJob {
			var k:String;
			var count:int;
			
			for(k in object){
				if(k == 'status'){
					job.status = CraftyStatus.fromAnonymous(object[k]);
				}
				else if(k == 'components'){
					job.components.length = 0;
					count = 0;
					while(object[k] && object[k][count] && 'item_classes' in object[k][count]){
						job.components.push(CraftyComponent.fromAnonymous(object[k][count]));
						count++;
					}
				}
				else if(k in job){
					job[k] = object[k];
				}
				else {
					resolveError(job, object, k);
				}
			}
			
			return job;
		}
	}
}