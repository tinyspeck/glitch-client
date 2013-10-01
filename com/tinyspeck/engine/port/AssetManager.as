package com.tinyspeck.engine.port {
	
	import com.tinyspeck.bootstrap.BootUtil;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.loader.SmartByteLoader;
	import com.tinyspeck.engine.loader.SmartWebBitmapLoader;
	import com.tinyspeck.engine.util.ObjectUtil;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.utils.Dictionary;
	
	public class AssetManager {
		/* singleton boilerplate */
		public static const instance:AssetManager = new AssetManager();
		
		public static var dongs_str:String = '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';
		public static var white_question_mark:String = 'iVBORw0KGgoAAAANSUhEUgAAABMAAAAbCAYAAACeA7ShAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAANpJREFUeNpi/P//PwMSKIfSLlCMDs4C8WoovQdDFmiYCxCf+U86AOkxBjkGhkFE+X/KQCjMMCYGysEqIDYGMahhGAh0YDMMFLAVQKwMxIxIOB0qhwuAIksQFmZnoBHBgAcLAvFdPGFnzEDAAHTcgccwF1LD7D0euXukGmaMx5J7pHhRCY8XO2CJlliDcAX+O6g8UYalEZsDcBlgDE0y74g1CJdhLkTkx1Uwr1Fi2Ez0koJcw+4SCl9qZXQGapYa1DeMEa0OGDyGYfPmTFA9gwOXD80IGLyGAQQYAOCJ7o6iqUDBAAAAAElFTkSuQmCC';
		
		public var assets:*;
		
		private const sbl_to_loadVO_map:Dictionary = new Dictionary();
		private const bmd_map:Dictionary = new Dictionary();
		private const swbl_to_loadVO_map:Dictionary = new Dictionary();
		
		/* constructor */
		public function AssetManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init(a:*):void {
			assets = a;
			
			// register fonts
			if(assets && assets.fontsA){
				for (var i:int=0;i<assets.fontsA.length;i++) {
					try {
						if (assets.fontsA[int(i)]) {
							Font.registerFont(assets[assets.fontsA[int(i)]]);
							
							CONFIG::debugging {
								Console.info('Font.registerFont -> '+ assets.fontsA[int(i)]+' '+assets[assets.fontsA[int(i)]]);
							}
						} else {
							; // shut up
							CONFIG::debugging {
								Console.warn('WTF '+assets.fontsA[int(i)]+' not found?');
							}
						}
					} catch(err:Error) {
						; // what
						CONFIG::debugging {
							Console.error('Font.registerFont -> '+ assets.fontsA[int(i)]+' '+assets[assets.fontsA[int(i)]]);
						}
					}
				}
			}
		}
		
		public function isBMLoading(key:String):Boolean {
			var bmdVO:BMDVO = bmd_map[key];
			if (!bmdVO) return false;
			if (bmdVO.loaded) return false;
			return true;
		}
		
		private function tryGetBitmapFromMap(key:String, callBack:Function):Boolean {
			var bmdVO:BMDVO = bmd_map[key];
			if (bmdVO) { // we have loaded or are loading
				if (bmdVO.loaded) { // we already have it!
					if (callBack != null) callBack(key, getBitmapFromMap(key));
				} else { // we're loading; add this callback for when loading ends
					if (callBack != null) bmdVO.callBacks.push(callBack);
				}
				return true;
			}
			
			// a new img to load
			// Console.warn('creating '+key+' in bmd_map');
			
			bmdVO = bmd_map[key] = new BMDVO();
			bmdVO.callBacks = [callBack];
				
			return false;
		}
		
		private function bitmapLoadDone(key:String):void {
			var bmdVO:BMDVO = bmd_map[key];
			if (!bmdVO) {
				CONFIG::debugging {
					Console.error('WTF '+key+' not in bmd_map?');
				}
				return;
			}
			
			bmdVO.loaded = true;
			
			for (var i:int;i<bmdVO.callBacks.length;i++) {
				bmdVO.callBacks[int(i)](key, getBitmapFromMap(key));
			}
			
			bmdVO.callBacks.length = 0;
			bmdVO.callBacks = null;
		}
		
		private function getBitmapFromMap(key:String):Bitmap {
			var bmdVO:BMDVO = bmd_map[key];
			if (!bmdVO) {
				; //cry more compiler
				CONFIG::debugging {
					Console.error(key+' has no bmdVO in bmd_map??');
				}
			}
			if (!bmdVO || !bmdVO.bmd) return null;
			return new Bitmap(bmdVO.bmd.clone());
		}
		
		//----------------------------------------------------------------------------------
		
		// key can be the name of a file in the Web/img dir like "vanity_nose_icon.png" you passed to loadBitmapFromWeb() to load bitmap,
		// or a key string you passed to loadBitmapFromBASE64() with a Base64 string to create a bitmap
		public function getLoadedBitmap(key:String):Bitmap {
			var bmdVO:BMDVO = bmd_map[key];
			if (!bmdVO) {
				CONFIG::debugging {
					Console.error('I have never seen the key "'+key+'" before. Before loading with the method, you must prime the pump by calling loadBitmapFromBASE64 or loadBitmapFromWeb, dude');
				}
				return null;
			}
			if (!bmdVO.loaded) {
				CONFIG::debugging {
					Console.error('Key "'+key+'" has not finished loading');
				}
				return null;
			}
			if (!bmdVO.bmd) {
				CONFIG::debugging {
					Console.error('I guess key "'+key+'" failed to load properly');
				}
				return null;
			}
			return getBitmapFromMap(key);
		}
		
		public function getLoadedBitmapData(key:String):BitmapData {
			var bmdVO:BMDVO = bmd_map[key];
			if (!bmdVO) {
				//Console.error('I have never seen the key "'+key+'" before. Before loading with the method, you must prime the pump by calling loadBitmapFromBASE64 or loadBitmapFromWeb, dude');
				return null;
			}
			if (!bmdVO.loaded) {
				//Console.error('Key "'+key+'" has not finished loading');
				return null;
			}
			if (!bmdVO.bmd) {
				//Console.error('I guess key "'+key+'" failed to load properly');
				return null;
			}
			
			return bmdVO.bmd;
		}
		
		public function removeLoadedBitmapData(key:String):void {
			var bmdVO:BMDVO = bmd_map[key];
			if (bmdVO && bmdVO.loaded) {
				if (bmdVO.bmd) {
					bmdVO.bmd.dispose();
				}
				bmdVO.bmd = null;
				delete bmd_map[key];
			} else if (!bmdVO) {
				//Console.warn(key+' not exists');
			} else {
				//Console.warn(key+' exists BUT is not loaded');
			}
		}
		
		//----------------------------------------------------------------------------------
		
		public function loadBitmapFromBASE64(key:String, str:String, callBack:Function):void {
			if (!tryGetBitmapFromMap(key, callBack)) {
				
				if (!str) {
					CONFIG::debugging {
						Console.error('You passed key "'+key+'", it was not already loaded, and you did not provide a str to decode for it. WTF DUDE!');
					}
					bitmapLoadDone(key);
					return;
				}
				
				var loadVO:LoadVO = new LoadVO();
				loadVO.type = LoadVO.TYPE_BASE64;
				loadVO.key = key;
				
				
				var sbl:SmartByteLoader = new SmartByteLoader(key);
				sbl_to_loadVO_map[sbl] = loadVO;
				
				// these are automatically removed on complete or error:
				sbl.error_sig.add(onBitmapBASE64imgLoadError);
				sbl.complete_sig.add(onBitmapBASE64imgComplete);
				
				sbl.load(ObjectUtil.decode(str));
			}
		}
		
		private function onBitmapBASE64imgComplete(sbl:SmartByteLoader):void {
			var loadVO:LoadVO = sbl_to_loadVO_map[sbl];
			var bm:Bitmap = Bitmap(sbl.contentLoaderInfo.content);
			bmd_map[loadVO.key].bmd = bm.bitmapData;
			finishWithBitmapBASE64imgLoad(sbl);
		}
		
		private function onBitmapBASE64imgLoadError(sbl:SmartByteLoader):void {
			finishWithBitmapBASE64imgLoad(sbl);
		}
		
		private function finishWithBitmapBASE64imgLoad(sbl:SmartByteLoader):void {
			var loadVO:LoadVO = sbl_to_loadVO_map[sbl];
			delete sbl_to_loadVO_map[sbl];
			bitmapLoadDone(loadVO.key);
		}
		
		//----------------------------------------------------------------------------------
		
		public function loadBitmapFromWeb(filename:String, callBack:Function, why:String):void {
			// first see if we have already loaded or are loading this
			if (tryGetBitmapFromMap(filename, callBack)) {
				return;
			}
			
			// first time! so load it.
			var url:String = (filename.toLowerCase().indexOf('http://') == 0) ? filename : BootUtil.root_url+'img/'+filename.replace('/img/', '');
			var loadVO:LoadVO = new LoadVO();
			loadVO.type = LoadVO.TYPE_WEB;
			loadVO.url = url;
			loadVO.filename = filename;
			loadVO.retries = 0;
			loadVO.why = why;
			
			var swbl:SmartWebBitmapLoader = new SmartWebBitmapLoader(loadVO.filename);
			swbl_to_loadVO_map[swbl] = loadVO;
			
			// these are automatically removed on complete or error:
			swbl.complete_sig.add(onBitmapWebimgComplete);
			swbl.error_sig.add(onBitmapWebimgLoadError);
			swbl.load(new URLRequest(loadVO.url));
		}
		
		private function onBitmapWebimgComplete(swbl:SmartWebBitmapLoader):void {
			var loadVO:LoadVO = swbl_to_loadVO_map[swbl];
			var bm:Bitmap = Bitmap(swbl.contentLoaderInfo.content);
			bmd_map[loadVO.filename].bmd = bm.bitmapData;
			finishWithBitmapWebimgLoad(swbl);
		}
		
		private function onBitmapWebimgLoadError(swbl:SmartWebBitmapLoader):void {
			finishWithBitmapWebimgLoad(swbl);
		}
		
		private function finishWithBitmapWebimgLoad(swbl:SmartWebBitmapLoader):void {
			var loadVO:LoadVO = swbl_to_loadVO_map[swbl];
			delete swbl_to_loadVO_map[swbl];
			bitmapLoadDone(loadVO.filename);
		}
		
		CONFIG::god public function memReport():String {
			var str:String = '\nAssetManager memReport\n+--------------------------------------------------\n'
			str+= 'bmd_map:\n'
			for (var k:String in bmd_map) {
				str+= 'bmd_map:' +k+' '+BitmapData(bmd_map[k].bmd)+'';
				if (bmd_map[k] && bmd_map[k].bmd) str+= ' '+BitmapData(bmd_map[k].bmd).rect;
				str+='\n';
			}
			str+= 'img_loader_map:\n';
			var loadVO:LoadVO;
			return str;
		}
	}
}

import flash.display.BitmapData;

class LoadVO {
	public static var TYPE_WEB:String = 'web';
	public static var TYPE_BASE64:String = 'base64';
	
	public var type:String;
	public var key:String;
	public var url:String;
	public var filename:String;
	public var retries:int = 0;
	public var why:String;
	public function LoadVO() {
		//
	}
}

class BMDVO {
	public var bmd:BitmapData;
	public var callBacks:Array;
	public var loaded:Boolean;
	public function BMDVO() {
		//
	}
}
