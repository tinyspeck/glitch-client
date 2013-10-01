package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.data.transit.TransitStatus;
	import com.tinyspeck.engine.event.TSEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class TransitManager extends EventDispatcher
	{
		/* singleton boilerplate */
		public static const instance:TransitManager = new TransitManager();
		
		private var _current_status:TransitStatus;
		private var travel_timer:Timer = new Timer(1000); //delay changes when the message comes in
				
		public function TransitManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function status(payload:Object):void {
			//make sure the proper transit map has the right info about current/next location
			_current_status = TransitStatus.fromAnonymous(payload, payload.tsid);
			dispatchEvent(new TSEvent(TSEvent.CHANGED, _current_status));
			
			//if there was a time and we haven't set up the timer yet
			if(_current_status.time_to_destination){
				if(!travel_timer.hasEventListener(TimerEvent.TIMER)){
					travel_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
				}
				
				//start countin'
				travel_timer.delay = _current_status.time_to_destination * 1000;
				travel_timer.reset();
				if(!travel_timer.running) travel_timer.start();
			}
		}
		
		public function clear():void {
			_current_status = null;
		}
		
		private function onTimerTick(event:TimerEvent = null):void {
			//let the listeners know
			dispatchEvent(new TSEvent(TSEvent.TIMER_TICK));
			travel_timer.stop();
		}
		
		public function get current_location_tsid():String {
			if(_current_status) return _current_status.current_tsid;
			
			return null;
		}
		
		public function get next_location_tsid():String {
			if(_current_status) return _current_status.next_tsid;
			
			return null;
		}
		
		public function get current_transit_tsid():String {
			if(_current_status) return _current_status.tsid;
			
			return null;
		}
		
		public function get current_status():TransitStatus {
			return _current_status;
		}
	}
}