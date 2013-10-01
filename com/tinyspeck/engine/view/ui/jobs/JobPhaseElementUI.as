package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.engine.data.job.JobPhase;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class JobPhaseElementUI extends Sprite
	{
		private var num_tf:TextField = new TextField();
		
		private var h:int;
		
		public function JobPhaseElementUI(h:int){
			this.h = h;
			
			TFUtil.prepTF(num_tf);
			num_tf.mouseEnabled = false;
			num_tf.width = h;
			num_tf.htmlText = '<p class="job_phase_num">88</p>';
			num_tf.y = int(h/2 - num_tf.height/2) + 1;
			addChild(num_tf);
		}
		
		public function show(phase:JobPhase, is_current:Boolean):void {
			visible = true;
			
			name = phase.hashName;
			
			var txt:String = '<p class="job_phase_num">';
			txt += is_current ? '<span class="job_phase_num_active">'+(int(phase.hashName)+1)+'</span>' : int(phase.hashName)+1;
			txt += '</p>';
			
			//populate the number
			num_tf.filters = is_current ? StaticFilters.black1px270Degrees_DropShadowA : StaticFilters.white1px90Degrees_DropShadowA;
			num_tf.htmlText = txt;
			
			//draw the circle
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(is_current ? 0x62800f : 0xc8d6db);
			g.drawCircle(h/2, h/2, h/2);
		}
	}
}