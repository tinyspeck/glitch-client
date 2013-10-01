package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.craftybot.CraftyJob;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CraftyDialog;
	import com.tinyspeck.engine.port.CraftyManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class CraftyJobsUI extends Sprite
	{
		private var elements:Vector.<CraftyJobElementUI> = new Vector.<CraftyJobElementUI>();
		private var add_bt:Button;
		
		private var no_queue_tf:TextField = new TextField();
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyJobsUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {
			//tf
			TFUtil.prepTF(no_queue_tf);
			no_queue_tf.width = 260;
			no_queue_tf.x = int(w/2 - no_queue_tf.width/2);
			no_queue_tf.y = 60;
			no_queue_tf.htmlText = '<p class="crafty_jobs_no_queue">Craftybot isn’t working on anything right now.<br><br><b>Why not give it a job to do?</b></p>';
			
			//bt
			add_bt = new Button({
				name: 'add',
				label: 'Start Crafting',
				size: Button.SIZE_GLITCHR,
				type: Button.TYPE_MINOR,
				w: 0 //makes the button auto-size
			});
			add_bt.addEventListener(TSEvent.CHANGED, onAddClick, false, 0, true);
			add_bt.visible = false;
			addChild(add_bt);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
			
			var i:int;
			var next_y:int;
			var total:int = elements.length;
			var element:CraftyJobElementUI;
			var job:CraftyJob;
			var pool_id:uint;
			
			//reset
			if(no_queue_tf.parent) no_queue_tf.parent.removeChild(no_queue_tf);
			
			//wipe the elements
			for(i = 0; i < total; i++){
				elements[int(i)].hide();
			}
			
			const jobs:Vector.<CraftyJob> = CraftyManager.instance.jobs;
			if(jobs && jobs.length){
				total = jobs.length;
				for(i = 0; i < total; i++){
					job = jobs[int(i)];
					if(job.status.is_active) continue; //active job shows up in the top thingie
					
					if(pool_id < elements.length){
						element = elements[int(pool_id)];
					}
					else {
						element = new CraftyJobElementUI(w);
						elements.push(element);
					}
					element.show(job);
					element.y = next_y;
					next_y += element.height;
					addChild(element);
					
					pool_id++;
				}
				
				add_bt.label = '+ Add another job';
				add_bt.y = next_y + 15;
			}
			else {
				//add a new job to the queue
				addChild(no_queue_tf);
				add_bt.label = 'Start Crafting';
				add_bt.y = int(no_queue_tf.y + no_queue_tf.height + 25);
			}
			
			//place the add button
			add_bt.x = int(w/2 - add_bt.width/2);
			add_bt.visible = true;
			
			//add a little padding
			const g:Graphics = graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0, int(add_bt.y + add_bt.height), 1, 17);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		private function onAddClick(event:TSEvent):void {
			//show the tools in the main dialog
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			CraftyDialog.instance.showTools();
		}
	}
}