package com.tinyspeck.vanity {
	
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.SimplePanel;
	
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class AbstractVanityDialog extends Sprite {
		
		protected var title_tf:TextField = new TextField();
		protected var body_tf:TextField = new TextField();
		protected var buttons_sp:Sprite = new Sprite();
		protected var simp_sp:Sprite = new Sprite();
		protected var simp:SimplePanel;
		protected var title_html:String = 'NEEDS TITLE';
		protected var body_html:String = 'NEEDS BODY';
		protected var title_bottom_margin:int = VanityModel.dialog_title_bottom_margin;
		protected var body_bottom_margin:int = VanityModel.dialog_body_bottom_margin;
		protected var w:int = VanityModel.dialog_w;
		protected var h:int = 0;
		protected var padd:int = VanityModel.dialog_padd;
		protected var button_font_size:int = VanityModel.button_font_size;
		protected var center:Boolean = false;
		protected var no_border:Boolean = false;
		
		
		public function AbstractVanityDialog() {
			super();
		}
		
		protected function init():void {
			simp = new SimplePanel(no_border);
			simp.outer_border_w = (no_border) ? 0 : 6;
			
			TFUtil.prepTF(title_tf);
			title_tf.embedFonts = false;
			title_tf.htmlText = title_html;
			title_tf.width = w-(padd*2);
			simp_sp.addChild(title_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.embedFonts = false;
			body_tf.htmlText = body_html;
			body_tf.width = w-(padd*2);
			simp_sp.addChild(body_tf);
			
			simp_sp.addChild(buttons_sp);
			
			build();
			
			layout();
			
			simp.padd_w = simp.padd_h = padd;
			simp.fillDO(simp_sp, '', w, h, center);
			
			addChild(simp);
		}
		
		protected function build():void {
			// extenders' delight
		}
		
		protected function layout():void {
			body_tf.y = title_tf.y+title_tf.height+title_bottom_margin;
			buttons_sp.y = body_tf.y+body_tf.height+body_bottom_margin;
		}
		
	}
}