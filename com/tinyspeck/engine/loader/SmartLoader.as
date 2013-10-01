package com.tinyspeck.engine.loader
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.Benchmark;
import com.tinyspeck.debug.Console;
import com.tinyspeck.debug.PerfLogger;
import com.tinyspeck.engine.util.EnvironmentUtil;
import com.tinyspeck.engine.util.StringUtil;
import com.tinyspeck.engine.util.URLUtil;

import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLRequest;
import flash.system.LoaderContext;
import flash.utils.getTimer;

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
 * OPEN, INIT, ERROR, PROGRESS, and COMPLETE Signals are dispatched directly
 * from the SmartLoader, NOT from the contentLoaderInfo.
 * 
 * This class is not reusable for multiple loads, nor is it suitable to be added
 * directly to the display list.
 * 
 * It disposes, and close()s before dispatching ERROR and COMPLETE; you will
 * need to unload() and unloadAndStop() on your own. All Signal listeners are
 * automatically removed as well.
 * 
 * You will have access to the eventLog property until you call clearEventLog()
 * or unload()/unloadAndStop().
 */
public class SmartLoader extends SmartLoaderBase
{
	
	// data
	/** A var so we can unloadAndStop it (set it null) */
	protected var loader:Loader;
	
	private var break_first_load:Boolean;

	/**
	 * Default: 2 retries after first load, cache busting on each retry, waiting
	 * 2 seconds between load attempts, timeout after waiting 10 seconds to
	 * connect, timeout after 5 seconds of 100% progress without COMPLETE event.
	 */
	public function SmartLoader(name:String) {
		super(name);
	}
	
	override public function get bytesLoaded():uint {
		return contentLoaderInfo.bytesLoaded;
	}
	
	override public function get bytesTotal():uint {
		return contentLoaderInfo.bytesTotal;
	}

	/**
	 * May throw a SmartLoaderError if you are trying to reuse this SmartLoader.
	 */
	public function load(urlRequest:URLRequest, context:LoaderContext=null, break_first_load:Boolean=false):void {
		if (loader || disposed) throwError(SmartLoaderError.REUSED);
		this.break_first_load = break_first_load;
		
		loader = new Loader();
		
		/*
		if (urlRequest.url == 'http://c2.glitch.bz/avatars/2012-09-23/7d9285059ff5bc12a27a87d779dd0c7a_1348468786_base.png') {
			urlRequest.url+= 'fff';
		}
		*/
		
		this.urlRequest = urlRequest;
		this.context = context;
		tryToLoad();
	}
	
	override internal function actuallyLoad():void {
		super.actuallyLoad();
		
		if (!urlRequest) {
			errorOut(new Event('actuallyLoad_CALLED_BUT_NOT_urlRequest disposed:'+disposed+' eventLog:'+eventLog));
			return
		}
		
		var url:String = urlRequest.url; 
		if (break_first_load && !retries) {
			var parts:Array = urlRequest.url.split('?');
			url = parts[0]+'BREAKFIRSTLOAD';
			if (parts.length > 1) url+='?'+parts[1]; 
			loader.load(new URLRequest(url), context || default_context);
		} else {
			if (EnvironmentUtil.getUrlArgValue('SWF_cb_all_loads') == '1') {
				urlRequest.url = URLUtil.cacheBust(urlRequest.url);
			}
			loader.load(urlRequest, context || default_context);
		}
		log('actuallyLoad '+url);
	}

	/** May throw a SmartLoaderError if you have called unloadAndStop() */
	public function get content():DisplayObject {
		if (!loader) throwError(SmartLoaderError.UNLOADED);
		try {
			return loader.content
		} catch(err:Error) {
			log('error getting content; '+err)
		}
		
		return null;
	}
	
	/** May throw a SmartLoaderError if you have called unloadAndStop() */
	public function get contentLoaderInfo():LoaderInfo {
		if (!loader) throwError(SmartLoaderError.UNLOADED);
		return loader.contentLoaderInfo;
	}

	override public function close():void {
		super.close();
		try { loader.close(); } catch (e:Error) {}
	}
	
	public function unload():void {
		dispose();
		clearEventLog();
		try { loader.unload(); } catch (e:Error) {}
	}
	
	public function unloadAndStop(gc:Boolean=true):void {
		dispose();
		clearEventLog();
		try { loader.unloadAndStop(gc); } catch (e:Error) {}
		// unloadAndStop should clear up every reference there is:
		loader = null;
	}
	
	private function onInit(event:Event):void {
		if (bytesTotal == bytesLoaded) {
			var init_is_same_as_complete:Boolean = false;
			log('init: '+bytesLoaded+' == '+bytesTotal+' calling onComplete init_is_same_as_complete:'+init_is_same_as_complete);
			if (init_is_same_as_complete) {
				onComplete(event);
			}
		} else {
			log('init: '+bytesLoaded+' < '+bytesTotal);
		}
	}
	
	override protected function onComplete(event:Event):void {
		
		if (!loader) {
			; //shut up compiler
			CONFIG::debugging {
				Console.error('WTF no loader')
			}
		} else if (!loader.contentLoaderInfo) {
			; //shut up compiler
			CONFIG::debugging {
				Console.error('WTF no loader.contentLoaderInfo')
			}
		} else {
			PerfLogger.addBytesLoadedData(
				loader.contentLoaderInfo.bytesLoaded, 
				(getTimer()-load_start_ms)/1000, 
				name+' '+urlRequest.url
			);
		}
		
		if (!content) {
			maybeRetry(new Event('COULD_NOT_GET_CONTENT'));
			return;
		}
		
		super.onComplete(event);
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
		const cli:LoaderInfo = loader.contentLoaderInfo;
		cli.addEventListener(Event.OPEN, onOpen, false, 0, true);
		cli.addEventListener(Event.INIT, onInit, false, 0, true);
		cli.addEventListener(ProgressEvent.PROGRESS, onProgress, false, 0, true);
		cli.addEventListener(Event.COMPLETE, onComplete, false, 0, true);
		cli.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
		cli.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler, false, 0, true);
		cli.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus, false, 0, true);
	}
	
	override protected function removeListeners():void {
		super.removeListeners();
		
		const cli:LoaderInfo = loader.contentLoaderInfo;
		cli.removeEventListener(Event.OPEN, onOpen);
		cli.removeEventListener(Event.INIT, onInit);
		cli.removeEventListener(ProgressEvent.PROGRESS, onProgress);
		cli.removeEventListener(Event.COMPLETE, onComplete);
		cli.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
		cli.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityErrorHandler);
		cli.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus);
	}
}
}