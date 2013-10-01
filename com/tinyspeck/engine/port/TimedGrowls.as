package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.ActivityModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class TimedGrowls
	{
		public static const CURRENT_SECONDS:String = '!current_seconds!';
		
		private var _growl_strings:Array;
		private var _total_seconds:int;
		private var _time_between_growls:int;
		private var _timer:Timer = new Timer(10000);
		private var _model:ActivityModel = TSModelLocator.instance.activityModel;
		
		public function TimedGrowls(growl_strings:Array = null, total_seconds:int = 0, time_between_growls:int = -1){
			_growl_strings = growl_strings;
			_total_seconds = total_seconds;
			_time_between_growls = time_between_growls;
		}
		
		public function start():void {
			//make sure we have something to growl
			if(_growl_strings.length > 0 && _total_seconds > 0){
				_timer.delay = (_time_between_growls == -1) ? Math.floor((_total_seconds*1000)/_growl_strings.length) : _time_between_growls*1000;
				_timer.start();
				_timer.addEventListener(TimerEvent.TIMER, _onTimerTick);
			}else{
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Timed growls has nothing to growl!');
				}
			}
		}
		
		private function _onTimerTick(event:TimerEvent):void {
			var pattern:RegExp = new RegExp('('+CURRENT_SECONDS+')', 'g');
			var message:String = _growl_strings[_timer.currentCount-1];
			message = message.replace(pattern, Math.ceil((_timer.delay*(_growl_strings.length-_timer.currentCount))/1000));
			
			_model.god_message = message;
			
			if(_timer.currentCount == _growl_strings.length){
				//all done, stop the timer
				_timer.stop();
				_timer.removeEventListener(TimerEvent.TIMER, _onTimerTick);
			}
		}
		
		public function set growl_strings(growl_strings:Array):void {
			_growl_strings = growl_strings;
		}
		
		public function get growl_strings():Array {
			return _growl_strings;
		}
		
		public function set total_seconds(seconds:int):void {
			_total_seconds = seconds;
		}
		
		public function get total_seconds():int {
			return _total_seconds;
		}
		
		public function set time_between_growls(seconds:int):void {
			_time_between_growls = seconds;
		}
		
		public function get time_between_growls():int {
			return _time_between_growls;
		}
		
	}
}