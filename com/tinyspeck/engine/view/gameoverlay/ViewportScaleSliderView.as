package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.ui.TSSlider;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class ViewportScaleSliderView extends TSSlider implements ITipProvider {
		/* singleton boilerplate */
		public static const instance:ViewportScaleSliderView = new ViewportScaleSliderView();
		
		private var model:TSModelLocator;
		private var mouse_is_down:Boolean;
		
		public function ViewportScaleSliderView():void {
			super(TSSlider.VERTICAL);
			
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			
			TipDisplayManager.instance.registerTipTrigger(this);
			
			alpha = 0.25;
			
			//setSize(slider_w, slider_h);
			backClick = true;
			fillLevelAlpha = 0;
			setSliderParams(model.flashVarModel.min_zoom, model.flashVarModel.max_zoom, model.layoutModel.loc_vp_scale);
			
			addEventListener(Event.CHANGE, onSliderChange, false, 0, true);
			
			addEventListener(MouseEvent.MOUSE_OVER, function():void {
				alpha = 1
//				TSTweener.addTween(this, {
//					alpha: 1,
//					time: 0.4,
//					transition: 'easeInCubic'
//				});
			});
			
			addEventListener(MouseEvent.MOUSE_OUT, function():void {
//				if (!mouse_is_down)
					alpha = 0.2;
//				TSTweener.addTween(this, {
//					alpha: 0.2,
//					time: 0.4,
//					transition: 'easeOutCubic'
//				});
			});
			
//			addEventListener(MouseEvent.MOUSE_DOWN, function():void {
//				mouse_is_down = true;
//			});
//			
//			addEventListener(MouseEvent.MOUSE_UP, function():void {
//				mouse_is_down = false;
//				//TODO check if the mouse is still over this before resetting alpha
//				alpha = 0.2
//			});
		}
		
		public function refresh():void {
			x = 18;
			y = 85;
			minimum = model.layoutModel.min_loc_vp_scale
			maximum = model.layoutModel.max_loc_vp_scale;
			value = model.layoutModel.loc_vp_scale;
		}
		
		public function show():void {
			visible = true;
		}
		
		public function hide():void {
			visible = false;
		}
		
		public function getTip(tip_target:DisplayObject=null):Object {
			return { txt: "Viewport Scale: " + (Math.round(value * 100) / 100) };
		}
		
		private function onSliderChange(e:Event):void {
			alpha = 1;
			TSFrontController.instance.setViewportScale(value, 0, true);
		}
	}
}
