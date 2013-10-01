package com.tinyspeck.bootstrap.model
{
	import com.tinyspeck.bridge.PrefsModel;
	
	CONFIG::debugging { import com.tinyspeck.debug.Console; }

	public class BootStrapModel
	{
		/* singleton boilerplate */
		public static const instance:BootStrapModel = new BootStrapModel();

		public var prefsModel:PrefsModel;
		public var api_token:String;
		
		private var _host:String;
		private var _low_port:int;
		private var _use_high_port_by_default:Boolean = true;
		private var _use_high_port:Boolean;
		private var _token:String;
		
		public function BootStrapModel() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			prefsModel = new PrefsModel();
			if (_use_high_port_by_default) {
				_use_high_port = true;
			}
		}
		
		public function get token():String
		{
			return _token;
		}

		public function set token(value:String):void
		{
			CONFIG::debugging {
				Console.warn(value);
			}
			_token = value;
		}

		/** Returns the correct port given the low_port and use_high_port */
		public function get port():uint {
			return _low_port + (use_high_port ? 1000 : 0);
		}
		
		/** The unmodified base port sent by the GS */
		public function get low_port():uint {
			return _low_port;
		}

		public function set low_port(value:uint):void {
			_low_port = value;
		}
		
		public function get use_high_port():Boolean {
			return _use_high_port;
		}
		
		public function get using_default_port():Boolean {
			if (_use_high_port_by_default) {
				return use_high_port;
			} else {
				return !use_high_port;
			}
		}
		
		public function switchToFallBackPort():void {
			if (_use_high_port_by_default) {
				_use_high_port = false;
			} else {
				_use_high_port = true;
			}
		}

		public function get host():String
		{
			return _host;
		}

		public function set host(value:String):void
		{
			CONFIG::debugging {
				Console.warn(value);
			}
			_host = value;
		}
	}
}