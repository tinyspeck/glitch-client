package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Sprite;
	import flash.text.TextField;

	public class FavorProgressBar extends Sprite
	{
		private var pb_current_tf:TextField = new TextField();
		private var pb_max_tf:TextField = new TextField();
		private var pb_favor_tf:TextField = new TextField();
		
		private var pb:ProgressBar;
		
		private var bg_color:uint = 0xdee2e3;
		private var shadow_color:uint = 0xbdc0c1;
		private var bar_top:uint = 0xf1b6c8;
		private var bar_bottom:uint = 0xd794a8;
		private var tip_top:uint = 0xdba5b5;
		private var tip_bottom:uint = 0xcb8c9f;
		private var bar_change_top:uint = 0xa2b42c;
		private var bar_change_bottom:uint = 0xa2b42c;
		private var bar_change_top_full:uint = 0xfee582;
		private var bar_change_bottom_full:uint = 0xe8b540;
		private var current:int;
		private var max:int;
		
		private var is_built:Boolean;
		
		private var _w:int;
		private var _h:int;
		
		public function FavorProgressBar(w:int, h:int){
			_w = w;
			_h = h;
		}
		
		private function buildBase():void {
			pb = new ProgressBar(_w, _h);
			addChild(pb);
			
			TFUtil.prepTF(pb_current_tf, false);
			pb_current_tf.htmlText = '<p class="favor_progress"><span class="favor_progress_current">9999</span></p>';
			pb_current_tf.x = 6;
			pb_current_tf.y = int(pb.height/2 - pb_current_tf.height/2 + 1);
			pb_current_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.5}, StaticFilters.white1px90Degrees_DropShadowA);
			pb.addChild(pb_current_tf);
			
			TFUtil.prepTF(pb_max_tf, false);
			pb.addChild(pb_max_tf);
			
			TFUtil.prepTF(pb_favor_tf, false);
			pb_favor_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.9}, StaticFilters.white3px_GlowA);
			pb.addChild(pb_favor_tf);
			
			//set the colors
			const cssm:CSSManager = CSSManager.instance;
			bg_color = cssm.getUintColorValueFromStyle('favor_progress_bar', 'backgroundColor', bg_color);
			shadow_color = cssm.getUintColorValueFromStyle('favor_progress_bar', 'shadowColor', shadow_color);
			bar_top = cssm.getUintColorValueFromStyle('favor_progress_bar', 'barTop', bar_top);
			bar_bottom = cssm.getUintColorValueFromStyle('favor_progress_bar', 'barBottom', bar_bottom);
			tip_top = cssm.getUintColorValueFromStyle('favor_progress_bar', 'tipTop', tip_top);
			tip_bottom = cssm.getUintColorValueFromStyle('favor_progress_bar', 'tipBottom', tip_bottom);
			bar_change_top = cssm.getUintColorValueFromStyle('shrine_donate_pb', 'barTop', bar_change_top);
			bar_change_bottom = cssm.getUintColorValueFromStyle('shrine_donate_pb', 'barBottom', bar_change_bottom);
			bar_change_top_full = cssm.getUintColorValueFromStyle('shrine_donate_pb', 'barTopFull', bar_change_top_full);
			bar_change_bottom_full = cssm.getUintColorValueFromStyle('shrine_donate_pb', 'barBottomFull', bar_change_bottom_full);
			pb.setFrameColors(bg_color, shadow_color);
			pb.setBarColors(bar_top, bar_bottom, tip_top, tip_bottom);
			
			is_built = true;
		}
		
		public function setCurrentAndMax(current:int, max:int):void {
			if(!is_built) buildBase();
			
			this.current = current;
			this.max = max;
			
			pb_current_tf.htmlText = '<p class="favor_progress"><span class="favor_progress_current">'+current+'</span></p>';
			
			//for now we gotta jack into the donation_favor since it's not stored on PC
			pb_max_tf.htmlText = '<p class="favor_progress_max">/'+max+'</p>';
			pb_max_tf.x = int(pb.width - pb_max_tf.width - 6);
			pb_max_tf.y = int(pb.height - pb_max_tf.height - 3);
			
			//set the bar
			pb.update(current/max);
		}
		
		public function setDonationChange(amount:Number, is_approx:Boolean = false):void {
			if(!is_built) buildBase();
			
			const favor_perc:Number = (amount + current) / max;
			var pb_favor_txt:String = '<p class="favor_progress_bar">';
			if(favor_perc <= 1){
				pb_favor_txt += '<span class="favor_progress_bar_favor">';
			}
			else {
				//more than enough
				pb_favor_txt += '<span class="favor_progress_bar_favor_full">';
			}
			
			var amount_str:String = amount.toString();
			if(amount_str.indexOf('.') != -1){
				//let's trim it down
				amount_str = amount.toFixed(1);
			}
			
			//is this an approx. number?
			if(is_approx) pb_favor_txt += 'approx. ';
			
			pb_favor_txt += '+'+amount_str;
			pb_favor_txt += '</span>';
			pb_favor_txt += '</p>';
			pb_favor_tf.htmlText = pb_favor_txt;
			pb_favor_tf.x = int(pb_max_tf.x - pb_favor_tf.width - 2);
			pb_favor_tf.y = int(pb.height/2 - pb_favor_tf.height/2 + 4);
			
			//update the change bar in the pb
			pb.setChangeBarColors(
				favor_perc > 1 ? bar_change_top_full : bar_change_top, 
				favor_perc > 1 ? bar_change_bottom_full : bar_change_bottom,
				favor_perc > 1 ? 1 : .5
			);
			pb.updateChangeBar(Math.min(favor_perc, 1));
		}
	}
}