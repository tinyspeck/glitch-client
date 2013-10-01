package com.tinyspeck.engine.util {
	import com.adobe.images.PNGEncoder;
	import com.adobe.utils.Base64Encoder;
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.utils.ByteArray;

	public class PNGUtil {
		private static var api_url:String;
		private static var api_token:String;
		
		public function PNGUtil() {
			
			
		}
		
		public static function setAPIUrl(url:String, token:String):void {
			api_url = url;
			api_token = token;
		}
		
		public static function savePngSheets(bmdsH:Object, post_args:Object, post_url:String, callbacker:Function):void {
			
			if (!bmdsH['image_base']) {
				CONFIG::debugging {
					Console.error('no base sheet!');
				}
				return;
			}
			
			var img:BitmapSnapshot = new BitmapSnapshot(null, post_args.checksum+'__'+'image_base'+'.png', 0, 0, bmdsH['image_base']);
			
			// ok, the BitmapSnapshot is now base.
			// so we can delete that from bmdsH and pass the rest of the sheets in to saveOnServerMultiPart
			delete bmdsH['image_base'];
			
			post_args.ctoken = api_token;
		
			img.saveOnServerMultiPart(
				'image_base',
				post_args,
				(post_url) ? post_url : api_url+'simple/god.avatars.storeSheets',
				bmdsH,
				function(ok:Boolean, txt:String = ''):void {
					if (callbacker is Function) callbacker(ok, txt);
				}
			);
		}
		
		public static function cleanBms():void {
			if (img_bm && img_bm.parent) img_bm.parent.removeChild(img_bm);
			if (img_100_bm && img_100_bm.parent) img_100_bm.parent.removeChild(img_100_bm);
			if (img_50_bm && img_50_bm.parent) img_50_bm.parent.removeChild(img_50_bm);
			
			img_bm = null;
			img_100_bm = null;
			img_50_bm = null;
		}
		
		private static var img_bm:Bitmap;
		private static var img_100_bm:Bitmap;
		private static var img_50_bm:Bitmap;
		
		public static function saveSinglesFromAvatarMc(post_args:Object, post_url:String, ava_swf:AvatarSwf, ac:AvatarConfig, callbacker:Function = null):void {
				//Console.warn('saveSinglesFromAvatarMc');
			
			// all these numbers work for the scale of 1.76.
			// they provde enough room for shows, tall hats/hair, and hair/hats that extend far out behind the head. 
			// if you really need to tweak, you gotta test with a lot of configs on the avatar 
			
			var holder:Sprite = new Sprite();
			var sub_scaler:Sprite = new Sprite();
			holder.addChild(sub_scaler);
			var w:int = 172;
			var h:int = 248;
			var scale:Number = 1.76;//parseFloat(EnvironmentUtil.getUrlArgValue('SWF_scale'));//1.78;
			
			var was_avatar_scaleX:Number = ava_swf.avatar.scaleX; // in case it was swapped
			var was_scaleX:Number = ava_swf.scaleX;
			var was_scaleY:Number = ava_swf.scaleY;
			var was_x:Number = ava_swf.x;
			var was_y:Number = ava_swf.y;
			var was_parent:DisplayObjectContainer = ava_swf.parent;
			var was_depth:int = (was_parent) ? was_parent.getChildIndex(ava_swf) : 0;
			
			ava_swf.avatar.scaleX = 1;
			ava_swf.scaleX = -scale;
			ava_swf.scaleY = scale;
			sub_scaler.addChild(ava_swf);
			ava_swf.x = (ava_swf.swf.loaderInfo.width*scale)+10; // 10 places it nicely so big hair fits
			ava_swf.y = 26;//parseInt(EnvironmentUtil.getUrlArgValue('SWF_y'));
			
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(ac, ava_swf);
			if (!acr.ready) {
				acr.addCallback(function(ac:AvatarConfig):void {
					//Console.warn('ac is NOW ready, snapping');
					saveSinglesFromAvatarMc(post_args, post_url, ava_swf, ac, callbacker);
				});
				return;
			} else {
				if (ac.placeholder) {
					ava_swf.initializeHead(ac);
					ava_swf.showPlaceholderSkin();
				} else {
					ava_swf.initializeHead(ac);
					ava_swf.hidePlaceholderSkin();
				}
			}
			
			ava_swf.playFrameSeq([14]);
			
			
			var img:BitmapSnapshot = new BitmapSnapshot(holder, 'image.png', w, h);
			img_bm = new Bitmap(img.bmd);
			
			CONFIG::debugging {
				Console.info('image is '+w+'x'+h);
			}
			
			// 100 size
			sub_scaler.scaleX = sub_scaler.scaleY = 100/172;
			var img_100:BitmapSnapshot = new BitmapSnapshot(holder, 'image_100.png', Math.round(w*sub_scaler.scaleX), Math.round(h*sub_scaler.scaleX));
			img_100_bm = new Bitmap(img_100.bmd);
			StageBeacon.stage.addChild(img_bm);
			StageBeacon.stage.addChild(img_100_bm);
			img_100_bm.x = img_bm.x+img_bm.width+0;
			CONFIG::debugging {
				Console.info('image_100 is '+img_100_bm.width+'x'+img_100_bm.height);
			}
			
			// 50 size
			sub_scaler.scaleX = sub_scaler.scaleY = 50/172;
			var img_50:BitmapSnapshot = new BitmapSnapshot(holder, 'image_50.png', Math.round(w*sub_scaler.scaleX), Math.round(h*sub_scaler.scaleX));
			img_50_bm = new Bitmap(img_50.bmd);
			StageBeacon.stage.addChild(img_50_bm);
			img_50_bm.x = img_100_bm.x+img_100_bm.width+0;
			CONFIG::debugging {
				Console.info('image_50 is '+img_50_bm.width+'x'+img_50_bm.height);
			}
			
			post_args.ctoken = api_token;
			img.saveOnServerMultiPart(
				'image',
				post_args,
				(post_url) ? post_url : api_url+'simple/god.avatars.storeSingles',
				{
					image_100: img_100.bmd,
					image_50: img_50.bmd
				},
				function(ok:Boolean, txt:String = ''):void {
					if (callbacker is Function) callbacker(ok, txt);
				}
			);
			
			ava_swf.avatar.scaleX = was_avatar_scaleX;
			ava_swf.scaleX = was_scaleX;
			ava_swf.scaleY = was_scaleY;
			ava_swf.x = was_x;
			ava_swf.y = was_y;
			if (was_parent && !(was_parent is Loader)) {
				was_parent.addChildAt(ava_swf, was_depth);
			}
		}
		
		public static function saveArticlePngFromAvatarMc(method:String, id:String, ava_swf:AvatarSwf, ac:AvatarConfig, ava_article_img_settings:Object, callbacker:Function = null):void {
			//Console.warn('saveArticlePngFromAvatarMc');
			CONFIG::debugging {
				Console.dir(ava_article_img_settings);
			}
			
			var out_w:int = 140;
			var out_h:int = 140;
			
			var w:int = 200;
			var h:int = 200;
			
			var scale:Number = ava_article_img_settings.scale;
			
			var holder:Sprite = new Sprite();
			
			var flipper:Sprite = new Sprite();
			//flipper.scaleX = -1;
			flipper.scaleX = -(out_w/w);
			flipper.scaleY = (out_h/h);
			flipper.x = out_w;
			holder.addChild(flipper);
			
			var fade_top:Shape = new Shape();
			var fade_bott:Shape = new Shape();
			
			ava_swf.scaleX = scale;
			ava_swf.scaleY = scale;
			flipper.addChild(ava_swf);
			ava_swf.x = (ava_article_img_settings.hasOwnProperty('x')) ? ava_article_img_settings.x : Math.round((w-(ava_swf.swf.loaderInfo.width*scale))/2);
			ava_swf.y = (ava_article_img_settings.hasOwnProperty('y')) ? ava_article_img_settings.y : Math.round((h-(ava_swf.swf.loaderInfo.height*scale))/2);
			
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(ac, ava_swf);
			if (!acr.ready) {
				acr.addCallback(function(ac:AvatarConfig):void {
					//Console.warn('ac is NOW ready, snapping');
					saveArticlePngFromAvatarMc(method, id, ava_swf, ac, ava_article_img_settings, callbacker);
				});
				return;
			} else {
				ava_swf.initializeHead(ac);
			}
			
			if (ava_article_img_settings.hide_head) {
				ava_swf.hideAllHead();
			} else {
				ava_swf.showAllHead()
			}
			
			if (ava_article_img_settings.hide_arms) {
				ava_swf.hideArms();
			} else {
				ava_swf.showArms()
			}
			
			/*
			if (!ava_article_img_settings.fade_top) ava_article_img_settings.fade_top = {
			h:30,
			colorsA: [0xffffff, 0xffffff, 0xffffff],
			alphasA: [1,1,0],
			ratiosA: [0,127,255]
			}
			if (!ava_article_img_settings.fade_bott) ava_article_img_settings.fade_bott = {
			h:30,
			colorsA: [0xffffff, 0xffffff, 0xffffff],
			alphasA: [0,1,1],
			ratiosA: [0,205,255]
			}
			*/
			
			if (ava_article_img_settings.hasOwnProperty('fade_top')) {
				DrawUtil.drawVerticalGradientBG(
					fade_top.graphics,
					200,
					ava_article_img_settings.fade_top.h,
					0,
					ava_article_img_settings.fade_top.colorsA,
					ava_article_img_settings.fade_top.alphasA,
					ava_article_img_settings.fade_top.ratiosA
				)
			}
			
			if (ava_article_img_settings.hasOwnProperty('fade_bott')) {
				fade_bott.y = h-ava_article_img_settings.fade_bott.h;
				DrawUtil.drawVerticalGradientBG(
					fade_bott.graphics,
					200,
					ava_article_img_settings.fade_bott.h,
					0,
					ava_article_img_settings.fade_bott.colorsA,
					ava_article_img_settings.fade_bott.alphasA,
					ava_article_img_settings.fade_bott.ratiosA
				)
			}
			
			flipper.addChild(fade_top);
			flipper.addChild(fade_bott);
			
			ava_swf.playFrameSeq([14]);
			
			if (!method) method = 'simple/god.faces.setImage';
			
			var img:BitmapSnapshot = new BitmapSnapshot(holder, 'avatar.png', out_w, out_h, null, null, false);
			img.saveOnServerMultiPart(
				'image',
				{
					ctoken: api_token,
					id: id
				},
				api_url+method,
				null,
				function(ok:Boolean, txt:String = ''):void {
					if (callbacker is Function) callbacker(ok, txt);
				}
			);
		}
		
		public static function saveBadgePngsFromMc(swf:MovieClip, class_tsid:String, callbacker:Function = null):Array {
			
			var holder:Sprite = new Sprite();
			holder.addChild(swf);
			
			swf.width = swf.height = 500;
			var image:BitmapSnapshot = new BitmapSnapshot(holder, 'badge.png', 500, 500);
			
			CONFIG::debugging {
				Console.info(image.bmd.rect);
			}
			
			//swf.width = swf.height = 180;
			//var image_180:BitmapSnapshot = new BitmapSnapshot(holder, 'badge.png', 180, 180);
			//swf.width = swf.height = 60;
			//var image_60:BitmapSnapshot = new BitmapSnapshot(holder, 'badge.png', 60, 60);
			
			image.saveOnServerMultiPart(
				'image',
				{
					ctoken: api_token,
					class_tsid:class_tsid
				},
				api_url+'simple/god.achievements.storeImages',
				null/*{
					image_60: image_60.bmd
				}*/,
				function(ok:Boolean, txt:String = ''):void {
					if (callbacker is Function) callbacker(ok, txt);
				}
			);
			
			return [new Bitmap(image.bmd)];
		}
		
		public static function getBase64StringFromByteArray(bytes:ByteArray):String {
			var myBase64Encoder:Base64Encoder = new Base64Encoder();
			myBase64Encoder.encodeBytes(bytes);
			var str:String = myBase64Encoder.toString();
			return str;
		}
		
		public static function getBase64StringFromBitmap(bm:Bitmap):String {
			return getBase64StringFromByteArray(PNGEncoder.encode(bm.bitmapData));
		}
		
		/**
		 * Bitmap to ByteArray UNTESTED
		 */
		public static function getByteArrayFromBitmap(bm:Bitmap):ByteArray {
			var bytes:ByteArray = new ByteArray();
			bytes.writeUnsignedInt(bm.bitmapData.width);
			bytes.writeBytes(bm.bitmapData.getPixels(bm.bitmapData.rect));
			//bytes.compress();
			return bytes;
		}
		
		/**
		 * ByteArray to Bitmap UNTESTED
		 */
		public static function getBitmapFromByteArray(bytes:ByteArray):Bitmap {
			var bm:Bitmap = null;
			try {
				bytes.uncompress();
				var width:int = bytes.readUnsignedInt();
				var height:int = ((bytes.length - 4) / 4) / width;
				var bmd:BitmapData = new BitmapData(width, height, true, 0);
				bmd.setPixels(bmd.rect, bytes);
				bm = new Bitmap(bmd);
			} catch (e:Error) {
				trace('BitmapSerialize error uncompressing bytes');                
			}
			return bm;
		}
	}
}