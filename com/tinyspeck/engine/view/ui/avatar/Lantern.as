package com.tinyspeck.engine.view.ui.avatar
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.port.RightSideView;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.view.AvatarDisposableSprite;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.utils.Timer;

	public class Lantern extends AvatarDisposableSprite
	{
		/* singleton boilerplate */
		public static const instance:Lantern = new Lantern();
		
		public static const DEFAULT_RADIUS:uint = 220;
		
		private static const BG_ALPHA:Number = .97;
		private static const ANI_TIME:Number = .2;
		private static const COLORS:Array = [0, 0, 0];
		private static const ALPHAS:Array = [0 ,0, BG_ALPHA];
		private static const SPREAD:Array = [210 ,230, 255];
		
		private var matrix:Matrix = new Matrix();
		private var avatar:AvatarView;
		private var flicker:Sprite = new Sprite();
		private var flicker_timer:Timer = new Timer(80);
		private var mouse_pt:Point = new Point();
		
		private var on_avatar:Boolean;
		
		private var _radius:uint;
		
		public function Lantern(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			mouseEnabled = mouseChildren = false;
			addChild(flicker);
		}
		
		public function show(on_avatar:Boolean, radius:uint = Lantern.DEFAULT_RADIUS):void {
			//if we are already showing, it, hide it real quick
			if(parent) hide();
			
			this.on_avatar = on_avatar;
			this.radius = radius;
			
			TSFrontController.instance.getMainView().masked_container.addChild(this);
			
			//how should we start to show this
			if(on_avatar){
				if(!avatar) avatar = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
				if(avatar){
					TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, avatar);
					worldDisposableSpriteChangeHandler(avatar);
				}
			}
			else {
				StageBeacon.mouse_move_sig.add(onMouseMove);
				TipDisplayManager.instance.pause();
				onMouseMove();
			}
			
			if(!flicker_timer.hasEventListener(TimerEvent.TIMER)){
				flicker_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			}
			flicker_timer.start();
			onTimerTick();
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			
			//remove stuff
			if(on_avatar){
				if(avatar) TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, avatar);
			}
			else {
				StageBeacon.mouse_move_sig.remove(onMouseMove);
				Mouse.show();
				TipDisplayManager.instance.resume();
			}
			
			flicker_timer.removeEventListener(TimerEvent.TIMER, onTimerTick);
			flicker_timer.stop();
		}
		
		private function onTimerTick(event:TimerEvent = null):void {
			ALPHAS[1] = MathUtil.randomInt(6, 7)/10;
			SPREAD[1] = MathUtil.randomInt(230, 235);
			const g:Graphics = flicker.graphics;
			g.clear();
			g.beginGradientFill(GradientType.RADIAL, COLORS, ALPHAS, SPREAD, matrix);
			g.drawCircle(0, 0, radius);
		}
		
		private function onMouseMove(event:MouseEvent = null):void {
			mouse_pt = StageBeacon.stage_mouse_pt;
			
			//decide if we show the cursor or not
			var show_cursor:Boolean;
			const lm:LayoutModel = model.layoutModel;
			if(mouse_pt.x < lm.gutter_w || mouse_pt.x > lm.loc_vp_w + lm.gutter_w - RightSideView.CHAT_PADD){
				show_cursor = true;
			}
			
			if(mouse_pt.y < lm.header_h || mouse_pt.y > lm.loc_vp_h + lm.header_h){
				show_cursor = true;
			}
			
			if(show_cursor){
				//throw the mouse point way off stage so the stage shows as all black
				mouse_pt.y = -radius*4;
				Mouse.show();
			}
			else {
				Mouse.hide();
			}
			
			draw(mouse_pt);
		}
		
		override public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {			
			super.worldDisposableSpriteChangeHandler(sp);
			
			if(!avatar) return;
			
			avatar_global.y -= avatar.h/2;
			draw(avatar_global);
		}
		
		override public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
			super.worldDisposableSpriteDestroyedHandler(sp);
			
			hide();
		}
		
		protected function draw(pt:Point):void {
			pt.x -= model.layoutModel.gutter_w;
			pt.y -= model.layoutModel.header_h;
			
			const g:Graphics = graphics;
			g.clear();
			g.beginFill(0, BG_ALPHA);
			g.drawRect(0, 0, model.layoutModel.loc_vp_w, model.layoutModel.loc_vp_w);
			
			g.drawCircle(pt.x, pt.y, radius);
			
			flicker.x = pt.x;
			flicker.y = pt.y;
		}
		
		public function get radius():uint { return _radius; }
		public function set radius(value:uint):void {
			_radius = value;
			
			//setup the flicker
			matrix.createGradientBox(radius*2, radius*2, 0, -radius, -radius);
		}
	}
}