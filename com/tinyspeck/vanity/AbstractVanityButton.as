package com.tinyspeck.vanity {
	
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	public class AbstractVanityButton extends Sprite implements ITipProvider {
		
		protected var is_over:Boolean;
		protected var is_selected:Boolean;
		protected var is_disabled:Boolean;
		protected var wh:int;
		protected var corner_radius:int;
		protected var c:uint = 0xffffff;
		
		protected var border_c:uint = 0xff0000;
		protected var border_w:uint = 0;
		
		protected var border_hi_c:uint = 0x00ff00;
		protected var border_hi_w:uint = 2;
		
		protected var border_sel_c:uint = 0x0000ff;
		protected var border_sel_w:uint = 2;
		
		protected var border_sel_outer_c:uint;
		protected var border_sel_outer_w:uint;
		
		protected var border_inner_w:int;
		
		
		protected var _disabled_pattern:BitmapData;
		protected var disabled_shape:Shape = new Shape();
		protected var new_sp:Sprite;
		protected var new_tf:TextField;
		protected var ad_sp:Sprite;
		protected var ad_tf:TextField;
		
		public function AbstractVanityButton() {
			super();
		}
		
		protected function init():void {
			useHandCursor = buttonMode = true;
			mouseChildren = false;
			addEventListener(MouseEvent.ROLL_OVER, onRollover);
			addEventListener(MouseEvent.ROLL_OUT, onRollout);
			draw();
		}
		
		private function createDisabledPattern():void {

			var light:uint = 0x30bbbbbb;
			var dark:uint = 0x60bbbbbb
			disabled_shape = new Shape();
			_disabled_pattern = new BitmapData(3, 3, true, light);
			_disabled_pattern.lock();
			_disabled_pattern.setPixel32(1, 0, dark);
			_disabled_pattern.setPixel32(2, 0, dark);
			_disabled_pattern.setPixel32(0, 1, dark);
			_disabled_pattern.setPixel32(2, 1, dark);
			_disabled_pattern.setPixel32(0, 2, dark);
			_disabled_pattern.setPixel32(1, 2, dark);
			/*
			011
			101
			110
			*/
			_disabled_pattern.unlock();
		}
		
		public function addDO(DO:DisplayObject, scale:Boolean=true, flip:Boolean=true, center:Boolean=true):void {
			addChild(DO);
			
			var padd:int = 4;
			var wh:int = wh-(padd*2);
			
			if (scale) {
				if (DO.width > DO.height) {
					DO.scaleX = DO.scaleY = wh/DO.width;
				} else {
					DO.scaleX = DO.scaleY = wh/DO.height;
				}
			}
			
			if (flip) DO.scaleX = -DO.scaleX;
			
			if (center) {
				var rect:Rectangle = DO.getBounds(this);
				DO.x = padd+Math.round(-rect.x+(wh-DO.width)/2);
				DO.y = padd+Math.round(-rect.y+(wh-DO.height)/2);
			}
		}
		
		protected function onRollover(e:MouseEvent):void {
			if (is_disabled) return;
			is_over = true;
			draw();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			return null;
		}
		
		protected function onRollout(e:MouseEvent):void {
			if (is_disabled) return;
			is_over = false;
			draw();
		}
		
		public function set disabled(s:Boolean):void {
			if (is_disabled == s) return;
			is_over = false;
			is_disabled = s;
			
			draw();
		}
		
		public function set selected(s:Boolean):void {
			if (is_selected == s) return;
			is_selected = s;
			draw();
		}
		
		public function set color(c:uint):void {
			if (this.c == c) return;
			this.c = c;
			draw();
		}
		
		protected var new_css_class:String = '';
		public function showNew():void {
			if (!new_sp) {
				new_sp = new Sprite();
				new_tf = new TextField();
				TFUtil.prepTF(new_tf, false);
				new_tf.embedFonts = false;
				new_tf.htmlText = '<p class="'+new_css_class+'">new</p>';
				new_sp.addChild(new_tf);
				addChild(new_sp);
			}
			
			// extender must now place the sp!
			
		}
		
		public function showHidden():void {
			if (!ad_sp) {
				ad_sp = new Sprite();
				ad_tf = new TextField();
				TFUtil.prepTF(ad_tf, false);
				ad_tf.embedFonts = false;
				ad_tf.htmlText = '<p class="'+new_css_class+'">A/D</p>';
				ad_sp.addChild(ad_tf);
				addChild(ad_sp);
			}
			
			// extender must now place the sp!
			
		}
		
		protected function drawDisabled():void {
			//alpha = (is_disabled) ? .5 : 1;
			
			var g:Graphics = graphics;
			
			if (is_disabled) {
				if (!_disabled_pattern) {
					createDisabledPattern();
					g = disabled_shape.graphics;
					g.clear();
					g.beginBitmapFill(_disabled_pattern);
					g.drawRoundRect(1, 1, wh-2, wh-2, corner_radius);
				}
				addChild(disabled_shape);
				disabled_shape.visible = true;
				//put it back
				g = graphics;
			} else if (disabled_shape) {
				disabled_shape.visible = false;
			}
		}
		
		protected function drawInnerBorder():void {
			if (!border_inner_w) return;
			
			var g:Graphics = graphics;
			g.lineStyle(0, 0, 0);
			var offset:int = border_inner_w;
			var a:Number;
			var inner_c:uint;
			
			if (is_selected) {
				offset = border_sel_w;
				inner_c = border_sel_c;
				a = 1;
			} else {
				offset = border_inner_w;
				inner_c = 0x000000;
				if (is_over) {
					a = .3;
				} else {
					a = .1;
				}
			}
			
			g.beginFill(inner_c, a);
			g.drawRoundRect(0, 0, wh, wh, corner_radius);
			
			// now fill in the center
			g.beginFill(c, 1);
			g.drawRoundRect(offset, offset, wh-(offset*2), wh-(offset*2), corner_radius);
		}
		
		protected function draw():void {
			drawDisabled();
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			var offset:int;
			
			if (is_selected) {
				// outerborder
				if (border_sel_outer_w) {
					g.beginFill(border_sel_outer_c, 1);
					offset = border_sel_w+border_sel_outer_w;
					g.drawRoundRect(-offset, -offset, wh+(offset*2), wh+(offset*2), corner_radius+offset);
				}
				
				// normal border, with selected color and w
				g.beginFill(border_sel_c, 1);
				offset = border_sel_w;
				g.drawRoundRect(-offset, -offset, wh+(offset*2), wh+(offset*2), corner_radius+border_sel_w);
			} else if (is_over) {
				// normal border with hi color and w
				g.beginFill(border_hi_c, 1);
				offset = border_hi_w;
				g.drawRoundRect(-offset, -offset, wh+(offset*2), wh+(offset*2), corner_radius+border_hi_w);
			} else {
				// normal border with normal border color and w
				g.beginFill(border_c, 1);
				offset = border_w;
				g.drawRoundRect(-offset, -offset, wh+(offset*2), wh+(offset*2), corner_radius);
			}
			
			// now fill in the center
			g.beginFill(c, 1);
			g.drawRoundRect(0, 0, wh, wh, corner_radius);
			
			drawInnerBorder();
			
		}
		
	}
}