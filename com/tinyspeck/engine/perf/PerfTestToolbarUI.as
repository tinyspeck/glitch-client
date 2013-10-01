package com.tinyspeck.engine.perf
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class PerfTestToolbarUI extends Sprite implements IRefreshListener
	{
		public static const instance:PerfTestToolbarUI = new PerfTestToolbarUI();
		
		private var all_holder:Sprite = new Sprite();
		private var title_tf:TextField = new TextField();
		private var esc_tf:TextField = new TextField();
		private var close_bt:Button;
		
		public function PerfTestToolbarUI(){			
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			//tfs
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="decorate_toolbar">0 tests remaining</p>';
			title_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(title_tf);
			
			TFUtil.prepTF(esc_tf, false);
			esc_tf.htmlText = '<p class="decorate_toolbar"><span class="decorate_toolbar_esc">You can stop testing at any time • But you might forfeit your prize...</span></p>';
			esc_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(esc_tf);
			
			addChild(all_holder);
			
			//build out any nav buttons
			buildButtons();
			
			refresh();
			
			visible = false;
		}
		
		public function update(totalTests:int):void {
			if (totalTests == 0) {
				title_tf.htmlText = '<p class="decorate_toolbar">Final test - you\'re the best!</p>';
			} else {
				title_tf.htmlText = '<p class="decorate_toolbar">' + totalTests + ' test' + ((totalTests == 1) ? '' : 's') + ' remaining...</p>';
			}
			refresh();
		}
		
		private function buildButtons():void {
			const bt_h:uint = TSModelLocator.instance.layoutModel.header_h - 5;
			
			//close button
			const close_DO:DisplayObject = new AssetManager.instance.assets.decorate_close();
			close_bt = new Button({
				name: 'stop_testing',
				label: 'Stop testing :(',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				h: 25,
				w: 120
			});
			close_bt.y = int(bt_h/2 - close_bt.height/2);
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
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
		
		public function refresh():void {
			esc_tf.x = int(title_tf.width - esc_tf.width)/2;
			esc_tf.y = int(title_tf.height - 6);
			close_bt.x = esc_tf.x + esc_tf.width + 20;
		}
		
		private function onBounceComplete():void {
			TSTweener.addTween(esc_tf, {alpha:1, time:.2, transition:'linear'});
		}
		
		private function onCloseClick(event:TSEvent):void {
			if(close_bt.disabled) return;
			close_bt.disabled = true;
			PerfTestManager.fatal("User stopped tests");
		}
	}
}