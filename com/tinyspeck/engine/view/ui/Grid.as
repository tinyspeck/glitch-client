package com.tinyspeck.engine.view.ui
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;

	public class Grid extends Sprite
	{
		private var HDASH:BitmapData;
		private var VDASH:BitmapData;
		
		private var _w:int;
		private var _h:int;
		private var _rows:int;
		private var _cols:int;
		private var _thickness:int;
		private var _color:uint;
		
		public function Grid(w:int, h:int, rows:int, cols:int, color_ARGB:uint = 0x88000000, thickness:int = 1){
			_w = w;
			_h = h;
			_rows = rows;
			_cols = cols;
			_thickness = thickness;
			_color = color_ARGB;
			
			mouseEnabled = false;
			
			init();
			draw();
		}
		
		private function init():void {
			var i:int;
			HDASH = new BitmapData(6, _thickness, true, 0);
			for(i = 0; i < _thickness; i++){
				HDASH.setPixel32(0, i, _color);
				HDASH.setPixel32(1, i, _color);
				HDASH.setPixel32(2, i, _color);
			}
			
			VDASH = new BitmapData(_thickness, 6, true, 0);
			for(i = 0; i < _thickness; i++){
				VDASH.setPixel32(i, 0, _color);
				VDASH.setPixel32(i, 1, _color);
				VDASH.setPixel32(i, 2, _color);
			}
		}
		
		private function draw():void {
			var h_offset:int = (_w-(_cols*_thickness))/_cols;
			var v_offset:int = (_h-(_rows*_thickness))/_rows;
			var next_x:int = h_offset;
			var next_y:int = v_offset;
			
			var i:int;
			var g:Graphics = graphics;
			g.clear();
						
			//draw the rows
			g.beginBitmapFill(HDASH);
			for(i = 1; i < _rows; i++){
				g.drawRect(0, next_y, _w, _thickness);
				next_y += v_offset + _thickness;
			}
			g.endFill();
			
			//draw the cols
			g.beginBitmapFill(VDASH);
			for(i = 1; i < _cols; i++){
				g.drawRect(next_x, 0, _thickness, _h);
				next_x += h_offset + _thickness;
			}
			g.endFill();
		}
		
		//couple of shortcut methods
		public function setRowsAndCols(rows:int, cols:int):void {
			_rows = rows;
			_cols = cols;
			draw();
		}
		
		public function setWidthAndHeight(w:int, h:int):void {
			_w = w;
			_h = h;
			draw();
		}
		
		public function get rows():int { return _rows; }
		public function set rows(value:int):void { 
			_rows = value;
			draw();
		}
		
		public function get cols():int { return _cols; }
		public function set cols(value:int):void { 
			_cols = value;
			draw();
		}
		
		public function get thickness():int { return _thickness; }
		public function set thickness(value:int):void { 
			_thickness = value;
			init();
			draw();
		}
		
		public function get color():uint { return _color; }
		public function set color(value:uint):void { 
			_color = value;
			init();
			draw();
		}
	}
}