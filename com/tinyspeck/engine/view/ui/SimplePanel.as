package com.tinyspeck.engine.view.ui {
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	public class SimplePanel extends Sprite {
		private var window_border:WindowBorder;
		private var tf:TextField = new TextField();
		private var content_sp:Sprite = new Sprite();
		private var _padd_w:int = 5;
		private var _padd_h:int = 5;
		private var bg_alpha:Number = 1;
		private var _max_w:int = 600;
		private var _outer_border_w:int = 0;
		private var outer_border_c:int = 0;
		private var outer_border_a:Number = .15;
		
		private var _min_w:int;
		private var _min_h:int;
		private var _pointer:String;
		private var _centered:Boolean;
		private var no_border:Boolean;
		
		public function set outer_border_w(value:int):void {
			_outer_border_w = value;
			doOuterBorder();
		}
		
		public function set padd_h(value:int):void {
			_padd_h = value;
		}
		
		public function set padd_w(value:int):void {
			_padd_w = value;
		}
		
		public function set max_w(value:int):void {
			_max_w = value;
		}

		public function SimplePanel(no_border:Boolean = false):void {
			super();
			this.no_border = no_border;
			_construct();
		}
		
		protected function _construct():void {
			window_border = new WindowBorder(0, 0, 2, bg_alpha, '', no_border);
			addChild(window_border);
			
			TFUtil.prepTF(tf);
			tf.embedFonts = false;
			
			addChild(content_sp);
		}
		
		public function doOuterBorder():void {
			var g:Graphics = graphics;
			g.clear();
			//put a semi-trans border on it
			if(_outer_border_w > 0){
				g.beginFill(outer_border_c, outer_border_a);
				g.drawRoundRect(-_outer_border_w, -_outer_border_w, window_border.w+_outer_border_w*2, window_border.h+_outer_border_w*2, 16);
				g.endFill();
			}
		}
		
		private function beforeFill(pointer:String='', min_w:int=0, min_h:int=0, centered:Boolean = true):void {
			while (content_sp.numChildren) content_sp.removeChildAt(0);
			// make sure we have enough room for pointers
			_pointer = pointer;
			_min_w = min_w || 60;
			_min_h = min_h;
			_centered = centered;
			
			content_sp.x = _padd_w;
			content_sp.y = _padd_h;
		}
		
		private function afterFill():void {
			window_border.setSize(content_sp.width+(_padd_w*2), content_sp.height+(_padd_h*2), _pointer);
			
			if (_min_w && _min_w > window_border.w) {
				window_border.setSize(_min_w, window_border.h, _pointer);
				if (_centered) content_sp.x = Math.round((window_border.w-content_sp.width)/2);
			}
			if (_min_h && _min_h > window_border.h) {
				window_border.setSize(window_border.w, _min_h, _pointer);
				content_sp.y = Math.round((window_border.h-content_sp.height)/2);
			}
			
			doOuterBorder();
		}
		
		public function fillDO(DO:DisplayObject, pointer:String='', min_w:int=0, min_h:int=0, centered:Boolean = true):void {
			beforeFill(pointer, min_w, min_h, centered);
			content_sp.addChild(DO);
			
			var rect:Rectangle = DO.getBounds(content_sp);
			DO.x = -rect.x;
			DO.y = -rect.y;
			
			afterFill();
		}
		
		public function fillText(txt:String, pointer:String='', min_w:int=0, min_h:int=0, centered:Boolean = true):void {
			beforeFill(pointer, min_w, min_h, centered);
			content_sp.addChild(tf);
			
			tf.width = _max_w; // max width			
			tf.htmlText = '<p class="simple_panel">'+txt+'</p>';
			
			tf.width = tf.textWidth+6;
			tf.height = tf.textHeight+4;
			
			afterFill();
		}
	}
}