package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.core.memory.DisposableSprite;
	
	import flash.display.MovieClip;
	
	public class InLocationOverlay extends DisposableSprite {
		
		private var baseClip:MovieClip;
		
		public function InLocationOverlay(overlayBase:MovieClip) {
			super();
			
			baseClip = overlayBase;
			addChild(overlayBase);
		}
		
		public function play():void {
			baseClip.play();
		}
		
	}
}