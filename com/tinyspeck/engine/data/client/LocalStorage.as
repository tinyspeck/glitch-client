package com.tinyspeck.engine.data.client
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.SharedObject;
	import flash.net.SharedObjectFlushStatus;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	/**
	 * LocalStorage works as such
	 * - remove all old local storage objects in the LocalStorageRequester
	 * - create a fresh TS_DATA object which will hold EVERYTHING FROM NOW TO ACQUISITION
	 * - TS_DATA.data.version is new and currently 1
	 * - TS_DATA.data.pl_tsid.* holds player preferences and chat history and is compressed
	 * - TS_DATA.data.locodeco holds uncompressed locodeco prefs
	 * - TS_DATA.data.locodeco.clipboard holds compressed clipboard
	 * - TS_DATA.data.log_data_records holds log_data_records count and is uncompressed
	 * - TS_LOG_DATA.data.net_msgs# holds log data and is compressed
	 */
	public class LocalStorage
	{	
		/********* DEFINE THINGS YOU WANT TO LOCALLY STORE **********/
		public static const IS_SOUND_MUTED:String = 'is_sound_muted';
		public static const SFX_VOLUME:String = 'sfx_volume';
		public static const MUSIC_VOLUME:String = 'music_volume';
		public static const IS_OPEN_STATS:String = 'is_open_stats';
		public static const IS_OPEN_ADMIN_DIALOG:String = 'is_open_admin_dialog';
		public static const ADMIN_DIALOG_SECTION:String = 'admin_dialog_section';
		public static const OPEN_CONTAINER_TSID:String = 'open_container_tsid';
		public static const LOCAL_CHAT_HISTORY:String = 'local_chat_history';
		public static const LAST_LOCATION_BACKUP:String = 'last_location_backup';
		public static const NET_MSGS:String = 'net_msgs';
		public static const CONTACT_LIST_OPEN:String = 'contact_list_open';
		public static const CONTACT_LIST_Y:String = 'contact_list_y';
		public static const MAP_Y:String = 'map_y';
		public static const LAST_MAP_TAB:String = 'last_map_tab';
		public static const MAP_CENTERED:String = 'map_centered';
		public static const MAP_HIDDEN:String = 'map_hidden';
		public static const GROUPS_OPEN:String = 'groups_open';
		public static const LOG_DATA_RECORDS:String = 'log_data_records';
		public static const CHAT_HISTORY:String = 'chat_history';
		public static const LOCODECO_CLIPBOARD:String = 'locodeco_clipboard';
		public static const LAST_UPDATE_FEED_TIMESTAMP:String = 'last_update_feed_timestamp';
		CONFIG::god public static const GOD_BUTTONS_PINNED:String = 'god_buttons_pinned';
		/************************************************************/
		
		private static const SO_NAME:String = 'TS_DATA';
		private static const SO_LOG_NAME:String = 'TS_LOG_DATA';
		public static const instance:LocalStorage = new LocalStorage();
		
		private var _pc_tsid:String;
		private var _so:SharedObject;
		/** flush the SO every 5 minutes */
		private var flush_timer:Timer = new Timer(300000);
				
		/* constructor */
		public function LocalStorage() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function init():void {
			try {
				_so = SharedObject.getLocal(SO_NAME, '/');
				_so.addEventListener(NetStatusEvent.NET_STATUS, function():void{});

				// prepare storage for current PC
				if (!_so.data.hasOwnProperty(_pc_tsid)) { 
					_so.data[_pc_tsid] = {};
					// so we can figure out what objects are PCs when iterating
					_so.data['is_pc'] = true;
				}

				//flush the SO every 5 minutes
				flush_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
				
				// remove legacy log data
				removeData(_so.data, 'log_data');
			} catch (err:Error) {
				CONFIG::debugging {
					Console.warn('could not create shared object');
				}
			}
		}
		
		public function appendLogData(data:Array):Boolean {
			try {
				var log_so:SharedObject = SharedObject.getLocal(SO_LOG_NAME, '/');
				if (!log_so) return false;
				var count:int = getGlobalData(LOG_DATA_RECORDS) || 0;
				var name:String = NET_MSGS+String(count);
				CONFIG::debugging {
					Console.info('appendLogData name:'+name);
				}
				//const logs:Object = getData(log_so.data, name) || {};
				//logs[name] = data;
				// set this data in the global store, not in PC storage
				setGlobalData(LOG_DATA_RECORDS, count+1, true); // set this in global
				return setData(log_so.data, name, data, false); // here
			} catch(err:Error) {
				CONFIG::debugging {
					Console.error(err);
				}
			}
			
			return false;
		}
			
		public function getLogData():Array {
			try {
				var log_so:SharedObject = SharedObject.getLocal(SO_LOG_NAME, '/');
				var A:Array = [];
				if (!log_so || (log_so.size == 0)) return A;
				var bytes:ByteArray;
				var byteArray:ByteArray;
				var count:int = getGlobalData(LOG_DATA_RECORDS) || 0;
				
				const logs:Object = log_so.data;
				for (var i:int=0;i<count;i++) {
					var name:String = NET_MSGS+String(i);// decompress
					if (log_so.data[name] is ByteArray) {
						bytes = new ByteArray();
						byteArray = log_so.data[name];
						if (!byteArray || (byteArray.length == 0)) continue;
						bytes.writeBytes(byteArray);
						bytes.uncompress();
						var A2:Array = bytes.readObject();
						/*CONFIG::debugging {
						Console.info('concat name:'+name+' '+A2.length);
						}*/
						A = A.concat(A2);
					}
				}
				return A;
			} catch(err:Error) {
				CONFIG::debugging {
					Console.error(err);
				}
			}
			return null;
		}
		
		public function removeLogStorage():void {
			try {
				var log_so:SharedObject = SharedObject.getLocal(SO_LOG_NAME, '/');
				setGlobalData(LOG_DATA_RECORDS, 0,  true); // set this in global
				if (!log_so) return;
				log_so.clear();
				log_so.flush();
			} catch(err:Error) {
				CONFIG::debugging {
					Console.error(err);
				}
			}
		}

		CONFIG::debugging public function trackAllData():void {
			if (!_so) return;
			var val:*;
			for (var k:String in _so.data) {
				if (k == 'is_pc') continue;
				val = _so.data[k];
				if (val is ByteArray) val = 'a ByteArray';
				Console.trackValue('LS '+k, val);
			}
			if (!_pc_tsid || !_so.data[_pc_tsid]) return;
			for (k in _so.data[_pc_tsid]) {
				if (k == 'is_pc') continue;
				val = getUserData(k);
				if (val is ByteArray) val = 'a ByteArray';
				Console.trackValue('LS.'+_pc_tsid+' '+k, val);
			}
		}
		
		public function removeUserData(name:String):Boolean {
			if (!_so) return false;
			return removeData(_so.data[_pc_tsid], name);
		}
		
		private function removeData(from:Object, name:String):Boolean {
			if (!from) return false;
			
			if (name in from) {
				delete from[name];
				CONFIG::debugging {
					Console.removeTrackedValue('LS '+name);
				}
			} else {
				return false;
			}
			
			return flushIt(0, name);
		}
		
		public function setGlobalData(name:String, data:*, flush:Boolean = false):Boolean {
			if (!_so) return false;
			return setData(_so.data, name, data, flush);
		}
		
		public function setUserData(name:String, data:*, flush:Boolean = false):Boolean {
			if (!_so) return false;
			return setData(_so.data[_pc_tsid], name, data, flush);
		}
		
		private function setData(to:Object, name:String, data:*, flush:Boolean):Boolean {
			if (!to) return false;
			
			var needed:uint = 0;
			
			if ((data is String || data is Boolean) && !data) {
				return removeData(to, name); // NEED TO PASS THE to
			} else {
				// compress and store
				const bytes:ByteArray = new ByteArray();
				bytes.writeObject(data);
				bytes.compress();
				to[name] = bytes;
				needed = bytes.length;
			}
			
			//if we are NOT flushing, then start a timer to flush it each minute
			if(!flush && !flush_timer.running) flush_timer.start();
			
			return (flush ? flushIt(needed, name) : true);
		}
		
		public function flushIt(needed:uint, name:String):Boolean {
			if (!_so) return false;
			try {
				const result:String = _so.flush(needed);
				CONFIG::debugging {
					trackAllData();
				}
				if (result == SharedObjectFlushStatus.FLUSHED) {
					return true;
				}
			} catch(err:Error) {
				BootError.handleError('setData could not flush so, trying to store or remove name:'+name, err, ['storage'], true);
			}
			return false;
		}
		
		public function getGlobalData(name:String):* {
			if (!_so) return;
			return getData(_so.data, name);
		}
		
		public function getUserData(name:String):* {
			if (!_so) return;
			return getData(_so.data[_pc_tsid], name);
		}
		
		private function getData(from:Object, name:String):* {
			if (!from) return;
			var ret:*;
			
			// decompress
			const bytes:ByteArray = new ByteArray();
			const byteArray:ByteArray = from[name];
			if (!byteArray || byteArray.length == 0) return;
			bytes.writeBytes(byteArray);
			bytes.uncompress();
			ret = bytes.readObject();
			
			return ret;
		}
		
		public function removeLocalStorage():void {
			if (!_so) return;
			_so.clear();
			_so.flush();
			CONFIG::debugging {
				Console.warn(SO_NAME+' SharedObject has been deleted!');
			}
		}
		
		/**
		 * Get the size of the SharedObject. USE THIS ONLY FOR ERROR REPORTING!!! (It's VERY expensive)
		 * @return number of bytes the SO is. Will return -1 if no SO found.
		 */		
		public function getStorageSize():Number {
			if(!_so) return -1;
			
			return _so.size;
		}
		
		private function onTimerTick(event:TimerEvent):void {
			//flush the SO
			flushIt(0, 'TimerEvent');
			//Console.warn('Flushing SharedObject data');
		}
		
		/**
		 * This is done only once in the BootStrap so we can get the TSID of the player 
		 * @param value player's TSID
		 */		
		public function set boot_pc_tsid(value:String):void { 
			_pc_tsid = value;
			init();
		}
	}
}