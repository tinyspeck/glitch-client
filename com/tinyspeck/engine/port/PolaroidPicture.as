package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class PolaroidPicture extends Sprite
	{			
		private var label_tf:TextField;
		
		private var bg_color:uint = 0xffffff;
		private var border_width:uint = 4;
		private var corner_radius:uint = 8;
		
		private var all_holder:Sprite = new Sprite();
		private var image_bg:Sprite = new Sprite();
		private var image_mask:Sprite = new Sprite();
		private var image_holder:Sprite = new Sprite();
		
		private var image_url:String;
		
		private var is_centered:Boolean;
		private var image_scale:Number = 1;
		
		private var _w:int;
		private var _h:int;
		private var _label:String;
		
		/**
		 * Create a Polaroid(r) picture! w / h are the IMAGE dimensions and the border_width is added around it 
		 * (and extra on the bottom if there is a label).
		 * @param w
		 * @param h
		 * @param label - Optional label to show under the image
		 * @param registration_point - use SpriteUtil to define if you want top left or center
		 */		
		public function PolaroidPicture(w:int, h:int, label:String = '', registration_point:String = null){
			_w = w;
			_h = h;
			_label = label;
			
			construct();
			SpriteUtil.setRegistrationPoint(all_holder, (registration_point ? registration_point : SpriteUtil.REGISTRATION_CENTER));
		}
		
		private function construct():void {
			var cssm:CSSManager = CSSManager.instance;
			bg_color = cssm.getUintColorValueFromStyle('polaroid', 'backgroundColor', bg_color);
			border_width = cssm.getNumberValueFromStyle('polaroid', 'borderWidth', border_width);
			corner_radius = cssm.getNumberValueFromStyle('polaroid', 'cornerRadius', corner_radius);
			
			addChild(all_holder);
			
			all_holder.addChild(image_bg);
			
			image_holder.x = border_width;
			image_holder.y = border_width;
			image_holder.mask = image_mask;
			image_holder.addChild(image_mask);
			all_holder.addChild(image_holder);
			
			all_holder.filters = StaticFilters.polaroidPictureBorder_DropShadowA;
			
			//set the label after everything is done to force the draw()
			label = _label;
		}
		
		private function draw():void {
			var g:Graphics = all_holder.graphics;
			g.clear();
			g.beginFill(bg_color);
			g.drawRoundRect(0, 0, width, height, corner_radius);
			
			g = image_bg.graphics;
			g.clear();
			g.beginFill(0x232323);
			g.drawRoundRect(border_width, border_width, _w, _h, corner_radius);
			
			g = image_mask.graphics;
			g.clear();
			g.beginFill(0x232323);
			g.drawRoundRect(0, 0, _w, _h, corner_radius);
		}
		
		public function clearPicture():void {
			label = '';
			SpriteUtil.clean(image_holder, true, 1);
		}
		
		/**
		 * Put something in the picture. 
		 * @param DO
		 * @param centered
		 * @param scale
		 */		
		public function setPicture(bm:Bitmap, centered:Boolean = true, scale:Number = 1):void {
			is_centered = centered;
			
			bm.smoothing = true;
			bm.scaleX = bm.scaleY = image_scale = scale;
			
			//clear the URL since we've replaced the image type
			image_url = null;
			
			showImage(bm);
		}
		
		/**
		 * Load anything that a Loader can load and place it in the picture.
		 * @param url
		 * @param centered
		 * @param scale
		 * WARNING: if loading an image file JPG/PNG/GIF etc. setting 'scale' to anything but 1 may make things look like shit
		 */		
		public function setPictureURL(url:String, centered:Boolean = true, scale:Number = 1):void {
			is_centered = centered;
			image_scale = scale;
			
			if(image_url != url){
				SpriteUtil.clean(image_holder, true, 1);
				
				AssetManager.instance.loadBitmapFromWeb(url, onImageComplete, 'Polaroid needs a picture');
			}
			else {
				//just show what is already there
				animateImage();
			}
		}
		
		private function onImageComplete(filename:String, bm:Bitmap):void {			
			if(bm){
				bm.smoothing = true;
				bm.scaleX = bm.scaleY = image_scale;
				
				showImage(bm);
				
				//set the URL only after it's loaded
				image_url = filename;
			} else {
				CONFIG::debugging {
					Console.warn('Something bad happened onImageComplete');
				}
			}
		}
		
		private function showImage(DO:DisplayObject):void {
			SpriteUtil.clean(image_holder, true, 1);
			
			if(is_centered){
				DO.x = int(image_bg.width/2 - DO.width/2);
				DO.y = int(image_bg.height/2 - DO.height/2);
			}
			
			image_holder.addChild(DO);
			
			animateImage();
		}
		
		private function animateImage():void {
			image_holder.alpha = 0;
			
			//fade in the pic like a polaroid
			TSTweener.addTween(image_holder, {alpha:1, time:.5, transition:'linear'});
		}
		
		/**
		 * Returns the width of the IMAGE ONLY 
		 * @return width of the image
		 */		
		public function get w():int { return _w; }
		public function set w(value:int):void {
			_w = w;
			draw();
		}
		
		/**
		 * Returns the height of the IMAGE ONLY 
		 * @return height of the image
		 */	
		public function get h():int { return _h; }
		public function set h(value:int):void {
			_h = h;
			draw();
		}
		
		override public function get width():Number {
			return _w + border_width*2;
		}
		
		override public function get height():Number {
			return _h + border_width*3 + int(label_tf.height); //3 puts the border gap below the TF
		}
		
		public function get label():String { return _label; }
		public function set label(value:String):void {
			_label = value;
			
			//fucking textfields that have a width already force wordwrap on a space? Really?
			//guess we'll have to make a new one everytime the label fucking changes
			if(label_tf) all_holder.removeChild(label_tf);
			label_tf = new TextField();
			TFUtil.prepTF(label_tf);
			label_tf.x = border_width;
			label_tf.y = _h + border_width*2;
			label_tf.htmlText = '<p class="polaroid_label">'+_label+'</p>';
			label_tf.width = _w;
			all_holder.addChild(label_tf);
			
			draw();
		}
		
		public function set registration_point(value:String):void {
			SpriteUtil.setRegistrationPoint(all_holder, value);
		}
	}
}