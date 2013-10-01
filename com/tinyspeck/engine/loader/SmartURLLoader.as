package com.tinyspeck.engine.loader
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.BootError;
import com.tinyspeck.debug.PerfLogger;
import com.tinyspeck.engine.util.URLUtil;

import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;

/**
 * Retries internally a given number of times, optionally cache-busting the URL.
 * A retry occurs when a SECURITY_ERROR or IO_ERROR event is caught, or when
 * PROGRESS has been 100% for a given number of seconds without COMPLETE, or
 * when we timeout waiting for CONNECT.
 * 
 * An ERROR Signal is dispatched when retries have been exhausted. If you get
 * this error, then everything has already been done to try and get the file:
 * Do not retry -- instead fall back or report an error.
 * 
 * OPEN, ERROR, PROGRESS, and COMPLETE Signals are dispatched directly from
 * the SmartURLLoader.
 * 
 * This class is not reusable for multiple loads, nor is it suitable to be added
 * directly to the display list.
 * 
 * It disposes, and close()s before dispatching ERROR and COMPLETE. All Signal
 * listeners are automatically removed as well.
 * 
 * You will have access to the eventLog property until you call clearEventLog().
 */
public class SmartURLLoader extends SmartLoaderBase
{
	
	// data
	private const loader:URLLoader = new URLLoader();

	/**
	 * Default: 2 retries after first load, cache busting on each retry, waiting
	 * 2 seconds between load attempts, timeout after waiting 10 seconds to
	 * connect, timeout after 5 seconds of 100% progress without COMPLETE event.
	 */
	public function SmartURLLoader(name:String, bypassThreader:Boolean=false) {
		super(name);
		this.bypassThreader = bypassThreader;
	}
	
	override public function get bytesLoaded():uint {
		return loader.bytesLoaded;
	}
	
	override public function get bytesTotal():uint {
		return loader.bytesTotal;
	}
	
	/**
	 * May throw a SmartURLLoaderError if you are trying to reuse this SmartURLLoader.
	 */
	public function load(urlRequest:URLRequest):void {
		if (disposed) throwError(SmartLoaderError.REUSED);
		
		this.urlRequest = urlRequest;
		tryToLoad();
	}
	
	override internal function actuallyLoad():void {
		if (disposed) {
			BootError.handleError('already disposed!', new Error('ALREADY_DISPOSED'), ['loader', 'SmartURLLoader'], true);
		} else if (!urlRequest) {
			BootError.handleError('no urlRequest? '+eventLog, new Error('MISSING_URLREQUEST'), ['loader', 'SmartURLLoader'], true);
			close();
		} else {
			super.actuallyLoad();
			loader.load(urlRequest);
		}
	}

	public function get data():* {
		return loader.data;
	}
	
	public function get dataFormat():String {
		return loader.dataFormat;
	}
	
	override public function close():void {
		try { loader.close(); } catch (e:Error) {}
		super.close();
	}
	
	override protected function maybeRetry(event:Event):void {
		if ((retries + 1) <= totalRetries) {
			removeListeners();
			(retries++);
			PerfLogger.addRetry(urlRequest.url);
			
			// don't call overridden close() so we don't dispose()
			try { loader.close(); } catch (e:Error) {}
			
			if (cacheBustOnRetry) urlRequest.url = URLUtil.cacheBust(urlRequest.url);
			log('retry #' + retries, event);
			retry_tim = StageBeacon.setTimeout(actuallyLoad, retryDelay);
		} else {
			errorOut(event);
		}
	}
	
	override protected function addListeners():void {
		super.addListeners();
		
		// weak handlers
		loader.addEventListener(Event.OPEN, onOpen, false, 0, true);
		loader.addEventListener(ProgressEvent.PROGRESS, onProgress, false, 0, true);
		loader.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
		loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler, false, 0, true);
		loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus, false, 0, true);
	}
	
	override protected function removeListeners():void {
		super.removeListeners();
		
		loader.removeEventListener(Event.OPEN, onOpen);
		loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
		loader.removeEventListener(Event.COMPLETE, onComplete);
		loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
		loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler);
		loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus);
	}
}
}