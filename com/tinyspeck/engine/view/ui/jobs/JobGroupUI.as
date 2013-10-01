package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.engine.data.job.JobGroup;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class JobGroupUI extends Sprite
	{
		private static const BUTTON_PADDING:int = 12;
		
		private var job_reqs:Vector.<JobRequirementsUI> = new Vector.<JobRequirementsUI>();
		
		private var prev_title:String;
		
		public function JobGroupUI(){}
		
		public function show(group:JobGroup, is_active:Boolean):void {
			var i:int;
			var total:int = group.reqs.length;
			var job_req:JobRequirementsUI;
			var next_x:int;
			var divider:DisplayObject = getChildByName(JobBucketUI.DIVIDER_NAME);
			
			//reset any reqs we have
			for(i = 0; i < job_reqs.length; i++){
				job_req = job_reqs[int(i)];
				job_req.visible = false;
				job_req.x = 0;
			}			
			
			for(i = 0; i < total; i++){				
				//check if we have one in the pool we can repurpose
				if(job_reqs.length > i){
					job_req = job_reqs[int(i)];
				}
				//new one
				else {
					job_req = new JobRequirementsUI();
					job_reqs.push(job_req);
					addChild(job_req);
				}				
				
				job_req.show(group.reqs[int(i)], is_active);
				job_req.x = next_x + (divider ? divider.width + 10 : 0);
				
				next_x += job_req.width + BUTTON_PADDING;
			}			
						
			//make sure we can see this
			visible = true;
		}
	}
}