package com.tinyspeck.core.beacon
{
	CONFIG const callback_debug:Boolean = false;
	
	import de.polygonal.core.ObjectPool;
	
	/**
	 * Support class for StageBeacon.setTimeout() that provides a more efficient
	 * implementation of setTimeout with as3-signals instead of Timers.
	 * 
	 * Note that code only runs during the game loop, not when rendering frames.
	 */
	internal final class SetTimeoutController {
		/** Cached list used during onGameLoop to avoid object creation */
		// you cannot parameterize a Vector with a nested class, so it must be an Array
		private static const reusableDelayedCallbackNodeList:Array = [];
		
		private static var DelayedCallbackNodePool:ObjectPool;
		
		// Implementation note:
		//
		// A linked list is used for the callbacks to maintain order (unlike a
		// Dictionary), to not be affected by the potential addition of items while
		// iterating (unlike a Dictionary, or an iterator over a Vector), and to
		// make insertions and deletions constant time without the need to compact
		// the data structure eventually as we remove items (unlike a Vector).
		// 
		// Iteration, addition, and deletion will be the most common operations,
		// which linked lists are great at, and there will not be any indexing of
		// individual elements, which they suck at.
		private static var delayedCallbacks:DelayedCallbackList;
		
		public static function init():void {
			DelayedCallbackNodePool = new ObjectPool(true);
			DelayedCallbackNodePool.allocate(DelayedCallbackNode, 50, 15, DelayedCallbackNode.resetInstance);
			
			delayedCallbacks = new DelayedCallbackList();
			
			StageBeacon.render_sig.add(onRender);
			StageBeacon.game_loop_sig.add(onGameLoop);
		}
		
		/**
		 * Use this instead of e.g. setTimeout(f, time, ... args) to get a
		 * callback to run at the time specified, guaranteed to run no earlier
		 * than the next fully rendered frame.
		 * 
		 * Returns id of callback in case you want to clearTimeout again later
		 * (guaranteed to be greater than 0).
		 */
		public static function setTimeout(callback:Function, delay:Number, frames:uint, args:Array = null):uint {
			const node:DelayedCallbackNode = getDelayedCallbackNode(callback, delay, frames, args);
			delayedCallbacks.add(node);
			return node.callback.id;
		}
		
		public static function clearTimeout(id:uint):void {
			// ids are always greater than one, short-circuit
			if (id == 0) return;
			
			CONFIG::callback_debug {
				trace ('clearTimeout(' + id + ')');
			}
			var node:DelayedCallbackNode = delayedCallbacks.head;
			while (node) {
				if (node.callback.id == id) {
					CONFIG::callback_debug {
						trace ('\t\tREMOVING:' + node);
					}
					delayedCallbacks.remove(node);
					
					CONFIG::callback_debug {
						trace ('\t\tRETURNING:' + node);
					}
					DelayedCallbackNodePool.returnObject(node);
					CONFIG::callback_debug {
						trace ('\t\tRETURNED:' + node);
					}
					break;
				}
				node = node.next;
			}
		}
		
		/**
		 * Use this instead of e.g. setInterval(f, time, ... args) to get a
		 * callback to run at the time specified, guaranteed to run no earlier
		 * than the next fully rendered frame.
		 * 
		 * Returns id of callback in case you want to clearInterval again later
		 * (guaranteed to be greater than 0).
		 */
		public static function setInterval(callback:Function, delay:Number, frames:uint, args:Array = null):uint {
			const node:DelayedCallbackNode = getDelayedCallbackNode(callback, delay, frames, args);
			node.callback.interval = true;
			delayedCallbacks.add(node);
			return node.callback.id;
		}
		
		public static function clearInterval(id:uint):void {
			clearTimeout(id);
		}
		
		private static function getDelayedCallbackNode(callback:Function, delay:Number, frames:uint, args:Array):DelayedCallbackNode {
			const node:DelayedCallbackNode = DelayedCallbackNodePool.borrowObject();
			node.init();
			node.callback.frames = frames;
			node.callback.delay = delay;
			node.callback.callback = callback;
			node.callback.args = args;
			return node;
		}
		
		private static function onRender():void {
			// short-circuit the callback (unnecessary, but faster)
			if (delayedCallbacks.length == 0) return;
			
			var node:DelayedCallbackNode = delayedCallbacks.head;
			while (node) {
				node.callback.tickFrames();
				node = node.next;
			}
		}
		
		private static function onGameLoop(ms_elapsed:int):void {
			// short-circuit the callback (unnecessary, but faster)
			if (delayedCallbacks.length == 0) return;
			
			var nextNode:DelayedCallbackNode;
			var node:DelayedCallbackNode = delayedCallbacks.head;
			
			CONFIG::callback_debug {
				trace('START onGameLoop ' + ms_elapsed);
				trace('ORIGINAL LIST: ' + delayedCallbacks);
				trace('PROCESSING');
			}
			
			while (node) {
				node.callback.tickTime();
				
				// caching is necessary in case the node is removed
				// as the reference is automatically nulled
				nextNode = node.next;
				
				CONFIG::callback_debug {
					trace ('\tNODE:' + node);
					trace ('\t\tNEXT:' + nextNode);
				}
				
				if (node.callback.readyToDoCallback()) {
					CONFIG::callback_debug {
						trace ('\t\tREADY:' + node);
					}
					
					reusableDelayedCallbackNodeList.push(node);
					
					if (node.callback.interval) {
						// interval timer
						node.callback.restartIntervalTimer();
					} else {
						// normal timer
						delayedCallbacks.remove(node);
						CONFIG::callback_debug {
							trace ('\t\tREMOVED:' + node);
						}
					}
				}
				
				node = nextNode;
			}

			// it isn't safe to do the callbacks while we're iterating the
			// linked list, as the list may be modified by the callbacks
			var isIntervalTimer:Boolean;
			for each (node in reusableDelayedCallbackNodeList) {
				// do this before doCallback(), just in case clearInterval()
				// is called during it, which will clear the interval
				isIntervalTimer = node.callback.interval;
				
				CONFIG::callback_debug {
					trace ('\tDOING CALLBACK:' + node);
				}
				node.callback.doCallback();
				CONFIG::callback_debug {
					trace ('\tDID CALLBACK:' + node);
				}

				// interval timers are only removed with clearInterval
				if (isIntervalTimer) continue;
				
				// but for normal timers...
				if (node.initialized) {
					CONFIG::callback_debug {
						trace ('\t\tRETURNING:' + node);
					}
					DelayedCallbackNodePool.returnObject(node);
					CONFIG::callback_debug {
						trace ('\t\tRETURNED:' + node);
					}
				} else {
					// if clearTimeout() was called as a side-effect by
					// doCallback(), the node will have been reset and
					// already returned to the pool
				}
			}
			reusableDelayedCallbackNodeList.length = 0;
			
			CONFIG::callback_debug {
				trace('END onGameLoop ' + ms_elapsed);
			}
		}
	}
}

import de.polygonal.core.IPoolableObject;

import flash.utils.getTimer;
	
class Callback implements IPoolableObject {
	public var callback:Function;
	public var args:Array;
	
	public function doCallback():void {
		callback.apply(null, args);
	}
	
	public function reset():void {
		callback = null;
		args = null;
	}
}

class DelayedCallback extends Callback {
	// increments automatically
	private static var next_id:uint = 1;
	
	public var id:uint = getNextId();
	public var delay:uint;
	public var frames:uint;
	public var interval:Boolean;
	
	private var creation_time:int;
	private var time_elapsed:int;
	private var frames_elapsed:int;
	
	public function init():void {
		id = getNextId();
		creation_time = getTimer();
	}
	
	override public function reset():void {
		super.reset();
		id = 0;
		delay = 0;
		frames = 0;
		interval = false;
		time_elapsed = 0;
		frames_elapsed = 0;
		creation_time = 0;
	}
	
	public function restartIntervalTimer():void {
		time_elapsed = 0;
		frames_elapsed = 0;
		creation_time = getTimer();
	}
	
	public function readyToDoCallback():Boolean {
		return ((frames == frames_elapsed) && (delay == time_elapsed));
	}
	
	public function tickTime():void {
		time_elapsed = (getTimer() - creation_time);
		if (time_elapsed > delay) {
			time_elapsed = delay;
		}
	}
	
	public function tickFrames():void {
		++frames_elapsed;
		if (frames_elapsed > frames) {
			frames_elapsed = frames;
		}
	}
	
	public function toString():String {
		return 'DelayedCallback['
			+ 'id:' + id 
			+ ', interval:' + interval
			+ ', ms:' + time_elapsed + '/' + delay
			+ ', frames:' + frames_elapsed + '/' + frames
			+ ', callback:' + (callback != null) + ']';
	}
	
	private static function getNextId():uint {
		return next_id++;
	}
}

class DelayedCallbackNode implements IPoolableObject {
	public const callback:DelayedCallback = new DelayedCallback();
	
	public var next:DelayedCallbackNode;
	public var prev:DelayedCallbackNode;
	
	public var initialized:Boolean;
	
	public static function resetInstance(node:DelayedCallbackNode):void {
		node.reset();
	}
	
	public function init():void {
		callback.init();
		initialized = true;
	}
	
	public function reset():void {
		callback.reset();
		next = null;
		prev = null;
		initialized = false;
	}
	
	public function toString():String {
		return 'DelayedCallbackNode[callback:' + callback + ']';
	}
}

class DelayedCallbackList {
	/** Head of the linked list of DelayedCallbacks */
	public var head:DelayedCallbackNode;
	
	/** Tail of the linked list of DelayedCallbacks */
	public var tail:DelayedCallbackNode;
	
	/** Length of the linked list of DelayedCallbacks */
	public var length:uint;
	
	/** Add to the end of the list */
	public function add(node:DelayedCallbackNode):void {
		if (length == 0) {
			node.next = null;
			node.prev = null;
			head = node;
			tail = node;
			length = 1;
		} else {
			node.prev = tail;
			node.next = null;
			tail.next = node;
			tail = node;
			(++length);
		}
	}
	
	/** Removes from the list in-place */
	public function remove(node:DelayedCallbackNode):void{
		if (node == head) {
			head = node.next;
		} else {
			node.prev.next = node.next;
		}
		
		if (node == tail) {
			tail = node.prev;
		} else {
			node.next.prev = node.prev;
		}
		
		node.prev = null;
		node.next = null;
		
		(--length);
	}
	
	public function toString():String {
		var str:String = 'DelayedCallbackList[';
		
		var node:DelayedCallbackNode = head;
		while (node) {
			str += ('\n\t' + node);
			node = node.next;
		}
		
		str += ']';
		return str;
	}
}
