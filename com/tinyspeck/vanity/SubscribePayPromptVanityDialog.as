package com.tinyspeck.vanity {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Bitmap;
	
	public class SubscribePayPromptVanityDialog extends AbstractVanityDialog {
		public var sub_bt:Button;
		public var no_bt:Button;
		private var badge_bm:Bitmap;
		
		public function SubscribePayPromptVanityDialog() {
			super();
			init();
		}
		
		override protected function init():void {
			title_html = '<p class="vanity_dialog_title">That item is only available to subscribers</p>';
			body_html = '<p class="vanity_dialog_body">Dang — your subscription has lapsed! But you can still get it and access to hundreds of other subscriber-only options when you subscribe.</p>';
			body_html+= '<p class="vanity_dialog_body"><br>And hey, good news! During beta, there are crazy good deals on subscriptions. Support Glitch and subscribe now!</p>';
			
			super.init();
		}
		
		override protected function build():void {
			title_tf.width = 280;
			body_tf.width = 280;
			
			badge_bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['wardrobe/large-lock.gif']);
			if (badge_bm) {
				simp_sp.addChild(badge_bm);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('wtf no badge_bm!');
				}
			}
			
			sub_bt = new Button({
				name: 'sub',
				label_face:'Arial',
				label_size: button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				label: 'View Subscription Options'
			});
			
			no_bt = new Button({
				name: 'sub',
				label_face:'Arial',
				label_size: button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				label: 'No thanks'
			});
			
			buttons_sp.addChild(sub_bt);
			buttons_sp.addChild(no_bt);
		}
		
		override protected function layout():void {
			badge_bm.x = 0;
			badge_bm.y = 0;
			title_tf.x = badge_bm.x+badge_bm.width+20;
			title_tf.width = w-badge_bm.width-20;
			body_tf.width = title_tf.width;
			body_tf.x = title_tf.x;
			body_tf.y = title_tf.y+title_tf.height+title_bottom_margin;
			
			buttons_sp.y = body_tf.y+body_tf.height+body_bottom_margin;
			
			
			sub_bt.x = title_tf.x;
			no_bt.x = sub_bt.x+sub_bt.width+10;
		}
	}
}