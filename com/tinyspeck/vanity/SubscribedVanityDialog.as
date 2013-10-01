package com.tinyspeck.vanity {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Bitmap;
	
	public class SubscribedVanityDialog extends AbstractVanityDialog {
		public var ok_bt:Button;
		private var bm:Bitmap;
		
		public function SubscribedVanityDialog() {
			super();
			init();
		}
		
		override protected function init():void {
			title_html = '<p class="vanity_subbed_dialog_title">Yay! now you\'re a subscriber!</p>';
			body_html = '<p class="vanity_subbed_dialog_body">Many wonderful new things await you in the wardrobe and vanity.</p>';
			super.init();
		}
		
		override protected function build():void {
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['wardrobe/check-large.gif']);
			if (bm) {
				simp_sp.addChild(bm);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('wtf no bm!');
				}
			}
			
			ok_bt = new Button({
				name: 'ok',
				label_face:'Arial',
				label_size: button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				label: 'Great! Let\'s get going'
			});
			buttons_sp.addChild(ok_bt);
		}
		
		override protected function layout():void {
			title_tf.x = Math.round((w-title_tf.width)/2);

			body_tf.x = Math.round((w-body_tf.width)/2);
			body_tf.y = title_tf.y+title_tf.height;
			buttons_sp.y = body_tf.y+body_tf.height+body_bottom_margin;
			
			if (bm) {
				bm.x = Math.round((w-bm.width)/2);
				bm.y = body_tf.y+body_tf.height+body_bottom_margin;
				buttons_sp.y = bm.y+bm.height+body_bottom_margin;
			}
			
			ok_bt.x = Math.round((w-ok_bt.width)/2);
			
		}
	}
}