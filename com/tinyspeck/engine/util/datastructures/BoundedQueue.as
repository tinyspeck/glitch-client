package com.tinyspeck.engine.util.datastructures {
	/** A fixed queue of length N with constant-time operations */
	public final class BoundedQueue {
		private var _items:Vector.<Object>;
		private var _maxLength:int;
		private var _length:int = 0;
		private var _start:int  = 0;
		private var _end:int    = 0;
		
		public function BoundedQueue(length:int) {
			_maxLength = length;
			_items = new Vector.<Object>(length, true);
		}
		
		/** Return current length of queue (fast) */
		public function get length():int {
			return _length;
		}
		
		/** Returns true when the queue is empty */
		public function empty():Boolean {
			return (!_length);
		}
		
		/** Returns true when the queue is full */
		public function full():Boolean {
			return (_length == _maxLength);
		}
		
		/** Returns the front of a (presumed) non-empty queue without popping */
		public function peek():Object {
			return _items[int(_start)];
		}
		
		/** Returns and removes the front of a non-empty queue or null */
		public function pop():Object {
			var val:Object = null;
			if (_length) {
				val = _items[int(_start)];
				_start = ((_start+1) % _maxLength);
				_length--;
			}
			return val;
		}
		
		/** Adds the value to the back of the queue; returns false if already full */
		public function push(value:Object):Boolean {
			if (_length < _maxLength) {
				_items[int(_end)] = value;
				_end = ((_end+1) % _maxLength);
				_length++;
				return true;
			}
			return false;
		}
		
		public function clear():void {
			_length = 0;
			_start  = 0;
			_items[int(0)] = null;
			_end    = 0;
		}
		
		public function toString():String {
			return ('[BoundedQueue _items: ' + _items+']');
		}
	}
}