package com.tinyspeck.engine.port
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;

	public class ItemstackStatusBar extends Sprite {
		
		private var w:int;
		private var h:int;
		private var bar_bg_color:uint = 0xbbdadf;
		private var bar_fill_color:uint = 0x277d8d;
		private var bar_low_color:uint = 0xdd4a2e;
		private var broken_icon:DisplayObject = new AssetManager.instance.assets.pack_tool_broken();
		
		private var is_low:Boolean;
		
		private var _capacity:int;
		private var _remaining:int;
		private var _is_broken:Boolean;
		
		public function ItemstackStatusBar(w:int, h:int) {
			this.w = w;
			this.h = h;
			init();
		}
		
		private function init():void {
			//set the colors
			bar_bg_color = CSSManager.instance.getUintColorValueFromStyle('itemstack_status_bar', 'bgColor', bar_bg_color);
			bar_fill_color = CSSManager.instance.getUintColorValueFromStyle('itemstack_status_bar', 'fillColor', bar_fill_color);
			bar_low_color = CSSManager.instance.getUintColorValueFromStyle('itemstack_status_bar', 'lowColor', bar_low_color);
			
			broken_icon.x = w - broken_icon.width;
			broken_icon.y = h - broken_icon.height;
			broken_icon.visible = false;
			addChild(broken_icon);
		}
		
		private function draw():void {
			var g:Graphics = graphics;
			g.clear();
			
			if(!_is_broken && capacity > 0){
				//bg
				g.beginFill(bar_bg_color);
				g.drawRoundRect(0, 0, w, h, 4);
				
				//fill
				var fill_amount:Number = Math.min(w * (remaining/capacity), w); //keeps things from going out of wack when charges are changed
				var radius:int = (fill_amount <= w-2) ? 0 : 2;
				g.beginFill((is_low ? bar_low_color : bar_fill_color));
				g.drawRoundRectComplex(0, 0, fill_amount, h, 2,radius,2,radius);
			}
			
			broken_icon.visible = _is_broken;
		}
		
		public function update(capacity:int, remaining:int, is_broken:Boolean):void {			
			_capacity = capacity;
			_remaining = remaining;
			_is_broken = is_broken;
			
			//let's figure out which color to draw the fill bar
			var ratio:Number = remaining/capacity;
			is_low = (ratio <= .1 || remaining == 1) ? true : false;
			
			draw();
		}
		
		public function get capacity():int { return _capacity; }
		public function get remaining():int { return _remaining; }
		public function get is_broken():Boolean { return _is_broken; }
	}
}