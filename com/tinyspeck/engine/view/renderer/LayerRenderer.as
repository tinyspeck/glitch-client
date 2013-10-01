package com.tinyspeck.engine.view.renderer
{
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.view.gameoverlay.InLocationOverlay;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	public class LayerRenderer extends DisposableSprite implements IDisposable {
		CONFIG::locodeco protected const decoToRenderer:Dictionary = new Dictionary(true);
		
		CONFIG::locodeco private var _decosDirty:Boolean;
		CONFIG::locodeco protected var _filtersDirty:Boolean;
		
		// Shapes representing end indices
		private const UNDERLAY_BELOW_DECOS:Shape = new Shape();
		protected const DECO:Shape = new Shape();
		protected const STANDALONE_DECO:Shape = new Shape();
		protected const _decoRenderers:Vector.<DecoRenderer> = new Vector.<DecoRenderer>();
		
		private var _layerData:Layer;
		
		protected var model:TSModelLocator;
		
		protected var _largeBitmap:LargeBitmap;
		
		public function LayerRenderer(layerData:Layer, useLargeBitmap:Boolean) {
			this.name = layerData.tsid;
			_layerData = layerData;
			this.model = TSModelLocator.instance;
			
			if (useLargeBitmap) createLargeBitmap();
			
			setupEndShapes();
		}
		
		/** Resets the layer for redrawing; be sure to finalize() again! */
		public function clearDecos():void {
			// if there's already a _largeBitmap, then we're using them
			if (_largeBitmap) createLargeBitmap();
			
			// dispose other potential DecoRenderers
			// (like standalones that are rendered as MovieClips above/below)
			var decoRenderer:DecoRenderer;
			for (var i:int = numChildren-1; i >= 0; --i) {
				decoRenderer = (getChildAt(i) as DecoRenderer);
				if (decoRenderer) {
					removeChildAt(i);
					decoRenderer.dispose();
				}
			}
		}
		
		protected function setupEndShapes():void {
			// add child at 0 to make sure underlay is drawn below decos in LargeBitmap
			addChildAt(UNDERLAY_BELOW_DECOS, 0);
			UNDERLAY_BELOW_DECOS.visible = false;
			UNDERLAY_BELOW_DECOS.name = 'UNDERLAY_BELOW_DECOS';
			
			addChild(DECO);
			DECO.visible = false;
			DECO.name = 'DECO';
			
			addChild(STANDALONE_DECO);
			STANDALONE_DECO.visible = false;
			STANDALONE_DECO.name = 'STANDALONE_DECO';
		}
		
		/**
		 * Only does something in experimental renderer; returns NaN or an
		 * ARGB uint otherwise
		 */
		public function getPixel32(point:Point):uint {
			return _largeBitmap.getPixel32(point);
		}
		
		/** Only does something in experimental renderer */
		public function setPixel32(point:Point, color:uint):void {
			_largeBitmap.setPixel32(point, color);
		}
		
		/** This function only clears LargeBitmap decos */
		protected function createLargeBitmap():void {
			CONFIG::god {
				if (!model.stateModel.render_mode.usesBitmaps) throw new Error();
			}
			
			var lbIndex:int = 0;
			if (_largeBitmap) {
				lbIndex = getChildIndex(_largeBitmap);
				removeChildAt(lbIndex);
				_largeBitmap.dispose();
				_largeBitmap = null;
			}
			
			_largeBitmap = new LargeBitmap(_layerData.w, _layerData.h,
				model.stateModel.render_mode.bitmapSegmentDimension, 
				0, 0);
			
			// decos don't be needin' mousin'
			_largeBitmap.mouseEnabled = false;
			_largeBitmap.mouseChildren = false;
			
			addChildAt(_largeBitmap, lbIndex);
		}
		
		override public function dispose():void {
			_layerData = null;
			_decoRenderers.length = 0;
			
			if (_largeBitmap) {
				_largeBitmap.dispose();
				_largeBitmap = null;
			}
			
			// dispose individual DecoRenderers
			var i:int;
			var decoRenderer:DecoRenderer;
			for (i = 0; i < numChildren; i++) {
				decoRenderer = (getChildAt(i) as DecoRenderer);
				if (decoRenderer) decoRenderer.dispose();
			}
			
			// do this AFTER above, since it will remove all children
			super.dispose();
			
			model = null;
		}
		
		public function setPosition(x:Number, y:Number, xOffset:Number, yOffset:Number):void {
			this.x = x + xOffset;
			this.y = y + yOffset;
		}		
		
		protected function addUnder(DO:DisplayObject, marker:DisplayObject):void {
			if (DO.parent) DO.parent.removeChild(DO);
			addChildAt(DO, getChildIndex(marker));
		}	
		
		protected function addAbove(DO:DisplayObject, marker:DisplayObject):void {
			if (DO.parent) DO.parent.removeChild(DO);
			
			var index:int;
			if (marker.parent == this) {
				index = getChildIndex(marker)+1;
				if (index >= numChildren) {
					addChild(DO);
				} else {
					addChildAt(DO, index);
				}
			} else {
				// EC: I believe this to be an error condition I must investigate http://bugs.tinyspeck.com/8294
				/*CONFIG::debugging {
					Console.info('DO:'+getQualifiedClassName(DO)+' marker:'+getQualifiedClassName(marker)+' marker.parent:'+marker.parent);
				}*/
				addChild(DO);
			}
		}
		
		public function placeOverlayBelowDecos(DO:DisplayObject):void {
			addUnder(DO as DisplayObject, UNDERLAY_BELOW_DECOS);
		}
		
		public function placeInLocationOverlay(inLocationOverlay:InLocationOverlay):void {
			addChild(inLocationOverlay as DisplayObject);
		}
		
		public function get tsid():String {
			return name;
		}
		
		public function get layerData():Layer {
			return _layerData;
		}
		
		/** Call this before making multiple calls to draw() for performance */
		public function lockBitmaps():void {
			_largeBitmap.lockBitmaps();
		}
		
		/** Call this after making multiple calls to draw() for performance */
		public function unlockBitmaps():void {
			_largeBitmap.unlockBitmaps();
		}
		
		/** Frees as much memory as possible but disables further draw()ing */ 
		public function finalize():void {
			_largeBitmap.finalize();
		}
		
		public function addDeco(decoRenderer:DecoRenderer):void {
			if (decoRenderer.deco.should_be_rendered_standalone) {
				// stack standalones on top; not correct, but easy
				addUnder(decoRenderer, STANDALONE_DECO);
				_decoRenderers.push(decoRenderer);
				
			} else if (_largeBitmap) {
				LocationCommands.drawDecoInLargeBitmap(decoRenderer, _largeBitmap, (this is MiddleGroundRenderer));
			} else {
				addUnder(decoRenderer, DECO);
				_decoRenderers.push(decoRenderer);
			}
			
			CONFIG::locodeco {
				decoToRenderer[decoRenderer.deco] = decoRenderer;
			}			
		}
		
		public function get largeBitmap():LargeBitmap {
			return _largeBitmap;
		}
		
		/** Get all display objects between specified indices */
		CONFIG::locodeco protected function getDisplayObjectsBetween(startIndex:uint, endIndex:uint, doClass:Class, startInclusive:Boolean = false):Array {
			var output:Array = [];
			var i:uint = (startInclusive) ? startIndex : startIndex + 1;
			for (i; i < endIndex; i++){
				var child:DisplayObject = getChildAt(i);
				if (child is doClass) {
					output.push(child);
				}
			}
			
			return output;
		}
		
		CONFIG::locodeco public function removeDeco(decoRenderer:DecoRenderer):void {
			removeChild(decoRenderer);
			
			CONFIG::locodeco {
				decoToRenderer[decoRenderer.deco] = null;
				delete decoToRenderer[decoRenderer.deco];
			}	
		}
		
		/** Refreshes the filters on every decoRenderer */
		CONFIG::locodeco public function updateFilters(disableHighlighting:Boolean):void {
			if (_filtersDirty) {
				for each (var decoRenderer:DecoRenderer in decoToRenderer) {
					LocationCommands.applyFiltersToView(_layerData, decoRenderer, disableHighlighting);
				}
				
				_filtersDirty = false;
			}	
		}
		
		CONFIG::locodeco public function getStandAloneDecos():Vector.<DecoRenderer> {
			var saDecos:Array = getDisplayObjectsBetween(getChildIndex(DECO), getChildIndex(STANDALONE_DECO), DecoRenderer);
			return Vector.<DecoRenderer>(saDecos);
		}
		
		CONFIG::locodeco public function getDecos():Vector.<DecoRenderer> {
			var decos:Array = getDisplayObjectsBetween(getChildIndex(UNDERLAY_BELOW_DECOS), getChildIndex(DECO), DecoRenderer);
			return Vector.<DecoRenderer>(decos);
		}
		
		CONFIG::locodeco public function get decosDirty():Boolean { return _decosDirty; }
		CONFIG::locodeco public function set decosDirty(value:Boolean):void {
			_decosDirty = value;
		}
		
		CONFIG::locodeco public function get filtersDirty():Boolean { return _filtersDirty; }
		CONFIG::locodeco public function set filtersDirty(value:Boolean):void { 
			_filtersDirty = value;
		}
		
		CONFIG::locodeco public function updateDecosForLayer():void {
			const disableHighlighting:Boolean = TSFrontController.instance.getMainView().gameRenderer.disableHighlighting;
			
			// remove and store existing decorenderers in a tsid -> dr map
			var decoMap:Object = {};
			var decoRenderer:DecoRenderer;
			
			const decos:Vector.<DecoRenderer> = getDecos();
			for each (decoRenderer in decos) {
				decoMap[decoRenderer.name] = decoRenderer;
				removeDeco(decoRenderer);
			}
			
			const standAloneDecos:Vector.<DecoRenderer> = getStandAloneDecos();
			for each (decoRenderer in standAloneDecos) {
				decoMap[decoRenderer.name] = decoRenderer;
				removeDeco(decoRenderer);
			}
			
			// remove unused deco renderers by only
			// re-adding deco renderers that are still in use or are new
			_layerData.decos.sort(SortTools.decoZSort);
			for each(var deco:Deco in _layerData.decos) {
				decoRenderer = decoMap[deco.tsid];
				
				// create new DecoRenderer if needed
				if (!decoRenderer) {
					decoRenderer = new DecoRenderer();
					// decoAsset can be null, it will get loaded later
					decoRenderer.init(deco);
					LocationCommands.applyFiltersToView(_layerData, decoRenderer, disableHighlighting);
				}
				
				// put it back
				addDeco(decoRenderer);
			}
		}

		public function get decoRenderers():Vector.<DecoRenderer> {
			return _decoRenderers;
		}

	}
}
