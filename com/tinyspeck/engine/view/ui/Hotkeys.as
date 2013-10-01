package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.ui.Keyboard;

	public class Hotkeys extends Sprite implements IRefreshListener
	{
		/* singleton boilerplate */
		public static const instance:Hotkeys = new Hotkeys();
		
		private static const ANI_TIME:Number = .1;
		
		private var asset:DisplayObject;
		
		private var close_bt:Button;
		
		private var is_built:Boolean;
		
		public function Hotkeys(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function buildBase():void {
			asset = new AssetManager.instance.assets.hotkeys();
			addChild(asset);
			
			const close_DO:DisplayObject = new AssetManager.instance.assets.close_x_small_gray();
			close_bt = new Button({
				name: 'close',
				graphic: close_DO,
				w: close_DO.width,
				h: close_DO.height,
				draw_alpha: 0
			});
			close_bt.addEventListener(TSEvent.CHANGED, hide, false, 0, true);
			addChild(close_bt);
			
			is_built = true;
		}
		
		public function show(show_close:Boolean = false):void {
			if(!is_built) buildBase();
			
			TSFrontController.instance.registerRefreshListener(this);
			TSFrontController.instance.getMainView().addView(this);
			TipDisplayManager.instance.goAway();
			
			TSTweener.removeTweens(this);
			alpha = 0;
			TSTweener.addTween(this, {alpha:1, time:ANI_TIME, transition:'linear'});
			
			//if we are showing the close button, listen to esc as well
			close_bt.visible = show_close;
			if(show_close){
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, hide, false, 0, true);
			}
			
			refresh();
		}
		
		public function hide(event:Event = null):void {
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {alpha:0, time:ANI_TIME, transition:'linear', onComplete:onTweenComplete});
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, hide);
		}
		
		private function onTweenComplete():void {
			TSFrontController.instance.unRegisterRefreshListener(this);
			if(parent) parent.removeChild(this);
		}
		
		public function refresh():void {
			if(!is_built) return;
			
			const draw_w:int = StageBeacon.stage.stageWidth;
			const draw_h:int = StageBeacon.stage.stageHeight;
			const g:Graphics = graphics;
			g.clear();
			g.beginFill(0, .4);
			g.drawRect(0, 0, draw_w, draw_h);
			
			asset.x = int(draw_w/2 - asset.width/2);
			asset.y = Math.min(100, Math.max(draw_h-asset.height-20, 0));
			
			close_bt.x = int(asset.x + asset.width - close_bt.width - 10);
			close_bt.y = int(asset.y + 55);
		}
	}
}