package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.sound.SoundManager;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.games.GameSplashButtonValue;
	import com.tinyspeck.engine.data.games.GameSplashButtons;
	import com.tinyspeck.engine.data.games.GameSplashGraphic;
	import com.tinyspeck.engine.data.games.GameSplashScreen;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingSplashScreenButtonPayloadVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.ScoreManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Rays;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;

	public class GameSplashScreenView extends BaseSplashScreenView {
		
		/* singleton boilerplate */
		public static const instance:GameSplashScreenView = new GameSplashScreenView();
		
		private const RAYS_SCENE:String = 'combinedSlow'; //thinFast, thinSlow, thickFast, thickSlow, combinedSlow
		private const GRAPHIC_FILTERS:Array = [];
		private const BODY_FILTERS:Array = [];
		private const FRAME_WAITING_STR:String = '_is_waiting'; //used in the overlay SWF to tell it to stop at the label instead of play
		
		public var splash_screen:GameSplashScreen; //this needs to be set to view anything!!
		
		private var buttons:Vector.<Button> = new Vector.<Button>(); //pool for re-using
		private var rays:Rays;
		private var swf_view:ArbitrarySWFView;
		
		private var graphic_tf:TextField = new TextField();
		private var body_tf:TextField = new TextField();
		
		private var graphic_holder:Sprite = new Sprite();
		private var button_holder:Sprite = new Sprite();
		
		private var graphic_glow:GlowFilter = new GlowFilter();
		private var graphic_drop:DropShadowFilter = new DropShadowFilter();
		private var body_glow:GlowFilter = new GlowFilter();
		private var body_drop:DropShadowFilter = new DropShadowFilter();
		
		private var is_graphic_loading:Boolean;
		private var is_graphic_loaded:Boolean;
		
		public function GameSplashScreenView(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {			
			super.buildBase();
			
			//setup the filter arrays real quick
			GRAPHIC_FILTERS.push(graphic_glow, graphic_drop);
			BODY_FILTERS.push(body_glow, body_drop);
			
			//add to view
			all_holder.addChild(graphic_holder);
			
			//tfs
			TFUtil.prepTF(graphic_tf);
			graphic_tf.wordWrap = false;
			all_holder.addChild(graphic_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.wordWrap = false;
			all_holder.addChild(body_tf);
			
			//buttons
			all_holder.addChild(button_holder);
			
			//rays
			rays = new Rays(RAYS_SCENE);
		}
		
		override public function show():Boolean {
			//hide it
			alpha = 0;
			
			//build it			
			if(!is_built) buildBase();
			
			if(!splash_screen){
				CONFIG::debugging {
					Console.warn('You need to set the splash_screen!');
				}
				return false;
			}
			
			//rays loaded in?
			if(splash_screen.show_rays && !rays.is_loaded) {
				return false;
			}
			
			//load the graphic
			if(!is_graphic_loaded && splash_screen.graphic && splash_screen.graphic.url){
				loadGraphic(splash_screen.graphic.url);
				return false;
			}
			
			//populate the textfields
			setText(splash_screen.tsid, splash_screen.graphic ? splash_screen.graphic.text : '', false);
			if(splash_screen.graphic){
				graphic_tf.x = int(graphic_holder.width/2 - graphic_tf.width/2) + splash_screen.graphic.text_delta_x;
				graphic_tf.y = int(graphic_holder.y + (graphic_holder.height/2 - graphic_tf.height/2) + splash_screen.graphic.text_delta_y);
			}
			
			setText(splash_screen.tsid, splash_screen.text, true);
			body_tf.x = int(graphic_holder.width/2 - body_tf.width/2) + splash_screen.text_delta_x;
			body_tf.y = int(graphic_holder.y + graphic_holder.height + splash_screen.text_delta_y);
			
			//show the buttons if we've got 'em
			setButtons(splash_screen.buttons);
			if(splash_screen.buttons){
				button_holder.x = int(graphic_holder.width/2 - button_holder.width/2 + splash_screen.buttons.delta_x);
				button_holder.y = int(body_tf.y + body_tf.height + splash_screen.buttons.delta_y);
			}
			
			//set the bg color/alpha
			bg_color = CSSManager.instance.getUintColorValueFromStyle('game_splash_'+splash_screen.tsid, 'backgroundColor');
			bg_alpha = CSSManager.instance.getNumberValueFromStyle('game_splash_'+splash_screen.tsid, 'backgroundAlpha');
			
			//setup for animation
			draw();
			animate();
			
			return tryAndTakeFocus();
		}
		
		override protected function tryAndTakeFocus():Boolean {
			if(!super.tryAndTakeFocus()) return false;
			
			//do we have a sound to play?
			if(splash_screen.sound) {
				SoundMaster.instance.playSound(splash_screen.sound);
			}
			
			//we can clear the flag for graphic loading since we've got focus and everything
			is_graphic_loaded = false;
			
			return true;
		}
		
		private function setText(tsid:String, txt:String, is_body:Boolean):void {
			const tf:TextField = is_body ? body_tf : graphic_tf;
			const glow:GlowFilter = is_body ? body_glow : graphic_glow;
			const shadow:DropShadowFilter = is_body ? body_drop : graphic_drop;
			const filters:Array = is_body ? BODY_FILTERS : GRAPHIC_FILTERS;
			const cssm:CSSManager = CSSManager.instance;
			const style_name:String = 'game_splash_'+tsid+(is_body ? '' : '_graphic');
			
			//reset stuff
			tf.x = tf.y = 0;
			tf.text = '';
			//tf.border = true;
			glow.alpha = 0;
			shadow.alpha = 0;
			
			//if we have a value in txt, go and do stuff
			if(txt){
				tf.htmlText = '<p class="game_splash_screen"><span class="'+style_name+'">'+txt+'</span></p>';
				
				//apply the filters if we have any
				glow.alpha = cssm.getNumberValueFromStyle(style_name, 'glowAlpha');
				glow.blurX = glow.blurY = cssm.getNumberValueFromStyle(style_name, 'glowWidth');
				glow.color = cssm.getUintColorValueFromStyle(style_name, 'glowColor');
				glow.strength = cssm.getNumberValueFromStyle(style_name, 'glowStrength', 12);
				
				shadow.alpha = cssm.getNumberValueFromStyle(style_name, 'shadowAlpha');
				shadow.color = cssm.getUintColorValueFromStyle(style_name, 'shadowColor');
				shadow.distance = cssm.getNumberValueFromStyle(style_name, 'shadowDistance', 2);
				shadow.angle = cssm.getNumberValueFromStyle(style_name, 'shadowAngle', 120);
				shadow.blurX = shadow.blurY = cssm.getNumberValueFromStyle(style_name, 'shadowWidth', 2);
			}
			
			tf.filters = filters;
		}
		
		private function setButtons(bts:GameSplashButtons):void {
			//reset the current buttons
			var i:int;
			var total:int = buttons.length;
			var bt_value:GameSplashButtonValue;
			var bt:Button;
			var next_x:int;
			var next_y:int;
			
			for(i = 0; i < total; i++){
				buttons[int(i)].x = buttons[int(i)].y = 0;
				buttons[int(i)].visible = false;
			}
			
			if(bts){
				//we have buttons to show, let's do that!
				total = bts.values.length;
				
				for(i = 0; i < total; i++){
					bt_value = bts.values[int(i)];
					
					//re-use or build a new one
					if(buttons.length > i){
						bt = buttons[int(i)];
						bt.visible = true;
					}
					else {
						bt = new Button({
							name: 'bt_'+i
						});
						bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
						buttons.push(bt);
						button_holder.addChild(bt);
					}
					
					//use the values to set the button
					bt.label = bt_value.label;
					bt.value = bt_value.click_payload;
					bt.setSizeAndType(bt_value.size, bt_value.type);
					bt.x = next_x;
					bt.y = next_y;
					if(bt_value.w) bt.w = bt_value.w;
					if(bt_value.h) bt.h = bt_value.h;
					//if(i == 0) bt.focus();
					
					//set the next_x/next_y
					next_x += bts.is_vertical ? 0 : bt.width + bts.padding;
					next_y += bts.is_vertical ? bt.height + bts.padding : 0;
				}
			}
		}
		
		override protected function animate():void {
			super.animate();
			
			//remove any running tweens
			TSTweener.removeTweens(rays);
						
			//delay the rays a little bit
			rays.alpha = 0;
			if(splash_screen.show_rays){
				all_holder.addChildAt(rays, 0);
				TSTweener.addTween(rays, {alpha:1, time:.5, delay:1, transition:'linear'});
			}
		}
		
		override protected function onAnimateComplete():void {
			super.onAnimateComplete();
			
			//do we have a graphic that needs to go to a custom frame?
			if(splash_screen.graphic && splash_screen.graphic.frame_label && graphic_holder.numChildren){
				ArbitrarySWFView(graphic_holder.getChildAt(0)).animate(splash_screen.graphic.frame_label);
			}
		}
		
		override protected function draw():void {
			//draw the background and mask	
			super.draw();
			
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const bottom:int = Math.max(button_holder.y + button_holder.height, body_tf.y + body_tf.height)/2;
			
			//move the graphics
			all_holder.x = int(lm.loc_vp_w/2 - graphic_holder.width/2);
			all_holder.y = int(lm.loc_vp_h/2 - bottom);
		}
		
		private function loadGraphic(url:String):void {
			if(!url){
				CONFIG::debugging {
					Console.warn('NO URL?!?!');
				}
				return;
			}
			
			//set the flag that we are loading
			if(is_graphic_loading) return;
			is_graphic_loading = true;
			
			//clean things out
			SpriteUtil.clean(graphic_holder);
			graphic_holder.y = 0;
			
			//figure out what we are loading
			const is_swf:Boolean = url.toLowerCase().substr(-3) == 'swf';
			
			if(is_swf){
				//add the _is_waiting to the label so the overlay knows to stay at the first frame of the label when it's done loading
				const graphic_props:GameSplashGraphic = ScoreManager.instance.current_splash_screen.graphic;
				const frame_label:String = graphic_props.frame_label ? graphic_props.frame_label + FRAME_WAITING_STR : '';
				
				swf_view = new ArbitrarySWFView(url, 0, frame_label);
				swf_view.addEventListener(TSEvent.COMPLETE, onSWFComplete, false, 0, true);
			}
			else {
				//regular image
				AssetManager.instance.loadBitmapFromWeb(url, onBitmapComplete, 'Loading image for splash screen');
			}
		}
		
		/**
		 * the way these files should work is that the only item on the stage has a movieclip that has the frame labels in it
		 * @see game_of_thrones_winner.fla for an example 
		 * @param event
		 */		
		private function onSWFComplete(event:TSEvent):void {
			const graphic_props:GameSplashGraphic = ScoreManager.instance.current_splash_screen.graphic;
			
			//add the swf and shift the holder up based on where the Y value of the MC is
			swf_view.scaleX = swf_view.scaleY = graphic_props.scale;
			graphic_holder.addChildAt(swf_view, 0);
			graphic_holder.y = int(-swf_view.mc.y * graphic_props.scale);
			
			placeGraphic();
		}
		
		private function onBitmapComplete(filename:String, bm:Bitmap):void {
			//nothing special put it where it needs to go
			graphic_holder.addChildAt(bm, 0);
			placeGraphic();
		}
		
		private function placeGraphic():void {			
			//if we are showing the rays, we need to place them in the right spot
			rays.x = int(graphic_holder.width/2 - 413);
			rays.y = int((graphic_holder.y + graphic_holder.height)/2 - 293);
			
			is_graphic_loaded = true;
			is_graphic_loading = false;
		}
		
		private function onButtonClick(event:TSEvent):void {
			var bt:Button = event.data as Button;
			if(bt.disabled) return;
			
			//send it off to the server
			if(bt.value){
				if('does_close' in bt.value && bt.value.does_close === true){
					hide();
				}
				//send it off to the server
				TSFrontController.instance.genericSend(new NetOutgoingSplashScreenButtonPayloadVO(bt.value));
			}
		}
		
		override protected function onDoneClick(event:Event = null):void {
			if (!ready_for_input) return;
			
			//if we have buttons make sure that one of them has does_close true as part of the value
			var i:int;
			var total:int = button_holder.numChildren;
			var bt:Button;
			var has_buttons:Boolean;
			
			for(i; i < total; i++){
				bt = button_holder.getChildAt(i) as Button;
				if(bt.visible){
					if(!has_buttons) has_buttons = true;
					if(bt.value && 'does_close' in bt.value && bt.value.does_close === true){
						//fire off the value to the server
						TSFrontController.instance.genericSend(new NetOutgoingSplashScreenButtonPayloadVO(bt.value));
						hide();
						return;
					}
				}
			}
			
			//if we don't have any buttons, let esc/enter close this
			if(!has_buttons){
				hide();
			}
			else {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		override public function hide():void {
			super.hide();
			TSTweener.addTween(rays, {alpha:0, time:.1, transition:'linear'});
		}
		
		override protected function onDoneTweenComplete():void {			
			super.onDoneTweenComplete();
			if(all_holder.contains(rays)) all_holder.removeChild(rays);
		}
	}
}