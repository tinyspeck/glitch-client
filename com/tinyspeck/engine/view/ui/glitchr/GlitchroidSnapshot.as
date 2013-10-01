package com.tinyspeck.engine.view.ui.glitchr
{
import com.tinyspeck.tstweener.TSTweener;

import com.tinyspeck.engine.event.TSEvent;
import com.tinyspeck.engine.memory.EnginePools;
import com.tinyspeck.engine.model.TSModelLocator;
import com.tinyspeck.engine.port.CSSManager;
import com.tinyspeck.engine.util.MathUtil;
import com.tinyspeck.engine.util.SpriteUtil;
import com.tinyspeck.engine.util.StringUtil;
import com.tinyspeck.engine.util.TFUtil;
import com.tinyspeck.engine.view.ui.glitchr.filters.GlitchrFiltersView;
import com.tinyspeck.engine.view.util.StaticFilters;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.GradientType;
import flash.display.Graphics;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.BitmapFilterQuality;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.TextField;

public class GlitchroidSnapshot extends Sprite
{
	/* singleton boilerplate */
	public static const instance:GlitchroidSnapshot = new GlitchroidSnapshot();
		
	private static const DEFAULT_CAPTION:String = "click to enter a caption...";
	private static const INNER_GLOW:GlowFilter = new GlowFilter(0x000000, 0.2, 49, 49, 2, BitmapFilterQuality.MEDIUM, true);
	private static const INNER_GLOW_ARRAY:Array = [INNER_GLOW];
	private static const MAX_CHARS_TO_DISPLAY:uint = 100;
	
	// holders
	private const all_holder:Sprite = new Sprite();
	private const caption_holder:Sprite = new Sprite();
	private const filter_view_holder:Sprite = new Sprite();
	private const image_holder:Sprite = new Sprite();
	private const image_holder_bg:Sprite = new Sprite();
	private const image_bitmap:Bitmap = new Bitmap();
	private const caption_tf:TextField = new TextField();
	private const caption_bm:Bitmap = new Bitmap();
	
	// from CSS
	private var caption_height:uint = 46;
	private var filter_view_height:uint = GlitchrFiltersView.FILTERS_VIEW_HEIGHT;
	private var filter_view_margin_top:uint = 5;
	private var filter_view_margin_bottom:uint = 5;
	private var border_width:uint = 17;
	
	// computed dimensions
	private var image_width:uint;
	private var image_height:uint;
	private var _w:int;
	private var _h:int;
	
	private var _caption:String;
	private var _filtersView:GlitchrFiltersView;
	private var model:TSModelLocator;
	
	public function GlitchroidSnapshot() {
		CONFIG::god {
			if(instance) throw new Error('Singleton');
		}
		
		model = TSModelLocator.instance;
		
		// init css
		const cssm:CSSManager = CSSManager.instance;
		border_width = cssm.getNumberValueFromStyle('glitchroid', 'borderWidth', border_width);
		caption_height = cssm.getNumberValueFromStyle('glitchroid', 'captionHeight', caption_height);
		
		// init displaylist
		caption_holder.addChild(caption_bm);
		image_holder.addChild(image_holder_bg);
		image_holder.addChild(image_bitmap);
		
		all_holder.addChild(image_holder);
		all_holder.addChild(caption_holder);
		if (model.flashVarModel.use_glitchr_filters) {
			all_holder.addChild(filter_view_holder);
		}
		
		addChild(all_holder);
		
		all_holder.filters = StaticFilters.glitchrPolaroidPicture_GlowA;

		//tf
		TFUtil.prepTF(caption_tf);
		caption_tf.mouseEnabled = false;
		caption_tf.embedFonts = false;
		
		caption_holder.useHandCursor = true;
		caption_holder.buttonMode = true;
		caption_holder.addEventListener(MouseEvent.CLICK, onCaptionClick, false, 0, true);
		
		// init look and feel
		setSize(100, 100, 100, 100);
		caption = DEFAULT_CAPTION;
		refresh();
	}
	
	private function get caption_width():uint {
		return (_w - 2*border_width);
	}
	
	private function refresh():void {
		redrawCaption();
		
		// position UI elements
		image_holder.x = border_width;
		image_holder.y = border_width;
		image_bitmap.width = image_width;
		image_bitmap.height = image_height;
		caption_holder.x = border_width;
		caption_holder.y = int(_h - border_width - caption_height);
		if (model.flashVarModel.use_glitchr_filters) {
			filter_view_holder.y = border_width + image_height + filter_view_margin_top;
		}
		caption_bm.x = int(caption_width/2 - caption_bm.width/2);
		caption_bm.y = int(caption_height/2 - caption_bm.height/2);
		
		var m:Matrix = EnginePools.MatrixPool.borrowObject();
		
		// draw polaroid background
		var g:Graphics = all_holder.graphics;
		g.clear();
		m.createGradientBox(_w, _h, 45 * MathUtil.DEG_TO_RAD);
		g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xe6ecee], [1, 1], [0, 255], m);
		g.drawRect(0, 0, _w, _h);
		image_holder_bg.filters = INNER_GLOW_ARRAY;

		// draw image background
		g = image_holder_bg.graphics;
		g.clear();
		g.beginFill(0x181818);
		g.drawRect(0, 0, image_width, image_height);
		m.createGradientBox(image_width, image_height, 45 * MathUtil.DEG_TO_RAD);
		g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0x000000], [0.26, 0.26], [0, 255], m);
		g.drawRect(0, 0, image_width, image_height);
		image_holder_bg.filters = INNER_GLOW_ARRAY;
		
		EnginePools.MatrixPool.returnObject(m);
		
		// The image filters view use a mask, which causes incorrect bounds to be used when trying to center the all_holder
		if (model.flashVarModel.use_glitchr_filters) all_holder.removeChild(filter_view_holder);
		SpriteUtil.setRegistrationPoint(all_holder, SpriteUtil.REGISTRATION_CENTER);
		if (model.flashVarModel.use_glitchr_filters) all_holder.addChild(filter_view_holder);
	}
	
	private function redrawCaption():void {
		var label_class:String = "glitchroid_label";
		if (_caption == DEFAULT_CAPTION) {
			label_class = "glitchroid_label_empty";
		}
		
		caption_tf.width = caption_width;
		caption_tf.htmlText = '<span class="' + label_class + '">'+StringUtil.encodeHTMLUnsafeChars(_caption)+'</span>';
		//caption_tf.htmlText = '<span class="' + label_class + '">'+StringUtil.truncate(StringUtil.encodeHTMLUnsafeChars(_caption), 200)+'</span>';
		caption_holder.alpha = CSSManager.instance.getNumberValueFromStyle(label_class, 'alpha', 0.8);
		
		// cut off at approximately three lines of text
	    if (caption_tf.numLines > 3) {
	        var char:int = caption_tf.getLineOffset(3) - 1 - 3;
	        caption_tf.htmlText = '<span class="' + label_class + '">'+StringUtil.encodeHTMLUnsafeChars(_caption.substring(0, char))+'...</span>';
	    }
		
		// keep increasing the line width until all the lines fit the bitmap:
		// the trick is that we're going to scale the text field's width to fit
		// the bitmap it's in, so we can actually make the line wider than that
		// bitmap and reduce the scale to fit a wider line in the same space
		var scale:Number = (caption_width / caption_tf.width);
		while ((scale * caption_tf.height) > caption_height) {
			// widen line
			caption_tf.width += 100;
			// compute the new scale
			scale = (caption_width / caption_tf.width);
		}
		
		// re-use or dispose existing bmd
		var bm_data:BitmapData = caption_bm.bitmapData;
		if (bm_data) {
				//trace('DISPOSE');
			if ((bm_data.width != caption_width) || (bm_data.height != caption_height)) {
				bm_data.dispose();
				bm_data = null;
			} else {
				//trace('REUSE');
				bm_data.fillRect(bm_data.rect, 0);
			}
		}
		
		if (!bm_data) {
			bm_data = new BitmapData(caption_width, caption_height, true, 0);
		}
		
		var m:Matrix = EnginePools.MatrixPool.borrowObject();
		m.scale(scale, scale);
		bm_data.draw(caption_tf, m, null, null, null, true);
		EnginePools.MatrixPool.returnObject(m);
		
		caption_bm.bitmapData = bm_data;
		caption_bm.smoothing = true;
		caption_bm.pixelSnapping = PixelSnapping.ALWAYS;
	}
	
	public function setSize(targetImageWidth:uint, targetImageHeight:uint, maxPolaroidWidth:uint, maxPolaroidHeight:uint):void {
		// build a model of a polaroid where the interior image is at its
		// native resolution and grab the aspect ratio
		_w = 2*border_width + targetImageWidth;
		_h = 3*border_width + caption_height + targetImageHeight;
		if (model.flashVarModel.use_glitchr_filters &&model.worldModel.pc &&  model.worldModel.pc.cam_filters.length) {
			_h += filter_view_margin_top + filter_view_height + filter_view_margin_bottom;
		}
		
		const targetAspectRatio:Number = (_w / _h);

		// take the aspect ratio of the max dimensions
		const maxAspectRatio:Number = (maxPolaroidWidth / maxPolaroidHeight);
		
		// shrink the max dimensions to fit the target aspect ratio
		if (targetAspectRatio > maxAspectRatio) {
			// max dims are wider than target, reduce height
			_w = maxPolaroidWidth;
			_h = maxPolaroidWidth / targetAspectRatio;
		} else {
			// max dims are taller than target, reduce width
			_w = maxPolaroidHeight * targetAspectRatio;
			_h = maxPolaroidHeight;
		}

		// now invert the math to find the dimensions of the interior image
		image_width  = _w - 2*border_width;
		image_height = _h - 3*border_width - caption_height;
		if (model.flashVarModel.use_glitchr_filters && model.worldModel.pc && model.worldModel.pc.cam_filters.length) {
			image_height -= filter_view_margin_top + filter_view_height;
		}
		
		refresh();
	}
	
	public function clearPicture():void {
		caption = DEFAULT_CAPTION;
		image_holder_bg.alpha = 1;
		if (image_bitmap.bitmapData) {
			image_bitmap.bitmapData.dispose();
		}
		
		if (_filtersView) {
			_filtersView.dispose();
			filter_view_holder.removeChild(_filtersView);
			_filtersView = null;
		}
	}
	
	public function setPicture(DO:DisplayObject):void {
		if (image_bitmap.bitmapData) {
			image_bitmap.bitmapData.dispose();
		}
		
		// shrink the image to fit
		var m:Matrix = EnginePools.MatrixPool.borrowObject();
		m.scale((image_width / DO.width), (image_height / DO.height));
		
		const new_bmd:BitmapData = new BitmapData(image_width, image_height);
		new_bmd.draw(DO, m, null, null, null, true);
		
		EnginePools.MatrixPool.returnObject(m);
		m = null;
		
		image_bitmap.bitmapData = new_bmd;
		image_bitmap.pixelSnapping = PixelSnapping.AUTO;
		image_bitmap.smoothing = true;
		
		SpriteUtil.clean(image_holder, true, 1);
		image_holder.addChild(image_bitmap);
		
		// fade in the image like a polaroid
		image_bitmap.alpha = 0;
		TSTweener.addTween(image_bitmap, {alpha:1, time:1.5, transition:'easeinoutquad', onComplete:showFitlersView});
		// cross-fade the background because it adds jagged edges to the image
		TSTweener.addTween(image_holder_bg, {alpha:0, delay:1, time:0.5, transition:'easeinoutquad'});
		
		refresh();
	}
	
	private function showFitlersView():void {
		if (!model.flashVarModel.use_glitchr_filters) return;
		if (!_filtersView) return;
		
		_filtersView.alpha = 0;
		_filtersView.visible = true;
		TSTweener.addTween(_filtersView, {alpha:1, time:0.3, transition:'easeinoutquad'});
	}
	
	public function setFiltersView(newFiltersView:GlitchrFiltersView):void {
		if (!model.flashVarModel.use_glitchr_filters) return;
		
		if (_filtersView) {
			_filtersView.dispose();
			filter_view_holder.removeChild(_filtersView);
		}
		
		newFiltersView.visible = false;
		newFiltersView.snapshotPreviewBitmap = image_bitmap;
		newFiltersView.y -= newFiltersView.height/6; // make it so that the filters view overlaps the bottom of the snapshot image.
		
		filter_view_holder.addChild(newFiltersView);
		_filtersView = newFiltersView;
		
		var filterViewBounds:Rectangle = _filtersView.getBounds(_filtersView);
		filter_view_holder.x = (_w - _filtersView.maxPageWidth) / 2;
	}
	
	/**
	 * Returns the width of the IMAGE ONLY 
	 * @return width of the image
	 */		
	public function get w():int { return _w; }
	public function set w(value:int):void {
		_w = w;
		refresh();
	}
	
	/**
	 * Returns the height of the IMAGE ONLY 
	 * @return height of the image
	 */	
	public function get h():int { return _h; }
	public function set h(value:int):void {
		_h = h;
		refresh();
	}
	
	override public function get width():Number {
		return _w;
	}
	
	override public function get height():Number {
		return _h;
	}
	
	public function get caption():String {
		return ((_caption == DEFAULT_CAPTION) ? '' : _caption);
	}
	
	public function set caption(value:String):void {
		_caption = value;
		refresh();
	}
	
	private function onCaptionClick(e:MouseEvent):void {
		dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
	}
	
	public function set registration_point(value:String):void {
		SpriteUtil.setRegistrationPoint(all_holder, value);
	}
	
	public function getFiltererdBMD():BitmapData {
		return _filtersView.getOutputBitmapData();
	}

	public function get filtersView():GlitchrFiltersView {
		return _filtersView;
	}

}
}