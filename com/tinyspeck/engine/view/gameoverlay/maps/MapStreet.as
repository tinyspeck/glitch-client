package com.tinyspeck.engine.view.gameoverlay.maps {
	import com.tinyspeck.engine.data.map.Street;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class MapStreet extends TSSpriteWithModel {		
		private static const ALERT_FLASH_COUNT:uint = 3;
		private static const ALERT_ANIMATION_TIME:Number = .2;
		private static const PADD:uint = 5;
		private static const NORMAL_ALPHA:Number = .7;
		private static const LOCKED_ALPHA:Number = .6;
		private static const HIGHLIGHT_ALPHA:Number = .85;
		private static const STREET_COLOR:uint = 0xffffff;
		private static const TF_DIM_ALPHA:Number = .5;
		
		public var street:Street;
		public var css_class:String;
		public var css_hover_class:String;
		
		private var tf:TextField;
		private var highlighter:Sprite;
		private var highlighted:Boolean;
		private var _is_current:Boolean;
				
		public function MapStreet(street:Street, tf:TextField) {
			super();
			this.name = street.tsid;
			this.street = street;
			this.tf = tf;
			_w = street.scaled_distance;
			_h = 6;
			tf.filters = StaticFilters.white3px_GlowA;
			draw();
			unhighlight();
		}
		
		private function draw():void {
			const line_padd:uint = 3;
			var g:Graphics = graphics;
			var a:Number = (_is_current ? 1 : (highlighted ? HIGHLIGHT_ALPHA : NORMAL_ALPHA));
			
			//reset
			g.clear();
			
			if (street.visited) {
				blendMode = BlendMode.OVERLAY;
				if (street.type == MapHub.STREET_LOCKED) {
					a = LOCKED_ALPHA;
				}
				g.beginFill(STREET_COLOR, a);
				g.drawRoundRect(-_w/2-line_padd, -_h/2, _w+line_padd*2, _h, _h);
			} else {
				//show the dots if this is new
				showDots();
				
				//change the blend mode for the dots
				blendMode = BlendMode.NORMAL;
			}
			
			//hit area
			g.beginFill(0, 0);
			g.drawRect(-_w/2, -_h/2-PADD, _w, _h+PADD*2);
		}
		
		public function alert():void {
			//blinky blinky
			if(!highlighter) {
				highlighter = new Sprite();
				highlighter.blendMode = BlendMode.OVERLAY;
				highlighter.mouseEnabled = highlighter.mouseChildren = false;
				
				var g:Graphics = highlighter.graphics;
				g.clear();
				g.lineStyle(_h, 0xffffff);
				g.moveTo(-_w/2, 0);
				g.lineTo(_w/2, 0);
				
				highlighter.alpha = 0;
				addChild(highlighter);
			}
			
			TSTweener.removeTweens(highlighter);
			for(var i:int=0; i < ALERT_FLASH_COUNT; i++){
				TSTweener.addTween([highlighter, tf], {alpha:1, time:ALERT_ANIMATION_TIME, delay:ALERT_ANIMATION_TIME*(i*2), transition:'linear', onUpdate:keepOnTop});
				TSTweener.addTween([highlighter, tf], {alpha:0, time:ALERT_ANIMATION_TIME, delay:ALERT_ANIMATION_TIME*(i*2+1), transition:'linear', onComplete:(i < ALERT_FLASH_COUNT-1 ? null : bringBackText)});
			}
			
			//show the street alert styles
			css_hover_class = 'hub_map_street_current_hover';
			css_class = 'hub_map_street_alert';
			unhighlight();
		}
		
		private function bringBackText():void {
			//bring the TF back after
			TSTweener.addTween(tf, {alpha:1, time:ALERT_ANIMATION_TIME, transition:'linear'});
		}
		
		private function keepOnTop():void {
			//put this on top of the Z
			if(tf.parent && tf.parent.parent) tf.parent.parent.setChildIndex(tf.parent, tf.parent.parent.numChildren-1);
			if(parent) parent.setChildIndex(this, parent.numChildren-1);
		}
		
		public function highlight():void {
			highlighted = true;
			draw();
			
			tf.htmlText = '<p class="'+css_class+'"><span class="'+css_hover_class+'">'+street['name']+'</span></p>';
			tf.alpha = 1;
			placeTf();
		}
		
		public function unhighlight():void {
			highlighted = false;
			draw();
			
			tf.htmlText = '<p class="'+css_class+'">'+street['name']+'</p>';
			tf.alpha = (!street.visited && css_class != 'hub_map_street_alert') || street.type == MapHub.STREET_LOCKED ? TF_DIM_ALPHA : 1;
			placeTf();
		}
		
		private function placeTf():void {
			if(Math.max(_w, tf.textWidth+4) == _w){
				tf.wordWrap = true;
				tf.width = _w;
				tf.x = int(-_w/2);
			} 
			else {
				tf.wordWrap = false;
				tf.x = int(-(tf.textWidth+4)/2);
			}
			tf.y = -int(tf.height/2 + 1);
		}
		
		private function showDots():void {
			//tried just doing a bitmapdata fill on the line graphics, looked like shit
			const radius:Number = 2.5;
			const padd:int = 3;
			var g:Graphics = graphics;
			var next_x:int = -_w/2;
			
			const a:Number = 0.4 * (_is_current ? 1 : (highlighted ? HIGHLIGHT_ALPHA : NORMAL_ALPHA));
			g.beginFill(0, a);
			
			while(next_x < _w/2){
				g.drawCircle(radius+next_x, 0, radius);
				next_x += radius*2 + padd;
			}
		}
		
		public function get is_current():Boolean { return _is_current; }
		public function set is_current(value:Boolean):void {
			_is_current = value;
			draw();
		}
		
		public function get street_width():int { return _w; }
	}
}