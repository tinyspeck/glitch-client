package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.text.TextField;

	public class HouseExpandYardImageUI extends Sprite
	{
		public static const ANIMATION_TIME:Number = .3;
		
		private static const BUFFER_W:uint = 38;
		private static const OVERLAY_ALPHA:Number = .5;
		private static const OVERLAY_ALPHA_HOVER:Number = .7;
		private static const ARROW_ALPHA:Number = .5;
		private static const ARROW_ALPHA_HOVER:Number = .8;
		private static const CHECKMARK_ALPHA:Number = .9;
		
		private var image_holder:Sprite = new Sprite();
		private var image_mask:Sprite = new Sprite();
		private var overlay:Sprite = new Sprite();
		private var arrow:Sprite = new Sprite();
		private var checkmark:Sprite = new Sprite();
		private var buffer:Sprite = new Sprite();
		
		private var inner_glowA:Array = [];
		private var inner_glow_greyscaleA:Array = [];
		private var greyscaleA:Array = [];
		
		private var current_side:String;
		
		private var is_built:Boolean;
		
		private var _w:int;
		private var _h:int;
		private var _enabled:Boolean;
		private var _selected:Boolean;
		
		public function HouseExpandYardImageUI(){}
		
		private function buildBase():void {
			const is_left:Boolean = current_side == 'left';
			
			addChild(image_mask);
			
			image_holder.mask = image_mask;
			addChild(image_holder);
			
			overlay.alpha = OVERLAY_ALPHA;
			addChild(overlay);
			
			const arrowDO:DisplayObject = new AssetManager.instance.assets.expand_yard_arrow();
			SpriteUtil.setRegistrationPoint(arrowDO);
			arrow.scaleX = is_left ? 1 : -1;
			arrow.y = int(_h/2);
			arrow.filters = StaticFilters.black2px90Degrees_DropShadowA;
			arrow.addChild(arrowDO);
			arrow.alpha = ARROW_ALPHA;
			addChild(arrow);
			
			checkmark.filters = StaticFilters.black2px90Degrees_DropShadowA;
			checkmark.alpha = CHECKMARK_ALPHA;
			addChild(checkmark);
			
			const checkmarkDO:DisplayObject = new AssetManager.instance.assets.expand_yard_check();
			checkmark.addChild(checkmarkDO);
			
			const tf:TextField = new TextField();
			TFUtil.prepTF(tf, false);
			tf.htmlText = '<p class="house_expand_yard_side">'+(is_left ? 'Left' : 'Right')+'</p>';
			tf.x = int(checkmark.width/2 - tf.width/2);
			tf.y = int(checkmark.height);
			checkmark.addChild(tf);
			checkmark.y = int(_h/2 - checkmark.height/2);
			checkmark.visible = false;
			
			//glow filter
			const inner_glow:GlowFilter = new GlowFilter();
			inner_glow.color = 0x50c9eb;
			inner_glow.inner = true;
			inner_glow.alpha = 1;
			inner_glow.strength = 30;
			inner_glow.quality = 2;
			inner_glow.blurX = inner_glow.blurY = 2;
			inner_glowA.push(inner_glow);
			
			//greyscale filters
			inner_glow_greyscaleA = StaticFilters.copyFilterArrayFromObject({color:0xbbbbbb}, inner_glowA);
			greyscaleA.push(ColorUtil.getGreyScaleFilter());
			
			//buffer pattern
			const stick_w:uint = 2; //inner glow color stick
			const buffer_rad:uint = 4;
			const pat_wh:uint = 6;
			const buffer_pat:BitmapData = new BitmapData(pat_wh, pat_wh, false, 0xFFb4e0ed);
			var i:int;
			buffer_pat.lock();
			for(i; i <= pat_wh; i++){
				buffer_pat.setPixel32(i, i, 0xFF9ed7e8);
			}
			buffer_pat.unlock();
			
			var g:Graphics = buffer.graphics;
			g.beginBitmapFill(buffer_pat);
			g.drawRoundRectComplex(0, 0, BUFFER_W, _h, is_left ? buffer_rad : 0, is_left ? 0 : buffer_rad, is_left ? buffer_rad : 0, is_left ? 0 : buffer_rad);
			g.beginFill(inner_glow.color);
			g.drawRect(is_left ? BUFFER_W-stick_w : 0, 0, stick_w, _h);
			addChildAt(buffer, 0);
			
			//toss the arrow in the buffer holder
			const expand_arrow:DisplayObject = new AssetManager.instance.assets.expand_arrow();
			const arrow_holder:Sprite = new Sprite();
			arrow_holder.addChild(expand_arrow);
			SpriteUtil.setRegistrationPoint(expand_arrow);
			arrow_holder.scaleX = is_left ? 1 : -1;
			arrow_holder.x = BUFFER_W/2;
			arrow_holder.y = _h/2;
			arrow_holder.alpha = .78;
			arrow_holder.filters = StaticFilters.copyFilterArrayFromObject({inner:false, alpha:.4}, inner_glowA);
			buffer.addChild(arrow_holder);
			
			//mouse stuff
			mouseChildren = false;
			useHandCursor = buttonMode = true;
			addEventListener(MouseEvent.ROLL_OVER, onMouse, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onMouse, false, 0, true);
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			is_built = true;
		}
		
		public function show(w:int, h:int, side:String):void {
			current_side = side;
			_w = w - BUFFER_W;
			_h = h;
			if(!is_built) buildBase();
			
			//reset
			select(false, false);
			
			showImage();
			draw();
		}
		
		public function select(is_selected:Boolean, animate:Boolean = true):void {
			_selected = is_selected;
			mouseEnabled = !is_selected;
			
			//animate the choice
			showSelect(animate);
		}
		
		private function showImage():void {			
			//go get a snap of our location
			use namespace client;
			const loc:Location = TSModelLocator.instance.worldModel.location;
			const scale:Number = _h/(loc.h/2);
			//const loc_snap:Bitmap = TSFrontController.instance.getMainView().gameRenderer.getSnapshot('NORMAL', loc.w*scale, _h); //shows ugly vertical bars
			const loc_snap:Bitmap = TSFrontController.instance.getMainView().gameRenderer.getSnapshot(CameraMan.SNAPSHOT_TYPE_NORMAL, loc.w/2, loc.h/2);
			
			//scale the bitmap, otherwise you get pixel lines where the wallpaper is
			loc_snap.smoothing = true;
			loc_snap.scaleX = loc_snap.scaleY = scale;
			
			//put it where it needs to go
			loc_snap.x = current_side == 'left' ? -1 : -loc_snap.width + _w;
			SpriteUtil.clean(image_holder);
			image_holder.addChild(loc_snap);
		}
		
		private function draw():void {
			//draw the overlay and the mask
			var g:Graphics = overlay.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, _w, _h);
			
			g = image_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, _w, _h);
			
			//center things up
			arrow.x = int(_w/2);
			checkmark.x = int(_w/2 - checkmark.width/2);
		}
		
		private function showSelect(animate:Boolean):void {
			//crossfade out the arrow and show the checkmark
			arrow.visible = !is_selected;
			checkmark.visible = is_selected;
			buffer.visible = is_selected;
			buffer.x = current_side == 'left' ? 0 : _w - BUFFER_W;
			
			if(animate){
				TSTweener.addTween(arrow, {alpha:is_selected ? 0 : ARROW_ALPHA, time:ANIMATION_TIME, transition:'linear'});
				TSTweener.addTween(overlay, {alpha:is_selected ? 0 : OVERLAY_ALPHA, time:ANIMATION_TIME, transition:'linear'});
				TSTweener.addTween(checkmark, {alpha:!is_selected ? 0 : CHECKMARK_ALPHA, time:ANIMATION_TIME, transition:'linear'});
				TSTweener.addTween(buffer, {x:current_side == 'left' ? -BUFFER_W : _w, time:ANIMATION_TIME, transition:'linear'});
			}
			else {
				//set the alphas to where they should be
				arrow.alpha = is_selected ? 0 : ARROW_ALPHA;
				checkmark.alpha = is_selected ? 0 : CHECKMARK_ALPHA;
				overlay.alpha = is_selected ? 0 : OVERLAY_ALPHA;
				
				//move the buffer over straight away
				if(is_selected) buffer.x = current_side == 'left' ? -BUFFER_W : _w;
			}
			
			//handle the filters
			filters = is_selected ? (animate ? inner_glowA : inner_glow_greyscaleA) : null;
			buffer.filters = is_selected && !animate ? greyscaleA : null;
		}
		
		private function onMouse(event:MouseEvent):void {
			//if we are showing the overlay, do stuff
			if(!enabled || is_selected) return;
			overlay.alpha = event.type == MouseEvent.ROLL_OVER ? OVERLAY_ALPHA_HOVER : OVERLAY_ALPHA;
			arrow.alpha = event.type == MouseEvent.ROLL_OVER ? ARROW_ALPHA_HOVER : ARROW_ALPHA;
		}
		
		private function onClick(event:MouseEvent):void {
			if(!enabled || is_selected) return;
			
			//slide this over and show the expanded area
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void {
			_enabled = value;
			mouseEnabled = value;
		}
		
		public function get is_selected():Boolean { return _selected; }
		
		override public function get width():Number { return _w; }
		override public function get height():Number { return _h; }
	}
}