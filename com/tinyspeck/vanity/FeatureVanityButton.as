package com.tinyspeck.vanity {
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	
	public class FeatureVanityButton extends AbstractVanityButton {
		
		private var article_class_name:String;

		public function FeatureVanityButton(article_class_name:String = '') {
			super();
			this.article_class_name = article_class_name;
			
			wh = VanityModel.features_bt_wh;
			corner_radius = VanityModel.features_bt_corner_radius;
			c = VanityModel.features_bt_c;
			border_c = VanityModel.features_bt_border_c;
			border_w = VanityModel.features_bt_border_w;
			border_hi_c = VanityModel.features_bt_border_hi_c;
			border_hi_w = VanityModel.features_bt_border_hi_w;
			border_sel_c = VanityModel.features_bt_border_sel_c;
			border_sel_w = VanityModel.features_bt_border_sel_w;
			new_css_class = 'feature_button_new';
			if (CONFIG::god) TipDisplayManager.instance.registerTipTrigger(this);
			
			init();
		}
		
		override public function showNew():void {
			super.showNew();
			var g:Graphics = new_sp.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(c, 1);
			
			new_sp.x = Math.round((wh-new_sp.width)/2);
			new_sp.y = wh-Math.round(new_sp.height/2);
			g.drawRect(-1, wh-new_sp.y, new_sp.width+2, 1);
		}
		
		override public function showHidden():void {
			super.showHidden();
			ad_sp.x = Math.round((wh-ad_sp.width)/2)-1;
			ad_sp.y = wh-ad_sp.height-2;
		}
		
		override protected function init():void {
			super.init();
		}
		
		override public function getTip(tip_target:DisplayObject = null):Object {
			if (!article_class_name) return null;
			return {
				no_embed: true,
				txt: 'A/D '+article_class_name,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			};
		}
		
	}
}