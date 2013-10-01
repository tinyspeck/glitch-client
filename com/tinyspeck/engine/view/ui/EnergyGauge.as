package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;

	public class EnergyGauge extends Sprite
	{
		private const ANIMATION_TIME:Number = 2;
		private const MIN_ANGLE:int = -180;
		private const MAX_ANGLE:int = 0;
		private const NEEDLE_THICKNESS:Number = 3;
		private const BORDER_THICKNESS:Number = 2;
		private const OFFSET_FROM_BORDER:Number = 1;
		private const RADIUS:uint = 19; //be careful when changing this as other classes scale the size of this
		private const INNER_RAD:int = RADIUS - BORDER_THICKNESS - OFFSET_FROM_BORDER;
		
		private static var is_built:Boolean;
		private static var _gauge_colors:Array = [];
		
		protected var border:Sprite = new Sprite();
		protected var face:Sprite = new Sprite();
		protected var arc:Sprite = new Sprite();
		protected var needle:Sprite = new Sprite();
		protected var needle_mask:Sprite = new Sprite();
		protected var inner_face:Sprite = new Sprite();
		
		protected var current_tf:TextField = new TextField();
		protected var total_tf:TextField = new TextField();
		
		protected var _value:Number;
		protected var _max_value:Number;
		protected var _current_gauge_color:Number;
		
		public function EnergyGauge(){						
			construct();
		}
		
		protected function construct():void {			
			//setup the gauge colors if not setup yet
			if(!is_built) setColors();
			
			addChild(border);
			addChild(face);
			addChild(arc);
			addChild(needle);
			addChild(needle_mask);
			addChild(inner_face);
			
			needle.mask = needle_mask;
			
			//tfs
			TFUtil.prepTF(current_tf);
			TFUtil.prepTF(total_tf);
			total_tf.mouseEnabled = current_tf.mouseEnabled = false;
			
			addChild(current_tf);
			addChild(total_tf);
			
			//filters
			var drop:DropShadowFilter = new DropShadowFilter();
			drop.inner = true;
			drop.angle = 120;
			drop.alpha = 1;
			drop.distance = 1;
			drop.blurX = drop.blurY = 0;
			
			arc.filters = [drop];
			
			drop = new DropShadowFilter();
			drop.angle = -90;
			drop.alpha = .3;
			drop.distance = 1;
			drop.blurX = drop.blurY = 0;
			
			current_tf.filters = [drop];
						
			draw();
			
			//set the tf widths so they can just center on their own
			//current_tf.border = total_tf.border = true;
			current_tf.width = border.width;
			current_tf.htmlText = '<p class="energy_gauge_current">9999</p>';
			current_tf.x = int(-current_tf.width/2);
			current_tf.y = int(-current_tf.height/2) - 2;
			
			total_tf.width = border.width;
			total_tf.htmlText = '<p class="energy_gauge_total">9999</p>';
			total_tf.x = int(-total_tf.width/2);
			total_tf.y = 1;
			total_tf.alpha = .4;
		}
		
		protected function draw():void {
			//draw the moving gauge
			drawGauge();
			
			//border		
			var g:Graphics = border.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(0xffffff);
			g.drawCircle(0, 0, RADIUS);
			g.endFill();
		}
		
		public function update(new_value:Number):void {
			if (isNaN(new_value) || _value == new_value) return;
			_value = new_value;
			if(_max_value < _value) _max_value = _value;
						
			//we're tweening with rotation
			var perc:Number = new_value / max_value;
			perc = Math.min(1, Math.max(0, perc));
			perc = Math.min(.9999999999, Math.max(0, perc));
			
			var index:int = Math.floor(perc*gauge_colors.length);
			_current_gauge_color = gauge_colors[index];
			var dest_rotation:Number = MIN_ANGLE+((MAX_ANGLE-MIN_ANGLE)*perc);
			
			//set the tfs
			current_tf.htmlText = '<p class="energy_gauge_current">'+_value+'</p>';
			total_tf.htmlText = '<p class="energy_gauge_total">'+max_value+'</p>';
			
			var g:Graphics = face.graphics;
			g.clear();
			
			// filled gauge circle
			g.lineStyle(0, 0, 0);
			g.beginFill(_current_gauge_color);
			g.drawCircle(0, 0, RADIUS - BORDER_THICKNESS);
			g.endFill();
			
			//filled inner face circle
			g = inner_face.graphics;
			g.clear();
			g.beginFill(_current_gauge_color);
			g.drawCircle(0, 0, RADIUS - BORDER_THICKNESS - NEEDLE_THICKNESS - OFFSET_FROM_BORDER);
			g.endFill();
			
			TSTweener.removeTweens(needle);//easeOutElastic
			if (needle.rotation == dest_rotation) return;
			
			TSTweener.addTween(needle, {rotation: dest_rotation, time: ANIMATION_TIME, transition: 'easeOutElastic'});
		}
		
		private function drawGauge():void {
			// arc of white			
			var g:Graphics = needle.graphics;
			g.clear();
			g.beginFill(0xffffff);
			DrawUtil.drawArc(g, 0, 0, MIN_ANGLE, MAX_ANGLE, INNER_RAD, 1);
			//DrawUtil.drawArc(g, 0, 0, MIN_ANGLE, MAX_ANGLE, INNER_RAD - NEEDLE_THICKNESS, 1);
			g.endFill();
			
			//needle mask
			g = needle_mask.graphics;
			g.clear();
			g.beginFill(0);
			DrawUtil.drawArc(g, 0, 0, MIN_ANGLE, MAX_ANGLE, INNER_RAD, 1);
			g.endFill();
			
			//the arc that gets filled by the needle
			g = arc.graphics;
			g.clear();
			g.beginFill(0x333333);
			DrawUtil.drawArc(g, 0, 0, MIN_ANGLE, MAX_ANGLE, INNER_RAD, 1);
			DrawUtil.drawArc(g, 0, 0, MIN_ANGLE, MAX_ANGLE, INNER_RAD - NEEDLE_THICKNESS, 1);
			g.endFill();
			
			arc.alpha = .4; //setting alpha here vs. the drawing allows the drop filter to look right
		}
		
		private function setColors():void {			
			var i:int;
			var pixelValue:uint;
			var energy_gradient:DisplayObject = new AssetManager.instance.assets.energy_mood_gradient();
			var bitmapdata:BitmapData = new BitmapData(energy_gradient.width, 1);
			bitmapdata.draw(energy_gradient);
			
			//get the colors for the energy gauge
			for(i = 0; i < energy_gradient.width; i++){
				pixelValue = bitmapdata.getPixel(i, 0);
				_gauge_colors[int(i)] = pixelValue;
			}
			
			is_built = true;
		}
		
		public function get value():Number { return _value; }
		public function set value(new_value:Number):void { 
			update(new_value);
		}
		
		public function get gauge_colors():Array { return _gauge_colors; }
		public function set gauge_colors(value:Array):void {
			_gauge_colors = value;
		}
		
		public function get max_value():Number { 
			if(!_max_value && TSModelLocator.instance && TSModelLocator.instance.worldModel && TSModelLocator.instance.worldModel.pc){
				return TSModelLocator.instance.worldModel.pc.stats.energy.max;
			}

			return _max_value;
		}
		
		public function set max_value(value:Number):void {
			_max_value = value;
		}
		
		public function get current_gauge_color():Number { return _current_gauge_color; }
	}
}