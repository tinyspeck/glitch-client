package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.engine.data.job.JobBucket;
	import com.tinyspeck.engine.data.job.JobGroup;
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class JobBucketUI extends Sprite
	{
		public static const DIVIDER_NAME:String = 'divider';
		
		private var job_groups:Vector.<JobGroupUI> = new Vector.<JobGroupUI>();
		private var dividers:Vector.<DisplayObject> = new Vector.<DisplayObject>();
		
		private var found_active:Boolean;
		private var is_complete:Boolean;
		private var is_active:Boolean;
		
		public function JobBucketUI(){}
		
		public function show(bucket:JobBucket):void {
			var i:int;
			var total:int = bucket.groups.length;
			var job_group:JobGroupUI;
			var divider:DisplayObject;
			var divider_count:int;
			var next_x:int;
			
			//make sure we can see this
			visible = true;
			
			//reset any groups we have
			for(i = 0; i < job_groups.length; i++){
				job_group = job_groups[int(i)];
				job_group.visible = false;
				job_group.x = 0;
			}
			
			//reset any dividers we have
			for(i = 0; i < dividers.length; i++){
				divider = dividers[int(i)];
				divider.visible = false;
				
				//remove it from any group
				if(divider.parent) divider.parent.removeChild(divider);
			}
			
			found_active = false;
			
			for(i = 0; i < total; i++){
				is_active = false;
				is_complete = isGroupComplete(bucket.groups[int(i)]);
				
				if(!is_complete && !found_active){
					is_active = true;
					found_active = true;
				}
				
				//check if we have one in the pool we can repurpose
				if(job_groups.length > i){
					job_group = job_groups[int(i)];
				}
				//new one
				else {
					job_group = new JobGroupUI();
					job_groups.push(job_group);
					addChild(job_group);
				}
				
				//put the arrow on the next groups
				if(i > 0){
					if(dividers.length > i-1){
						divider = dividers[int(i-1)];
						divider.visible = true;
					}
					else {
						divider = new AssetManager.instance.assets.job_group_divider();
						divider.name = DIVIDER_NAME;
						divider.y = int(JobRequirementsUI.Y_OFFSET + (JobRequirementsUI.BUTTON_HEIGHT/2 - divider.height/2));
						dividers.push(divider);
					}
					
					job_group.addChild(divider);
				}
				
				job_group.show(bucket.groups[int(i)], is_active);
				job_group.x = next_x;
				
				next_x += job_group.width + 10;
			}
		}
		
		private static function isGroupComplete(group:JobGroup):Boolean {
			var i:int;
			var total:int = group.reqs.length;
			
			for(i; i < total; i++){
				if(!group.reqs[int(i)].completed) return false;
			}
			
			return true;
		}
	}
}