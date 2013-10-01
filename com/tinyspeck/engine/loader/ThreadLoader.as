package com.tinyspeck.engine.loader 
{
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.PerfLogger;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	public class ThreadLoader
	{
		private const loadTimer:Timer = new Timer(0);
		private const checkemTimer:Timer = new Timer(2000);
		private const checkSomeBytesTimer:Timer = new Timer(100);
		
		// effectively const, but must be inited at runtime
		public var LOADER_CONTEXT:LoaderContext;
		public var APPLICATION_DOMAIN:ApplicationDomain;
		public var SECURITY_DOMAIN:SecurityDomain;
		
		private var label:String = '';
		private var freeLoaders:Vector.<Loader>;
		private var _threads:int;
		private var items:Vector.<LoaderItem>;
		private var checkLoadersMap:Dictionary;
		private var checkLoadersCount:int;
		private var checkSomeBytesLoadersMap:Dictionary;
		private var checkSomeBytesLoadersCount:int;
		private var loaderItemMap:Dictionary;
		
		public function ThreadLoader(label:String, threads:int = 200, use_sec_dom:Boolean = true) {
			this.label = label;
			_threads = threads;
			if (use_sec_dom) SECURITY_DOMAIN = SecurityDomain.currentDomain;
			init();
		}
		
		public function get threads():int {
			return _threads;
		}

		private function init():void {
			checkemTimer.addEventListener(TimerEvent.TIMER, checkem);
			checkSomeBytesTimer.addEventListener(TimerEvent.TIMER, checkForSomeBytes);
			loadTimer.addEventListener(TimerEvent.TIMER, load);
			
			APPLICATION_DOMAIN = ApplicationDomain.currentDomain;
			LOADER_CONTEXT = new LoaderContext(true,APPLICATION_DOMAIN,SECURITY_DOMAIN);
			items = new Vector.<LoaderItem>();
			checkLoadersMap = new Dictionary();
			checkLoadersCount = 0;
			checkSomeBytesLoadersMap = new Dictionary();
			checkSomeBytesLoadersCount = 0;
			loaderItemMap = new Dictionary();
			freeLoaders = new Vector.<Loader>();
			
			for (var i:int = 0; i < _threads; i++) {
				var loader:Loader = new Loader();
				freeLoaders.push(new Loader());
			}
		}
		
		private function checkForSomeBytes(e:TimerEvent):void {
			var loaderItem:LoaderItem;
			var warn_limit:int = 5000;
			var error_limit:int = 20000;
			for (var obj:Object in checkSomeBytesLoadersMap) {
				loaderItem = (obj as LoaderItem);
				if (loaderItem.bytesLoaded) {
					removeLoaderFromSomeBytesChecking(loaderItem);
				} else {
					var elapsed_ms:int = getTimer() - loaderItem.load_start_ms;
					if (elapsed_ms > error_limit) {
						// no progress loading for error_limit ms
						Benchmark.addCheck('TL.checkForSomeBytes '+label+': error_no_bytes_loaded in '+elapsed_ms+'ms: '+loaderItem.deets);
						removeLoaderFromSomeBytesChecking(loaderItem);
						loaderItem.should_report_load_progress = true;
						
						var restart_load_after_error_no_bytes_loaded:Boolean = true;
						if (restart_load_after_error_no_bytes_loaded) {
							// report an error which should restart the load if
							// the owner wants that and there are retries
							PerfLogger.addLongLoad(loaderItem.urlRequest.url);
							errorOutOnLoaderInfoError(loaderItem.loader_info);
						} else {
							// this just logs a client error, but lets it hang forever
							BootError.handleError('TL.checkForSomeBytes '+label+': error_no_bytes_loaded in '+elapsed_ms+'ms: '+loaderItem.deets, null, ['loader'], true, false);
						}
						
					} else if (elapsed_ms > warn_limit && !loaderItem.warned_on_no_bytes) {
						// no progress loading for warn_limit ms
						Benchmark.addCheck('TL.checkForSomeBytes '+label+': warn_no_bytes_loaded in '+elapsed_ms+'ms: '+loaderItem.deets);
						loaderItem.should_report_load_progress = true;
						loaderItem.warned_on_no_bytes = true;
					}
				}
			}
		}
		
		private function checkem(e:TimerEvent):void {
			var loaderItem:LoaderItem;
			for (var obj:Object in checkLoadersMap) {
				loaderItem = (obj as LoaderItem);
				// this should always be true, but let's check anyway
				if (loaderItem.bytesLoaded == loaderItem.bytesTotal) {
					// if it's done loading but there's no content available...
					if (!loaderItem.content) {
						if (!loaderItem.reported_complete_but_no_content) {
							Benchmark.addCheck('TL.checkem '+label+': complete_but_no_content: '+loaderItem.deets);
							loaderItem.reported_complete_but_no_content = true;
						}
						// and it's been 10 seconds since it finished loading
						if ((getTimer() - loaderItem.load_end_ms) > 10000) {
							// report an error which should restart the load if
							// the owner wants that and there are retries
							// (hopefully very fast from browser cache)
							Benchmark.addCheck('TL.checkem '+label+': complete_but_no_content_for_10_seconds: '+loaderItem.deets);
							BootError.handleError('TL.checkem '+label+': complete_but_no_content_for_10_seconds: '+loaderItem.deets, null, ['loader'], true, false);
							PerfLogger.addNoContentError(loaderItem.urlRequest.url);
							errorOutOnLoaderInfoError(loaderItem.loader_info);
						}
						continue;
					}
					
					//Console.reportError('LOADED BUT FAILED TO FIRE COMPLETE EVENT BEFORE checkem '+loader_item.label+' '+loader_item.urlRequest.url);
					reportLoaderInfoComplete(loaderItem.loader_info);
					removeLoaderFromCompletionChecking(loaderItem);
				}
			}
		}
		
		public function addLoaderItem(loader_item:LoaderItem):void {
			if (loader_item) {
				loader_item.in_q = new Date().getTime();
				items.push(loader_item);
				loadTimer.start();
			}
		}
		
		private function load(e:TimerEvent):void {
			loadTimer.stop();
			while (freeLoaders.length > 0 && items.length > 0) {
				var loader:Loader = freeLoaders.shift();
				var loader_item:LoaderItem = items.shift();
				loaderItemMap[loader] = loader_item;
				
				loader_item.loader_info = loader.contentLoaderInfo;
				CONFIG::debugging {
					Console.log(48, 'load '+loader_item.deets);
				}

				var id:String = loader_item.label;
				CONFIG::debugging {
					Console.trackValue('Z TL '+id, 0);
				}
				
				loader_item.load_start_ms = getTimer();
				checkLoaderForSomeBytes(loader_item);
				startWithLoader(loader);
			}
		}
		
		private function startWithLoader(loader:Loader):void {
			// putting these first just in case there can be a synchronous error in calling loadBytes
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderIOError);
			loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHTTPStatus);
			loader.contentLoaderInfo.addEventListener(Event.INIT, onLoaderComplete);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
			loader.contentLoaderInfo.addEventListener(Event.OPEN, onLoaderOpen);
			
			const loader_item:LoaderItem = loaderItemMap[loader];
			if (loader_item.byteArray) {
				LOADER_CONTEXT.applicationDomain = loader_item.appDomain || new ApplicationDomain();
				LOADER_CONTEXT.checkPolicyFile = false;
				loader.loadBytes(loader_item.byteArray, LOADER_CONTEXT);
			} else if (loader_item.urlRequest && loader_item.urlRequest.url) {
				CONFIG::debugging {
					Console.log(66, loader_item.urlRequest.url);
				}
				LOADER_CONTEXT.applicationDomain = loader_item.appDomain || APPLICATION_DOMAIN;
				LOADER_CONTEXT.checkPolicyFile = true;
				
				Benchmark.addCheck('TL.startWithLoader '+label+': '+loader_item.deets);
				
				// remove the true to fake a load failure on dullite chunks
				if (true || loader_item.urlRequest.url.indexOf('/dullite-') == -1 || loader_item.busted) {
					loader.load(loader_item.urlRequest, LOADER_CONTEXT);
				}
					
				// TOO VERBOSE Benchmark.addCheck('TL.startWithLoader '+label+': '+loader_item.deets);
			} else {
				BootError.handleError('TL: No URL and no ByteArray', new Error('loaderItem: ' + loader_item.deets), ['loader'], false);
			}
		}
		
		private function finishWithLoader(loader:Loader):void {
			// IMPORTANT!!!
			// This function is now being called BEFORE the loader_item fail/success callbacks, so
			// that those function are free to call loader_item.dispose() without screwing up the
			// logging below. This is ok, because we are not doing anything destructive to the loader_item
			// in this method. SO PLEASE CONTINUE TO DO NOTHING DESTRUCTIVE TO THE LOADER_ITEM!!!!
			// IMPORTANT!!!
			
			const loader_item:LoaderItem = loaderItemMap[loader];
			if (loader_item.byteArray) {
				//
			} else if (loader_item.urlRequest && loader_item.urlRequest.url) {
				/* TOO VERBOSE (still)
				if (loader_item.should_report_load_progress) {
					Benchmark.addCheck('TL.finishWithLoader '+label+': '+loader_item.deets);
				}
				*/
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('NO URL AND NO byteArray dammit!')
				}
			}
			
			if (false) { // this is if we want to reuse, which is problematic to say the least!
				freeLoaders.push(loader);
			} else {
				// clean up
				if (loader in loaderItemMap) {
					loaderItemMap[loader] = null;
					delete loaderItemMap[loader];
				}
				
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderIOError);
				loader.contentLoaderInfo.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onLoaderHTTPStatus);
				loader.contentLoaderInfo.removeEventListener(Event.INIT, onLoaderComplete);
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
				loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
				loader.contentLoaderInfo.removeEventListener(Event.OPEN, onLoaderOpen);
	
				// make a new loader available
				freeLoaders.push(new Loader());
			}
			loadTimer.start();
		}
		
		private function reportLoaderInfoComplete(loader_info:LoaderInfo):void {
			const loader:Loader = loader_info.loader;
			const loader_item:LoaderItem = loaderItemMap[loader_info.loader];
			loader_item.bytesLoaded = loader_info.bytesLoaded;
			loader_item.bytesTotal = loader_info.bytesTotal;
			
			const perc:Number = loader_info.bytesLoaded/loader_info.bytesTotal*100;
			if (loader_info.bytesLoaded != loader_info.bytesTotal || !loader_info.content) {
				Benchmark.addCheck('TL.reportLoaderInfoComplete ***PREMATURE*** '+label+': '+StringUtil.formatNumber(perc, 2)+'% of '+loader_item.deets);
				return;
			}
			
			removeLoaderFromCompletionChecking(loader_item);
			removeLoaderFromSomeBytesChecking(loader_item);
			
			CONFIG::debugging {
				Console.log(48, 'loaded ('+Event.COMPLETE+')'+loader_info.url);
			}
			
			loader_item.content = (loader_info.content as MovieClip);
			loader_item.load_end_ms = getTimer();
			loader_item.logComplete();
			loader_item.loadedAppDomain = loader_item.loader_info.applicationDomain;
			
			finishWithLoader(loader);
			loader_item.callBackSuccess(loader_item);
		}
		
		private function onLoaderComplete(event:Event):void {
			const loader_info:LoaderInfo = (event.target as LoaderInfo);
			const perc:Number = loader_info.bytesLoaded/loader_info.bytesTotal*100;
			const loader_item:LoaderItem = loaderItemMap[loader_info.loader];
			loader_item.bytesLoaded = loader_info.bytesLoaded;
			loader_item.bytesTotal = loader_info.bytesTotal;
			//Benchmark.addCheck('TL.onLoaderComplete '+label+': '+StringUtil.formatNumber(perc, 2)+'% of '+loader_item.deets);
			reportLoaderInfoComplete(loader_info);
		}
		
		private function errorOutOnLoaderInfoError(loader_info:LoaderInfo):void {
			var loader:Loader = loader_info.loader;
			var loader_item:LoaderItem = loaderItemMap[loader];
			loader_item.bytesLoaded = loader_info.bytesLoaded;
			loader_item.bytesTotal = loader_info.bytesTotal;
			loader_item.load_end_ms = getTimer();
			loader_item.logError();
			
			// just to be sure
			removeLoaderFromCompletionChecking(loader_item);
			removeLoaderFromSomeBytesChecking(loader_item)
			
			const perc:Number = loader_info.bytesLoaded/loader_info.bytesTotal*100;
			Benchmark.addCheck('TL.errorOutOnLoaderInfoError '+label+': '+StringUtil.formatNumber(perc, 2)+'% of '+loader_item.deets);
			finishWithLoader(loader);
			loader_item.callBackFail(loader_item);
		}
		
		private var logged_500_err:Boolean;
		private function onLoaderHTTPStatus(event:HTTPStatusEvent):void {
			if (event) {
				var loader_info:LoaderInfo = event.target as LoaderInfo;
				var loader:Loader = loader_info.loader;
				var loader_item:LoaderItem = loaderItemMap[loader];
				Benchmark.addCheck('TL.onLoaderHTTPStatus: '+loader_item.deets+' status:'+event.status+' event:'+event);
				if (event.status >= 500) {
					if (!logged_500_err) {
						logged_500_err = true;
						BootError.handleError('TL onLoaderHTTPStatus500: '+loader_item.deets+' '+event, null, ['loader'], true);
					}
					PerfLogger.add500Error(loader_item.urlRequest.url);
					errorOutOnLoaderInfoError(loader_item.loader_info);
				}
			}
		}
		
		private function onLoaderIOError(event:IOErrorEvent):void {
			var loader_info:LoaderInfo = event.target as LoaderInfo;
			var loader:Loader = loader_info.loader;
			var loader_item:LoaderItem = loaderItemMap[loader];
			loader_item.bytesLoaded = loader_info.bytesLoaded;
			loader_item.bytesTotal = loader_info.bytesTotal;
			
			CONFIG::debugging {
				Console.warn('onLoaderIOError: '+loader_item.deets +' '+ event);
			}
			
			PerfLogger.addIOError(loader_item.urlRequest.url);
			errorOutOnLoaderInfoError(loader_info);
		}
		
		private function onLoaderOpen(event:Event):void {
			const loader_info:LoaderInfo = event.target as LoaderInfo;
			const loader_item:LoaderItem = loaderItemMap[loader_info.loader];
			loader_item.connection_opened = true;
		}
		
		private function onLoaderProgress(event:ProgressEvent):void {
			const loader_info:LoaderInfo = event.target as LoaderInfo;
			const loader_item:LoaderItem = loaderItemMap[loader_info.loader];
			
			loader_item.bytesLoaded = event.bytesLoaded;
			loader_item.bytesTotal = event.bytesTotal;
			
			var logged_progress_previously_in_this_method:Boolean;
			if (!loader_item.reported_load_progress && event.bytesLoaded) {
				logged_progress_previously_in_this_method = true;
				if (loader_item.should_report_load_progress || loader_item.busted) {
					Benchmark.addCheck('TL.onLoaderProgress:1 '+label+': '+loader_item.deets);
				}
				loader_item.reported_load_progress = true;
			}
			
			CONFIG::debugging {
				Console.trackValue('Z TL '+loader_item.label, StringUtil.formatNumber((getTimer()-loader_item.load_start_ms)/1000, 2)+ 's '+StringUtil.formatNumber(event.bytesLoaded/1024, 2)+'kb');
			}
			
			if (loader_item.callBackProgress is Function) {
				loader_item.callBackProgress(loader_item);
			}
			
			if (event.bytesLoaded == event.bytesTotal) {
				if (!logged_progress_previously_in_this_method) {
					if (loader_item.should_report_load_progress || loader_item.busted) {
						Benchmark.addCheck('TL.onLoaderProgress:2 '+label+': '+loader_item.deets);
					}
				}
				loader_item.load_end_ms = getTimer();
				removeLoaderFromSomeBytesChecking(loader_item);
				checkLoaderForCompletion(loader_item);
			}
		}
		
		private function checkLoaderForSomeBytes(loader_item:LoaderItem):void {
			if (loader_item in checkSomeBytesLoadersMap) return;
			
			checkSomeBytesLoadersMap[loader_item] = true;
			checkSomeBytesLoadersCount++;
			if (!checkSomeBytesTimer.running) {
				// TOO VERBOSE Benchmark.addCheck('TL '+label+': starting up');
				checkSomeBytesTimer.start();
			}
		}
		
		private function removeLoaderFromSomeBytesChecking(loader_item:LoaderItem):void {
			if (loader_item in checkSomeBytesLoadersMap) {
				delete checkSomeBytesLoadersMap[loader_item];
				checkSomeBytesLoadersCount--;
				
				// kill the timer when we're not waiting for anything
				if (checkSomeBytesLoadersCount == 0) {
					// TOO VERBOSE Benchmark.addCheck('TL '+label+': shutting down');
					checkSomeBytesTimer.stop();
				}
			}
		}
		
		private function checkLoaderForCompletion(loader_item:LoaderItem):void {
			if (loader_item in checkLoadersMap) return;
			
			checkLoadersMap[loader_item] = true;
			checkLoadersCount++;
			if (!checkemTimer.running) {
				// TOO VERBOSE Benchmark.addCheck('TL '+label+': starting up');
				checkemTimer.start();
			}
		}
		
		private function removeLoaderFromCompletionChecking(loader_item:LoaderItem):void {
			if (loader_item in checkLoadersMap) {
				delete checkLoadersMap[loader_item];
				checkLoadersCount--;
				
				// kill the timer when we're not waiting for anything
				if (checkLoadersCount == 0) {
					// TOO VERBOSE Benchmark.addCheck('TL '+label+': shutting down');
					checkemTimer.stop();
				}
			}
		}
	}
}