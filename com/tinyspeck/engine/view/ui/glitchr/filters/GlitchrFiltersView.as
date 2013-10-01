package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	/**
	 * A view that contains filter preview thumbnails.  Applies filters to both the snapshot preview and output
	 * bitmap when a thumbnail is clicked.
	 */
	public class GlitchrFiltersView extends HorizScrollingContainer {
		
		public static const FILTERS_VIEW_HEIGHT:Number = 40;
		
		private static const THUMBNAIL_MARGIN:Number = 15;
		private const thumbnails:Vector.<FilterThumbnailView> = new Vector.<FilterThumbnailView>();
		private const bmdCopyHelper:Point = new Point();
		
		private var _snapshotPreviewBitmap:Bitmap;
		private var _outputBitmap:Bitmap;
		private var snapshotCopyNoFilters:Bitmap;	// keep a copy of original to clear overlays.
		private var outputBitmapData:BitmapData;
		private var originalFilterComponents:Array;
		private var selectedThumbnail:FilterThumbnailView;
		private var glitchrFilters:Vector.<GlitchrFilter>;
		
		public function GlitchrFiltersView(outputBitmap:Bitmap, maxPageWidth:Number, glitchrFilters:Vector.<GlitchrFilter>) {
			super(maxPageWidth, 20, 0);
			
			_outputBitmap = outputBitmap;
			outputBitmapData = new BitmapData(_outputBitmap.width, _outputBitmap.height, true, 0);
			originalFilterComponents = _outputBitmap.filters;
			this.glitchrFilters = glitchrFilters;
		}
		
		private function setupFilterThumbnails():void {
			
			// original
			addThumbnailForFilter(new GlitchrFilter("", "Normal", originalFilterComponents), true, true);
			
			for each (var filter:GlitchrFilter in glitchrFilters) {
				addThumbnailForFilter(filter);
			}
		}
		
		private function addThumbnailForFilter(glitchrFilter:GlitchrFilter, selected:Boolean = false, adjustable:Boolean = false):void {
			
			var thumbnail:FilterThumbnailView = new FilterThumbnailView(_outputBitmap.bitmapData, glitchrFilter, adjustable);
			
			appendChild(thumbnail, THUMBNAIL_MARGIN, FilterThumbnailView.UNHIGHLIGHTED_DIMENSION);
			thumbnails.push(thumbnail);
			
			thumbnail.clicked.add(onThumbnailClicked);
			
			if (selected) {
				selectedThumbnail = thumbnail;
				selectedThumbnail.selected = true;
				selectedThumbnail.scaleUp();
				selectedThumbnail.filterAlphaChanged.add(onFilterAlphaChanged);
			}
		}
		
		/** Applies thumbnail's filters to snapshot preview and output Bitmaps */
		private function onThumbnailClicked(thumbnail:FilterThumbnailView):void {
			
			if (!_snapshotPreviewBitmap) {
				throw new Error("A snap shot Bitmap has not been specified.");
			}
			
			if (selectedThumbnail == thumbnail) return;
			
			if (selectedThumbnail) {
				selectedThumbnail.selected = false;
				selectedThumbnail.filterAlphaChanged.remove(onFilterAlphaChanged);
			}
			
			selectedThumbnail = thumbnail;
			selectedThumbnail.selected = true;
			selectedThumbnail.filterAlphaChanged.add(onFilterAlphaChanged);
			
			var glitchrFilter:GlitchrFilter = thumbnail.glitchrFilter;
			bakeFiltersAndOverlaysToSnapshot(glitchrFilter, glitchrFilter.defaultAlpha);
		}
		
		/** Update the snapshot preview with the new alpha */
		private function onFilterAlphaChanged(newAlpha:Number):void {
			bakeFiltersAndOverlaysToSnapshot(selectedThumbnail.glitchrFilter, newAlpha);
		}
		
		private function bakeFiltersAndOverlaysToSnapshot(glitchrFilter:GlitchrFilter, alpha:Number = 1.0):void {
			var alphaTransform:ColorTransform = new ColorTransform(); // use a colortransform to apply filter alpha
			alphaTransform.alphaMultiplier = alpha;
			
			snapshotCopyNoFilters.filters = glitchrFilter.components;
			_snapshotPreviewBitmap.bitmapData.fillRect(_snapshotPreviewBitmap.bitmapData.rect, 0);
			_snapshotPreviewBitmap.bitmapData.draw(snapshotCopyNoFilters, null, alphaTransform);
			snapshotCopyNoFilters.filters = [];
			
			GlitchrFilterUtils.drawOverlaysToBitmapData(glitchrFilter, _snapshotPreviewBitmap.bitmapData, alpha);
		}
		
		override public function dispose():void {
			if (_outputBitmap) _outputBitmap.filters = [];
			if (_snapshotPreviewBitmap) _snapshotPreviewBitmap.filters = [];
			
			if (snapshotCopyNoFilters) {
				snapshotCopyNoFilters.parent.removeChild(snapshotCopyNoFilters);
				snapshotCopyNoFilters.bitmapData.dispose();
			}
		}

		public function set snapshotPreviewBitmap(value:Bitmap):void { 
			setupFilterThumbnails();
			_snapshotPreviewBitmap = value;
			copySnapshotBMD();
		}
		
		private function copySnapshotBMD():void {
			var snapshotBMD:BitmapData = _snapshotPreviewBitmap.bitmapData;
			var snapshotBMDCopy:BitmapData = new BitmapData(snapshotBMD.width, snapshotBMD.height, true, 0);
			snapshotBMDCopy.copyPixels(snapshotBMD, snapshotBMD.rect, bmdCopyHelper);
			snapshotCopyNoFilters = new Bitmap(snapshotBMDCopy, "auto", true);
			snapshotCopyNoFilters.visible = visible;
			
			// add a copy of the snapshot behind the original.  As filter alpha is reduced this copy will start to show through.
			var snapshotIndex:uint = _snapshotPreviewBitmap.parent.getChildIndex(_snapshotPreviewBitmap);
			_snapshotPreviewBitmap.parent.addChildAt(snapshotCopyNoFilters, snapshotIndex);
		}
		
		public function set outputBitmap(value:Bitmap):void { _outputBitmap = value; }
		
		/** Applies chosen Bitmap filters to BitmapData */
		public function getOutputBitmapData():BitmapData {
			
			_outputBitmap.filters = selectedThumbnail.glitchrFilter.components;
			
			var outputBMD:BitmapData = _outputBitmap.bitmapData;
			var bakedBMD:BitmapData = _outputBitmap.bitmapData.clone();	// cloning will make it so the orignal shows through when filter alphas are reduced
			var alphaTransform:ColorTransform = new ColorTransform(); // use a colortransform to apply filter alpha
			alphaTransform.alphaMultiplier = selectedThumbnail.filterAlpha;
			bakedBMD.draw(_outputBitmap, null, alphaTransform);
			GlitchrFilterUtils.drawOverlaysToBitmapData(selectedThumbnail.glitchrFilter, bakedBMD, selectedThumbnail.filterAlpha);
			
			return bakedBMD;
		}
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			 if (snapshotCopyNoFilters) {
				 snapshotCopyNoFilters.visible = value;
			 }
		}
		
		public function getSelectedGlitchrFilter():GlitchrFilter {
			return selectedThumbnail.glitchrFilter;
		}
	}
}