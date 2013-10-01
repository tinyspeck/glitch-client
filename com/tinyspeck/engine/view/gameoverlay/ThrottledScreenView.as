package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class ThrottledScreenView extends TSSpriteWithModel {
		/* singleton boilerplate */
		public static const instance:ThrottledScreenView = new ThrottledScreenView();
		
		private const container:Sprite = new Sprite();
		
		public function ThrottledScreenView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			buttonMode = true;
			useHandCursor = true;
			
			addChild(container);
			
			const play_button:DisplayObject = new AssetManager.instance.assets.play_button();
			container.addChild(play_button);
			play_button.x = int(-play_button.width/2);
			play_button.y = int(-play_button.height/2);

			const explanation_tf:TextField = new TextField()
			TFUtil.prepTF(explanation_tf, true);
			explanation_tf.wordWrap = false;
			explanation_tf.filters = StaticFilters.anncText_DropShadowA;
			explanation_tf.htmlText = '<p class="throttled_explanation">Power Saving Mode<br/><span class="throttled_explanation_resume">Click to Resume</span></p>';
			explanation_tf.x = int(-explanation_tf.width/2);
			explanation_tf.y = int(play_button.height/2);
			container.addChild(explanation_tf);
			
			StageBeacon.pre_throttle_sig.add(onPreThrottled);
			StageBeacon.throttled_sig.add(onThrottled);
			StageBeacon.unthrottled_sig.add(onUnthrottled);
			
			refresh(true);
			
			// initially not visible
			alpha = 0;
		}
		
		private function fadeOut():void {
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {alpha:0, time:(StageBeacon.PRE_THROTTLE_DELAY/1000), onComplete:removeFromParent});
		}
		
		private function removeFromParent():void {
			if (parent) parent.removeChild(this);
		}
		
		private function fadeIn():void {
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {alpha:1, time:(StageBeacon.PRE_THROTTLE_DELAY/1000)});
		}
		
		private function onUnthrottled():void {
			StageBeacon.waitForNextFrame(fadeOut);
		}
		
		private function onPreThrottled():void {
			refresh(true);
			TipDisplayManager.instance.goAway();
			TSFrontController.instance.getMainView().addView(this);
			fadeIn();
		}
		
		private function onThrottled():void {
			//
		}
		
		public function refresh(force:Boolean = false):void {
			// only redraw if we're displayed
			if (parent || force) {
				draw();
				container.x = (StageBeacon.stage.stageWidth / 2);
				const height_to_center_in:int = Math.min(StageBeacon.stage.stageHeight, model.layoutModel.header_h+model.layoutModel.loc_vp_h);
				container.y = (height_to_center_in / 2);
			}
		}
		
		protected function draw():void {
			const g:Graphics = graphics;
			const opacity:Number = model.flashVarModel.throttle_opacity;
			const width:int = StageBeacon.stage.stageWidth;
			const height:int = StageBeacon.stage.stageHeight;
			
			g.clear();
			
			// draw background
			g.beginFill(0x000000, opacity);
			//const background_fill:BitmapData = new BitmapData(1, 4, true, 0);
			//background_fill.setPixel32(0, 1, 0xCC000000);
			//background_fill.setPixel32(0, 2, 0xCC000000);
			//background_fill.setPixel32(0, 3, 0xCC000000);
			//g.beginBitmapFill(background_fill);
			g.drawRect(0, 0, width, height);
		}
	}
}
