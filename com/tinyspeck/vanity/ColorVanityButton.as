package com.tinyspeck.vanity {
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.DisplayObject;
	
	public class ColorVanityButton extends AbstractVanityButton {
		
		private var color_name:String;

		public function ColorVanityButton(color_name:String = 'ffff') {
			super();
			this.color_name = color_name;
			
			wh = VanityModel.colors_bt_wh;
			corner_radius = VanityModel.colors_bt_corner_radius;
			c = VanityModel.colors_bt_c;
			border_c = VanityModel.colors_bt_border_c;
			border_w = VanityModel.colors_bt_border_w;
			border_hi_c = VanityModel.colors_bt_border_hi_c;
			border_hi_w = VanityModel.colors_bt_border_hi_w;
			border_sel_c = VanityModel.colors_bt_border_sel_c;
			border_sel_w = VanityModel.colors_bt_border_sel_w;
			border_sel_outer_c = VanityModel.colors_bt_border_sel_outer_c;
			border_sel_outer_w = VanityModel.colors_bt_border_sel_outer_w;
			border_inner_w = 1;
			new_css_class = 'color_button_new';
			TipDisplayManager.instance.registerTipTrigger(this);
			
			init();
		}
		
		override public function showNew():void {
			super.showNew();
			new_sp.x = Math.round((wh-new_sp.width)/2)-1;
			new_sp.y = Math.round((wh-new_sp.height)/2)-1;
		}
		
		override public function showHidden():void {
			super.showHidden();
			ad_sp.x = Math.round((wh-ad_sp.width)/2)-1;
			ad_sp.y = wh-ad_sp.height+3;
		}
		
		override protected function init():void {
			super.init();
		}
		
		override public function getTip(tip_target:DisplayObject = null):Object {
			return {
				no_embed: true,
				txt: color_name,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			};
		}
		
	}
}