package com.tinyspeck.engine.port {
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	
	public class WindowBorder extends Sprite {
		
		public static var POINTER_BOTTOM_CENTER:String = 'POINTER_BOTTOM_CENTER';
		public static var POINTER_TOP_CENTER:String = 'POINTER_TOP_CENTER';
		public static var POINTER_TOP_LEFT:String = 'TOP_LEFT';
		public static var POINTER_LEFT_TOP:String = 'LEFT_TOP';
		public static var POINTER_NONE:String = 'NONE';
		
		protected var _border_sp:Sprite = new Sprite();
		protected var _fill_sh:Shape = new Shape();
		
		protected var bg_alpha:Number;
		protected var _bg_c:uint = 0xffffff;
		
		protected var no_border:Boolean = false;
		
		protected var _border_w:int;
		protected var _w:int;
		protected var _h:int;
		
		protected var _pointer:String;
		
		private var _corner_rad:int = 10;
		
		public function WindowBorder(w:int, h:int, border_w:int = 2, bg_alpha:Number = 1, pointer:String = '', no_border:Boolean = false, bg_c:Number = 0xffffff) {
			super();
			_w = w;
			_h = h;
			_border_w = border_w;
			this.bg_alpha = bg_alpha;
			_pointer = pointer || WindowBorder.POINTER_NONE;
			this.no_border = no_border;
			this.bg_c = bg_c;
			init();
		}
		
		private function init():void {
			addChild(_fill_sh);
			addChild(_border_sp);
			if (!no_border) _border_sp.filters = StaticFilters.windowBorder_GlowA;
			_draw();
		}
		
		public function setSize(w:int, h:int, pointer:String = ''):void {
			_w = w;
			_h = h;
			_pointer = pointer || WindowBorder.POINTER_NONE;
			_draw();
		}
		
		public function get w():int {
			return _w;
		}
		
		public function get h():int {
			return _h;
		}
		
		private function _fill(g:Graphics, a:Number):void {
			g.clear();
			//g.lineStyle(0, 0x000000, 0);
			g.beginFill(bg_c, a);
			g.drawRoundRect(_border_w, _border_w, _w-(_border_w*2), _h-(_border_w*2), _corner_rad);
			g.endFill();
			if (_pointer == WindowBorder.POINTER_LEFT_TOP) {
				g.beginFill(bg_c, a);
				g.moveTo(_border_w, 12);
				g.lineTo(_border_w-10, 4);
				g.lineTo(_border_w, 22);
				g.endFill();
			} else if (_pointer == WindowBorder.POINTER_TOP_LEFT) {
				g.beginFill(bg_c, a);
				g.moveTo(25, _border_w);
				g.lineTo(41, _border_w-10);
				g.lineTo(35, _border_w);
				g.endFill();
			} else if (_pointer == WindowBorder.POINTER_TOP_CENTER) {
				g.beginFill(bg_c, a);
				g.moveTo(Math.round(w/2)-8, _border_w);
				g.lineTo(Math.round(w/2), _border_w-10);
				g.lineTo(Math.round(w/2)+8, _border_w);
				g.endFill();
			} else if (_pointer == WindowBorder.POINTER_BOTTOM_CENTER) {
				g.beginFill(bg_c, a);
				g.moveTo(Math.round(w/2)+8, h-_border_w);
				g.lineTo(Math.round(w/2), h-_border_w+10);
				g.lineTo(Math.round(w/2)+18, h-_border_w);
				g.endFill();
			}
		}
		
		override public function get graphics():Graphics {
			return _fill_sh.graphics;
		}
		
		private function _draw():void {
			_fill(_fill_sh.graphics, bg_alpha); // known issue: if there is a border, the below _fill makes passing bg_alpha not matter, cause it gets overdrawn with alpha 1
			if (!no_border) _fill(_border_sp.graphics, 1);
		}
		
		public function get corner_rad():int { return _corner_rad; }
		public function set corner_rad(value:int):void {
			_corner_rad = value;
			_draw();
		}
		
		public function get bg_c():uint { return _bg_c; }
		public function set bg_c(value:uint):void {
			_bg_c = value;
			_draw();
		}
		
		public function setBorderColor(new_color:uint, new_alpha:Number = 1):void {
			
			//change the filter
			var glow:GlowFilter = new GlowFilter();
			glow.color = new_color;
			glow.alpha = .37;
			glow.blurX = 2;
			glow.blurY = 2;
			glow.strength = 10;
			glow.quality = 4;
			glow.knockout = true;
			
			if (!no_border){
				_border_sp.filters = [glow];
				_border_sp.alpha = new_alpha;
			} 
		}		
	}
}