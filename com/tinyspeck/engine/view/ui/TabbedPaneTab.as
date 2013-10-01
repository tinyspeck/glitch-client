package com.tinyspeck.engine.view.ui {
	
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class TabbedPaneTab extends Sprite {
		
		private var label:String;
		private var w:int;
		private var h:int;
		private var line_c:uint = 0x000000;
		private var bg_c:uint = 0x000000;
		private var bg_alpha:uint = 1;
		private var corner_radius:int = 4;
		private var tf_padd:int = 8;
		private var tf:TextField = new TextField;
		private var active:Boolean;

		public function TabbedPaneTab(id:String, label:String, w:int, h:int, line_c:uint, bg_c:uint, bg_alpha:Number, corner_radius:int = -1) {
			super();
			name = id;
			this.label = label;
			this.w = w;
			this.h = h;
			this.line_c = line_c;
			this.bg_c = bg_c;
			this.bg_alpha = bg_alpha;
			if (corner_radius > -1) this.corner_radius = corner_radius;
			init();
		}
		
		private function init():void {
			useHandCursor = buttonMode = true;
			mouseChildren = false;
			TFUtil.prepTF(tf, false);
			tf.embedFonts = false;
			tf.htmlText = '<p class="tabbed_pane_tab_default">'+label+'</p>';
			addChild(tf);
			tf.y = Math.round((h-tf.height)/2);
			if (w) {
				tf.x = Math.round((w-tf.width)/2);
			} else {
				tf.x = tf_padd;
				w = (tf_padd*2)+tf.width;
			}
			draw();
		}
		
		public function makeActive():void {
			active = true;
			draw();
		}
		
		public function makeInActive():void {
			active = false;
			draw();
		}
		
		private function draw():void {
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(0, 0, 0, true);
			g.beginFill(0, 0);
			g.drawRect(0, 0, w, h);
			g.endFill();
			
			if (active) {
				tf.htmlText = '<p class="tabbed_pane_tab_active_default">'+label+'</p>';
				g.lineStyle(0, line_c, 1, true);
				g.beginFill(bg_c, bg_alpha);
				g.drawRoundRect(0, 0, w, h, corner_radius);
				g.endFill();
				
				// block bottom of roundRect
				g.lineStyle(0, 0, 0, true);
				g.beginFill(bg_c, 1);
				g.drawRect(0, corner_radius, w, h-corner_radius+1);
				
				// draw lines down to pane
				g.lineStyle(0, line_c, 1, true);
				g.moveTo(0, corner_radius);
				g.lineTo(0, h);
				g.moveTo(w, corner_radius);
				g.lineTo(w, h);
				
			} else {
				tf.htmlText = '<p class="tabbed_pane_tab_default">'+label+'</p>';
			}
		}
		
	}
}