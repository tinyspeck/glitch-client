package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class LightBox extends Sprite implements IRefreshListener, IMoveListener, IFocusableComponent
	{
		/* singleton boilerplate */
		public static const instance:LightBox = new LightBox();
		
		protected static const BG_ALPHA:Number = .9;
		protected static const BORDER_W:uint = 10;
		protected static const BORDER_ALPHA:Number = .9;
		protected static const BUTTON_GAP:uint = 5;
		
		protected var close_bt:Button;
		
		protected var bg:Sprite = new Sprite();
		protected var all_holder:Sprite = new Sprite(); //used for holding the image and extra
		protected var image_holder:Sprite = new Sprite();
		protected var button_holder:Sprite = new Sprite();
		protected var extra_holder:Sprite = new Sprite();
		protected var spinner_holder:Sprite = new Sprite();
		
		protected var title_tf:TextField = new TextField();
		
		protected var has_focus:Boolean;
		protected var is_built:Boolean;
		
		public function LightBox(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		protected function buildBase():void {
			registerSelfAsFocusableComponent();
			
			bg.addEventListener(MouseEvent.CLICK, onEsc, false, 0, true);
			addChild(bg);
			
			TFUtil.prepTF(title_tf, false);
			title_tf.x = BORDER_W - 2;
			
			addChild(all_holder);
			
			//bt
			const close_DO:DisplayObject = new AssetManager.instance.assets.close_x_making_slot();
			close_bt = new Button({
				name: 'close',
				graphic: close_DO,
				w: close_DO.width,
				h: close_DO.height,
				draw_alpha: 0
			});
			close_bt.y = int(-close_DO.height/2);
			close_bt.addEventListener(TSEvent.CHANGED, onEsc, false, 0, true);
			all_holder.addChild(close_bt);
			
			//spinner
			const spinner:DisplayObject = new AssetManager.instance.assets.spinner();
			spinner_holder.addChild(spinner);
			
			is_built = true;
		}
		
		/**
		 * Main method that runs this thing 
		 * @param image_url REQUIRED url for image to load
		 * @param title_str OPTIONAL title to display above the image
		 * @param buttons OPTIONAL button vector that will show right aligned to the image
		 * @param extra_sp OPTIONAL anything else that will be centered BELOW the buttons
		 */		
		public function show(image_url:String, title_str:String = '', buttons:Vector.<Button> = null, extra_sp:Sprite = null):void {
			if(!image_url) return;
			if(!is_built) buildBase();
			
			//try and take focus
			if(!TSFrontController.instance.requestFocus(this)) return;
			
			//hide the tooltip if it's up (having it show over this looks dumb)
			TipDisplayManager.instance.goAway();
			
			//reset
			const needs_load:Boolean = image_holder.name != image_url;
			close_bt.visible = !needs_load;
			title_tf.visible = !needs_load;
			
			//handle the buttons
			showButtons(buttons);
			
			//handle the extra stuff
			showExtra(extra_sp);
			
			if(needs_load){
				close_bt.x = 0;
				if(title_tf.parent) title_tf.parent.removeChild(title_tf);
				if(image_holder.parent) image_holder.parent.removeChild(image_holder);
				if(button_holder.parent) button_holder.parent.removeChild(button_holder);
				if(extra_holder.parent) extra_holder.parent.removeChild(extra_holder);
				
				//go ahead and load the image
				all_holder.addChild(spinner_holder);
				SpriteUtil.clean(image_holder);
				AssetManager.instance.loadBitmapFromWeb(image_url, onImageLoad, 'Lightbox needs the shit!');
			}
			else {
				if(buttons) all_holder.addChild(button_holder);
				if(extra_sp) all_holder.addChild(extra_holder);
			}
			
			//we have a title?
			if(title_str){
				title_tf.htmlText = '<p class="lightbox">'+title_str+'</p>';
				title_tf.y = -int(title_tf.height);
				all_holder.addChild(title_tf);
			}
			
			//add this to the view
			alpha = 0;
			TSTweener.addTween(this, {alpha:1, time:.2, transition:'linear'});
			TSFrontController.instance.getMainView().addView(this);
			
			//listen
			TSFrontController.instance.registerRefreshListener(this);
			TSFrontController.instance.registerMoveListener(this);
			
			refresh();
		}
		
		public function hide():void {
			//fade it out and remove from stage
			TSTweener.addTween(this, {alpha:0, time:.2, transition:'linear', onComplete:onTweenComplete});
			
			TSFrontController.instance.releaseFocus(this);
			
			//no more listen
			TSFrontController.instance.unRegisterRefreshListener(this);
			TSFrontController.instance.removeMoveListener(this);
		}
		
		public function refresh():void {
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			var g:Graphics = bg.graphics;
			g.clear();
			g.beginFill(0, BG_ALPHA);
			g.drawRect(0, 0, StageBeacon.stage.stageWidth, StageBeacon.stage.stageHeight);
			
			g = image_holder.graphics;
			g.clear();
			if(image_holder.width){
				g.beginFill(0xffffff, BORDER_ALPHA);
				g.drawRoundRect(0, 0, image_holder.width + BORDER_W*2, image_holder.height + BORDER_W*2, 16);
			}
			
			//center the stuff
			all_holder.x = int(StageBeacon.stage.stageWidth/2 - all_holder.width/2);
			all_holder.y = lm.header_h + Math.max(0, int(lm.loc_vp_h/2 - all_holder.height/2));
		}
		
		protected function showButtons(buttons:Vector.<Button>):void {
			//we do it this way because we don't want spriteutil to kill the buttons
			while(button_holder.numChildren) button_holder.removeChildAt(0);
			button_holder.x = button_holder.y = 0;
			
			if(buttons){
				const total:int = buttons.length;
				var i:int;
				var bt:Button;
				var next_x:int;
				
				//loop through and attach them to the holder, in reverse order
				for(i = total-1; i >= 0; i--){
					bt = buttons[int(i)];
					bt.x = next_x;
					next_x += bt.width + BUTTON_GAP;
					button_holder.addChild(bt);
				}
				
				//place it (until it loads)
				button_holder.x = int(image_holder.width - button_holder.width - BORDER_W);
				button_holder.y = int(image_holder.height + BUTTON_GAP);
			}
		}
		
		protected function showExtra(extra_sp:Sprite):void {
			//we do it this way because we don't want spriteutil to kill the sp
			while(extra_holder.numChildren) extra_holder.removeChildAt(0);
			extra_holder.x = extra_holder.y = 0;
			
			if(extra_sp) {
				extra_holder.addChild(extra_sp);
				extra_holder.x = int(image_holder.width/2 - extra_holder.width/2);
				extra_holder.y = (button_holder.numChildren ? button_holder.y + button_holder.height : image_holder.height) + 10;
			}
		}
		
		protected function onImageLoad(filename:String, bm:Bitmap):void {
			image_holder.name = filename;
			bm.x = BORDER_W;
			bm.y = BORDER_W;
			image_holder.addChild(bm);
			all_holder.addChildAt(image_holder, 0);
			
			close_bt.visible = true;
			close_bt.x = bm.width + BORDER_W;
			title_tf.visible = true;
			
			if(button_holder.numChildren){
				all_holder.addChild(button_holder);
				button_holder.x = int(bm.width - button_holder.width + BORDER_W);
				button_holder.y = bm.height + BORDER_W*2 + BUTTON_GAP;
			}
			
			if(extra_holder.numChildren){
				all_holder.addChild(extra_holder);
				extra_holder.x = int(image_holder.width/2 - extra_holder.width/2);
				extra_holder.y = (button_holder.numChildren ? button_holder.y + button_holder.height : bm.height + BORDER_W) + 10;
			}
			
			//remove the spinner
			if(spinner_holder.parent) spinner_holder.parent.removeChild(spinner_holder);
			
			refresh();
		}
		
		protected function onTweenComplete():void {
			//remove it from where it needs to be removed from
			if(parent) parent.removeChild(this);
		}
		
		protected function onEsc(event:Event = null):void {
			hide();
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
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEsc);
		}
		
		protected function startListeningForControlEvts():void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEsc, false, 0, true);
		}
		
		/*********************************************
		 * Stuff that's used for the iMoveListener *
		 *********************************************/
		public function moveLocationHasChanged():void {}
		public function moveLocationAssetsAreReady():void {}
		public function moveMoveEnded():void {}
		public function moveMoveStarted():void {
			if(parent) hide();
		}		
	}
}