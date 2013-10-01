package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;

	public class EnergyBarTip extends Sprite
	{
		protected static const TF_PADD:int = 5;
		
		protected var tf:TextField = new TextField();
		
		protected var holder:Sprite = new Sprite();
		
		protected var left_drop:DropShadowFilter = new DropShadowFilter();
		
		protected var _value:int;
		protected var _max_value:int;
		
		public function EnergyBarTip(){
			mouseEnabled = mouseChildren = false;
			
			TFUtil.prepTF(tf, false);
			tf.filters = StaticFilters.white1px_GlowA;
			tf.x = TF_PADD;
			holder.addChild(tf);
			
			//setup stuff
			draw();
			
			addChild(holder);
			holder.y = int(-holder.height/2);
			
			//filter
			left_drop.angle = -180;
			left_drop.distance = 1;
			left_drop.blurX = 2;
			left_drop.blurY = 0;
			left_drop.alpha = .1;
			holder.filters = [left_drop];
		}
		
		protected function draw():void {
			tf.htmlText = '<p class="energy_bar_tip"><span class="energy_bar_tip_current">'+_value+'</span>/'+_max_value+'</p>';
			
			const draw_w:int = int(tf.width + 3);
			const draw_h:int = int(tf.height);
			const g:Graphics = holder.graphics;
			g.clear();
			g.beginFill(0xffffff, .9);
			g.moveTo(0, draw_h/2-1);
			g.lineTo(TF_PADD, 0);
			g.lineTo(TF_PADD, draw_h);
			g.lineTo(0, draw_h/2-1);
			g.drawRoundRectComplex(TF_PADD, 0, draw_w, draw_h, 0, 4, 0, 4);
		}
		
		public function set value(new_value:int):void {
			_value = new_value;
			draw();
		}
		
		public function set max_value(new_value:int):void {
			_max_value = new_value;
			draw();
		}
	}
}