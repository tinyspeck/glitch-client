package com.tinyspeck.vanity {
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	
	public class LoadingVanityDialog extends AbstractVanityDialog {
		
		public var pb:ProgressBar = new com.tinyspeck.engine.view.gameoverlay.ProgressBar(280, 28);
		private var pb_tf:TextField = new TextField();
		private var ear_icon:Bitmap = AssetManager.instance.getLoadedBitmap('ear_icon_str');
		private var eye_icon:Bitmap = AssetManager.instance.getLoadedBitmap('eye_icon_str');
		private var nose_icon:Bitmap = AssetManager.instance.getLoadedBitmap('nose_icon_str');
		private var mouth_icon:Bitmap = AssetManager.instance.getLoadedBitmap('mouth_icon_str');
		
		private var shown_do:DisplayObject;
		private var shown_txt:String;
		private var colors_sp:Sprite;
		private var colors_interv:uint;
		private var current_color_i:int = -1;
		
		public function LoadingVanityDialog() {
			super();
			no_border = true;
			h = 0;
			w = 280;
			init();
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
		}
		
		private function onEnterFrame(e:Event):void {
			updateDisplay(pb.displayed_perc);
		}
		
		override protected function init():void {
			title_html = '';
			body_html = '';

			TFUtil.prepTF(pb_tf, false);
			pb_tf.embedFonts = false;
			//if (CONFIG::god) {
				pb_tf.htmlText = '<p class="vanity_loading_pb_text">Loading Vanity...</p>';
			//} else {
			//	pb_tf.htmlText = '<p class="vanity_loading_pb_text2">Loading Vanity...</p>';
			//}
			
			super.init();
			//updateDisplay(0);
		}
		
		override protected function build():void {
			while(simp_sp.numChildren) simp_sp.removeChildAt(0);
			
			simp_sp.addChild(body_tf);
			simp_sp.addChild(pb);
			simp_sp.addChild(pb_tf);
		}
		
		override protected function layout():void {
			pb.y = 0;
			body_tf.x = 70;
			body_tf.y = pb.y+pb.h+10;
			//if (CONFIG::god) {
				pb_tf.x = Math.round((pb.w-pb_tf.width)/2);
				pb_tf.y = pb.y-pb_tf.height-12;
			//} else {
			//	pb_tf.filters = [StaticFilters.lightWhite1px90Degrees_DropShadow];
			//	pb_tf.x = 10;
			//	pb_tf.y = pb.y+Math.round((pb.height-pb_tf.height)/2);
			//}
				
		}
		
		private function showThisIfNotShowing(DO:DisplayObject, txt:String):void {
			if (shown_txt != txt) {
				body_html = '<p class="vanity_loading">'+txt+'</p>';
				body_tf.htmlText = body_html;
				shown_txt = txt;
			}
			
			if (shown_do == DO) return;
			if (!DO) {
				CONFIG::debugging {
					Console.warn('NO DO');
				}
				return;
			}
			if (shown_do && shown_do.parent) shown_do.parent.removeChild(shown_do);
			
			simp_sp.addChild(DO);
			
			DO.x = body_tf.x-43+Math.round((43-DO.width)/2);
			DO.y = body_tf.y+Math.round((body_tf.height-DO.height)/2);
			
			shown_do = DO;
		}
		
		private function updateDisplay(perc:Number):void {
			if (perc > .70) {
				createColors();
				showThisIfNotShowing(colors_sp, 'creating colors...');
			} else if (perc > .45) {
				showThisIfNotShowing(eye_icon, 'popping in eyeballs...');
			} else if (perc > .20) {
				showThisIfNotShowing(mouth_icon, 'shaping mouths...');
			} else if (perc > .10) {
				showThisIfNotShowing(ear_icon, 'forming ears...');
			} else {
				showThisIfNotShowing(nose_icon, 'growing noses...');
			}
			
			//body_html = '<p class="vanity_loading">'+((perc*100).toFixed(0))+'</p>';
			//body_tf.htmlText = body_html;
		}
		
		private function changeColor():void {
			if (!colors_sp) return;
			if (!VanityModel.loading_colors.length) return;
			current_color_i++;
			if (current_color_i >= VanityModel.loading_colors.length) current_color_i = 0;
			var wh:int = 24;
			var g:Graphics = colors_sp.graphics;
			g.clear();
			g.beginFill(VanityModel.loading_colors[current_color_i], 1);
			g.drawRoundRect(0, 0, wh, wh, VanityModel.colors_bt_corner_radius);
			g.beginFill(0, .2);
			g.drawRoundRect(0, 0, wh, wh, VanityModel.colors_bt_corner_radius);
			g.beginFill(VanityModel.loading_colors[current_color_i], 1);
			g.drawRoundRect(1, 1, wh-2, wh-2, VanityModel.colors_bt_corner_radius);
		}
		
		private function createColors():void {
			if (!colors_sp) {
				colors_sp = new Sprite();
				colors_sp.graphics.lineStyle(0, 0, 0);
				changeColor();
				colors_interv = StageBeacon.setInterval(changeColor, 100);
			} 
		}
		
		public function clean():void {
			if (colors_interv) StageBeacon.clearInterval(colors_interv);
			colors_interv = 0;
		}
	}
}
