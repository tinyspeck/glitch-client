package com.tinyspeck.engine.util
{
	import com.tinyspeck.engine.Version;
	
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;

	public final class EnvironmentUtil
	{
		//Here's a list of helpful items to capture
		//var pageURL:String = ExternalInterface.call('window.location.href.toString');
		//var pageHost:String = ExternalInterface.call('window.location.hostname.toString');
		//var pagePath:String = ExternalInterface.call('window.location.pathname.toString');
		//var pageProtocol:String = ExternalInterface.call('window.location.protocol.toString');
		//var userAgent:String = ExternalInterface.call('window.navigator.userAgent.toString');
		//var platform:String = ExternalInterface.call('window.navigator.platform.toString');
		
		public static function getBrowserUserAgent():String {
			return ExternalInterface.call('window.navigator.userAgent.toString');
		}
		
		public static function getFlashVersion():String {
			return Capabilities.version;
			// MAC 10,1,51,95 is 10.1b3	
		}
		
		public static function getFlashVersionArray():Array {
			var str:String = getFlashVersion();
			return str.split(' ')[1].split(',');
		}
		
		public static function getMajorFlashVersion():int {
			const versionA:Array = getFlashVersionArray();
			return int(versionA[0]);
		}
		
		public static function getMinorFlashVersion():int {
			const versionA:Array = getFlashVersionArray();
			return int(versionA[1]);
		}
		
		/** Returns 'win','mac','lnx','and' */
		public static function get platform():String {
			return String(Capabilities.version.split(' ', 1)[0]).toLowerCase();
		}
		
		public static function get is_mac():Boolean {
			return Capabilities.os.toLowerCase().indexOf('mac') > -1;
		}
		
		public static function get is_safari():Boolean {
			return (getBrowserUserAgent().toLowerCase().indexOf('safari') > -1);
		}
		
		public static function get is_chrome():Boolean {
			return (getBrowserUserAgent().toLowerCase().indexOf('chrome') > -1);
		}
		
		public static function getUrlArgValue(n:String):String {
			return getURLAndQSArgs().args[n] || '';
		}
		
		public static function getWindowWidth():int {
			return ExternalInterface.call('$(window).width');
		}
		
		public static function getWindowHeight():int {
			return ExternalInterface.call('$(window).height');
		}
		
		/**
		 * http://www.mehtanirav.com/2008/11/27/opening-external-links-in-new-window-from-as3/ 
		 * @return Name of the browser so we can work around IE's bullshit
		 */		
		public static function getBrowserName():String {			
			//Uses external interface to reach out to browser and grab browser useragent info.
			const browserAgent:String = ExternalInterface.call("function getBrowser(){return navigator.userAgent;}");         
			
			//Determines brand of browser
			var browser:String = 'Undefined';
			if(browserAgent != null && browserAgent.indexOf("Firefox")>= 0) {
				browser = "Firefox";
			}
			else if(browserAgent != null && browserAgent.indexOf("Safari")>= 0){
				browser = "Safari";
			}
			else if(browserAgent != null && browserAgent.indexOf("MSIE")>= 0){
				browser = "IE";
			}
			else if(browserAgent != null && browserAgent.indexOf("Opera")>= 0){
				browser = "Opera";
			}
			
			return (browser);
		}
		
		private static var URLAndQSArgs:Object;
		public static function getURLAndQSArgs():Object {
			if (URLAndQSArgs) return URLAndQSArgs;
			var url:String = '';
			var args:Object = {};
			var qs:String = ''
			
			try {
				url = ExternalInterface.call('window.location.href.toString');
				var pairs:Array;
				var parts:Array = url.split('?');
				var root_url:String = url.split('?')[0];
				qs = parts[parts.length-1];
				pairs = qs.split('&');
				
				for (var i:int=0; i<pairs.length; i++) {
					var p:int = pairs[int(i)].indexOf('=');
					if (p != -1) {
						var name:String = pairs[int(i)].substring(0, p);
						var value:String = pairs[int(i)].substring(p+1).split('#')[0];
						//var readableString:String = unescape(urlencodedString).replace(/\+/g, " "); ??
						args[name] = unescape(value);
					}
				}
			} catch (err:Error) {
				//
			} 
			
			URLAndQSArgs = {
				args: args,
				url: root_url,
				qs: qs
			};
			
			return URLAndQSArgs;
		}
		
		public static function clientVersionIsBetween(leftRevision:*, rightRevision:*):Boolean {
			var after_revision:Number = parseInt(leftRevision);
			if (isNaN(after_revision)) after_revision = Number.MIN_VALUE;
			
			var before_revision:Number = parseInt(rightRevision);
			if (isNaN(before_revision)) before_revision = Number.MAX_VALUE;
			
			const bootstrapRevision:Number = parseInt(com.tinyspeck.engine.Version.revision);
			if (!isNaN(bootstrapRevision) && (bootstrapRevision > after_revision) && (bootstrapRevision < before_revision)) {
				return true;
			}
			
			const engineRevision:Number = parseInt(com.tinyspeck.engine.Version.revision);
			if (!isNaN(engineRevision) && (engineRevision > after_revision) && (engineRevision < before_revision)) {
				return true;
			}
			
			return false;
		}
		
	}
}