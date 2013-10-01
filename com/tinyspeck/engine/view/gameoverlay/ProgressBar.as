package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.DrawUtil;
	
	import flash.display.BlendMode;
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	
	public class ProgressBar extends DisposableSprite {
		public static const DIRECTION_LEFT_TO_RIGHT:String = 'left_to_right';
		public static const DIRECTION_RIGHT_TO_LEFT:String = 'right_to_left';
		
		private const BAR_COLORS:Array = [];
		
		private var BORDER_COLOR:uint = 0xd6d6d6;
		private var BORDER_WIDTH:uint = 2;
		private var FRAME_TOP_COLOR:Number = 0x656b6b;
		private var FRAME_TOP_ALPHA:Number = 1;
		private var FRAME_COLOR:Number = 0x9ca3a3;
		private var FRAME_ALPHA:Number = 1;
		private var BAR_COLOR_TIP_TOP:Number = 0x9db52e;
		private var BAR_COLOR_TIP_BOTTOM:Number = 0x879f08;
		private var BAR_COLOR_TOP:Number = 0xafca2f;
		private var BAR_COLOR_BOTTOM:Number = 0x95b101;
		private var BAR_CHANGE_COLOR_TOP:Number = -1;
		private var BAR_CHANGE_COLOR_BOTTOM:Number = -1;
		private var CORNER_SIZE:uint = 6;
		private var TIP_WIDTH:uint = 2;
		private var frame:Sprite = new Sprite();
		private var bar_holder:Sprite = new Sprite();
		private var bar:Sprite = new Sprite();
		private var bar_tip:Sprite = new Sprite();
		private var bar_change:Sprite = new Sprite();
		private var bar_mask:Sprite = new Sprite();
		private var perc:Number = 0;
		private var change_alpha:Number = .5;
		private var _w:int = 100;
		private var _h:int = 10;
		private var _draw_border:Boolean;
		private var _dim_speed:Number = 1.5;
		private var _change_speed:Number = 3;
		private var _change_delay:Number = .4;
		private var _direction:String;
		
		public function ProgressBar(w:int = 100, h:int = 10, p:Number = 0, direction:String = ProgressBar.DIRECTION_LEFT_TO_RIGHT) {
			_w = w;
			_h = h;
			_direction = direction;
			perc = p;
			blendMode = BlendMode.LAYER;
			init();
		}
		
		private function init():void {
			addChild(frame);
			addChild(bar_holder);
			addChild(bar_mask);
			
			bar_holder.addChild(bar_change);
			bar_holder.addChild(bar);
			bar_holder.addChild(bar_tip);
			bar_holder.mask = bar_mask;
			
			bar_change.alpha = 0;
			
			drawFrame();
			drawBar();
		}
		
		public function stopTweening():void {
			TSTweener.removeTweens(bar_holder);
		}
		
		public function startTweening():void {
			tweenDim();
		}
		
		private function tweenBright():void {
			TSTweener.addTween(bar_holder, {_brightness:0, time:_dim_speed, transition: 'linear', onComplete:tweenDim});
		}
		
		private function tweenDim():void {
			TSTweener.addTween(bar_holder, {_brightness:-.2, time:_dim_speed, transition: 'linear', onComplete:tweenBright});
		}
		
		private function drawFrame():void {
			var g:Graphics = frame.graphics;
			g.clear();
			g.lineStyle(0, 0, 0, true);
			g.beginFill(FRAME_TOP_COLOR, Math.min(FRAME_TOP_ALPHA + FRAME_ALPHA, 1)); //we add the alphas together since this isn't a dropshadow
			g.drawRoundRect(0, 0, _w, _h, CORNER_SIZE);
			g.drawRoundRect(0, 2, _w, _h-2, CORNER_SIZE); //draws the cutout
			
			g.beginFill(FRAME_COLOR, FRAME_ALPHA);
			g.drawRoundRect(0, 2, _w, _h-2, CORNER_SIZE);
			
			g = graphics;
			g.clear();
			if(_draw_border) {
				g.beginFill(FRAME_COLOR);
				g.lineStyle(BORDER_WIDTH*2, BORDER_COLOR, 1, true, LineScaleMode.NONE , CapsStyle.ROUND);
				g.drawRoundRect(0, 0, _w, _h, CORNER_SIZE-1);
			}
		}
		
		public function get displayed_perc():Number {
			// we do a min here, because the bar never actually shows 0 because we always display a little. so if perc is lower, use that
			return (bar) ? Math.min(perc, bar.width/_w) : 0;
		}
		
		private function drawBar():void {
			var bar_w:int = _w*perc;
			if (bar_w < 5) {
				bar_w = 5;
			}
			
			// reset this shit!
			bar.scaleX = bar.scaleY = bar_change.scaleX = bar_change.scaleY = 1;
			
			var g:Graphics = bar.graphics;
			g.clear();
			BAR_COLORS[0] = BAR_COLOR_TOP;
			BAR_COLORS[1] = BAR_COLOR_BOTTOM;
			DrawUtil.drawVerticalGradientBG(g, bar_w - (BAR_COLOR_TOP != BAR_COLOR_TIP_TOP ? 0 : TIP_WIDTH), _h, 0, BAR_COLORS);
			
			g = bar_change.graphics;
			g.clear();
			BAR_COLORS[0] = BAR_CHANGE_COLOR_TOP == -1 ? BAR_COLOR_TOP : BAR_CHANGE_COLOR_TOP;
			BAR_COLORS[1] = BAR_CHANGE_COLOR_BOTTOM == -1 ? BAR_COLOR_BOTTOM : BAR_CHANGE_COLOR_BOTTOM;
			DrawUtil.drawVerticalGradientBG(g, bar_w, _h, 0, BAR_COLORS);
			
			g = bar_tip.graphics;
			g.clear();
			BAR_COLORS[0] = BAR_COLOR_TIP_TOP;
			BAR_COLORS[1] = BAR_COLOR_TIP_BOTTOM;
			DrawUtil.drawVerticalGradientBG(g, TIP_WIDTH, _h, 0, BAR_COLORS);
			bar_tip.x = direction == DIRECTION_LEFT_TO_RIGHT ? bar.width : bar.x - bar_tip.width;
			
			g = bar_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, _w, _h, CORNER_SIZE);
			
			// always have to do this when we drawBar, because we must reset scale as above, and that wipes out the proper display of perc
			update(perc);
		}
		
		public function update(p:Number = -1, animate_change:Boolean = false):void {
			if (p>=0 && p<=1) {
				var bar_w:int = _w*p - (BAR_COLOR_TOP != BAR_COLOR_TIP_TOP ? 0 : TIP_WIDTH);
				if (bar_w < 5 - TIP_WIDTH) {
					bar_w = 5 - TIP_WIDTH;
				}
				
				if(p > 0) {
					bar.alpha = bar_tip.alpha = 1;
				}
				else {
					bar.alpha = bar_tip.alpha = 0;
				}
				
				if(animate_change){
					//show the change as an alpha amount and animate the proper bar to that amount
					bar_change.alpha = change_alpha;
					
					if(p < perc){
						//solid bar lower, animate alpha bar
						bar_change.width = bar.width;
						TSTweener.addTween(bar_change, {x:direction == DIRECTION_LEFT_TO_RIGHT ? 0 : _w - bar_w, width:bar_w, time:change_speed, delay:_change_delay, transition:'linear',
							onComplete:function():void {
								bar_change.alpha = 0;
							}
						});
						
						bar.width = bar_w;
						bar.x = direction == DIRECTION_LEFT_TO_RIGHT ? 0 : _w - bar_w;
						bar_tip.x = direction == DIRECTION_LEFT_TO_RIGHT ? bar.width : bar.x - bar_tip.width;
					}
					else {
						//alpha bar higher, animate solid
						bar_change.width = bar_w + TIP_WIDTH;
						bar_change.x = direction == DIRECTION_LEFT_TO_RIGHT ? 0 : _w - bar_w;
						updateWithAnimation(change_speed, p, _change_delay);
					}
				}
				else {
					bar.width = bar_w;
					bar.x = direction == DIRECTION_LEFT_TO_RIGHT ? 0 : _w - bar_w;
					bar_tip.x = direction == DIRECTION_LEFT_TO_RIGHT ? bar.width : bar.x - bar_tip.width;
				}
				
				perc = p;
			}
		}
		
		public function updateWithAnimation(secs_to_complete:Number, p:Number, delay:Number = 0):void {			
			if (p>=0 && p<=1) {
				var progress:ProgressBar = this;
				var bar_w:int = _w*p - (BAR_COLOR_TOP != BAR_COLOR_TIP_TOP ? 0 : TIP_WIDTH);
				bar.alpha = bar_tip.alpha = 1;
				
				TSTweener.removeTweens(bar);
				TSTweener.addTween(bar, {x:direction == DIRECTION_LEFT_TO_RIGHT ? 0 : _w - bar_w, width:bar_w, time:secs_to_complete, delay:delay, transition:'linear',
					onUpdate:function():void {
						//move the tip
						bar_tip.x = direction == DIRECTION_LEFT_TO_RIGHT ? bar.width : bar.x - bar_tip.width;
					},
					onComplete:function():void {
						bar_change.alpha = 0;
						if(p == 0) bar.alpha = bar_tip.alpha = 0;
						dispatchEvent(new TSEvent(TSEvent.COMPLETE, progress));
					}
				});
				
				perc = p;
			}
		}
		
		/**
		 * This will force the change bar below the main bar to show up 
		 * @param p
		 */		
		public function updateChangeBar(p:Number = -1):void {
			if (p>=0 && p<=1) {
				var bar_w:int = _w*perc - (BAR_COLOR_TOP != BAR_COLOR_TIP_TOP ? 0 : TIP_WIDTH);
				if (bar_w < 5 - TIP_WIDTH) {
					bar_w = 5 - TIP_WIDTH;
				}
				
				var change_bar_w:int = _w*p - (BAR_COLOR_TOP != BAR_COLOR_TIP_TOP ? 0 : TIP_WIDTH);
				if (change_bar_w < 5) {
					change_bar_w = 5;
				}
				
				if(p > perc) {
					//show a little bit past the bar w
					change_bar_w = Math.max(change_bar_w, bar_w + TIP_WIDTH + 1);
					bar_change.alpha = change_alpha;
				}
				else {
					bar_change.alpha = 0;
				}
				
				bar_change.width = change_bar_w;
			}
		}
		
		public function setBarColors(bar_top:uint, bar_bottom:uint, tip_top:uint, tip_bottom:uint):void {
			BAR_COLOR_TOP = bar_top;
			BAR_COLOR_BOTTOM = bar_bottom;
			BAR_COLOR_TIP_TOP = tip_top;
			BAR_COLOR_TIP_BOTTOM = tip_bottom;
			
			drawBar();
		}
		
		public function setChangeBarColors(bar_top:uint, bar_bottom:uint, bar_alpha:Number = .5):void {
			BAR_CHANGE_COLOR_TOP = bar_top;
			BAR_CHANGE_COLOR_BOTTOM = bar_bottom;
			change_alpha = bar_alpha;
			
			drawBar();
		}
		
		public function setFrameColors(bg:uint, shadow:uint, bg_alpha:Number = 1, shadow_alpha:Number = 1):void {
			FRAME_COLOR = bg
			FRAME_TOP_COLOR = shadow;
			FRAME_ALPHA = bg_alpha;
			FRAME_TOP_ALPHA = shadow_alpha;
			
			drawFrame();
		}
		
		public function setBorderColor(color:uint, w:uint):void {
			BORDER_COLOR = color;
			BORDER_WIDTH = w;
			draw_border = true;
		}
		
		public function get corner_size():uint { return CORNER_SIZE; }
		public function set corner_size(value:uint):void {
			CORNER_SIZE = value;
			drawFrame();
			drawBar();
		}
		
		public function get draw_border():Boolean { return _draw_border; }
		public function set draw_border(value:Boolean):void {
			_draw_border = value;
			drawFrame();
		}
		
		public function set dim_speed(value:Number):void { _dim_speed = value; }
		
		public function get w():Number { return frame.width + BORDER_WIDTH*2; }
		public function set w(value:Number):void { width = value; }
		
		override public function set width(value:Number):void {
			_w = value;
			drawFrame();
			drawBar();
		}
		
		public function get h():Number { return frame.height + BORDER_WIDTH*2; }
		public function set h(value:Number):void { height = value; }
		
		override public function set height(value:Number):void {
			_h = value;
			drawFrame();
			drawBar();
		}
		
		public function get change_speed():Number { return _change_speed; }
		public function set change_speed(value:Number):void {
			_change_speed = value;
		}
		
		public function get change_delay():Number { return _change_delay; }
		public function set change_delay(value:Number):void {
			_change_delay = value;
		}
		
		public function get border_width():int { return BORDER_WIDTH; }
		
		public function get current_perc():Number { return perc; }
		
		public function get bar_x():Number { return bar.x; }
		public function get bar_w():Number { return bar.width; }
		
		public function get direction():String { return _direction; }
		public function set direction(value:String):void {
			_direction = value;
			drawBar();
		}
	}
}