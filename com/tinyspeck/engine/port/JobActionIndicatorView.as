package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	

	public class JobActionIndicatorView extends ActionIndicatorView
	{
		public static const QUEST_ACTIVE:String = 'quest_active';
		public static const QUEST_COMPLETE:String = 'quest_complete';
		
		public var job_id:String;
		
		private var phase_timer:Timer;
		private var _current_available_time:int;
		
		public function JobActionIndicatorView(itemstack_tsid:String, type:String = JobActionIndicatorView.QUEST_ACTIVE){
			super(itemstack_tsid, type);
			// super calls init()
		}
		
		override protected function init():void {
			
			// define classes for tfs
			msg_tf_css_class = 'quest_bubble_msg';
			alt_msg_tf_css_class = 'quest_bubble_alt_msg';
			
			//setup the icon
			_icon = new AssetManager.instance.assets[getIconNameFromType()]();
			
			//progress color/alpha
			progress_color = CSSManager.instance.getUintColorValueFromStyle('quest_bubble_progress', 'color', progress_color);
			progress_alpha = CSSManager.instance.getNumberValueFromStyle('quest_bubble_progress', 'alpha', progress_alpha);
			
			useHandCursor = buttonMode = true;
			mouseChildren = false;
			
			super.init();
		}
		
		private function getIconNameFromType():String {
			if (type == QUEST_ACTIVE) return 'quest_bubble_active';
			if (type == QUEST_COMPLETE) return 'quest_bubble_complete';
			
			// return a valid one in any case
			return 'quest_bubble_active';
		}
		
		override public function set type(str:String):void {
			if ([QUEST_ACTIVE, QUEST_COMPLETE].indexOf(str) == -1) {
				CONFIG::debugging {
					Console.error('illegal type:'+str);
				}
				return;
			}
			
			if(_type != str){
				//we need a new icon
				_icon = new AssetManager.instance.assets[getIconNameFromType()]();
			}

			super.type = str;
		}
		
		private function onTimerTick(event:TimerEvent = null):void {
			var time_left:String = StringUtil.formatTime(current_available_time, false);
			
			if(current_available_time < 60 && current_available_time > 0){					
				//less than a minute
				time_left = 'Less than 1 min';
			}
			else if(current_available_time <= 0){
				_current_available_time = 0;
				msg = 'Project available';
				alt_msg = '';
				phase_timer.stop();
				return;
			}
			
			msg = '<span class="quest_bubble_phase_time">'+time_left+'</span>'+
				  '<br><span class="quest_bubble_complete">until next phase</span>';
			
			//decrement the current time by delay
			_current_available_time -= phase_timer.delay/1000;
		}
		
		public function stopTimer():void {
			if(phase_timer) phase_timer.stop();
			_current_available_time = 0;
		}
		
		public function get current_available_time():int { return _current_available_time; }
		public function set current_available_time(value:int):void {
			_current_available_time = value;
					
			if(!phase_timer && value > 0){
				phase_timer = new Timer(1000);
				phase_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			}
			
			phase_timer.delay = 0;
			onTimerTick();
			phase_timer.delay = 1000;
			
			//start/stop if we need to
			if(value > 0){
				phase_timer.reset();
				phase_timer.start();
			} else if (phase_timer){
				phase_timer.stop();
			}
		}
	}
}