package com.tinyspeck.engine.util
{
	import com.tinyspeck.engine.port.CSSManager;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;

	public class TFUtil
	{
		private static const defaultTextFormat:TextFormat = new TextFormat();
		
		/**
		 * Allows you to setup a textfield with default values. 
		 * @param tf	
		 * @param is_multi 
		 * 
		 * NOTE: width/height can only be set when is_multi is true
		 */		
		public static function prepTF(tf:TextField, is_multi:Boolean=true, hover_style:Object=null):void {
			if(!tf) return;
			
			resetTF(tf);
			tf.embedFonts = true;
			tf.selectable = false;
			if (hover_style) {
				tf.styleSheet = new StyleSheet();
				tf.styleSheet.parseCSS(CSSManager.instance.css);
				tf.styleSheet.setStyle('a:hover', hover_style);
			} else {
				tf.styleSheet = CSSManager.instance.styleSheet;
			}
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.mouseWheelEnabled = false;
			tf.wordWrap = is_multi;
			tf.multiline = is_multi;
		}
		
		public static function resetTF(tf:TextField):void {
			tf.htmlText = '';
			//obj.text = null;
			
			tf.alwaysShowSelection = false;
			tf.antiAliasType = AntiAliasType.NORMAL;
			tf.autoSize = TextFieldAutoSize.NONE;
			tf.background = false;
			tf.backgroundColor = 0xFFFFFF;
			tf.border = false;
			tf.borderColor = 0x000000;
			tf.condenseWhite = false;
			tf.displayAsPassword = false;
			tf.embedFonts = false;
			tf.gridFitType = GridFitType.PIXEL;
			tf.maxChars = 0;
			tf.mouseWheelEnabled = true;
			tf.multiline = false;
			tf.restrict = null;
			tf.scrollH = 0;
			tf.scrollV = 0;
			tf.selectable = true;
			tf.sharpness = 0;
			tf.textColor = 0x000000;
			tf.thickness = 0;
			tf.type = TextFieldType.DYNAMIC;
			tf.useRichTextClipboard = false;
			tf.wordWrap = false;
			
			tf.styleSheet = null;
			tf.defaultTextFormat = defaultTextFormat;
		}
		
		/**
		 * This is a shortcut method to the same method in CSSManager
		 * @param tf
		 * @param style_name
		 * 
		 */		
		public static function setTextFormatFromStyle(tf:TextField, style_name:String):void {
			if(!tf || !style_name) return;
			
			tf.styleSheet = null; //can't have a stylesheet at the same time
			tf.defaultTextFormat = CSSManager.instance.getTextFormatFromStyle(style_name);
		}
		
		/**
		 * Takes a passed in TF and outputs a bitmap 
		 * @param tf
		 * @param use_smoothing Pass false if you don't want the bitmap to have smoothing applied
		 * @return Bitmap of the TF
		 * TODO make this a shotcut method if one already exists in the codebase someplace
		 */		
		public static function createBitmap(tf:TextField, use_smoothing:Boolean = true):Bitmap {
			if(!tf) return null;
			
			const data:BitmapData = new BitmapData(tf.width, tf.height, true, 0);
			data.draw(tf);
			const bm:Bitmap = new Bitmap(data, 'auto', use_smoothing);
			
			return bm;
		}
	}
}