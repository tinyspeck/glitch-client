package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.text.StyleSheet;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	public class CSSManager
	{
		public var css:String;
		public var styleSheet:StyleSheet = new StyleSheet();
		
		/* singleton boilerplate */
		public static const instance:CSSManager = new CSSManager();
		
		/* constructor */
		public function CSSManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init(css:String):void {
			this.css = css;
			styleSheet.parseCSS(css);
		}
		
		public function getStyle(style_name:String):Object {
			if (style_name.indexOf('.') == -1) style_name = '.'+style_name;
			return styleSheet.getStyle(style_name);
		}
		
		public function getArrayValueFromStyle(style_name:String, value_name:String, default_value:Array = null):Array {
			var style:Object = getStyle(style_name);
			if (!style.hasOwnProperty(value_name)) return default_value;
			
			return String(style[value_name]).split(',');
		}
		
		public function getNumberValueFromStyle(style_name:String, value_name:String, default_value:Number = 0):Number {
			var style:Object = getStyle(style_name);
			if (!style.hasOwnProperty(value_name)) return default_value;
			
			return parseFloat(style[value_name]);
		}
		
		public function getBooleanValueFromStyle(style_name:String, value_name:String, default_value:Boolean = false):Boolean {
			var style:Object = getStyle(style_name);
			if (!style.hasOwnProperty(value_name)) return default_value;
			
			if (String(style[value_name]).toLowerCase() == 'true') return true;
			if (style[value_name] == 1) return true;
			return false;
		}
		
		public function getStringValueFromStyle(style_name:String, value_name:String, default_value:String = ''):String {
			var style:Object = getStyle(style_name);
			if (!style.hasOwnProperty(value_name)) return default_value;
			
			//make sure to remove double quotes
			return StringUtil.stripDoubleQuotes(style[value_name]);
		}
		
		public function getUintColorValueFromStyle(style_name:String, value_name:String, default_value:uint = 0):uint {
			var style:Object = getStyle(style_name);
			if (!style) return default_value;
			if (!style.hasOwnProperty(value_name)) return default_value;
			
			return StringUtil.cssHexToUint(style[value_name]);
		}
		
		public function getTextFormatFromStyle(style_name:String):TextFormat {
			var tf:TextFormat = new TextFormat();
			tf.font = getStringValueFromStyle(style_name, 'fontFamily', 'HelveticaEmbed');
			tf.size = getNumberValueFromStyle(style_name, 'fontSize', 12);
			tf.color = getUintColorValueFromStyle(style_name, 'color', 0);
			tf.leading = getNumberValueFromStyle(style_name, 'leading', 0);
			tf.bold = getStringValueFromStyle(style_name, 'fontWeight', 'normal') == 'bold' ? true : false;
			tf.align =  getStringValueFromStyle(style_name, 'textAlign', TextFormatAlign.LEFT);
						
			return tf;
		}
	}
}