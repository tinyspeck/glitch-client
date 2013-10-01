package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.job.JobPhase;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.JobManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class JobPhaseUI extends Sprite implements ITipProvider
	{
		private static const HEIGHT:uint = 24;
		
		private var all_holder:Sprite = new Sprite();
		private var white_block:Sprite = new Sprite();
		
		private var progress:ProgressBar;
		private var elements:Vector.<JobPhaseElementUI> = new Vector.<JobPhaseElementUI>();
		
		private var active_tf:TextField = new TextField();
		private var pb_active_tf:TextField = new TextField();
		private var pb_perc_tf:TextField = new TextField();
						
		private var _w:int;
		
		public function JobPhaseUI(w:int){
			_w = w;
			
			mouseEnabled = false;
			
			var cssm:CSSManager = CSSManager.instance;
			var pb_bar_top:uint = cssm.getUintColorValueFromStyle('job_phase_pb', 'topColor', 0xd2e1a6);
			var pb_bar_bottom:uint = cssm.getUintColorValueFromStyle('job_phase_pb', 'bottomColor', 0xc0d582);
			var pb_tip_top:uint = cssm.getUintColorValueFromStyle('job_phase_pb', 'tipTopColor', 0x99ab65);
			var pb_tip_bottom:uint = cssm.getUintColorValueFromStyle('job_phase_pb', 'tipBottomColor', 0x99ab65);
			
			progress = new ProgressBar(302, HEIGHT);
			progress.setFrameColors(0xd8dada, 0x979898);
			progress.setBarColors(pb_bar_top, pb_bar_bottom, pb_tip_top, pb_tip_bottom);
			
			TFUtil.prepTF(pb_active_tf, false);
			pb_active_tf.htmlText = '<p class="job_phase_pb_active">Placeholderp</p>';
			pb_active_tf.x = int(HEIGHT/2 + 5);
			pb_active_tf.y = int(HEIGHT/2 - pb_active_tf.height/2) + 1;
			progress.addChild(pb_active_tf);
			
			TFUtil.prepTF(pb_perc_tf, false);
			pb_perc_tf.autoSize = TextFieldAutoSize.RIGHT;
			pb_perc_tf.x = progress.width - 10;
			pb_perc_tf.htmlText = '<p class="job_phase_pb_perc">0.0%</p>';
			pb_perc_tf.y = int(HEIGHT/2 - pb_perc_tf.height/2) + 1;
			progress.addChild(pb_perc_tf);
			
			addChild(white_block);
			addChild(progress);
			addChild(all_holder);
			
			//active
			TFUtil.prepTF(active_tf, false);
			addChild(active_tf);
			
			draw();
		}
		
		public function show(is_intro:Boolean):void {
			var phases:Vector.<JobPhase> = JobManager.instance.job_info.phases;
			var phase_index:int = JobManager.instance.job_info.getCurrentPhaseIndex();
			var current_phase:JobPhase;
			var i:int;
			var total:int = phases.length;
			var element:JobPhaseElementUI;
			var next_x:int;
			var gap:int;
			
			if(phase_index == -1) {
				//job must be done, but let's make sure
				if(phases[phases.length-1].is_complete){
					phase_index = phases.length-1;
				}
				else {
					//this ain't good
					CONFIG::debugging {
						Console.warn('phase_index -1 and last phase is not complete');
					}
					BootError.handleError('phase total: '+phases.length, new Error('Job phase effed up'), null, true);
					return;
				}
			}
			
			visible = true;
						
			progress.visible = !is_intro;
			white_block.visible = is_intro;
			active_tf.visible = is_intro;
			
			current_phase = phases[phase_index];
			progress.x = 0;
			pb_active_tf.htmlText = '<p class="job_phase_pb_active">'+current_phase.name+'</p>';
			
			active_tf.htmlText = is_intro ? '<p class="job_phase_active">Phase '+(phase_index+1)+': '+current_phase.name+'</p>' : '';
			active_tf.x = 0;
			active_tf.y = int(HEIGHT/2 - active_tf.height/2) + 1;
			
			white_block.x = 0;
			var g:Graphics = white_block.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, is_intro ? active_tf.width + 10 : 1, HEIGHT);
			
			//calculate the gap between circles
			gap = (_w - (is_intro ? white_block.width : progress.width + HEIGHT/2))/(total-1); //+HEIGHT/2 because progress goes UNDER the number
			
			//hide any elements we already have
			for(i = 0; i < elements.length; i++){
				element = elements[int(i)];
				element.x = 0;
				element.visible = false;
			}
			
			for(i = 0; i < total; i++){				
				//reuse
				if(elements.length > i){
					element = elements[int(i)];
				}
				//new one
				else {
					element = new JobPhaseElementUI(HEIGHT);
					elements.push(element);
					all_holder.addChild(element);
				}
				
				element.x = next_x;
				element.show(phases[int(i)], i == phase_index);
				
				next_x += gap;
				if(i == phase_index){
					if(is_intro) active_tf.x = element.x + HEIGHT + 5;
					if(is_intro) white_block.x = element.x + HEIGHT;
					if(!is_intro) progress.x = element.x + HEIGHT/2 + 2; //visual tweak
					
					next_x += is_intro ? white_block.width : progress.width - HEIGHT/2 + 2;
					
					TipDisplayManager.instance.unRegisterTipTrigger(element);
				}
				else {
					TipDisplayManager.instance.registerTipTrigger(element);
				}
			}
		}
		
		public function hide():void {
			visible = false;
		}
		
		private function draw():void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xc8d6db);
			g.drawRect(0, HEIGHT/2, _w, 2);
		}
		
		public function updateProgress(percent:Number):void {
			progress.update(percent);
			pb_perc_tf.htmlText = '<p class="job_phase_pb_perc">'+(percent*100).toFixed(1)+'% complete</p>';
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !JobManager.instance.job_info) return null;
			const phase:JobPhase = JobManager.instance.job_info.phases[int(tip_target.name)];
						
			return {
				txt: 'Phase '+(int(tip_target.name)+1)+': '+(phase.is_complete ? phase.name : "It's a secret!"),
				pointer: WindowBorder.POINTER_BOTTOM_CENTER	
			}
		}
				
		public function get w():int { return _w; }
		public function set w(value:int):void {
			_w = value;
			draw();
		}
		
		public function get h():int { return HEIGHT; }
	}
}