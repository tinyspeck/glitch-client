package com.tinyspeck.engine.port {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class StatBurst extends Sprite {
		
		public static const XP:String = 'xp';
		public static const MOOD:String = 'mood';
		public static const ENERGY:String = 'energy';
		public static const CURRANTS:String = 'currants';
		
		private var circle:Shape = new Shape();
		private var val_tf:TextField = new TextField();
		private var _circle_perc:Number = 0;
		private var _text_perc:Number = 0;
		private var end_circle_size:int = 50;
		private var end_text_size:Number = 18;
		private var text_w:Number;
		private var txt:String;
		private var _type:String;
		public var running:Boolean = false;
		public var val_showing:int;
		
		private var layoutModel:LayoutModel;
		
		public function StatBurst(type:String = null) {
			super();
			layoutModel = TSModelLocator.instance.layoutModel;
			
			if(type) _type = type;
			
			init();
		}
		
		private function init():void {
			addChild(circle);
			
			TFUtil.prepTF(val_tf, false);
			val_tf.filters = StaticFilters.statBurstGlowA;
			addChild(val_tf);
		}
		
		public function end():void {
			TSTweener.removeTweens(this);
			TSTweener.removeTweens(val_tf);
			done();
		}
		
		private function done():void {
			running = false;
			if (this.parent) this.parent.removeChild(this);
		}
		
		public function get text_perc():Number {
			return _text_perc;
		}
		
		public function set text_perc(perc:Number):void {
			_text_perc = perc;
			val_tf.htmlText = '<p class="stat_burst_value"><font size="'+int(end_text_size*_text_perc)+'">'+txt+'</font></p>';
			val_tf.width = val_tf.textWidth+4;
			val_tf.height = val_tf.textHeight+4;
			val_tf.x = -(val_tf.width/2)-2; // looks better over a couple pixels
			val_tf.y = -val_tf.height/2;
			val_tf.alpha = 1;
			val_tf.visible = (_text_perc != 0);
			//circle.x = val_tf.width/2;
		}
		
		public function get circle_perc():Number {
			return _circle_perc;
		}
		
		public function get type():String { return _type; }
		public function set type(value:String):void { _type = value; }
		
		public function set circle_perc(perc:Number):void {
			_circle_perc = perc;
			var g:Graphics = circle.graphics;
			g.clear();
			g.beginFill(0xffffff, .8);
			g.lineStyle(2, 0xffffff);
			g.drawCircle(0, 0, (end_circle_size/2)*_circle_perc);
		}
		
		public function go(val:int):void {
			if (!val) return;
			if (running) end();
			
			//place in main view so that a) it doesn't go over the full screen overlays and b) when the browser changes size it doesn't move
			TSFrontController.instance.getMainView().addView(this);
			
			running = true;
			val_showing = val;
			const abs_val:Number = Math.abs(val);
			if(type == XP){
				//special case for imagination, always the same color
				txt = '<span class="stat_burst_value_add"><span class="stat_burst_value_imagination">'+(val > 0 ? '+' : '-')+abs_val+'</span></span>';
			}
			else if (val > 0) {
				txt = '<span class="stat_burst_value_add">+'+abs_val+'</span>';
			} 
			else {
				txt = '<span class="stat_burst_value_subtract">-'+abs_val+'</span>';
			}
			
			//measure the size
			text_perc = 1;
			text_w = val_tf.width;
			
			const final_y_delta:int = val > 0 ? -40 : 40;
			const self:StatBurst = this;
			circle_perc = 0;
			text_perc = 0;
			
			TSTweener.addTween(self, {circle_perc:1, time:.3, transition:'easeOutBack'});
			TSTweener.addTween(self, {circle_perc:0, time:.3, delay:.3, transition:'easeInOutBack'});
			
			const move_by:int = 2;
			const move_in:Number = .05;
			const trans:String = 'easeOutCubic';
			TSTweener.addTween(self, {text_perc:1, time:.2, delay:.2, transition:trans, onComplete:function():void {
				TSTweener.addTween(val_tf, {y:val_tf.y-move_by, delay:0, time:move_in, transition:trans, onComplete:function():void {
					TSTweener.addTween(val_tf, {y:val_tf.y+(move_by*2), delay:0, time:move_in*2, transition:trans, onComplete:function():void {
						TSTweener.addTween(val_tf, {y:val_tf.y-(move_by*2), delay:0, time:move_in*2, transition:trans, onComplete:function():void {
							TSTweener.addTween(val_tf, {y:val_tf.y+move_by, delay:0, time:move_in, transition:trans, onComplete:function():void {
								TSTweener.addTween(val_tf, {y:val_tf.y+final_y_delta, alpha:0, delay:1.5, time:.4, transition:trans, onComplete:function():void{
									self.done();
								}});
							}});
						}});
					}});
				}});
			}});
			
			//push this to the right because we don't do centered bursts anymore
			x += text_w/2;
		}
	}
}