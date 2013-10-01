package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class HiLeaderboardElement extends Sprite {
		
		public var variant:String;
		public var variant_name:String;
		private const h:int = 20;
		private const icon_wh:int = 20;
		private var _count:int = -1;
		private var highlighter:Sprite = new Sprite();;

		private var iiv:ItemIconView;
		private var current_tf:TextField = new TextField();
		
		public function HiLeaderboardElement(variant:String, variant_name:String){
			this.variant = variant;
			this.variant_name = variant_name;
			build();
		}
		
		public function set count(count:int):void {
			_count = count;
			current_tf.htmlText = '<p class="date_time_sub_title">'+count+' '+variant_name+(count != 1 && variant_name.substr(-1, 1) != 's' ? 's':'')+'</p>';
		}
		
		public function get count():int {
			return _count;
		}
		
		public function highlight():void {
			TSTweener.removeTweens(highlighter);
			highlighter.alpha = 1;
			TSTweener.addTween(highlighter, {alpha:0, delay:1, time:2});
		}
		
		private function build():void {
			var g:Graphics;
			highlighter.alpha = 0;
			g = highlighter.graphics;
			g.beginFill(0xf7ef0a, 1);
			g.drawRoundRect(0, 0, 114, h, 10);
			g.endFill();
			addChild(highlighter);
			
			
			TFUtil.prepTF(current_tf, false);
			addChild(current_tf);
			current_tf.x = icon_wh+5;
			current_tf.y = 1;
			if (variant == 'dongs') {
				var self:HiLeaderboardElement = this;
				AssetManager.instance.loadBitmapFromBASE64('dongs_str', AssetManager.dongs_str, function(key:String, bm:Bitmap):void {
					bm.filters = HiLeaderboard.shadow_filter;
					self.addChild(bm);
				});
			} else {
				iiv = new ItemIconView('hi_overlay', icon_wh, {state:'1', config:{variant:variant}}, 'default');
				iiv.filters = StaticFilters.black1px90Degrees_DropShadowA;
				addChild(iiv);
			}
			g = this.graphics;
			g.beginFill(0x00cc00, 0);
			g.drawRect(0, 0, 200, h);
			g.endFill();
		}
	}
}