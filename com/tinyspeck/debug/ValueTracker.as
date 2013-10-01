package com.tinyspeck.debug
{
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.getTimer;

	public class ValueTracker
	{
		protected var _value_tf:TextField;
		protected var order:Array = [];
		protected var elements:Object = {};
		protected var dirty:Boolean = false;
		protected var _shown:Boolean = false;
		CONFIG::debugging protected var trackSelfFunc:Function;
		
		public function log(key:String, ...values):void {
			//if (key.substr(0, 3) != 'AAA') return;
			//don't fill up the elements unless we are god. Don't want to hog memory!
			if(!(key in elements)) order.push(key);
			if (elements[key] != values.toString()) {
				elements[key] = values.toString();
				
				if (key.indexOf('zzzdebug') != 0) {
					// don't mark it dirty if it is a track for debugging this class
					dirty = true;
				}
			}
		}
		
		public function remove(key:String):void {
			delete elements[key];
			if (order.indexOf(key) > -1) { //only if the fucker exists
				order.splice(order.indexOf(key), 1);
			}
			dirty = true;
		}
		
		public function removeAll():void {
			order.length = 0;
			elements = {};
			dirty = true;
		}
		
		protected function updateLogIfDirty():void {
			if (dirty) updateLog();
		}
		
		public function set shown(s:Boolean):void {
			_shown = s;
			if (_shown) {
				updateLog();
			}
		}
		
		protected var upd_c:int = 0;
		protected var total_upd_ms:int = 0;
		protected var avg_upd_ms:Number = 0;
		protected var last_upd_time:int = getTimer();
		protected function updateLog():void {
			CONFIG::god {
				//let's see if the log is there for updating
				if(_value_tf == null) return;
				if(!_shown) return;
				
				var start:int = getTimer();
				CONFIG::debugging {
					trackSelfFunc('zzzdebug since last', getTimer()-last_upd_time);
				}
				last_upd_time = getTimer();
				
				var txt:String = '';
				var i:int = 0;
				var total:int = order.length;
				order.sort();
				for(i; i < total; i++){
					txt += order[int(i)]+' -> '+elements[order[int(i)]]+'\r';
				}
				_value_tf.text = txt;
				if (_value_tf.autoSize != TextFieldAutoSize.LEFT) {
					_value_tf.height = _value_tf.textHeight+4;
				}
				
				total_upd_ms+= (getTimer()-start);
				avg_upd_ms = (total_upd_ms/upd_c);
				upd_c++;
				CONFIG::debugging {
					trackSelfFunc('zzzdebug avg ms', total_upd_ms+'/'+upd_c+'='+avg_upd_ms.toFixed(3));
				}					
				dirty = false;
			}
		}
		
		public function set value_tf(tf:TextField):void {
			_value_tf = tf;
			dirty = true;
		}
		
		public function get value_tf():TextField {
			return _value_tf;
		}
	}
}