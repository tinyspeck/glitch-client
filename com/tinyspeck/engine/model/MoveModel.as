package com.tinyspeck.engine.model {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.loading.LoadingInfo;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	import com.tinyspeck.engine.util.StringUtil;
	
	import org.osflash.signals.Signal;
	
	public class MoveModel extends AbstractPropertyProvider {
				
		public static const DOOR_MOVE:String = 'door';
		public static const SIGNPOST_MOVE:String = 'signpost';
		public static const TELEPORT_MOVE:String = 'teleport';
		public static const FOLLOW_MOVE:String = 'follow';
		public static const LOGIN_MOVE:String = 'login';
		public static const RELOGIN_MOVE:String = 'relogin';
		
		public var relogin:Boolean = false;
		private var _moving:Boolean = false;

		public function get moving():Boolean {
			return _moving;
		}

		public function set moving(value:Boolean):void {
			//if (_moving != value) {
				CONFIG::debugging {
					Console.info('MOVING SET TO '+value+' '+StringUtil.getCallerCodeLocation());
				}
			//}
			_moving = value;
			StageBeacon.isMoving = value;
		}

		public var rebuilding_location:Boolean;
		public var move_failed:Boolean = false;
		public var move_type:String;
		public var from_tsid:String = '';
		public var signpost_index:String = ''; // used by signpost moves
		public var to_tsid:String = ''; // used by teleport_follow moves
		private var _move_was_in_location:Boolean = true;
		public var move_was_in_location_sig:Signal = new Signal(String);

		public function get move_was_in_location():Boolean {
			return _move_was_in_location;
		}

		public function set move_was_in_location(value:Boolean):void {
			_move_was_in_location = value;
			if (_move_was_in_location) {
				move_was_in_location_sig.dispatch(move_type);
			}
		}

		public var delay_loading_screen_ms:int = 0;
		public var loading_info:LoadingInfo;
		public var loading_music:String = ''; //if loading_music is sent on the *_move_start we hang on to the ref of it here
				
		//Err, network settings in an implict move model ? 
		private var _host:String = '';//What 
		private var _low_port:int;//What 
		private var _use_high_port:Boolean;
		private var _token:String = '';
		
		public function MoveModel() {
			super();
		}
		
		public function set host(value:String):void {
			if (!value) return;
			Benchmark.addCheck('got new host: '+value);
			_host = value;
		}

		/** The unmodified base port sent by the GS */
		public function set low_port(value:int):void {
			if (!value) return;
			Benchmark.addCheck('got new low_port: '+value);
			_low_port = value;
		}

		public function set token(value:String):void {
			if (!value) return;
			Benchmark.addCheck('got new token: '+value);
			_token = value;
		}

		public function set use_high_port(value:Boolean):void {
			Benchmark.addCheck('got new use_high_port: '+value);
			_use_high_port = value;
		}
		
		public function get use_high_port():Boolean {
			return _use_high_port;
		}
		
		public function get token():String {
			return _token;
		}

		public function get low_port():int {
			return _low_port;
		}
		
		/** Returns the correct port given the low_port and use_high_port */
		public function get port():int {
			return _low_port + (use_high_port ? 1000 : 0);
		}
		
		public function get host():String {
			return _host;
		}
	}
}