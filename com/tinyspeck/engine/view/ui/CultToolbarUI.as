package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;

	public class CultToolbarUI extends Sprite implements IRefreshListener
	{
		public static const FADE_OUT_MS:Number = 200;
		
		private static const BUTTON_PADD:uint = 5;
		
		private var all_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var esc_tf:TextField = new TextField();
		
		private var close_bt:Button;
		
		private var close_local_pt:Point;
		private var close_global_pt:Point;
		
		public function CultToolbarUI(){			
			//tfs
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="decorate_toolbar">You are in Cultivation Mode</p>';
			title_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(title_tf);
			
			TFUtil.prepTF(esc_tf, false);
			esc_tf.htmlText = '<p class="decorate_toolbar"><span class="decorate_toolbar_esc">Press esc to exit</span></p>';
			esc_tf.x = int(title_tf.width/2 - esc_tf.width/2);
			esc_tf.y = int(title_tf.height - 6);
			esc_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(esc_tf);
			
			addChild(all_holder);
			
			//build out any nav buttons
			buildButtons();
			
			visible = false;
		}
		
		private function buildButtons():void {
			const bt_w:uint = 58;
			const bt_h:uint = TSModelLocator.instance.layoutModel.header_h - 5;
			const bt_y:int = -2;
			const gap:int = 4;
			var next_x:int = all_holder.width + 10;
			
			
			//close button
			const close_DO:DisplayObject = new AssetManager.instance.assets.decorate_close();
			close_bt = new Button({
				name: 'close',
				graphic: close_DO,
				graphic_padd_w: 9,
				graphic_padd_t: 9,
				size: Button.SIZE_TINY,
				type: Button.TYPE_DECORATE,
				w: 28,
				h: 27
			});
			close_bt.y = int(bt_h/2 - close_bt.height/2);
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			close_local_pt = new Point(int(close_bt.width/2), int(close_bt.height));
			addChild(close_bt);
		}
		
		public function show():void {
			TSTweener.removeTweens(this);
			visible = true;
			TSFrontController.instance.registerRefreshListener(this);
			refresh();
			alpha = 1;
			close_bt.disabled = false;
			
			//make sure the esc text is hiding
			esc_tf.alpha = 0;
			
			//bounce in the text
			all_holder.y = -all_holder.height - 10;
			const end_y:int = TSModelLocator.instance.layoutModel.header_h/2 - all_holder.height/2;
			TSTweener.addTween(all_holder, {y:end_y, time:.7, transition:'easeOutBounce', onComplete:onBounceComplete});
		}
		
		/**
		 * Should only be called via YDM's hideDecorateToolbar()
		 */		
		public function hide():void {
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			//fade it out
			TSTweener.addTween(this, {alpha:0, time:FADE_OUT_MS/1000, transition:'linear', onComplete:onHideComplete});
		}
		
		public function refresh():void {
			close_bt.x = int(TSModelLocator.instance.layoutModel.header_bt_x - close_bt.width);
			
			//center it
			all_holder.x = int(close_bt.x/2 - all_holder.width/2);
		}
		
		public function getCloseButtonBasePt():Point {
			close_global_pt = close_bt.localToGlobal(close_local_pt);
			return close_global_pt;
		}
		
		private function onBounceComplete():void {
			TSTweener.addTween(esc_tf, {alpha:1, time:.2, transition:'linear'});
		}
		
		private function onCloseClick(event:TSEvent):void {
			if(close_bt.disabled) return;
			CultManager.instance.closeFromUserInput();
		}
		
		private function onHideComplete():void {			
			visible = false;
		}
	}
}