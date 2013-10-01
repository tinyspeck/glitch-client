package com.tinyspeck.engine.data.pc {
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.ColorUtil;
	
	public class AvatarConfigColor extends AbstractTSDataEntity {
		
		public var tintColor:uint;
		public var brightness:int = 100;
		public var saturation:int = 100;
		public var contrast:int = 100;
		public var tintAmount:int = 100;
		public var alpha:int = -1;

		
		public function AvatarConfigColor(hashName:String) {
			super(hashName);
		}
		
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			ob.tintColor = ColorUtil.colorNumToStr(tintColor);
			ob.brightness = brightness;
			ob.saturation = saturation;
			ob.contrast = contrast;
			ob.tintAmount = tintAmount;
			ob.alpha = alpha;
			
			return ob;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):AvatarConfigColor {
			var acc:AvatarConfigColor = new AvatarConfigColor(hashName);
			
			for(var j:String in object){
				var val:* = object[j];
				if(j in acc){
					if (j == 'tintColor') {
						acc.tintColor = ColorUtil.colorStrToNum(val);
					} else {
						acc[j] = val;
					}
				}else{
					resolveError(acc,object,j);
				}
			}
			return acc;
		}
		
		public static function parseMultiple(object:Object):Object {
			var D:Object = {};
			for (var k:String in object) {
				if (object[k] is String) {
					//BootError.handleError('Expected a hash of color object, instead got a string: '+k+':'+object[k], new Error('Bad value for hair_colors'), null, !CONFIG::god);
					CONFIG::debugging {
						Console.error('Expected a hash of color object, instead got a string: '+k+':'+object[k]);
					}
					return null;
				}
				if (object[k].tintColor === '') continue;
				D[k] = AvatarConfigColor.fromAnonymous(object[k], k);
			}
			return D;
		}
		
	}
}