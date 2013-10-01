package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.net.NetOutgoingSnapTravelForgetVO;
	import com.tinyspeck.engine.net.NetOutgoingSnapTravelVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.utils.getTimer;

	public class SnapTravelView extends BaseScreenView
	{
		/* singleton boilerplate */
		public static const instance:SnapTravelView = new SnapTravelView();
		
		private static const IMAGE_PADD:uint = 16; //width of the frame around the snap
		private static const SNAP_SHOW_DELAY_MS:uint = 2000; //how long to show the text before showing the image
		private static const COLORS:Array = [0x3a3a3a, 0];
		private static const ALPHAS:Array = [1, 1];
		private static const RATIOS:Array = [0, 255];
		private static const MATRIX:Matrix = new Matrix();
		private static const TIMEOUT_MS:uint = 10000; //how long before we give up from not hearing from the API
		
		public var scale_to_viewport:Boolean;
		
		private var button_holder:Sprite = new Sprite();
		private var snap_holder:Sprite = new Sprite(); //holds the image and text
		private var image_holder:Sprite = new Sprite();
		private var forget_holder:Sprite = new Sprite();
		private var flash_holder:Sprite = new Sprite();
		private var author_holder:Sprite = new Sprite();
		
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var author_tf:TSLinkedTextField = new TSLinkedTextField();
		private var forget_tf:TextField = new TextField();
		private var location_tf:TextField = new TextField();
		
		private var go_bt:Button;
		private var api_call:APICall;
		
		private var location_tsid:String;
		private var location_x:Number;
		private var location_y:Number;
		private var load_timer:uint;
		
		private var loading_image:Boolean;
		
		public function SnapTravelView(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			bg_color = CSSManager.instance.getUintColorValueFromStyle('snap_travel', 'backgroundColor', 0);
			bg_alpha = CSSManager.instance.getNumberValueFromStyle('snap_travel', 'alpha', .75);
			
			//tf
			TFUtil.prepTF(body_tf);
			body_tf.filters = StaticFilters.black2px90Degrees_DropShadowA;
			body_tf.x = 30;
			all_holder.addChild(body_tf);
			
			//snap stuff
			image_holder.x = image_holder.y = IMAGE_PADD;
			snap_holder.blendMode = BlendMode.LAYER;
			snap_holder.addChild(image_holder);
			all_holder.addChild(snap_holder);
			
			//buttons
			go_bt = new Button({
				name: 'go',
				label: 'Go there!',
				size: Button.SIZE_GLITCHR,
				type: Button.TYPE_GLITCHR,
				w: 150
			});
			go_bt.addEventListener(TSEvent.CHANGED, onGoClick, false, 0, true);
			button_holder.addChild(go_bt);
			
			TFUtil.prepTF(forget_tf, false);
			forget_tf.htmlText = '<p class="snap_travel_body"><span class="snap_travel_forget">Forget it</span></p>';
			forget_tf.filters = StaticFilters.black2px90Degrees_DropShadowA;
			forget_tf.x = 8;
			forget_tf.y = 2;
			forget_holder.addChild(forget_tf);
			onForgetMouse();
			forget_holder.x = int(go_bt.width/2 - forget_holder.width/2);
			forget_holder.y = int(go_bt.height + 12);
			forget_holder.addEventListener(MouseEvent.CLICK, onOkClick, false, 0, true);
			forget_holder.addEventListener(MouseEvent.ROLL_OVER, onForgetMouse, false, 0, true);
			forget_holder.addEventListener(MouseEvent.ROLL_OUT, onForgetMouse, false, 0, true);
			forget_holder.useHandCursor = forget_holder.buttonMode = true;
			forget_holder.mouseChildren = false;
			button_holder.addChild(forget_holder);
			all_holder.addChild(button_holder);
			
			//location
			TFUtil.prepTF(location_tf);
			location_tf.filters = StaticFilters.copyFilterArrayFromObject({blurX:3, blurY:3}, StaticFilters.black2px90Degrees_DropShadowA).concat(
				StaticFilters.copyFilterArrayFromObject({blurX:3, blurY:3, alpha:.3}, StaticFilters.black_GlowA));
			location_tf.x = 53;
			location_tf.y = 30;
			all_holder.addChild(location_tf);
			
			//author
			TFUtil.prepTF(author_tf, false);
			author_tf.x = 6;
			author_tf.y = 4;
			author_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			author_holder.addChild(author_tf);
			all_holder.addChild(author_holder);
			
			//api stuff
			api_call = new APICall();
			api_call.addEventListener(TSEvent.COMPLETE, onAPIComplete, false, 0, true);
		}
		
		// SHOULD ONLY EVER BE CALLED FROM TSFrontController.instance.tryShowScreenViewFromQ();
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
			
			//set the body text
			body_tf.htmlText = '<p class="snap_travel_body">'+payload.text+'</p>';
			
			//reset
			body_tf.visible = true;
			location_tsid = null;
			go_bt.disabled = true;
			forget_holder.mouseEnabled = true;
			button_holder.visible = false;
			snap_holder.visible = false;
			location_tf.visible = false;
			author_holder.visible = false;
			SpriteUtil.clean(image_holder);
			load_timer = 0;
			
			//load a random snap
			loading_image = true;
			api_call.snapsRandomForCamera();
			
			//set the timeout
			StageBeacon.setTimeout(showSnap, SNAP_SHOW_DELAY_MS + (fade_in_secs*1000));
			
			//setup to animate
			refresh();
			animate();
			
			return tryAndTakeFocus(payload);
		}
		
		override public function refresh():void {			
			super.refresh();
			const lm:LayoutModel = model.layoutModel;
			
			//scale the snap if we need to
			if(scale_to_viewport){
				image_holder.scaleX = image_holder.scaleY = 1;
				var image_scale:Number = 1;
				if(image_holder.width > lm.loc_vp_w){
					image_scale = lm.loc_vp_w/image_holder.width;
				}
				
				//if it's still too high
				if(image_holder.height * image_scale > lm.loc_vp_h){
					image_scale = lm.loc_vp_h/image_holder.height;
				}
				
				image_holder.scaleX = image_holder.scaleY = image_scale;
			}
			else if(image_holder.scaleX != 1){
				image_holder.scaleX = image_holder.scaleY = 1;
			}
			
			const draw_h:int = image_holder.height + IMAGE_PADD*2;
			var g:Graphics = snap_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, image_holder.width + IMAGE_PADD*2, draw_h);
			
			snap_holder.y = int(lm.loc_vp_h/2 - snap_holder.height/2);
			snap_holder.x = int(draw_w/2 - snap_holder.width/2);
			
			//set the width of the TFs
			body_tf.width = int(draw_w - body_tf.x*2);
			body_tf.y = int(lm.loc_vp_h/2 - body_tf.height/2);
			location_tf.width = int(draw_w - location_tf.x*2);
			
			//set the buttons positions
			button_holder.x = int(draw_w/2 - button_holder.width/2);
			button_holder.y = int(lm.loc_vp_h - button_holder.height - 30);
			
			//make sure the flash is the right w/h
			if(flash_holder.parent){
				g = flash_holder.graphics;
				g.clear();
				g.beginFill(0xffffff);
				g.drawRect(0, 0, lm.loc_vp_w, lm.loc_vp_h);
			}
			
			//place the author holder
			author_holder.x = int(lm.loc_vp_w - author_holder.width);
			author_holder.y = int(lm.loc_vp_h - author_holder.height);
			
			all_holder.x = lm.gutter_w;
			all_holder.y = lm.header_h;
		}
		
		private function showSnap():void {
			//see if we are still loading the image, if so, try again real soon
			if(loading_image) {
				if(load_timer == 0) {
					load_timer = getTimer();
				}
				else if(getTimer() - load_timer > TIMEOUT_MS){
					//this is bad, we didn't hear anything back, so we need to close up shop
					model.activityModel.activity_message = 
						Activity.createFromCurrentPlayer('Your camera seems to have gone all wonky. Give it another try soon.');
					done();
					return;
				}
				StageBeacon.setTimeout(showSnap, 200);
				return;
			}
			
			//show the flash
			SoundMaster.instance.playSound('CAMERA_SHUTTER');
			all_holder.addChild(flash_holder);
			refresh();
			TSTweener.removeTweens(flash_holder);
			flash_holder.alpha = 0;
			TSTweener.addTween(flash_holder, {alpha:1, time:.1, transition:'linear', 
				onComplete:function():void {
					snap_holder.visible = true;
					button_holder.visible = true;
					body_tf.visible = false;
					location_tf.visible = true;
					author_holder.visible = true;
				}
			});
			TSTweener.addTween(flash_holder, {alpha:0, time:.6, delay:.3, transition:'linear',
				onComplete:function():void {
					if(flash_holder.parent) flash_holder.parent.removeChild(flash_holder);
				}
			});
		}
		
		private function onForgetMouse(event:MouseEvent = null):void {
			const is_over:Boolean = event && event.type == MouseEvent.ROLL_OVER;
			const g:Graphics = forget_holder.graphics;
			g.clear();
			g.beginFill(0, is_over ? .7 : .4);
			g.drawRoundRect(0, 0, int(forget_tf.width + forget_tf.x*2), int(forget_tf.height + forget_tf.y*2), 10);
		}
		
		override protected function onOkClick(event:Event):void {
			SoundMaster.instance.playSound(forget_holder.mouseEnabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(!forget_holder.mouseEnabled) return;
			super.onOkClick(event);
			
			//disable the buttons
			go_bt.disabled = true;
			forget_holder.mouseEnabled = false;
			
			//tell the server we want to forget it
			TSFrontController.instance.genericSend(new NetOutgoingSnapTravelForgetVO());
		}
		
		private function onGoClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!go_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(go_bt.disabled || !location_tsid) return;
			
			//disable the buttons
			go_bt.disabled = true;
			forget_holder.mouseEnabled = false;
			
			//tell the server we want to travel
			TSFrontController.instance.genericSend(new NetOutgoingSnapTravelVO(location_tsid, location_x, location_y));
			
			//close up shop
			done();
		}
		
		private function onAPIComplete(event:TSEvent):void {
			//set the location and x/y
			const snap_data:Object = event.data && 'snap' in event.data ? event.data.snap : null;
			if(snap_data){
				location_tsid = snap_data.location_tsid;
				location_x = snap_data.location_x;
				location_y = snap_data.location_y;
				
				//enabled the go button
				go_bt.disabled = false;
				
				//set the location text
				var loc_txt:String = '<p class="snap_travel_body"><span class="snap_travel_location">';
				const loc:Location = model.worldModel.getLocationByTsid(location_tsid);
				const hub:Hub = loc ? model.worldModel.getHubByTsid(loc.hub_id) : null;
				
				//set the loc
				loc_txt += loc ? loc.label : 'Some interesting place';
				
				//set the hub
				loc_txt += '<span class="snap_travel_hub"><br>in '
				loc_txt += hub ? hub.label : 'Ur';
				loc_txt += '</span>';
				
				loc_txt += '</span></p>';
				location_tf.htmlText = loc_txt;
				
				//set the author
				var author_txt:String = '<p class="snap_travel_author">';
				if('owner' in snap_data){
					const vag_ok:Boolean = StringUtil.VagCanRender(snap_data.owner.name);
					author_tf.embedFonts = vag_ok;
					if(!vag_ok) author_txt += '<font face="Arial">';
					author_txt += 'Snapshot taken by: ';
					author_txt += '<a class="snap_travel_author_link" href="event:'+TSLinkedTextField.LINK_PLAYER_INFO+'|'+snap_data.owner.tsid+'">';
					if(snap_data.owner.name.indexOf('<') != -1 || snap_data.owner.name.indexOf('>') != -1){
						author_txt += StringUtil.encodeHTMLUnsafeChars(snap_data.owner.name, false);
					}
					else {
						author_txt += snap_data.owner.name;
					}
					author_txt += '</a>';
					if(!vag_ok) author_txt += '</font>';
				}
				else {
					author_txt += 'Snapshot by someone, but not sure who';
				}
				author_txt += '</p>';
				author_tf.htmlText = author_txt;
				
				//draw the box around it
				var g:Graphics = author_holder.graphics;
				g.clear();
				g.beginFill(0, .4);
				g.drawRoundRect(0, 0, int(author_tf.width + author_tf.x*2), int(author_tf.height + author_tf.y*2), 10);
				
				//load the image
				AssetManager.instance.loadBitmapFromWeb(snap_data.urls.orig, onImageComplete, 'Loading a snap to travel to');
			}
			else {
				CONFIG::debugging {
					Console.warn('Missing data in the "snap" hash');
				}
			}
		}
		
		private function onImageComplete(filename:String, bm:Bitmap):void {			
			loading_image = false;
			
			if(bm){
				bm.smoothing = true;
				bm.alpha = 0;
				image_holder.addChild(bm);
				
				//draw the black BG, and then fade in the bm
				MATRIX.createGradientBox(bm.width, bm.height, Math.PI/4);
				const g:Graphics = image_holder.graphics;
				g.clear();
				g.beginGradientFill(GradientType.LINEAR, COLORS, ALPHAS, RATIOS, MATRIX);
				g.drawRect(0, 0, bm.width, bm.height);
				TSTweener.addTween(bm, {alpha:1, time:.5, delay:2, transition:'linear'});
				
				refresh();
			} else {
				CONFIG::debugging {
					Console.warn('Something bad happened onImageComplete');
				}
			}
		}
	}
}