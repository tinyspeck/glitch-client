package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.craftybot.CraftyJob;
	
	import flash.display.Sprite;

	public class CraftyActiveUI extends Sprite
	{
		private var in_progress:CraftyProgress;
		private var job_complete:CraftyProgress;
		private var element:CraftyActiveElementUI;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyActiveUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {
			in_progress = new CraftyProgress(w, false);
			addChildAt(in_progress, 0);
			
			const element_padd:uint = 6;
			element = new CraftyActiveElementUI(w + element_padd*2);
			element.x = -element_padd;
			element.y = int(in_progress.height + 1);
			addChild(element);
			
			job_complete = new CraftyProgress(w, true);
			addChildAt(job_complete, 0);
			
			is_built = true;
		}
		
		public function show(job:CraftyJob):void {
			if(!is_built) buildBase();
			
			in_progress.show(job);
			job_complete.show(job);
			
			element.show(job);
			
			job_complete.y = int(element.y + element.height + 1);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			
			if(!is_built) return;
			in_progress.hide();
			job_complete.hide();
		}
		
		override public function get height():Number {
			if(!is_built) return 0;
			return job_complete.y + job_complete.height + 1; //border
		}
	}
}