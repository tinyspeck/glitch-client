package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.quasimondo.geom.ColorMatrix;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class ImgMenuElement extends TSSpriteWithModel
	{
		private static const TITLE_ALPHA:Number = .9;
		private static const SUB_ALPHA:Number = .35;
		private static const SUB_ALPHA_HOVER:Number = .8;
		private static const DISABLED_ALPHA:Number = .35;
		private static const CLOUD_ALPHA:Number = .7;
		private static const ORIGIN:Point = new Point();
		
		protected var holder:Sprite = new Sprite();
		protected var img_holder:Sprite = new Sprite();
		protected var tip_holder:Sprite = new Sprite();
		
		protected var img_holder_bitmap:Bitmap;
		protected var cloud:Cloud = new Cloud('just_load_the_damn_base_mc');
		protected var cloud_hover:Bitmap;
		protected var cloud_mask:Cloud;
		protected var spinner:MovieClip;
		
		protected var title_tf:TextField = new TextField();
		protected var sub_tf:TextField = new TextField();
		protected var tip_tf:TextField = new TextField();
		
		protected var img_url:String;
		protected var type:String;
		protected var tip_txt:String;
		protected var sound_id:String;
				
		protected var is_built:Boolean;
		protected var is_focused:Boolean;
		protected var _enabled:Boolean;
		
		public function ImgMenuElement(){}
		
		protected function buildBase():void {
			spinner = new AssetManager.instance.assets.spinner();
			spinner.scaleX = spinner.scaleY = 0.8;
			spinner.mouseChildren = false;
			spinner.alpha = 0.75;
			var cm:ColorMatrix = new com.quasimondo.geom.ColorMatrix();
			cm.adjustContrast(1);
			cm.adjustBrightness(80);
			cm.colorize(0xFFFFFF);
			spinner.filters = [cm.filter];
			
			holder.cacheAsBitmap = true; //this allows the text to not jitter when bobbing
			addChild(holder);
			
			TFUtil.prepTF(title_tf, false);
			title_tf.alpha = TITLE_ALPHA;
			holder.addChild(title_tf);
			
			TFUtil.prepTF(sub_tf, false);
			sub_tf.alpha = SUB_ALPHA;
			holder.addChild(sub_tf);
			
			//tooltip text
			TFUtil.prepTF(tip_tf, false);
			tip_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			tip_tf.alpha = CSSManager.instance.getNumberValueFromStyle('imagination_menu_tip', 'alpha', 1);
			tip_holder.addChild(tip_tf);
			
			//mouse
			enabled = true;
			mouseChildren = false;
			
			is_built = true;
		}
		
		public function show():Boolean {
			if(sound_id && parent){
				SoundMaster.instance.playSound(sound_id);
			}
			return true;
		}
		
		public function hide():void {
			
		}
		
		protected function setTitle(txt:String):void {
			title_tf.htmlText = '<p class="imagination_menu_title">'+txt+'</p>';
			if(cloud && cloud.is_loaded) title_tf.x = int(cloud.width/2 - title_tf.width/2);
		}
		
		protected function setSubText(txt:String):void {
			sub_tf.htmlText = '<p class="imagination_menu_sub">'+txt+'</p>';
			if(cloud && cloud.is_loaded) sub_tf.x = int(cloud.width/2 - sub_tf.width/2);
		}
		
		protected function setImageInMask(img_url:String):void {
			if(this.img_url == img_url) return;
			this.img_url = img_url;
			
			//go get stuff
			SpriteUtil.clean(img_holder);
			holder.addChild(spinner);
			AssetManager.instance.loadBitmapFromWeb(img_url, onImageLoad, 'iMG Menu');
		}
		
		protected function setCloudByType(type:String):void {
			if(cloud && !cloud.is_loaded){
				//no clouds?! This shouldn't happen, but better safe than sorry
				StageBeacon.setTimeout(setCloudByType, 500, type);
				return;
			}
			this.type = type;
			
			cloud = new Cloud(type);
			cloud.y = int(title_tf.y + title_tf.height + 7);
			holder.addChildAt(cloud, 0);
			
			//setup the bitmap for the hover filter
			const buffer_w:int = 6;
			const cloud_rect:Rectangle = cloud.getBounds(cloud);
			const matrix:Matrix = new Matrix();
			matrix.translate(buffer_w, buffer_w);
			cloud_rect.width += buffer_w*2;
			cloud_rect.height += buffer_w*2;
			const bm_data:BitmapData = new BitmapData(cloud_rect.width, cloud_rect.height, true, 0);
			// crank up the colors so we get a hard edge for the glow filter
			bm_data.draw(cloud, matrix, new ColorTransform(1,1,1,1, 150,150,150,170));
			// but smooth the edge so it's not jagged
			bm_data.applyFilter(bm_data, bm_data.rect, ORIGIN, new BlurFilter(1.5, 1.5));
			if (cloud_hover && cloud_hover.bitmapData) cloud_hover.bitmapData.dispose();
			cloud_hover = new Bitmap(bm_data);
			cloud_hover.x = -buffer_w;
			cloud_hover.y = cloud.y - buffer_w;
			cloud_hover.alpha = 0;
			cloud_hover.filters = StaticFilters.tsSpriteKnockout_GlowA;
			holder.addChildAt(cloud_hover, 0);
			
			//set the right alpha for the cloud
			cloud.alpha = CLOUD_ALPHA;
			
			//move the titles if we've got em
			title_tf.x = int(cloud.width/2 - title_tf.width/2);
			sub_tf.y = int(cloud.y + cloud.height + 3);
			sub_tf.x = int(cloud.width/2 - sub_tf.width/2);
			
			spinner.x = (holder.width - spinner.width)/2;
			spinner.y = (holder.height)/2;
		}
		
		public function setTipText(txt:String):void {
			//shortcut method
			tip_txt = txt;
			drawTip(true);
		}
		
		protected function drawTip(force:Boolean = false):void {
			if(!tip_txt){
				if(tip_holder.parent) tip_holder.parent.removeChild(tip_holder);
				return;
			}
			const vag_ok:Boolean = StringUtil.VagCanRender(tip_txt);
			var display_txt:String = tip_txt;
			
			tip_tf.embedFonts = vag_ok;
			if(!vag_ok) display_txt = '<font face="Arial">'+tip_txt+'</font>';
			tip_tf.htmlText = '<p class="imagination_menu_tip">'+display_txt+'</p>';
			
			/*
			var g:Graphics = tip_holder.graphics;
			g.clear();
			g.beginFill(tip_color);
			g.drawRoundRect(0, 0, tip_tf.width + tip_tf.x*2, tip_tf.height + tip_tf.y*2, 6);
			*/
			
			//add it to the holder if it's not there and we are in focus
			if(!tip_holder.parent && (is_focused || force)) holder.addChild(tip_holder);
			tip_holder.x = int(cloud.width/2 - tip_holder.width/2);
			tip_holder.y = int(cloud.y + cloud.height + 15);
		}
		
		protected function onImageLoad(filename:String, bm:Bitmap):void {
			if(!cloud){
				//no cloud yet, wtf charles.
				StageBeacon.setTimeout(onImageLoad, 300, filename, bm);
				return;
			}
			
			// hide loading spinner
			if (spinner.parent) spinner.parent.removeChild(spinner);
			
			if (!bm) {
				// when a load error occurs, report it and tag it
				BootError.handleError(this+' ImgMenuElement given bad image URL: '+filename, new Error('Missing image'), ['cdn'], true);
				bm = new Bitmap();
			}
			
			//add the image to the cloud, scaled and junk
			cloud_mask = new Cloud(type);
			var scale:Number = cloud.height/bm.height;
			bm.smoothing = true;
			bm.scaleX = bm.scaleY = scale;
			if(bm.width < cloud.width){
				//if the image isn't wide enough to fit it in the cloud, scale by width and center vertically
				bm.scaleX = bm.scaleY = 1;
				scale = cloud.width/bm.width;
				bm.scaleX = bm.scaleY = scale;
				bm.y = int(cloud.height/2 - bm.height/2);
			}
			bm.x = int(cloud.width/2 - bm.width/2);
			
			img_holder.mask = cloud_mask;
			img_holder.y = cloud.y;
			img_holder.addChild(cloud_mask);
			img_holder.addChild(bm);
			if (img_holder_bitmap && img_holder_bitmap.bitmapData) img_holder_bitmap.bitmapData.dispose();
			img_holder_bitmap = bm;
			
			holder.addChildAt(img_holder, holder.getChildIndex(cloud)+1);
		}
		
		public function set focused(value:Boolean):void {
			if(is_focused == value) return;
			
			is_focused = value;
			
			sub_tf.alpha = value ? SUB_ALPHA_HOVER : SUB_ALPHA;
			if(cloud_hover){
				if(enabled) {
					TSTweener.addTween(cloud_hover, {alpha:value ? 1 : 0, time:.1, transition:'linear'});
				}
				else if(!enabled && cloud_hover.alpha > 0){
					//this was enabled, but got disabled, turn off the cloud alpha
					cloud_hover.alpha = 0;
				}
			}
			
			//see if we need to display the tooltip
			if(enabled && value && tip_txt){
				holder.addChild(tip_holder);
				drawTip();
				tip_holder.alpha = 0;
				TSTweener.addTween(tip_holder, {alpha:1, time:.1, transition:'linear'});
			}
			else if(holder.contains(tip_holder)){
				TSTweener.addTween(tip_holder, {alpha:0, time:.1, transition:'linear',
					onComplete:function():void {
						if(holder.contains(tip_holder)) holder.removeChild(tip_holder);
					}
				});
			}
			
			if(value && sound_id) SoundMaster.instance.playSound(sound_id);
		}
		
		override public function get width():Number {
			if(cloud && cloud.is_loaded) return cloud.width;
			return super.width;
		}
		
		override public function get height():Number {
			return sub_tf.y + sub_tf.height;
		}
		
		public function get cloud_base_y():Number {
			//find the Y value for the base of the cloud
			if(cloud && cloud.is_loaded){
				return cloud.y + cloud.height;
			}
			else {
				return height;
			}
		}
		
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void {
			_enabled = value;
			holder.alpha = value ? 1 : DISABLED_ALPHA;
			useHandCursor = buttonMode = value;
		}
	}
}