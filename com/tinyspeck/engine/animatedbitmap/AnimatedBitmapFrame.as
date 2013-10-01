package com.tinyspeck.engine.animatedbitmap {
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	/**
	 * Represents a frame region within a sprite sheet
	 */
	public class AnimatedBitmapFrame {
		
		private const _scrollRect:Rectangle = new Rectangle();
		
		private var _name:String;
		private var _bitmapData:BitmapData;
		private var _label:String;
		private var _displayListX:Number;	// x coordinate of frame (much like getBounds() rectangle's x)
		private var _displayListY:Number;	// y coordinate of frame (much like getBounds() rectangle's y)
		private var _width:Number;
		private var _height:Number;
		private var _sheetCoordX:Number;
		private var _sheetCoordY:Number;
		
		private var _parentIndex:int = -1;
		
		public function AnimatedBitmapFrame(name:String, bitmapData:BitmapData, label:String, displayListX:Number, displayListY:Number, 
											sheetCoordX:Number, sheetCoordY:Number) {
			_name = name;
			_bitmapData = bitmapData;
			_label = label;
			_displayListX = displayListX;
			_displayListY = displayListY;
			_sheetCoordX = sheetCoordX;
			_sheetCoordY = sheetCoordY;
			
			_width = _bitmapData.width;
			_height = _bitmapData.height;
			
			_scrollRect.x = _sheetCoordX; _scrollRect.y = _sheetCoordY;
			_scrollRect.width = _width; _scrollRect.height = _height;
		}
		
		public function get scrollRect():Rectangle { return _scrollRect; }
		
		public function get name():String { return _name; }
		public function get label():String { return _label; }
		
		public function get bitmapData():BitmapData { return _bitmapData; }
		public function set bitmapData(value:BitmapData):void { _bitmapData = value; }
		
		public function get displayListX():Number { return _displayListX; }
		public function set displayListX(value:Number):void { _displayListX = value; }
		
		public function get displayListY():Number { return _displayListY; }
		public function set displayListY(value:Number):void { _displayListY = value; }
		
		public function get sheetCoordX():Number { return _sheetCoordX; }
		public function set sheetCoordX(value:Number):void { 
			_sheetCoordX = value;
			_scrollRect.x = value;
		}
		
		public function get sheetCoordY():Number { return _sheetCoordY; }
		public function set sheetCoordY(value:Number):void { 
			_sheetCoordY = value;
			_scrollRect.y = value;
		}
		
		public function get width():Number { return _width; }
		public function set width(value:Number):void { 
			_width = value;
			_scrollRect.width = width;
		}
		
		public function get height():Number { return _height; }
		public function set height(value:Number):void { 
			_height = value;
			_scrollRect.height = _height;
		}
		
		public function get parentIndex():int { return _parentIndex; }
		public function set parentIndex(value:int):void { _parentIndex = value; }
		
		public function toString():String {
			return "AnimatedBitmapFrame { parentIndex: " + _parentIndex + ", sheetCoordX: " + _sheetCoordX + ", sheetCoordY: " + _sheetCoordY +
				", width: " + _width + ", height: " + _height + ", displayListX: " +
				_displayListX + ", displayListY: " + _displayListY + " scrollRect: " + _scrollRect;
		}
	}
}