package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	
	public class QuoinAnimation extends Sprite
	{
		public var running:Boolean = false;
		public var val_showing:int;
		
		private const circle:Shape = new Shape();
		private const val_tf:TextField = new TextField();
		private const glow:GlowFilter = new GlowFilter();
		
		private const move_by:int = 2;
		private const move_in:Number = .05;
		private const default_end_circle_size:int = 50;
		private var end_circle_size:int = 50;
		private const default_end_text_size:Number = 24;
		private var end_text_size:Number;
		
		private var is_shard:Boolean;
		private var delay:Number;
		private var txt:String;
		private var _circle_perc:Number = 0;
		private var _text_perc:Number = 0;
		private var color_num:uint;
		private var color_str:String;
		
		public function QuoinAnimation() {
			init();
		}
		
		private function init():void {
			addChild(circle);
			
			val_tf.selectable = false;
			val_tf.multiline = false;
			val_tf.wordWrap = false;
			val_tf.embedFonts = true;
			val_tf.antiAliasType = AntiAliasType.ADVANCED;
			val_tf.border = false;
			val_tf.styleSheet = CSSManager.instance.styleSheet;
			addChild(val_tf);
			
			glow.color = 0x666666;
			glow.alpha = 1;
			glow.blurX = 2;
			glow.blurY = 2;
			glow.strength = 9;
			glow.quality = 4;
			val_tf.filters = [glow];
		}
		
		public function end():void {
			TSTweener.removeTweens(this);
			TSTweener.removeTweens(val_tf);
			done();
		}
		
		private function done():void {
			running = false;
			if (parent) parent.removeChild(this);
		}
		
		public function get text_perc():Number {
			return _text_perc;
		}
		
		public function set text_perc(perc:Number):void {
			_text_perc = perc;
			//val_tf.width = 200;
			//val_tf.height = 1000;
			val_tf.htmlText = '<p class="quoin_animation"><font size="'+int(end_text_size*_text_perc)+'" color="'+color_str+'">'+txt+'</font></p>';
			val_tf.width = val_tf.textWidth+4;
			val_tf.height = val_tf.textHeight+4;
			val_tf.x = -(val_tf.width/2)-2; // looks better over a couple pixels
			val_tf.y = -val_tf.height/2;
			val_tf.alpha = 1;
		}
		
		public function get circle_perc():Number {
			return _circle_perc;
		}
		
		public function set circle_perc(perc:Number):void {
			_circle_perc = perc;
			var g:Graphics = circle.graphics;
			g.clear();
			g.beginFill(color_num, .5);
			g.lineStyle(2, color_num);
			g.drawCircle(0, 0, (end_circle_size/2)*_circle_perc);
		}
		
		public function go(delay:Number=0, val:int=0, stat:String='', end_text_size:Number=0, end_circle_size:Number=0, is_shard:Boolean=false):void {
			if (running) return;
			running = true;
			this.delay = delay;
			this.end_text_size = (end_text_size) ? end_text_size : default_end_text_size;
			this.end_circle_size = (end_circle_size) ? end_circle_size : default_end_circle_size;
			this.is_shard = is_shard;
			
			color_num = (is_shard) ? 0xF0F0BD : 0xffffff; //0xf4f4e7
			color_str = ColorUtil.colorNumToStr(color_num, true);
			
			val_showing = val;
			if (stat) stat = ' '+stat;
			if(val>=0){
				if (is_shard) {
					txt = '<span class="quoin_animation_add">'+String(Math.abs(val))+stat+'</span>';
				} else {
					txt = '+<span class="quoin_animation_add">'+String(Math.abs(val))+stat+'</span>';
				}
			}else{
				txt = '-<span class="quoin_animation_subtract">'+String(Math.abs(val))+stat+'</span>';
			}
						
			circle_perc = 0;
			text_perc = 0;
			
			if (val || stat) { // then show the burst and value
				val_tf.visible = true;
				tweenCircle();
				tweenText();
			} else { // no value, just grow and shrink the burst
				val_tf.visible = false;
				tweenGrowAndShrink();
				//tweenCircle();
			}
		}
		
		/////////////////////

		private function tweenCircle():void {
			TSTweener.addTween(this, {circle_perc:1, delay:delay, time:.5, transition:'easeOutBack', onComplete:tweenCircle2});
		}
		
		private function tweenCircle2():void {
			// this is in case we start using tweenCircle instead of tweenGrowAndShrink 
			var completeFunc:Function = (val_tf.visible) ? null : done; 
			
			TSTweener.addTween(this, {circle_perc:0, time:.5, transition:'easeInOutBack', onComplete:completeFunc});
		}
		
		/////////////////////

		private function tweenText():void {
			var this_delay:Number = (is_shard) ? delay : .4+delay;
			TSTweener.addTween(this, {text_perc:1, time:.2, delay:this_delay, transition:'easeOutCubic', onComplete:tweenText2});
		}
		
		private function tweenText2():void {
			if (is_shard) {
				TSTweener.addTween(val_tf, {alpha:0, delay:.5, time:.4, transition:'easeOutCubic', onComplete:done});
			} else {
				TSTweener.addTween(val_tf, {y:val_tf.y-move_by, delay:0, time:move_in, transition:'easeOutCubic', onComplete:tweenText3});
			}
		}
		
		private function tweenText3():void {
			TSTweener.addTween(val_tf, {y:val_tf.y+(move_by*2), delay:0, time:move_in*2, transition:'easeOutCubic', onComplete:tweenText4});
		}
		
		private function tweenText4():void {
			TSTweener.addTween(val_tf, {y:val_tf.y-(move_by*2), delay:0, time:move_in*2, transition:'easeOutCubic', onComplete:tweenText5});
		}
		
		private function tweenText5():void {
			TSTweener.addTween(val_tf, {y:val_tf.y+move_by, delay:0, time:move_in, transition:'easeOutCubic', onComplete:tweenText6});
		}
		
		private function tweenText6():void {
			TSTweener.addTween(val_tf, {y:val_tf.y-40, alpha:0, delay:1.5, time:.4, transition:'easeOutCubic', onComplete:done});
		}
		
		/////////////////////
		
		private function tweenGrowAndShrink():void {
			TSTweener.addTween(this, {circle_perc:1, delay:delay, time:.3, transition:'easeOutBack', onComplete:tweenGrowAndShrink2});
		}
		
		private function tweenGrowAndShrink2():void {
			TSTweener.addTween(this, {circle_perc:0, time:.2, transition:'easeInOutBack', onComplete:done});
		}
		
	}
}