package com.tinyspeck.engine.loader
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.BootError;

import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

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
 * from the SmartByteLoader, NOT from the contentLoaderInfo.
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
public class SmartByteLoader extends SmartLoaderBase
{
	
	// data
	/** A var so we can unloadAndStop it (set it null) */
	protected var loader:Loader;
	private var bytes:ByteArray;

	/**
	 * Default: 2 retries after first load, cache busting on each retry, waiting
	 * 2 seconds between load attempts, timeout after waiting 10 seconds to
	 * connect, timeout after 5 seconds of 100% progress without COMPLETE event.
	 */
	public function SmartByteLoader(name:String) {
		super(name);
	}
	
	override protected function get default_context():LoaderContext {
		return LOADER_CONTEXT_NO_SEC_NO_POLICY;
	}
	
	override public function get bytesLoaded():uint {
		return contentLoaderInfo.bytesLoaded;
	}
	
	override public function get bytesTotal():uint {
		return contentLoaderInfo.bytesTotal;
	}

	override internal function actuallyLoad():void {
		if (disposed) {
			BootError.handleError('already disposed!', new Error('ALREADY_DISPOSED'), ['loader', 'SmartByteLoader'], true);
		} else if (!bytes) {
			BootError.handleError('no bytes? '+eventLog, new Error('MISSING_URLREQUEST'), ['loader', 'SmartByteLoader'], true);
			close();
		} else {
			super.actuallyLoad();
			loader.loadBytes(bytes, context || default_context);
		}
	}

	/**
	 * May throw a SmartLoaderError if you are trying to reuse this SmartByteLoader.
	 */
	public function load(bytes:ByteArray, context:LoaderContext=null):void {
		if (loader || disposed) throwError(SmartLoaderError.REUSED);
		log('load(' + (bytes ? bytes.length : 'null') + ')');
		
		loader = new Loader();
		
		this.bytes = bytes;
		this.context = context;
		tryToLoad();
	}

	/** May throw a SmartLoaderError if you have called unloadAndStop() */
	public function get content():DisplayObject {
		if (!loader) throwError(SmartLoaderError.UNLOADED);
		return loader.content;
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
		log('init');
		// just in case we didn't get an OPEN event for some reason
		connectTimeoutTimer.stop();
		init_sig.dispatch(this);
	}
	
	override protected function maybeRetry(event:Event):void {
		if ((retries + 1) <= totalRetries) {
			removeListeners();
			(retries++);
			
			// don't call overridden close() so we don't dispose()
			try { loader.close(); } catch (e:Error) {}
			
			log('retry #' + retries, event);
			retry_tim = StageBeacon.setTimeout(actuallyLoad, retryDelay);
		} else {
			errorOut(event);
		}
	}
	
	/** Not a complete dispose, just the stuff SmartByteLoader added */
	override protected function dispose():void {
		super.dispose();
		bytes = null;
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