package com.tinyspeck.bridge {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.util.DrawUtil;
	
	import flash.display.BlendMode;
	import flash.display.Sprite;

	/** Shown when the game loses focus to suggest clicking in it */
	public class ClickToFocus extends Sprite {
		public function ClickToFocus() {
			blendMode = BlendMode.INVERT;
			buttonMode = true;
			useHandCursor = true;
			
			// EC: I don't think this should interfere with clicking on things
			// JS: You're right, the reasoning was so the hand would show up as
			//     the entire game is a clickable surface since it doesn't have
			//     focus; so I will do that but not capture the click
			mouseChildren = true;
			mouseEnabled = true;
			
			StageBeacon.resize_sig.add(onResize);
			StageBeacon.flash_focus_changed_sig.add(onFlashFocusChanged);
			
			onFlashFocusChanged(StageBeacon.flash_has_focus);
		}
		
		private function onFlashFocusChanged(flash_has_focus:Boolean):void {
			visible = !flash_has_focus;
		}
		
		private function onResize():void {
			graphics.clear();
			
			// invisible fill (so the mouse collides with it)
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
			
			DrawUtil.drawDashedRect(graphics, stage.stageWidth-1, stage.stageHeight-1);
		}
	}
}
