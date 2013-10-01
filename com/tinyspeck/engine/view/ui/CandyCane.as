package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;

	public class CandyCane extends Sprite
	{
		protected var holder:Sprite = new Sprite();
		protected var masker:Shape = new Shape();
		
		protected var bmd:BitmapData;
		
		protected var _w:uint;
		protected var _h:uint;
		protected var _stripe_w:uint;
		protected var _draw_alpha:Number;
		protected var _ani_speed:Number;
		protected var _bg_color:int;
		protected var _color:uint;
		protected var _extra_padding:uint;
		
		public function CandyCane(w:uint, h:uint, stripe_w:uint, alpha:Number = .1, ani_speed:Number = .4, color:uint = 0xffffff, bg_color:int = -1, extra_padding:int = 0){
			_w = w;
			_h = h;
			_stripe_w = stripe_w;
			_draw_alpha = alpha;
			_ani_speed = ani_speed;
			_color = color;
			_bg_color = bg_color;
			
			//set the mask
			mask = masker;
			addChild(holder);
			addChild(masker);
			
			//draw it up
			draw();
		}
		
		public function animate(is_animating:Boolean, force_start:Boolean = false):void {
			if((is_animating && !TSTweener.isTweening(holder)) || force_start){
				//start it up
				keepThatCandyGoing();
			}
			else if(!is_animating){
				//shut'r down
				TSTweener.removeTweens(holder);
			}
		}
		
		protected function draw():void {
			var g:Graphics = masker.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, _w, _h);
			
			if(bmd) bmd.dispose();
			bmd = DrawUtil.drawCandyCanePattern(_h, _stripe_w, _draw_alpha, _color, _extra_padding);
			
			g = holder.graphics;
			g.clear();
			g.beginBitmapFill(bmd);
			g.drawRect(0, 0, _w + bmd.width, _h);
			
			if(_bg_color != -1){
				g = graphics;
				g.clear();
				g.beginFill(_bg_color);
				g.drawRect(0, 0, _w, _h);
			}
		}
		
		protected function keepThatCandyGoing():void {
			holder.x = 0;
			TSTweener.addTween(holder, {x:-bmd.width, time:_ani_speed, transition:'linear', onComplete:keepThatCandyGoing});
		}
		
		/*******************************
		 *     Getters / Setters       *
		 ******************************/
		override public function get height():Number { return _h; }
		override public function set height(value:Number):void {
			_h = value;
			draw();
		}
		
		override public function get width():Number { return _w; }
		override public function set width(value:Number):void {
			_w = value;
			draw();
		}
		
		public function get stripe_w():uint { return _stripe_w; }
		public function set stripe_w(value:uint):void {
			_stripe_w = value;
			draw();
		}
		
		public function get draw_alpha():Number { return _draw_alpha; }
		public function set draw_alpha(value:Number):void {
			_draw_alpha = value;
			draw();
		}
		
		public function get ani_speed():Number { return _ani_speed; }
		public function set ani_speed(value:Number):void {
			_ani_speed = value;
		}
		
		public function get color():uint { return _color; }
		public function set color(value:uint):void {
			_color = value;
			draw();
		}
		
		public function get bg_color():int { return _bg_color; }
		public function set bg_color(value:int):void {
			_bg_color = value;
			draw();
		}
		
		public function get extra_padding():int { return _extra_padding; }
		public function set extra_padding(value:int):void {
			_extra_padding = value;
			draw();
		}
	}
}