package com.tinyspeck.engine.util {
import flash.external.ExternalInterface;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.Capabilities;
	
	public class URLUtil {
		
		public static const cdn_host_alias_map:Object = {
			'c1.glitch.bz': [
				'c1b.glitch.bz',
				'c1c.glitch.bz',
			],
			'c2.glitch.bz': [
				'c2b.glitch.bz',
				'c2c.glitch.bz',
			],
			'c6.glitch.bz': [
				'c6b.glitch.bz',
				'c6c.glitch.bz',
			]
		}
		
		public static function getTarget(t:String):String {
			if (EnvironmentUtil.is_chrome) return '_blank';
			return t;
		}
		
		public static function cacheBust(url:String):String {
			// append ?cb=123456 or &cb=123456 to the very end, and see if we have a host alias
			const cb:String = 'cb='+String(new Date().getTime());
			const connector:String = (url.lastIndexOf('?') != -1) ? '&' : '?';
			
			// try swapping out host!
			const parts:Array = url.split('/');
			const host:String = (url.toLowerCase().indexOf('http://') == 0) ? parts[2] : null;
			if (host && cdn_host_alias_map[host]) {
				const new_host:String = ObjectUtil.randomFromArray(cdn_host_alias_map[host]);
				url = 'http://'+new_host+'/';
				if (parts.length > 3) {
					url+= parts.slice(3).join('/');
				}
			}
			
			return url+connector+cb;
		}
		
		/** If mark_as_auto_reloaded, SWF_auto_reloaded_after_error will be set to 1 */
		/** If NOT mark_as_auto_reloaded, SWF_auto_reloaded_after_error will be removed from the URL */
		public static function reload(mark_as_auto_reloaded:Boolean = false):void {
			var URLAndQSArgs:Object = EnvironmentUtil.getURLAndQSArgs();
			var url:String = URLAndQSArgs.url;
			var connector:String = '?';
			
			if (mark_as_auto_reloaded) {
				url+= '?SWF_auto_reloaded_after_error=1';
				connector = '&';
			}
			
			for (var k:String in URLAndQSArgs.args) {
				if (k == 'SWF_auto_reloaded_after_error') continue;
				url+= connector+k+'='+URLAndQSArgs.args[k];
				connector = '&';
			}
			navigateToURL(new URLRequest('javascript:window.location.replace("'+url+'");'), '_self');
		}
		
		/**
		 * Opens a popup window to Twitter with whatever you pass as "text", an optional link_url
		 * @param text - What you want to tweet
		 * @param link_url - Optional link to display in the tweet at the end of "text"
		 * @param w - Width of popup window, default is 525
		 * @param h - Height of popup window, default is 450
		 */		
		public static function openTwitter(text:String, link_url:String = '', w:int = 525, h:int = 450):void {
			const url:String = 'https://twitter.com/share?url='+encodeURIComponent(link_url)+'&text='+encodeURIComponent(StringUtil.escapeQuotes(text));
			openPopupWindow(url, 'Twitter', w, h);
		}
		
		/**
		 * Opens a popup window to Facebook
		 * @param link_url - Where the post is linking to
		 * @param w - Width of popup window, default is 570
		 * @param h - Height of popup window, default is 335
		 */	
		public static function openFacebook(link_url:String, w:int = 570, h:int = 335):void {
			const url:String = 'http://www.facebook.com/sharer/sharer.php?u='+encodeURIComponent(link_url);
			openPopupWindow(url, 'Facebook', w, h);
		}
		
		public static function openPinterest(text:String, link_url:String = '', media_url:String = '', w:int = 680, h:int = 300):void {
			const url:String = 'http://pinterest.com/pin/create/button/?url='+encodeURIComponent(link_url)
				+'&description='+encodeURIComponent(StringUtil.escapeQuotes(text))
				+'&media='+encodeURIComponent(media_url);
			openPopupWindow(url, 'Pinterest', w, h);
		}
		
		public static function openGooglePlus(link_url:String, w:int = 600, h:int = 320):void {
			const url:String = 'https://plus.google.com/share?url='+encodeURIComponent(link_url);
			openPopupWindow(url, 'GooglePlus', w, h);
		}
		
		/**
		 * Opens a javascript popup window 
		 * @param url - What the popup load
		 * @param name - Name of the window (Should be unique to what you're doing)
		 * @param w - Width of the window
		 * @param h - Height of the window
		 * @param is_center - Center the window on the screen (default is true)
		 */		
		public static function openPopupWindow(url:String, name:String, w:int, h:int, is_center:Boolean = true):void {
			var options:String = "width="+w+",height="+h+",toolbar=no,scrollbars=yes";
			if(is_center){
				//offset the top and the left
				const left:int = Capabilities.screenResolutionX/2 - w/2;
				const top:int = Capabilities.screenResolutionY/2 - h/2;
				options += ",left="+left+",top="+top;
			}
			const javascript:String = "window.open('"+url+"','"+name+"','"+options+"');";
						
			if(EnvironmentUtil.getBrowserName() != 'IE'){
				navigateToURL(new URLRequest('javascript:'+javascript+' void(0);'), '_self');
			}
			else {
				ExternalInterface.call('function setWMWindow() {'+javascript+'}');
			}
		}
	}
}