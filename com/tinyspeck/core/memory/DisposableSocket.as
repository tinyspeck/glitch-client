package com.tinyspeck.core.memory
{
	import com.tinyspeck.engine.memory.EnginePools;
	
	import flash.net.Socket;
	
	public class DisposableSocket extends Socket
	{
		private var listeners:Vector.<EventListenerVO>;
		
		public function DisposableSocket(host:String=null, port:int=0)
		{
			super(host, port);
			init();
		}
		
		private function init():void
		{
			listeners = new Vector.<EventListenerVO>();
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false) : void
		{
			var elvo:EventListenerVO = EnginePools.EventListenerVOPool.borrowObject();
			elvo.type = type
			elvo.listener = listener;
			elvo.useCapture = useCapture;
			listeners[listeners.length] = elvo;
			super.addEventListener(type,listener,useCapture,priority,useWeakReference);
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false) : void
		{
			//Find the event listeners in the listeners list.
			var elvo:EventListenerVO;
			var l:int = listeners.length;
			for(var i:int = 0; l<i; i++){
				elvo = listeners[int(i)];
				if(elvo.type == type && elvo.listener == listener && elvo.useCapture == useCapture){
					EnginePools.EventListenerVOPool.returnObject(elvo);
					listeners.splice(i,1);
					--l;
					--i;
				}
			}
			super.removeEventListener(type, listener, useCapture);
		}
		
		public function removeAllEventListeners():void
		{
			var elvo:EventListenerVO;
			var l:int = listeners.length;
			for(var i:int = 0; i<l; i++){
				elvo = listeners[int(i)];
				super.removeEventListener(elvo.type, elvo.listener, elvo.useCapture);
				EnginePools.EventListenerVOPool.returnObject(elvo);
			}
			listeners.length = 0;
		}
		
		public function dispose():void
		{
			removeAllEventListeners();
			listeners = null;
		}
	}
}