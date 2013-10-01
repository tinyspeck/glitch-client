package com.tinyspeck.vanity {
	import com.tinyspeck.engine.view.ui.Button;
	
	public class LeavingVanityDialog extends AbstractVanityDialog {
		public var stay_bt:Button;
		public var home_bt:Button;
		public var wardrobe_bt:Button;
		
		public function LeavingVanityDialog() {
			super();
			init();
		}
		
		override protected function init():void {
			title_html = '<p class="vanity_dialog_title"></p>';
			body_html = '<p class="vanity_dialog_body"></p>';
			super.init();
		}
		
		public function makeForSaved():void {
			title_html = '<p class="vanity_dialog_title">Your changes have been saved!</p>';
			title_tf.htmlText = title_html;
			body_html = '<p class="vanity_dialog_body">Would you like to head to the home page, to the wardrobe to change your clothes, or to stay here to make more changes to your avatar?</p>';
			body_tf.htmlText = body_html;
			
			layout();
		}
		
		public function makeForUnsaved():void {
			title_html = '<p class="vanity_dialog_title">You have unsaved changes</p>';
			title_tf.htmlText = title_html;
			body_html = '<p class="vanity_dialog_body">If you leave now, you\'ll lose your changes!</p>';
			body_tf.htmlText = body_html;
			
			layout();
		}
		
		override protected function layout():void {
			super.layout();
			stay_bt.x = 0;
			home_bt.x = w - home_bt.width;
			wardrobe_bt.x = home_bt.x - 10 - wardrobe_bt.width;
			simp.fillDO(simp_sp, '', w, h, center);
		}
		
		override protected function build():void {
			stay_bt = new Button({
				name: 'cancel',
				label_face:'Arial',
				label_size: button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR, // find the reddish version of this!
				label: 'Stay here'
			});
			buttons_sp.addChild(stay_bt);
			
			home_bt = new Button({
				name: 'save',
				label_face:'Arial',
				label_size: button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				label: 'Return to site'
			});
			buttons_sp.addChild(home_bt);
			
			wardrobe_bt = new Button({
				name: 'discard',
				label_face:'Arial',
				label_size: button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR, // find the reddish version of this!
				label: 'Go to wardrobe'
			});
			buttons_sp.addChild(wardrobe_bt);
		}
	}
}