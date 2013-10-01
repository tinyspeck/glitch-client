/**
 *  VERSION: 2.00 
 *  DATE: 12/11/2009
 *  ACTIONSCRIPT VERSION: 3.0 
 *  AUTHOR : STEPHEN BRAITSCH : stephen@quietless.com
 *  DOCUMENTATION: http://www.quietless.com/kitchen/upload-bitmapdata-snapshot-to-server-in-as3
 **/

package com.quietless.bitmap {
	import com.adobe.images.PNGEncoder;
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.MultiPartByteArray;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	public class BitmapSnapshot extends EventDispatcher implements IDisposable {
		
		private var _bmd:BitmapData;
		private var _name		:String; 			// name to give the newly created image //		
		private var _image 		:ByteArray;			// image data represented as a byte array //
		private var callback:Function;
		private var ba_string:String;
		
		public function BitmapSnapshot($targ:DisplayObject, $name:String = 'MyImage.png', $width:Number = 0, $height:Number = 0, $bmd:BitmapData = null, $ba:ByteArray = null, $transparent:Boolean = true) {
			_name = $name;
			var bmd:BitmapData;
			
			if ($bmd) {
				bmd = $bmd;
			} else if ($targ) {
				// draw the display object into a new bitmapdata object //	
				bmd = new BitmapData($width || $targ.width, $height || $targ.height, $transparent, 0xffffff);
				bmd.draw($targ);
			} else if ($ba) {
				_image = $ba;
			}
			
			_bmd = bmd;
			
			// encode the bitmapdata object to png or jpg based on the name it was was given //
			var ext:String = $name.substr(-3);
			CONFIG::debugging var a:Date = new Date();
			if (ext=='png') _image = PNGEncoder.encode(bmd);
			CONFIG::debugging {
				// out time to generate image file //
				Console.priinfo(427, 'Time to produce $name:"'+$name+'" image = '+(new Date().time-a.time)/1000+' seconds');
				if (!_image) Console.warn('!! Failed To Convert : '+ (($targ)?$targ.name:'(no target, must be a bmd)')+ 'To An Image - !! Ensure File Extension Is Either .jpg or .png');
			}
		}
		
		public function get name():String {
			return _name;
		}
		
		public function dispose():void {
			if (_bmd) {
				_bmd.dispose();
				_bmd = null;
			}
			if (_image) {
				_image.clear();
				_image = null;
			}
			callback = null;
		}
		
		public function get bmd():BitmapData {
			return _bmd;
		}
		
		public function saveToDesktop():void {
			var fr:FileReference = new FileReference();
			fr.save(_image, _name);
		}
		
		public function saveOnServerMultiPart(img_var_name:String, vars:Object, url:String, extra_files:Object, callback:Function):void {
			CONFIG::debugging {
				Console.priinfo(427, 'img_var_name:'+img_var_name+' vars:'+vars+' url:'+url+' extra_files:'+extra_files+' callback:'+callback);
			}
			this.callback = callback;
			var sb:MultiPartByteArray = new MultiPartByteArray();
			var k:String;
			for (k in vars) sb.addVar(k, vars[k]);
			if (extra_files) {
				for (k in extra_files) {
					CONFIG::debugging {
						Console.priinfo(427, 'calling addFile for k:'+k+' sb.length:'+sb.length);
					}
					var ba:ByteArray = (extra_files[k] is ByteArray) ? extra_files[k] : PNGEncoder.encode(extra_files[k]);
					sb.addFile(k, k, ba);
				}
			}
			CONFIG::debugging {
				Console.priinfo(427, 'calling last addFile() sb.length:'+sb.length);
			}
			sb.addFile(img_var_name, img_var_name, _image);
			CONFIG::debugging {
				Console.priinfo(427, 'after addFile() sb.length:'+sb.length);
			}
			
			var req:URLRequest = new URLRequest(url);
			req.requestHeaders.push(new URLRequestHeader("Content-type", "multipart/form-data; boundary="+sb.boundary));
			req.method = URLRequestMethod.POST;
			req.data = sb;
			CONFIG::debugging {
				Console.priinfo(427, 'url:'+url+' sb.length:'+sb.length);
				ba_string = sb.toString();
			}
			
			var ldr:URLLoader = new URLLoader();
			ldr.addEventListener(Event.COMPLETE, onRequestComplete);
			ldr.addEventListener(IOErrorEvent.IO_ERROR, onRequestFailure);
			ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityViolation);
			ldr.load(req);
			CONFIG::debugging {
				Console.priinfo(427, 'after load()');
			}
		}
		
		public function saveOnServer($script:String, $type:String, $id:String, callback:Function = null, $id_name:String = 'tsid', $state:String = ''):void {
			this.callback = callback;
			var hdr:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
			
			var url:String = $script+'?type='+$type+'&'+$id_name+'='+$id+'&cb='+new Date().getTime();
			if ($state) url+= '&state='+$state;
			CONFIG::debugging {
				Console.warn(66, url);
			}
			
			var req:URLRequest = new URLRequest(url);
			req.requestHeaders.push(hdr);
			req.data = _image;
			req.method = URLRequestMethod.POST;
			
			var ldr:URLLoader = new URLLoader();
			ldr.dataFormat = URLLoaderDataFormat.BINARY;
			ldr.addEventListener(Event.COMPLETE, onRequestComplete, false, 0, true);
			ldr.addEventListener(IOErrorEvent.IO_ERROR, onRequestFailure, false, 0, true);
			ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityViolation, false, 0, true);
			CONFIG::debugging {
				ldr.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus, false, 0, true);
			}
			ldr.load(req);
		}
		
		//- EVENT HANDLERS ----------------------------------------------------------------------
		
		private function onRequestComplete(e:Event):void {
			CONFIG::debugging {
				Console.priinfo(427, 'Upload of '+_name+' was successful!!!!!!!!! maybe. Here\'s what was echoed:');
				Console.info(e.target.data);
				if (ba_string) Console.priinfo(427, 'data: '+ba_string.substr(0, Math.min(20, ba_string.length)));
			}
			if (this.callback is Function) this.callback(true, e.target.data);
		}	
		
		CONFIG::debugging private function onHttpStatus(e:HTTPStatusEvent):void {
			Console.priinfo(427, 'Upload of '+_name+' status:'+e);
		}
		
		private function onRequestFailure(e:IOErrorEvent):void {
			CONFIG::debugging {
				Console.priinfo(427, 'Upload of '+_name+' has failed: '+e);
				if (ba_string) Console.priinfo(427, 'data: '+ba_string.substr(0, Math.min(20, ba_string.length)));
				Console.error(e);
			}
			if (this.callback is Function) this.callback(false, null);
		}	
		
		private function onSecurityViolation(e:SecurityErrorEvent):void {
			CONFIG::debugging {
				Console.error('Security Violation has occurred, check crossdomain policy files '+e);
				if (ba_string) Console.priinfo(427, 'data: '+ba_string.substr(0, Math.min(20, ba_string.length)));
			}
			if (this.callback is Function) this.callback(false, null);
		}				
	}
}
