package com.tinyspeck.vanity {
	import com.tinyspeck.engine.view.ui.Button;
	
	public class HatVanityDialog extends AbstractVanityDialog {
		public var remove_bt:Button;
		public var hide_bt:Button;
		
		public function HatVanityDialog() {
			super();
			init();
		}
		
		override protected function init():void {
			title_html = '<p class="vanity_dialog_title">We’re hiding your hat for now</p>';
			body_html = '<p class="vanity_dialog_body">Poor little Glitch avatars can’t wear hats and have flowing locks at the same time. We’ve hidden your hat so you can see what your hair looks like.</p>';
			super.init();
		}
		
		override protected function build():void {
			hide_bt = new Button({
				name: 'hat_hide',
				label_face:'Arial',
				label_size: button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				label: 'Hide my hat for now'
			});
			buttons_sp.addChild(hide_bt);
			
			remove_bt = new Button({
				name: 'hat_remove',
				label_face:'Arial',
				label_size: button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				label: 'Remove my hat'
			});
			remove_bt.x = hide_bt.width + 10;
			buttons_sp.addChild(remove_bt);
		}
	}
}