package com.tinyspeck.engine.loader
{
import avmplus.getQualifiedClassName;

import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.BootError;
import com.tinyspeck.debug.Console;
import com.tinyspeck.debug.PerfLogger;
import com.tinyspeck.engine.util.StringUtil;

import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.events.TimerEvent;
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.SecurityDomain;
import flash.utils.Timer;
import flash.utils.getTimer;

import org.osflash.signals.Signal;

internal class SmartLoaderBase
{
	internal static const LOADER_CONTEXT:LoaderContext = new LoaderContext(
		true,
		ApplicationDomain.currentDomain,
		SecurityDomain.currentDomain
	);
	
	internal static const LOADER_CONTEXT_NO_SEC_NO_POLICY:LoaderContext = new LoaderContext(
		false,
		ApplicationDomain.currentDomain
	);
	
	// not using this one yet, but might need to when we get to using smartloaders for AvatarResourceManager
	// which currently uses a ThreadLoader without a sec context
	internal static const LOADER_CONTEXT_NO_SEC:LoaderContext = new LoaderContext(
		true,
		ApplicationDomain.currentDomain
	);
	
	/** Sends a (SmartByteLoader) on loader INIT */
	public const init_sig:Signal = new Signal(SmartLoaderBase);
	
	/** Sends a (SmartLoaderBase) on loader OPEN */
	public const open_sig:Signal = new Signal(SmartLoaderBase);
	
	/** Sends a (SmartLoaderBase) on loader PROGRESS; grab bytesLoaded and bytesTotal from the argument */
	public const progress_sig:Signal = new Signal(SmartLoaderBase);
	
	/** Sends a (SmartLoaderBase) on loader COMPLETE */
	public const complete_sig:Signal = new Signal(SmartLoaderBase);
	
	/** Sends a (SmartLoaderBase) on loader ERROR */
	public const error_sig:Signal = new Signal(SmartLoaderBase);
	
	/** Sends a (SmartLoaderBase) on loader HTTPStatus */
	public const http_status_sig:Signal = new Signal(SmartLoaderBase);
	
	
	// preferences/behavior
	public var name:String;
	public var totalRetries:int              = 2;
	public var retryDelay:Number             = 2000;
	public var cacheBustOnRetry:Boolean      = true;
	public var enableConnectTimeout:Boolean  = true;
	public var enableCompleteTimeout:Boolean = true;
	protected var bypassThreader:Boolean;
	
	// data
	protected const connectTimeoutTimer:Timer  = new Timer(10000);
	protected const completeTimeoutTimer:Timer = new Timer(5000);
	protected var urlRequest:URLRequest;
	protected var context:LoaderContext;
	protected var retry_tim:uint;
	
	// state
	internal var retries:int = 0;
	protected var disposed:Boolean;
	protected var progressReported:Boolean;
	protected var load_start_ms:int;
	protected var load_requested_ms:int;
	protected var load_end_ms:int;
	
	private var _eventLog:String = '';
	private var _httpStatus:int = 0;
	
	private var _start_url:String;
	public function get start_url():String {
		return _start_url;
	}
	
	public function SmartLoaderBase(name:String) {
		this.name = name;
		log(getQualifiedClassName(this));
		log('name: '+name);
	}
	
	protected function get default_context():LoaderContext {
		LOADER_CONTEXT.applicationDomain = new ApplicationDomain();
		return LOADER_CONTEXT;
	}
	
	public function get bytesLoaded():uint {
		return 0;
	}
	
	public function get bytesTotal():uint {
		return 0;
	}
	
	public function get connectTimeout():Number {
		return connectTimeoutTimer.delay;
	}
	
	public function set connectTimeout(value:Number):void {
		connectTimeoutTimer.delay = value;
	}
	
	public function get completeTimeout():Number {
		return completeTimeoutTimer.delay;
	}
	
	public function set completeTimeout(value:Number):void {
		completeTimeoutTimer.delay = value;
	}
	
	public function get httpStatus():int {
		return _httpStatus;
	}
	
	public function clearEventLog():void {
		return;
		_eventLog = '';
	}
	
	public function get eventLog():String {
		return _eventLog;
	}
	
	public function close():void {
		/*if (disposed) {
			log('close called, but this has already been disposed');
			BootError.handleError('already disposed!', new Error('ALREADY_DISPOSED'), ['loader', 'SmartURLLoader'], true);
			return;
		}*/
		if (!bypassThreader) {
			log('close and call SmartThreader.loadDone')
			SmartThreader.loadDone(this);
		} else {
			log('close');
		}
		dispose();
	}
	
	protected function tryToLoad():void {
		load_requested_ms = getTimer();
		if (urlRequest) {
			_start_url = urlRequest.url;
		}
		
		if (bypassThreader) {
			log('tryToLoad and bypassThreader '+_start_url);
			actuallyLoad();
		} else {
			log('tryToLoad using SmartThreader.addToQ (SmartThreader is now loading: '+SmartThreader.currently_loading+') '+_start_url);
			SmartThreader.addToQ(this);
		}
	}
	
	internal function actuallyLoad():void {
		log('actuallyLoad');
		addListeners();
		
		progressReported = false;
		
		completeTimeoutTimer.stop();
		if (enableConnectTimeout) {
			connectTimeoutTimer.reset();
			connectTimeoutTimer.start();
		}
		progressReported = false;
		
		completeTimeoutTimer.stop();
		if (enableConnectTimeout) {
			connectTimeoutTimer.reset();
			connectTimeoutTimer.start();
		}
		load_start_ms = getTimer();
	}
	
	public function toString():String {
		return eventLog;
	}
	
	protected function maybeRetry(event:Event):void {
	}
	
	protected function errorOut(event:Event):void {
		log('errorOut, '+totalRetries+' retries used up', event);
		
		error_sig.dispatch(this);
		
		// close() will dispose for us too
		close();
	}
	
	protected function dispose():void {
		if (!disposed) {
			disposed = true;
			urlRequest = null;
			removeListeners();
			
			init_sig.removeAll();
			open_sig.removeAll();
			progress_sig.removeAll();
			complete_sig.removeAll();
			error_sig.removeAll();
			http_status_sig.removeAll();
		}
	}
	
	protected function onConnectTimeout(event:TimerEvent):void {
		if (urlRequest) PerfLogger.addLongLoad(urlRequest.url);
		log('connect timeout (indicating no bytes have been loaded in '+connectTimeoutTimer.delay+'ms)');
		connectTimeoutTimer.stop();
		maybeRetry(event);
	}
	
	protected function onCompleteTimeout(event:TimerEvent):void {
		if (urlRequest) PerfLogger.addNoContentError(urlRequest.url);
		log('complete timeout (indicating no COMPLETE event fired '+completeTimeoutTimer.delay+'ms after we got all bytes)');
		completeTimeoutTimer.stop();
		maybeRetry(event);
	}
	
	protected function onOpen(event:Event):void {
		log('open');
		connectTimeoutTimer.stop();
		open_sig.dispatch(this);
	}
	
	protected function onProgress(event:ProgressEvent):void {
		// just in case we didn't get an OPEN event for some reason
		connectTimeoutTimer.stop();
		
		const progress:int = Math.floor(event.bytesTotal ? (100 * event.bytesLoaded / event.bytesTotal) : 0);
		if (!progressReported) {
			progressReported = true;
			log('progress: ' + progress+'%');
		}
		if (progress == 100) {
			// when we hit 100%, start counting down waiting for COMPLETE
			log('progress: ' + progress+'%');
			if (enableCompleteTimeout) {
				completeTimeoutTimer.reset();
				completeTimeoutTimer.start();
			}
		}
		
		progress_sig.dispatch(this);
	}
	
	protected function onComplete(event:Event):void {
		load_end_ms = getTimer();
		log('complete '+StringUtil.formatNumber(bytesLoaded/1024, 2)+'kb in '+getSecStr(load_end_ms-load_start_ms)+' secs');
		stopTimers();
		complete_sig.dispatch(this);
		close();
	}
	
	protected function onHTTPStatus(event:HTTPStatusEvent):void {
		if (event.status >= 500) {
			PerfLogger.add500Error(urlRequest.url);
		}
		_httpStatus = event.status;
		log('http-status (' + _httpStatus + '): ' + event);
		http_status_sig.dispatch(this);
	}
	
	protected function onSecurityErrorHandler(event:SecurityErrorEvent):void {
		log('security error: '+event);
		stopTimers();
		maybeRetry(event);
	}
	
	protected function onIOError(event:IOErrorEvent):void {
		if (urlRequest) PerfLogger.addIOError(urlRequest.url);
		log('io error: '+event);
		stopTimers();
		maybeRetry(event);
	}
	
	public function log(msg:String, event:Event = null):void {
		if (load_requested_ms) {
			msg = getSecStr(getTimer()-load_requested_ms)+' '+msg;
		}
		var str:String = msg + (event?' '+event:'');
		CONFIG::debugging {
			Console.priinfo(239, name+' '+str);
		}
		_eventLog += (str+ '\n');
	}
	
	protected function addListeners():void {
		log('addListeners');
		connectTimeoutTimer.addEventListener(TimerEvent.TIMER, onConnectTimeout, false, 0, true);
		completeTimeoutTimer.addEventListener(TimerEvent.TIMER, onCompleteTimeout, false, 0, true);
	}
	
	protected function removeListeners():void {
		log('removeListeners');
		connectTimeoutTimer.removeEventListener(TimerEvent.TIMER, onConnectTimeout, false);
		completeTimeoutTimer.removeEventListener(TimerEvent.TIMER, onCompleteTimeout, false);
		
		stopTimers();
	}
	
	protected function throwError(id:*=0):void {
		log('error: ' + id);
		throw new SmartLoaderError(eventLog, id);
	}
	
	private function stopTimers():void {
		if (retry_tim) {
			StageBeacon.clearTimeout(retry_tim);
			retry_tim = 0;
		}
		connectTimeoutTimer.stop();
		completeTimeoutTimer.stop();
	}
	
	protected function getSecStr(ms:int):String {
		return (ms/1000).toFixed(2);
	}
}
}