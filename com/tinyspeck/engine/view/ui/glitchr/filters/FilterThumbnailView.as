package com.tinyspeck.engine.view.ui.glitchr.filters {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Consists of a preview bitmap, a selection box and a hitbox for mouse events.  Both the bitmap and selection box scale when
	 * moused over, however the hitbox scale remains the same.
	 */ 
	public class FilterThumbnailView extends Sprite {

		public static const UNHIGHLIGHTED_DIMENSION:Number = 46;
		
		[Embed("../../../../../../../assets/filterthumb.png")]
		public static const ThumbnailBitmap:Class;
		
		private static const FILTER_SCALEUP_DIMENSION:Number = 300;
		private static const HIGHLIGHTED_DIMENSION:Number = 1.1 * UNHIGHLIGHTED_DIMENSION;
		private static const UNHIGHLIGHTED_SCALE:Number = UNHIGHLIGHTED_DIMENSION / HIGHLIGHTED_DIMENSION;
		private static const THUMBNAIL_SCALE_DURATION:Number = 0.2; // seconds
		private static const NAME_TEXT_MARGIN:Number = UNHIGHLIGHTED_DIMENSION + 2;
		private static const SELECTION_COLOR:uint = 0xffffff;
		private static const SELECTION_OUTLINE_COLOR:uint = 0xd88300;
		private static const SELECTION_OUTLINE_THICKNESS:uint = 1;
		private static const BORDER_WIDTH:Number = 4;
		private static const BORDER_CORNER:Number = 14;
		private static const SLIDER_MARGIN:Number = -34;
		
		public const filterAlphaChanged:Signal = new Signal(Number);
		public const clicked:Signal = new Signal(FilterThumbnailView);
		
		private const selectionBox:Shape = new Shape();
		private const _hitBox:Sprite = new Sprite();
		private const selectionContainer:Sprite = new Sprite();
		
		private var thumbnailBitmap:Bitmap;
		private var nameText:TextField;
		private var _glitchrFilter:GlitchrFilter;
		private var scaleDownValue:Number = UNHIGHLIGHTED_SCALE;
		private var alphaSlider:FilterSlider;
		private var adjustable:Boolean;
		private var _filterAlpha:Number;
		
		public function FilterThumbnailView(targetBitmapData:BitmapData, glitchrFilter:GlitchrFilter, adjustable:Boolean = false) {
			_glitchrFilter = glitchrFilter;
			
			this.name = glitchrFilter.name;
			this.adjustable = adjustable;
			
			addChild(selectionContainer);
			
			setupBitmap(targetBitmapData);
			setupInteractionShapes();
			setupNameTextField();
			setupAlphaSlider();
			setupEvents();
		}
		
		private function setupNameTextField():void {
			nameText = new TextField();
			TFUtil.prepTF(nameText, false);
			updateNameTextField();
			addChild(nameText);
		}
		
		private function updateNameTextField(selected:Boolean = false):void {
			
			var cssClass:String;
			if (selected) {
				cssClass = "glitchr_filters_selected";
			} else {
				cssClass = "glitchr_filters";
			}
			
			nameText.htmlText = '<p class="'+cssClass+'">'+name+'</p>';
			nameText.x = - nameText.width / 2 + hitBox.width/2;
			nameText.y = NAME_TEXT_MARGIN;
		}
		
		private function setupBitmap(bitmapData:BitmapData):void {
						
			var fullScaleBitmap:Bitmap = new ThumbnailBitmap() as Bitmap;
			fullScaleBitmap.smoothing = true;
			var thumbScaleUp:Number = FILTER_SCALEUP_DIMENSION / fullScaleBitmap.height;
			fullScaleBitmap.filters = _glitchrFilter.components;
			
			var tmpBMD:BitmapData = new BitmapData(FILTER_SCALEUP_DIMENSION, FILTER_SCALEUP_DIMENSION, true, 0);
			var scaleUpMatrix:Matrix = new Matrix();
			scaleUpMatrix.scale(thumbScaleUp, thumbScaleUp);
			tmpBMD.draw(fullScaleBitmap, scaleUpMatrix);
			
			// draw overlays
			GlitchrFilterUtils.drawOverlaysToBitmapData(glitchrFilter, tmpBMD);
			
			var tmpBitmap:Bitmap = new Bitmap(tmpBMD);
			tmpBitmap.smoothing = true;
			
			var drawScale:Number = HIGHLIGHTED_DIMENSION / FILTER_SCALEUP_DIMENSION;
			var thumbnailBMD:BitmapData = new BitmapData(HIGHLIGHTED_DIMENSION, HIGHLIGHTED_DIMENSION, true, 0);
			var scaleMat:Matrix = new Matrix();
			scaleMat.scale(drawScale, drawScale);
			thumbnailBMD.draw(tmpBitmap, scaleMat);
			tmpBitmap.bitmapData.dispose();
			
			thumbnailBitmap = new Bitmap(thumbnailBMD, "auto", true);
			thumbnailBitmap.x = - thumbnailBitmap.width/2;
			thumbnailBitmap.y = - thumbnailBitmap.height;
			
			selectionContainer.addChild(thumbnailBitmap);
		}
		
		private function setupInteractionShapes():void {

			selectionBox.graphics.beginFill(SELECTION_COLOR);
			selectionBox.graphics.lineStyle(SELECTION_OUTLINE_THICKNESS, SELECTION_OUTLINE_COLOR);
			selectionBox.graphics.drawRoundRect(0, 0, thumbnailBitmap.width + BORDER_WIDTH*2, thumbnailBitmap.height + BORDER_WIDTH*2, BORDER_CORNER, BORDER_CORNER);
			selectionBox.graphics.endFill();
			selectionBox.x = - selectionBox.width/2 + SELECTION_OUTLINE_THICKNESS/2;
			selectionBox.y = - selectionBox.height + BORDER_WIDTH + SELECTION_OUTLINE_THICKNESS;
			selectionBox.visible = false;
			selectionContainer.addChildAt(selectionBox, 0);
			
			var border:Sprite = new Sprite();
			border.graphics.beginFill(0xffffff);
			border.graphics.drawRoundRect(0, 0, thumbnailBitmap.width + BORDER_WIDTH*2, thumbnailBitmap.height + BORDER_WIDTH*2, BORDER_CORNER, BORDER_CORNER);
			border.graphics.endFill();
			border.x = -border.width/2;
			border.y = -border.height + BORDER_WIDTH;
			selectionContainer.addChildAt(border, 0);
			
			selectionContainer.scaleX = selectionContainer.scaleY = UNHIGHLIGHTED_SCALE;
			
			selectionContainer.x = thumbnailBitmap.width/2 - BORDER_WIDTH/2;
			selectionContainer.y = thumbnailBitmap.height - BORDER_WIDTH;
			
			// draw hitbox with unhighlighted bitmap dimensions.
			_hitBox.graphics.beginFill(0xff0000, 0);
			_hitBox.graphics.drawRect(0, 0, thumbnailBitmap.width * UNHIGHLIGHTED_SCALE, thumbnailBitmap.height * UNHIGHLIGHTED_SCALE);
			_hitBox.graphics.endFill();
			_hitBox.buttonMode = true;
			addChild(_hitBox);
		}
		
		private function setupAlphaSlider():void {

			alphaSlider = new FilterSlider();
			alphaSlider.setSliderParams(0, 1, glitchrFilter.defaultAlpha);
			alphaSlider.x = -alphaSlider.width/2 + hitBox.width/2;
			alphaSlider.y = SLIDER_MARGIN;
			addChild(alphaSlider);
			
			alphaSlider.addEventListener(Event.CHANGE, onAlphaSliderChanged);
			alphaSlider.visible = false;
			
			_filterAlpha = glitchrFilter.defaultAlpha;
		}
		
		private function onAlphaSliderChanged(e:Event):void {
			_filterAlpha = alphaSlider.value;
			filterAlphaChanged.dispatch(alphaSlider.value);
		}
		
		private function setupEvents():void {
			_hitBox.addEventListener(MouseEvent.ROLL_OVER, scaleUp, false, 0, true);
			_hitBox.addEventListener(MouseEvent.ROLL_OUT, scaleDown, false, 0, true);
			
			addEventListener(MouseEvent.CLICK, onClicked);
		}
		
		public function scaleUp(e:MouseEvent = null):void {
			TSTweener.removeTweens(selectionContainer);
			TSTweener.addTween(selectionContainer, {scaleX:1, scaleY:1, time:THUMBNAIL_SCALE_DURATION, transition:'easeinoutquad'});
			
			//Brings the thumbnail to the front when it is rolled over
			if (parent) parent.setChildIndex(this, (parent.numChildren - 1));
		}
		
		public function scaleDown(e:MouseEvent = null):void {
			TSTweener.removeTweens(selectionContainer);
			TSTweener.addTween(selectionContainer, {scaleX:scaleDownValue, scaleY:scaleDownValue, time:THUMBNAIL_SCALE_DURATION, transition:'easeinoutquad'});
		}
		
		private function onClicked(e:MouseEvent):void {
			clicked.dispatch(this);
		}
		
		public function set selected(value:Boolean):void {
			
			if (value) {
				scaleDownValue = 1;
			} else {
				scaleDownValue = UNHIGHLIGHTED_SCALE;
				scaleDown();
			}

			updateNameTextField(value);
			
			alphaSlider.visible = value && !adjustable;
			selectionBox.visible = value;
		}

		public function get glitchrFilter():GlitchrFilter { return _glitchrFilter; }
		public function get hitBox():Sprite { return _hitBox; }
		public function get filterAlpha():Number { return _filterAlpha; }
	}
}