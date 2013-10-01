package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.AbstractTSView;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	
	public class FlashUnfocusedView extends AbstractTSView {
		
		/* singleton boilerplate */
		public static const instance:FlashUnfocusedView = new FlashUnfocusedView();
		
		private var showing:Boolean;
		private var model:TSModelLocator;
		private var bg:Shape = new Shape();
		
		public function FlashUnfocusedView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			mouseChildren = mouseEnabled = false;
			model = TSModelLocator.instance;
			addChild(bg);
			refresh();
			alpha = 0;
			visible = false;

			if (CONFIG::god && !CONFIG::locodeco && false) {
				StageBeacon.flash_focus_changed_sig.add(onFlashFocusChanged);
				if (!StageBeacon.flash_has_focus) show();
			}
		}
		
		private function onFlashFocusChanged(value:Boolean):void {
			if (value) {
				hide();
			} else {
				show();
			}
		}
		
		private function show():void {
			if (showing) return;
			showing = true;
			paint();
			refresh();
			
			if(TSTweener.isTweening(this)) TSTweener.removeTweens(this);
			
			// _autoAlpha handles setting visible to true
			TSTweener.addTween(this, {_autoAlpha: 1, time: .2, transition: 'easeInOutSine'});
		}
		
		private function hide():void {
			if (!showing) return;
			showing = false;
			
			if(TSTweener.isTweening(this)) TSTweener.removeTweens(this);
			
			// _autoAlpha handles setting visible to false
			TSTweener.addTween(this, {_autoAlpha: 0, time: .2, transition: 'easeInOutSine'});
		}
		
		private function paint():void {
			if (!showing) return;
			
			var g:Graphics = bg.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(0, .5);
			g.drawRect(0, 0, 10, 10)
		}
		
		public function refresh():void {
			if (!showing) return;
			
			bg.width = model.layoutModel.loc_vp_w;
			bg.height = model.layoutModel.loc_vp_h;
		}
	}
}