package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.DrawUtil;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class EnergyBar extends Sprite
	{
		private static const WIDTH:uint = 77;
		private static const HEIGHT:uint = 64;
		private static const THICKNESS:uint = 13;
		private static const LEFT_CURVE_W:uint = 15;
		private static const MIN_ANGLE:Number = 102.5;
		private static const MAX_ANGLE:Number = -1.5;
		private static const ANIMATION_TIME:Number = 2;
		private static const TIP_OFFSET:Number = 4.1;
		
		protected var bg:Sprite = new Sprite();
		protected var shine:Sprite = new Sprite();
		protected var juice:Sprite = new Sprite();
		protected var juice_mask:Sprite = new Sprite();
		protected var spinner:Sprite = new Sprite();
		
		protected var tip:EnergyBarTip = new EnergyBarTip();
		
		protected var bar_colors:Array = [];
		
		protected var is_built:Boolean;
		protected var is_animating:Boolean;
		
		protected var _value:Number;
		protected var _max_value:Number;
		protected var _current_bar_color:Number;
		
		public function EnergyBar(){}
		
		protected function buildBase():void {
			//bg
			drawCurve(bg, 0xbfced3);
			addChild(bg);
			
			//juice
			drawCurve(juice_mask, 0);
			addChild(juice_mask);
			juice.mask = juice_mask;
			spinner.x = LEFT_CURVE_W;
			spinner.addChild(juice);
			spinner.mouseEnabled = spinner.mouseChildren = false;
			addChild(spinner);
			
			//shine
			drawShine();
			shine.x = shine.y = 2;
			shine.mouseEnabled = false;
			addChild(shine);
			
			//mouse stuff
			bg.addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			bg.addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			
			//setup the guage colors
			setColors();
			
			is_built = true;
		}
		
		protected function drawCurve(sp:Sprite, color:uint):void {
			const curve_offset:Number = 2;
			const top_h:uint = 6;
			const g:Graphics = sp.graphics;
			g.beginFill(color);
			
			//left curve
			g.moveTo(0, HEIGHT);
			g.curveTo(0,HEIGHT-THICKNESS/2, LEFT_CURVE_W,HEIGHT-THICKNESS);
			g.lineTo(LEFT_CURVE_W, HEIGHT);
			g.lineTo(0, HEIGHT);
			
			//inner curve
			g.moveTo(LEFT_CURVE_W, HEIGHT-THICKNESS);
			g.curveTo(WIDTH-THICKNESS-curve_offset,HEIGHT-THICKNESS, WIDTH-THICKNESS, top_h);
			g.lineTo(WIDTH, top_h);
			
			//outer curve
			g.curveTo(WIDTH-curve_offset*2,HEIGHT-curve_offset, LEFT_CURVE_W,HEIGHT);
			g.lineTo(LEFT_CURVE_W, HEIGHT-THICKNESS);
			
			//top cap
			g.drawRoundRectComplex(WIDTH-THICKNESS, 0, THICKNESS, top_h, 5, 5, 0, 0);
		}
		
		protected function drawShine():void {
			//mostly the same as drawCurve but dif start_x and the curve where the top height is
			const curve_offset:Number = 2;
			const top_h:uint = 6;
			const start_x:int = 13;
			const g:Graphics = shine.graphics;
			g.lineStyle(1, 0xffffff, .4);
			g.moveTo(start_x, HEIGHT-THICKNESS);
			g.curveTo(WIDTH-THICKNESS-curve_offset,HEIGHT-THICKNESS, WIDTH-THICKNESS, top_h);
			g.lineTo(WIDTH-THICKNESS, top_h-2);
			g.curveTo(WIDTH-THICKNESS,0, WIDTH-THICKNESS/2-2,0);
		}
		
		protected function setColors():void {
			var i:int;
			var pixelValue:uint;
			var energy_gradient:DisplayObject = new AssetManager.instance.assets.energy_mood_gradient();
			var bitmapdata:BitmapData = new BitmapData(energy_gradient.width, 1);
			bitmapdata.draw(energy_gradient);
			
			//get the colors for the energy gauge
			for(i = 0; i < energy_gradient.width; i++){
				pixelValue = bitmapdata.getPixel(i, 0);
				bar_colors[int(i)] = pixelValue;
			}
		}
		
		protected function onTweenUpdate():void {			
			//spinner.rotation = int(spinner.rotation);
			var perc:Number = 1-((spinner.rotation-MAX_ANGLE)/(MIN_ANGLE-MAX_ANGLE));
			perc = Math.min(1, Math.max(0, perc));
			
			//update the tip
			//TODO this doesn't go right along the curve, might have to find something better
			tip.x = WIDTH-LEFT_CURVE_W+(TIP_OFFSET-(perc*TIP_OFFSET));
			tip.y = TIP_OFFSET*perc;
			tip.value = max_value*perc;
			tip.rotation = -spinner.rotation;
			
			//perc of 1 = black, that's bad!			
			const index:int = Math.floor(Math.min(.9999999999, Math.max(0, perc))*bar_colors.length);
			_current_bar_color = bar_colors[index];
			
			var g:Graphics = juice.graphics;
			g.clear();
			
			g.beginFill(_current_bar_color);
			DrawUtil.drawArc(g, 0, 0, -180, 0, WIDTH, -1);
			
			g.beginFill(0xffffff,.2);
			DrawUtil.drawArc(g, 0, 2, -180, 0, WIDTH-4, -1);
			
			//make sure the tip is showing
			onRollOver();
			is_animating = true;
		}
		
		protected function onTweenComplete():void {
			//this solves any crazy rounding issues
			tip.value = _value;
			juice.visible = _value > 0;
			
			//wait a little bit and then call the mouse out
			is_animating = false;
			StageBeacon.setTimeout(onRollOut, 1000);
		}
		
		protected function onRollOver(event:MouseEvent = null):void {
			if(is_animating) return;
			TSTweener.removeTweens(tip);
			
			//delay it showing up only if this is a mouse event
			TSTweener.addTween(tip, {alpha:1, time:.1, delay:(event ? .1 : 0), transition:'linear', onStart:onTipShow});
		}
		
		protected function onRollOut(event:MouseEvent = null):void {
			if(is_animating) return;
			TSTweener.removeTweens(tip);
			TSTweener.addTween(tip, {alpha:0, time:.1, delay:.3, transition:'linear', onComplete:onTipHide});
		}
		
		protected function onTipShow():void {
			tip.alpha = 0;
			//spinner.addChild(tip);
		}
		
		protected function onTipHide():void {
			if(tip.parent) tip.parent.removeChild(tip);
		}
		
		public function getValue():Number { return _value; }
		public function setValue(new_value:Number, animate:Boolean = true):void {
			if(!is_built) buildBase();
			
			if(isNaN(new_value) || _value == new_value) return;
			if(_max_value < new_value) _max_value = new_value;
			_value = new_value;
			
			var perc:Number = new_value / max_value;
			perc = Math.min(1, Math.max(0, perc));
			const dest_rotation:Number = MIN_ANGLE+((MAX_ANGLE-MIN_ANGLE)*perc);
			
			TSTweener.removeTweens(spinner);
			if (spinner.rotation == dest_rotation) return;
			juice.visible = true;
			
			//animate the spin
			if(animate){
				TSTweener.addTween(spinner, {
					rotation: dest_rotation, 
					time: ANIMATION_TIME, 
					transition: 'easeOutCubic', 
					onUpdate:onTweenUpdate, 
					onComplete:onTweenComplete
				});
			}
			else {
				//put it where it needs to go and jump to it being complete
				spinner.rotation = dest_rotation;
				onTweenUpdate();
				onTweenComplete();
			}
		}
		
		public function get max_value():Number { 
			if(!_max_value && TSModelLocator.instance && TSModelLocator.instance.worldModel && TSModelLocator.instance.worldModel.pc){
				return TSModelLocator.instance.worldModel.pc.stats.energy.max;
			}
			
			return _max_value;
		}
		
		public function set max_value(new_value:Number):void {
			if(_max_value == new_value) return;
			
			_max_value = new_value;
			tip.max_value = _max_value;
		}
		
		public function get current_bar_color():Number { return _current_bar_color; }
	}
}