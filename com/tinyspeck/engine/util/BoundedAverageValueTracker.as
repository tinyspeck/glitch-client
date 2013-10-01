package com.tinyspeck.engine.util {
	import com.tinyspeck.engine.util.datastructures.BoundedQueue;
	
	/** Track the average of the last N values in constant time and linear space */
	public final class BoundedAverageValueTracker {
		
		private var _queue:BoundedQueue;
		private var _runningAverage:Number = 0;
		private var _min:Number = Number.MAX_VALUE;
		private var _max:Number = Number.MIN_VALUE;
		private var _trackMinMax:Boolean;
		
		public function BoundedAverageValueTracker(length:int, trackMinMax:Boolean = false) {
			_queue = new BoundedQueue(length);
			_trackMinMax = trackMinMax;
		}
		
		/** Track a new value (overwriting the oldest value) */
		public function push(value:Number):void {
			var len:Number;
			if (_queue.full()) {
				// throw out the oldest value
				const oldestValue:Number = Number(_queue.pop());
				// add the new value
				_queue.push(value);
				// update the average
				len = _queue.length;
				_runningAverage = ((value - oldestValue + (len * _runningAverage)) / len);
			} else {
				// add the new value
				_queue.push(value);
				// update the average
				len = _queue.length;
				_runningAverage = ((value + ((len - 1) * _runningAverage)) / len);
			}
			if (_trackMinMax) {
				_min = Math.min(_runningAverage, _min);
				_max = Math.max(_runningAverage, _max);
			}
		}	
		
		/** Returns the running average in O(1) or NaN if there are no values yet */
		public function get averageValue():Number {
			return _runningAverage;
		}
		
		/** Returns the max seen since the last reset */
		public function get max():Number {
			return _max;
		}
		
		/** Resets the min and max values seen */
		public function resetMinMax():void {
			_min = Number.MAX_VALUE;
			_max = Number.MIN_VALUE;
		}
		
		/** Resets everything */
		public function reset():void {
			if (_trackMinMax) resetMinMax();
			_queue.clear();
		}
		
		public function toString():String {
			return ('[BoundedAverageValueTracker avg: ' + _runningAverage.toFixed(4) + 
				'\t_queue:'+_queue + 
				'\taverageValue:'+averageValue +
				(_trackMinMax ? 
					('\tmin: ' + _min.toFixed(4) +
						'\tmax: ' + _max.toFixed(4)) : ''))+
				']';
		}
	}
}