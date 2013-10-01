package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.InfoManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearch;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;

	public class InfoToolbarUI extends Sprite implements IRefreshListener
	{
		private var all_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var esc_tf:TextField = new TextField();
		
		private var close_local_pt:Point;
		private var close_global_pt:Point;
		
		private var close_bt:Button;
		private var item_search:ItemSearch = InfoManager.instance.item_search;
		private var model:TSModelLocator;
		
		private var is_built:Boolean;
		
		public function InfoToolbarUI(){
			model = TSModelLocator.instance;
		}
		
		private function buildBase():void {
			//tfs
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="decorate_toolbar">You are in Info-getting Mode</p>';
			title_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(title_tf);
			
			TFUtil.prepTF(esc_tf, false);
			esc_tf.htmlText = '<p class="decorate_toolbar"><span class="decorate_toolbar_esc">Use TAB key for quick search, arrow keys to look around, and ESC to close</span></p>';
			esc_tf.x = int(title_tf.width/2 - esc_tf.width/2);
			esc_tf.y = int(title_tf.height - 6);
			esc_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(esc_tf);
			
			all_holder.y = int(model.layoutModel.header_h/2 - all_holder.height/2 + 2);
			addChild(all_holder);
			
			//close button
			const bt_h:uint = model.layoutModel.header_h - 5;
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
			close_bt.y = int(bt_h/2 - close_bt.height/2 + 1);
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			close_local_pt = new Point(int(close_bt.width/2), int(close_bt.height));
			addChild(close_bt);
			
			//item search
			item_search.x = int(all_holder.width/2 - item_search.width/2);
			item_search.y = model.layoutModel.header_h;
			addChild(item_search);
			
			visible = false;
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
			
			visible = true;
			TSFrontController.instance.registerRefreshListener(this);
			refresh();
			alpha = 1;
			close_bt.disabled = false;
			
			//focus on input right away
			item_search.show(false);
			
			//make sure the esc text is hiding
			TSTweener.removeTweens(esc_tf);
			esc_tf.alpha = 0;
			TSTweener.addTween(esc_tf, {alpha:1, time:.2, transition:'linear'});
		}
		
		/**
		 * Should only be called via YDM's hideInfoToolbar()
		 */		
		public function hide():void {
			TSFrontController.instance.unRegisterRefreshListener(this);
			item_search.hide();
			
			//hide it
			visible = false;
		}
		
		public function refresh():void {
			close_bt.x = int(model.layoutModel.header_bt_x - close_bt.width);
			
			//center it
			all_holder.x = int(close_bt.x/2 - all_holder.width/2);
			item_search.x = int(close_bt.x/2 - item_search.width/2);
		}
		
		public function getCloseButtonBasePt():Point {
			close_global_pt = close_bt.localToGlobal(close_local_pt);
			return close_global_pt;
		}
		
		private function onCloseClick(event:TSEvent):void {
			if(close_bt.disabled) return;
			close_bt.disabled = true;
			
			//closed the toolbar, shut it down
			TSFrontController.instance.stopInfoMode();
		}
		
		override public function get height():Number {
			if(!is_built) return super.height;
			return esc_tf.y + esc_tf.height;
		}
	}
}