package com.tinyspeck.engine.view.geo {
	import com.tinyspeck.engine.port.TSSprite;
	
	public class SignpostSignView extends TSSprite {
		
		private var _signpostView:SignpostView;
		
		public function SignpostSignView(signpostView:SignpostView) {
			super();
			_signpostView = signpostView;
		}
		
		public function get signpostView():SignpostView {
			return _signpostView;
		}
	}
}