package com.tinyspeck.engine.loader
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.PerfLogger;
	import com.tinyspeck.engine.util.URLUtil;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	
	public class SmartSoundLoader extends SmartLoaderBase
	{
		
		// data
		/** A var so we can unloadAndStop it (set it null) */
		protected var snd:Sound;
		
		/**
		 * Default: 2 retries after first load, cache busting on each retry, waiting
		 * 2 seconds between load attempts, timeout after waiting 10 seconds to
		 * connect, timeout after 5 seconds of 100% progress without COMPLETE event.
		 */
		public function SmartSoundLoader(name:String, snd:Sound) {
			super(name);
			this.snd = snd;
			bypassThreader = true;
		}
		
		override public function get bytesLoaded():uint {
			return snd.bytesLoaded;
		}
		
		override public function get bytesTotal():uint {
			return snd.bytesTotal;
		}
		
		/**
		 * May throw a SmartLoaderError if you are trying to reuse this SmartLoader.
		 */
		public function load(urlRequest:URLRequest):void {
			if (this.urlRequest || disposed) throwError(SmartLoaderError.REUSED);
			
			this.urlRequest = urlRequest;
			tryToLoad();
		}
		
		override internal function actuallyLoad():void {
			super.actuallyLoad();
			snd.load(urlRequest);
		}
		
		/** May throw a SmartLoaderError if you have called unloadAndStop() */
		public function get content():Sound {
			if (!snd) throwError(SmartLoaderError.UNLOADED);
			return snd;
		}
		
		override protected function onComplete(event:Event):void {
			if (!snd) {
				; //shut up compiler
				CONFIG::debugging {
					Console.error('WTF no loader')
				}
			} else {
				PerfLogger.addBytesLoadedData(
					snd.bytesLoaded, 
					(getTimer()-load_start_ms)/1000, 
					name+' '+urlRequest.url
				);
			}
			
			super.onComplete(event);
		}
		
		override protected function maybeRetry(event:Event):void {
			if ((retries + 1) <= totalRetries) {
				removeListeners();
				(retries++);
				PerfLogger.addRetry(urlRequest.url);
				
				if (cacheBustOnRetry) urlRequest.url = URLUtil.cacheBust(urlRequest.url);
				log('retry #' + retries, event);
				retry_tim = StageBeacon.setTimeout(actuallyLoad, retryDelay);
			} else {
				errorOut(event);
			}
		}
		
		override protected function dispose():void {
			super.dispose();
			snd = null;
		}
		
		override protected function addListeners():void {
			super.addListeners();
			
			// weak handlers
			snd.addEventListener(Event.OPEN, onOpen, false, 0, true);
			snd.addEventListener(ProgressEvent.PROGRESS, onProgress, false, 0, true);
			snd.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
			snd.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
			snd.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler, false, 0, true);
			snd.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus, false, 0, true);
		}
		
		override protected function removeListeners():void {
			super.removeListeners();
			
			snd.removeEventListener(Event.OPEN, onOpen);
			snd.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			snd.removeEventListener(Event.COMPLETE, onComplete);
			snd.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			snd.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler);
			snd.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus);
		}
	}
}