package com.tinyspeck.engine.util {
	
	import com.quasimondo.geom.ColorMatrix;
	
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	
	public class ColorUtil {
		
		public function ColorUtil() {
			//
		}
		
		public static function colorNumToStr(color:uint, include_pound:Boolean = false):String {
			var color_str:String = color.toString(16).toUpperCase();
			while(color_str.length < 6) color_str = "0" + color_str;
			return (include_pound ? '#' : '') + color_str;
		}
		
		public static function colorStrToNum(color:String):uint {
			if(color.substr(0,1) == '#') color = color.substr(1);
			return parseInt("0x" + color, 16);
		}
		
		public static function getColorTransform(c:uint):ColorTransform {
			const rr:int = c >> 16 & 0xFF;
			const gg:int = c >> 8 & 0xFF;
			const bb:int = c & 0xFF;
			return new ColorTransform(0, 0, 0, 1, rr, gg, bb, 0);
		}
		
		private static const HEX:String = "0123456789ABCDEF";
		public static function getHex(n:Number):String {
			return HEX.charAt((n >> 4) & 0xf) + HEX.charAt(n & 0xf);
		}
		
		public static function getRandomColor(max:Number=255):Number {
			var a:String = getHex( 255 );
			var r:String = getHex( Math.random() * max );
			var g:String = getHex( Math.random() * max );
			var b:String = getHex( Math.random() * max );
			
			return Number( "0x" + a + r + g + b );
		}

		public static function rgb2hsv(c:uint):Object {
			const hsv:Object = {};
			const r:Number = (c >> 16 & 0xFF)/255;
			const g:Number = (c >> 8 & 0xFF)/255;
			const b:Number = (c & 0xFF)/255;
			const x:Number = Math.min(Math.min(r, g), b);
			const val:Number = Math.max(Math.max(r, g), b);
			if (x==val) {
				hsv.h = 0;
				hsv.s = 0;
				hsv.v = Math.round(val*100);
			} else {
				const f:Number = (r == x) ? g-b : ((g == x) ? b-r : r-g);
				const i:Number = (r == x) ? 3 : ((g == x) ? 5 : 1);
				hsv.h = Math.round((i-f/(val-x))*60)%360;
				hsv.s = Math.round(((val-x)/val)*100);
				hsv.v = Math.round(val*100);
			}
			
			return hsv;
		}
		
		public static function getGreyScaleFilter():ColorMatrixFilter {
			var matrix:Array = [.33,.33,.33,0,0,
								.33,.33,.33,0,0,
								.33,.33,.33,0,0,
								0,0,0,1,0];
			return new ColorMatrixFilter(matrix);
		}
		
		public static function getInvertColors():ColorMatrixFilter {
			var color_matrix:ColorMatrix = new ColorMatrix();
			color_matrix.invert();
			
			return new ColorMatrixFilter(color_matrix.matrix);
		}
			
		public static function getDotColor(c_str:String):uint {
			if (c_str && c_str.indexOf('#') == 0) {
				return colorStrToNum(c_str);
			}
			
			return 0;
		}
		
		/** Returns the alpha part of an ARGB color (0 - 255). */
		public static function getAlpha(color:uint):int { return (color >> 24) & 0xff; }
	}
}
/*
package com.malee.utils {
	
	public class ColorUtil {
		
		private static const HEX:String = "0123456789ABCDEF";
		
		public static function getColor(num:Number):Object {
			
			var ob:Object = {};
			
			ob.a = num >> 24 & 0xFF;
			ob.r = num >> 16 & 0xFF;
			ob.g = num >> 8 & 0xFF;
			ob.b = num & 0xFF;
			
			return ob;
		}
		
		public static function getHex(n:Number):String {
			
			return HEX.charAt((n >> 4) & 0xf) + HEX.charAt(n & 0xf);
		}
		
		public static function getRandomColor(max:Number):Number {
			
			var a:String = getHex( 255 );
			var r:String = getHex( Math.random() * max );
			var g:String = getHex( Math.random() * max );
			var b:String = getHex( Math.random() * max );
			
			return Number( "0x" + a + r + g + b );
		}
		
		public static function numberRGB(color:String):Number {
			
			return parseInt(color, 16);
		}
		
		public static function stringRGB(num:Number):String {
			
			var col:Object = getColor(num);
			
			var r:String = getHex(col.r);
			var g:String = getHex(col.g);
			var b:String = getHex(col.b);
			
			return r.concat(g, b);
		}
		
		public static function stringARGB(num:Number):String {
			
			var col:Object = getColor(num);
			
			var a:String = getHex(col.a);
			var r:String = getHex(col.r);
			var g:String = getHex(col.g);
			var b:String = getHex(col.b);
			
			return a.concat(r, g, b);
		}
	}
}
*/