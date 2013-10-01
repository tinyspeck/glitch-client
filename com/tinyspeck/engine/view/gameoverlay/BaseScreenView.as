package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingScreenViewCloseVO;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.ui.Rays;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.ui.Keyboard;


	public class BaseScreenView extends AbstractTSView implements IFocusableComponent, IRefreshListener
	{		
		protected var model:TSModelLocator;
		protected var rays:Rays;
				
		protected var all_holder:Sprite = new Sprite();
		protected var all_mask:Sprite = new Sprite();
		
		protected var bg_color:uint;
		protected var bg_alpha:Number = 0;
		protected var fade_in_secs:Number = .4;
		protected var fade_out_secs:Number = .3;
		
		protected var close_payload:Object;
		
		protected var is_built:Boolean;
		protected var has_focus:Boolean;
		protected var ready_for_input:Boolean;
		protected var is_using_rays:Boolean;
		
		public function BaseScreenView(){
			model = TSModelLocator.instance;
			registerSelfAsFocusableComponent();
		}
		
		protected function buildBase():void {			
			addChild(all_holder);
			addChild(all_mask);
			mask = all_mask;
			
			is_built = true;
		}
		
		protected function loadRays(rays_scene:String = '', scale:Number = 0):void {			
			if(!rays_scene) rays_scene = Rays.SCENE_COMBINED_SLOW;
			if(scale == 0) scale = Rays.SCALE_DEFAULT;
			rays = new Rays(rays_scene, scale);
			
			is_using_rays = true;
		}
		
		protected function tryAndTakeFocus(payload:Object):Boolean {
			//give this bad boy some focus
			if(!TSFrontController.instance.requestFocus(this, payload)) {
				CONFIG::debugging {
					Console.warn('could not take focus');
				}
				return false;
			}
			
			//do we have a sound to play?
			if(payload && 'sound' in payload) {
				//make sure the bg audio fades for this
				StageBeacon.setTimeout(SoundMaster.instance.playSound, fade_in_secs*1000, payload.sound, 0, 0, false, true);
				//SoundMaster.instance.playSound(payload.sound, 0, 0, false, true);
			}
			
			//set the close payload if we have one
			close_payload = 'close_payload' in payload ? payload.close_payload : null;
			
			//add this to the refresh subscribers
			TSFrontController.instance.registerRefreshListener(this);
			
			return true;
		}
		
		public function makeSureBaseIsLoaded():Boolean {
			//is it built yet?
			if(!is_built) buildBase();
			
			//if we are using rays, make sure they are loaded
			if(is_using_rays && rays && !rays.is_loaded) return false;
			
			return true;
		}
		
		protected function animate():void {
			//remove any running tweens
			TSTweener.removeTweens([this, rays]);
			
			//add to display
			TSFrontController.instance.getMainView().addView(this);
			
			//fade in
			alpha = 0;
			ready_for_input = false;
			TSTweener.addTween(this, {alpha:1, time:fade_in_secs, transition:'linear', onComplete:onAnimateComplete});
			
			//delay the rays a little bit
			if(rays) rays.alpha = 0;
			if(is_using_rays){
				all_holder.addChildAt(rays, 0);
				TSTweener.addTween(rays, {alpha:1, time:.5, delay:fade_in_secs+.6, transition:'linear'});
			}
		}
		
		protected function onAnimateComplete():void {
			ready_for_input = true;
		}
		
		public function refresh():void {
			if(is_built) draw();
		}
		
		protected function get draw_w():int {
			return model.layoutModel.loc_vp_w;
		}
		
		protected function draw():void {
			//draw the background and mask	
			const draw_x:int = model.layoutModel.gutter_w;
			const draw_y:int = model.layoutModel.header_h;
			const draw_h:int = model.layoutModel.loc_vp_h;
			const rad:int = model.layoutModel.loc_vp_elipse_radius;
			
			//bg
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(bg_color, bg_alpha);
			g.drawRect(draw_x, draw_y, draw_w, draw_h);
			
			//mask
			g = all_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRectComplex(draw_x, draw_y, draw_w, draw_h, rad, 0, rad, 0);
		}
		
		protected function done():void {
			if(rays) TSTweener.addTween(rays, {alpha:0, time:.1, transition:'linear'});
			TSTweener.addTween(this, {alpha:0, time:fade_out_secs, transition:'linear', onComplete:onDoneTweenComplete});
		}
		
		protected function onDoneTweenComplete():void {
			TSFrontController.instance.screenViewClosed();
			if (this.parent) this.parent.removeChild(this);
			TSFrontController.instance.releaseFocus(this);
			
			//remove this from the refresh subscribers
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			//send off the close payload if we have one
			if(close_payload){
				TSFrontController.instance.genericSend(new NetOutgoingScreenViewCloseVO(close_payload));
				close_payload = null;
			}
		}
		
		protected function onOkClick(event:Event):void {
			if(!ready_for_input) return;
			done();
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
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			startListeningForControlEvts();
		}
		
		private function stopListeningForControlEvts():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onOkClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onOkClick);
		}
		
		private function startListeningForControlEvts():void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onOkClick, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onOkClick, false, 0, true);
		}
	}
}