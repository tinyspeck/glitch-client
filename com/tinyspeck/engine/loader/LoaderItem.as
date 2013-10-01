package com.tinyspeck.engine.loader {
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.PerfLogger;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.vo.ArbitrarySWFLoadVO;
	
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	public class LoaderItem {
		public static var count:int;
		public var id:int = -1;
		public var label:String;
		public var urlRequest:URLRequest = new URLRequest();
		public var byteArray:ByteArray;
		public var loadAttempts:int = 0;

		public function get load_end_ms():int {
			return _load_end_ms;
		}
		
		public function get deets():String {
			var name:String = label;
			
			// we really only use this for logging, and so we don't need the whole label in the log.
			// the whole label now includes ::http://... since we switched to itemsstacks being able
			// to load different swfs, not just the swf specified by the item.
			// so let's just strip off that url in logging
			if (name.indexOf('::') > -1) {
				name = name.split('::')[0]+'::(url)';
			}
				
			var details:String = id+' "'+name+'"';
			if (urlRequest) details+= ' '+urlRequest.url;
			if (busted) details+= ' busted';
			if (warned_on_no_bytes) details+= ' warned_on_no_bytes';
			if (!connection_opened) details+= ' !connection_opened';
			details += (' (' + progress * 100 + '%)');
			return '['+details+']';
		}
		
		public function get progress():Number {
			return (bytesTotal ? (bytesLoaded / bytesTotal) : 0);
		}
		
		public function set load_end_ms(value:int):void {
			_load_end_ms = value;
		}
		
		public function logComplete():void {
			if (loader_info) {
				PerfLogger.addBytesLoadedData(loader_info.bytesLoaded, (load_end_ms-load_start_ms)/1000, label);
				var str:String;
				// TOO VERBOSE 
				str = 'LI.logComplete '+deets+' '+StringUtil.formatNumber(loader_info.bytesLoaded/1024, 2)+'kb in '+((load_end_ms-load_start_ms)/1000).toFixed(2)+' secs';
				// if you uncomment the above, comment the below:
				// str = 'LI.logComplete "'+label+'" '+StringUtil.formatNumber(loader_info.bytesLoaded/1024, 2)+'kb in '+((load_end_ms-load_start_ms)/1000).toFixed(2)+' secs';
				Benchmark.addCheck(str);
			}
		}
		
		public function logError():void {
			if (loader_info) {
				var str:String;
				// TOO VERBOSE 
				str = 'LI.logError '+deets;
				// if you uncomment the above, comment the below:
				// str = 'LI.logError "'+label+'" '+StringUtil.formatNumber(loader_info.bytesLoaded/1024, 2)+'kb in '+((load_end_ms-load_start_ms)/1000).toFixed(2)+' secs';
				Benchmark.addCheck(str);
			}
		}

		public var callBackSuccess:Function;
		public var callBackFail:Function;
		public var callBackProgress:Function;
		
		/** Usually stores the ItemstackLoadVO subclass */
		public var vo:ArbitrarySWFLoadVO;
		
		public var content:MovieClip;
		public var loader_info:LoaderInfo;
		public var load_error_timer:Number;
		public var bytesLoaded:int;
		public var bytesTotal:int;
		public var in_q:int;
		public var should_report_load_progress:Boolean;
		public var reported_load_progress:Boolean;
		public var reported_complete_but_no_content:Boolean;
		public var busted:Boolean;
		public var connection_opened:Boolean;
		public var warned_on_no_bytes:Boolean;
		public var appDomain:ApplicationDomain;
		public var loadedAppDomain:ApplicationDomain; // pulled from loader_item.loader_info after laoded and before calling unload() on the loader (which destroys the appdomain)
		
		public var load_start_ms:int;
		private var _load_end_ms:int;
		
		public function LoaderItem(label:String, url:String, byteArrray:ByteArray, callBackSuccess:Function, callBackFail:Function, callBackProgress:Function = null) {
			urlRequest.url = url;
			this.label = label;
			this.byteArray = byteArrray;
			this.callBackSuccess = callBackSuccess;
			this.callBackFail = callBackFail;
			this.callBackProgress = callBackProgress;
			count++;
			id = count;
		}
		
		/** Will cache bust the existing URL request for the next load */
		public function cacheBust():void {
			// cache bust the next attempt, browser cache may be bad
			urlRequest.url = URLUtil.cacheBust(urlRequest.url);
			busted = true;
			Benchmark.addCheck('LoaderItem.cacheBust: ' + deets);
		}
		
		public function dispose(unload:Boolean, andStop:Boolean):void {
			in_q = 0;
			load_error_timer = 0;
			bytesTotal = 0;
			bytesLoaded = 0;
			_load_end_ms = 0;
			loadAttempts = 0;
			load_start_ms = 0;

			if (loader_info) {
                //TODO is there anything we should do to dispose of loader_info on its own
                if (loader_info.loader && unload) {
					// close BEFORE unloading
					try {
						loader_info.loader.close();
					} catch(e:Error){
						//
					};
					try {
						if (andStop) {
							loader_info.loader.unloadAndStop(true);
						} else {
							loader_info.loader.unload();
						}
					} catch (e:Error) {
						//
					}
				}
            }
			
			vo = null;
			label = null;
			content = null;
			loader_info = null;
			appDomain = null;
			byteArray = null;
			urlRequest = null;
			callBackFail = null;
			callBackSuccess = null;
			callBackProgress = null;
			reported_load_progress = false;
			should_report_load_progress = false;
			reported_complete_but_no_content = false;
			busted = false;
			connection_opened = false;
			warned_on_no_bytes = false;
			id = -1;
		}
	}
}
