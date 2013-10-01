package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Sprite;
	import flash.text.TextField;

	public class HOGToolbarUI extends Sprite implements IRefreshListener
	{
		private var text_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var esc_tf:TextField = new TextField();
		
		public function HOGToolbarUI(){
			//tfs
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="decorate_toolbar">You are in HAND OF GOD Mode</p>';
			title_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			text_holder.addChild(title_tf);
			
			TFUtil.prepTF(esc_tf, false);
			esc_tf.htmlText = '<p class="decorate_toolbar"><span class="decorate_toolbar_esc">Arrows scroll • Esc exits • "1", "0", "-", or "+" keys change selected item scale (exit to save scale changes)</span></p>';
			esc_tf.x = int(title_tf.width/2 - esc_tf.width/2);
			esc_tf.y = int(title_tf.height - 6);
			esc_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			text_holder.addChild(esc_tf);
			
			addChild(text_holder);
			
			visible = false;
		}
		
		public function show():void {
			visible = true;
			TSFrontController.instance.registerRefreshListener(this);
			refresh();
			
			//make sure the esc text is hiding
			esc_tf.alpha = 0;
			
			//bounce in the text
			text_holder.y = -text_holder.height - 10;
			const end_y:int = TSModelLocator.instance.layoutModel.header_h/2 - text_holder.height/2;
			TSTweener.addTween(text_holder, {y:end_y, time:.7, transition:'easeOutBounce', onComplete:onBounceComplete});
		}
		
		public function hide():void {
			visible = false;
			TSFrontController.instance.unRegisterRefreshListener(this);
		}

		public function refresh():void {
			//text holder
			text_holder.x = int(text_holder.width/2);
		}
		
		private function onBounceComplete():void {
			TSTweener.addTween(esc_tf, {alpha:1, time:.2, transition:'linear'});
		}
	}
}