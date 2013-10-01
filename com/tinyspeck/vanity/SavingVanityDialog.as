package com.tinyspeck.vanity {
	
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	
	public class SavingVanityDialog extends AbstractVanityDialog {
		
		public var pb:ProgressBar = new com.tinyspeck.engine.view.gameoverlay.ProgressBar(200, 20);
		
		public function SavingVanityDialog() {
			super();
			h = 0;
			w = 0;
			init();
		}
		
		override protected function init():void {
			title_html = '';
			body_html = '<p class="vanity_dialog_body">Saving...</p>';
			super.init();
		}
		
		public function setTxt(txt:String):void {
			body_html = '<p class="vanity_dialog_body">'+txt+'</p>';
			body_tf.htmlText = body_html;
		}
		
		override protected function build():void {
			while(simp_sp.numChildren) simp_sp.removeChildAt(0);
			
			simp_sp.addChild(body_tf);
			simp_sp.addChild(pb);
		}
		
		override protected function layout():void {
			body_tf.y = 0;
			pb.y = body_tf.y+body_tf.height+10;
		}
	}
}