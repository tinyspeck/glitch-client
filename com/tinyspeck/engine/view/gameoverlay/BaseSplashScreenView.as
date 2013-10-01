package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.IFocusableComponent;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.ui.Keyboard;

	public class BaseSplashScreenView extends AbstractTSView implements IFocusableComponent, IRefreshListener
	{
		protected var all_holder:Sprite = new Sprite();
		protected var all_mask:Sprite = new Sprite();
		
		protected var bg_color:uint;
		protected var bg_alpha:Number = 0;
		
		protected var is_built:Boolean;
		protected var ready_for_input:Boolean;
		protected var has_focus:Boolean;
		
		public function BaseSplashScreenView(){
			registerSelfAsFocusableComponent();
		}
		
		/**
		 * This should be called from any class that extends this 
		 */		
		protected function buildBase():void {
			//holders
			addChild(all_holder);
			addChild(all_mask);
			mask = all_mask;
			
			is_built = true;
		}
		
		public function show():Boolean {
			CONFIG::debugging {
				Console.error('This needs to be overridden!!!');
			}
			return false;
		}
		
		public function refresh():void {
			if(is_built) draw();
		}
		
		protected function draw():void {
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const draw_w:int = lm.loc_vp_w;
			const draw_h:int = lm.loc_vp_h;
			const rad:int = lm.loc_vp_elipse_radius;
			
			//bg
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(bg_color, bg_alpha);
			g.drawRoundRectComplex(0, 0, draw_w, draw_h, rad, 0, rad, 0);
			
			//mask
			g = all_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRectComplex(0, 0, draw_w, draw_h, rad, 0, rad, 0);
		}
		
		protected function animate():void {
			//remove any running tweens
			TSTweener.removeTweens(this);
			
			//add to display
			TSFrontController.instance.getMainView().addView(this);
			
			//fade in
			ready_for_input = false;
			TSTweener.addTween(this, {alpha:1, time:.4, transition:'linear', onComplete:onAnimateComplete});
		}
		
		protected function onAnimateComplete():void {
			ready_for_input = true;
		}
		
		protected function tryAndTakeFocus():Boolean {
			//give this bad boy some focus
			if(!TSFrontController.instance.requestFocus(this)) {
				CONFIG::debugging {
					Console.warn('could not take focus');
				}
				return false;
			}
						
			//add this to the refresh subscribers
			TSFrontController.instance.registerRefreshListener(this);
			
			return true;
		}
		
		protected function onDoneClick(event:Event = null):void {
			if (!ready_for_input) return;
			
			hide();
		}
		
		public function hide():void {
			TSTweener.addTween(this, {alpha:0, time:.3, transition:'linear', onComplete:onDoneTweenComplete});
		}
		
		protected function onDoneTweenComplete():void {
			if (this.parent) this.parent.removeChild(this);
			TSFrontController.instance.releaseFocus(this);
			
			//remove this from the refresh subscribers
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			//let any listeners know that it's closed
			dispatchEvent(new TSEvent(TSEvent.CLOSE));
		}
		
		/*********************************************
		 * Stuff that's used for the focus component *
		 *********************************************/
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			has_focus = false;
			stopListeningForControlEvts();
		}
		
		public function registerSelfAsFocusableComponent():void {
			TSModelLocator.instance.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			TSModelLocator.instance.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			startListeningForControlEvts();
		}
		
		protected function stopListeningForControlEvts():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onDoneClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onDoneClick);
		}
		
		protected function startListeningForControlEvts():void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onDoneClick, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onDoneClick, false, 0, true);
		}
	}
}