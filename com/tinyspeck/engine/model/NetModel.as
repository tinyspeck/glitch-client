package com.tinyspeck.engine.model {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.PerfLogger;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	
	import flash.utils.Dictionary;

	public class NetModel extends AbstractPropertyProvider {
		public var disconnected_msg:String;
		public var connected:Boolean = false;
		public var reconnectToken:String;
		public var should_reconnect:Boolean = false;
		public var should_reload:Boolean = false;
		public var should_reload_at_next_location_move:Boolean = false;
		public var reload_message:String;
		public var client_disconnected:Boolean = false;
		public var reconnecting_after_unexpected_disconnect:Boolean = false;
		public var sentMessages:Dictionary = new Dictionary();
		
		public var last_activity:int;
		//TODO remove one day when we're satisfied that we solved the socket readObject problems
		public var last_sent_message:Object = {};
		//TODO remove one day when we're satisfied that we solved the socket readObject problems
		public var last_rcvd_message:Object = {};
		
		private var _loggedIn:Boolean = false;
		
		public function get loggedIn():Boolean {
			return _loggedIn;
		}

		public function set loggedIn(value:Boolean):void {
			_loggedIn = value;
			PerfLogger.logged_in = value;
			StageBeacon.isLoggedIn = value;
			Benchmark.addCheck('NetModel loggedIn: '+_loggedIn);
		}
	}
}