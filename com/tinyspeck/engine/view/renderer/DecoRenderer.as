package com.tinyspeck.engine.view.renderer
{
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.engine.animatedbitmap.AnimatedBitmap;
	import com.tinyspeck.engine.animatedbitmap.BitmapAtlas;
	import com.tinyspeck.engine.animatedbitmap.BitmapAtlasGenerator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.MCUtil;
	import com.tinyspeck.engine.util.TFUtil;
	
	import de.polygonal.core.IPoolableObject;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	CONFIG::god import com.tinyspeck.debug.Console;
	
	final public class DecoRenderer extends Sprite implements IPoolableObject, IAbstractDecoRenderer, IDisposable {
		public var decoAsset:MovieClip;
		public var w:int;
		public var h:int;
		
		private var inited:Boolean = false;
		private var _tf:TextField;
		private var _deco:Deco;
		private var animatedBitmap:AnimatedBitmap;
		
		public function DecoRenderer() {
			//
		}
		
		override public function get width():Number {
			return w;
		}
		
		override public function get height():Number {
			return h;
		}
		
		/** If no decoAsset is given, a new copy will be loaded dynamically */
		public function init(deco:Deco, decoAsset:MovieClip = null):void {
			if (inited) return;
			inited = true;
			
			name = deco.tsid
			this._deco = deco;
			this.decoAsset = decoAsset;
			
			if (TSModelLocator.instance.stateModel.render_mode.usesBitmaps) {
				// cacheAsBitmap = false
			} else {
				cacheAsBitmap = true;
			}
			
			if (decoAsset) {
				addChildAt(decoAsset, 0);
			} else {
				// in SWF_bitmap_renderer, instance animations are loaded
				// dynamically since we only keep template copies on hand;
				// in LocoDeco, dropping a new asset onto the canvas is dynamic too
				if (DecoAssetManager.loadIndividualDeco(deco.sprite_class, onDecoAssetLoad)) {
					// we're loading the asset now!
				} else {
					// asset is missing; we'll render red boxes when editing
				}
			}
			
			syncRendererWithModel();
			
			CONFIG::locodeco {
				TSModelLocator.instance.stateModel.registerCBProp(editingChangeHandler, 'editing');
			}
		}
		
		private function onDecoAssetLoad(mc:MovieClip, class_name:String, swfWidth:Number, swfHeight:Number):void {
			 
			decoAsset = mc; // if sprite sheeting fails, the native decoAsset will be added normally.
			
			CONFIG::god {
				try {
					const model:TSModelLocator = TSModelLocator.instance;
					if (_deco.animated && model.flashVarModel.sprite_sheet_decos_copypixels && model.stateModel.render_mode == RenderMode.BITMAP) {
						assetMovieClipToAnimatedBitmap(mc);
						return;
					}
				} catch (e:Error) {
					CONFIG::god {
						Console.error("Could not generate sprite sheet for deco: " + deco.sprite_class + ".  Dimensions too big or too many frames ?");
					}
				}
			}
			
			addAndSyncDecoAsset();
		}
		
		/** Convert decoAssset MovieClip to AnimatedBitmap */
		private function assetMovieClipToAnimatedBitmap(movieClip:MovieClip):void {
			// if an atlas has already been generated, re-use it
			var atlas:BitmapAtlas = DecoAssetManager.getBitmapAtlas(_deco.sprite_class);
			if (atlas) {
				onBitmapAtlasCreated(atlas);
				return;
			}
			
			// if an atlas does not exist, create it
			var frameIndices:Vector.<int> = getFrameIndices(_deco.sprite_class);
			var uniqueFrames:uint = frameIndices != null ? getUniqueFrameCount(frameIndices) : movieClip.totalFrames;
			var atlasGen:BitmapAtlasGenerator = BitmapAtlasGenerator.instance;
			var container:MovieClip = new MovieClip();
			container.addChild(movieClip);
			var maxScale:Number = getMaxScale(movieClip, uniqueFrames);
			maxScale = maxScale < 1 ? 1 : maxScale;
			if (maxScale < 1.5) maxScale = Math.floor(maxScale); // floor scale under 1.5 to 1, as scaling introduces a huge performance hit.
			atlasGen.fromMovieClipContainer(container, onBitmapAtlasCreated, null, maxScale, 0, null, frameIndices, true, onSpriteSheetError);
		}
		
		private function onSpriteSheetError():void {
			CONFIG::god {
				Console.error("Could not generate sprite sheet for deco: " + deco.sprite_class + ".  Dimensions too big or too many frames ?");
			}
			addAndSyncDecoAsset();
		}
		
		private function getUniqueFrameCount(indices:Vector.<int>):uint {
			var count:uint = 0;
			for each (var index:int in indices) {
				if (index == -1) count++;
			}
			
			return count;
		}
		
		private function getMaxScale(mc:MovieClip, uniqueFrames:uint):Number {
			var scale:Number = _deco.w > _deco.h ? _deco.w/mc.width : _deco.h/mc.height;
			var surfaceArea:Number = _deco.w * _deco.h * uniqueFrames;
			var height:Number = surfaceArea/BitmapAtlasGenerator.MAX_TEXTURE_WIDTH;
			
			if (height > BitmapAtlasGenerator.MAX_TEXTURE_HEIGHT) {
				return (scale * BitmapAtlasGenerator.MAX_TEXTURE_HEIGHT/height)
			}
			
			return scale;
		}
		
		private function getFrameIndices(spriteClass:String):Vector.<int> {
			var className:String = "animated_deco_frame_indices";
			var indicesArray:Array = CSSManager.instance.getArrayValueFromStyle(className, spriteClass);
			if (indicesArray && indicesArray.length) {
				return Vector.<int>(indicesArray);
			}
			
			return null;
		}
		
		/** Create AnimatedBitmap using specified BitmapAtlas */
		private function onBitmapAtlasCreated(atlas:BitmapAtlas):void {
			// cache atlas if it hasn't been.
			if (!DecoAssetManager.getBitmapAtlas(_deco.sprite_class)) {
				DecoAssetManager.addBitmapAtlas(_deco.sprite_class, atlas);
			}
			
			// create the animation based on drawing method
			const model:TSModelLocator = TSModelLocator.instance;
			animatedBitmap = new AnimatedBitmap(atlas, true, "auto", true); //set smoothing to true if too pixelated.
			DecoAssetManager.bitmapAtlasesDisposed.addOnce(animatedBitmap.dispose);
			(animatedBitmap as AnimatedBitmap).play();
			
			animatedBitmap.scaleX = 1 / atlas.scaleFactorX;
			animatedBitmap.scaleY = 1 / atlas.scaleFatorY;
			
			// finally, add the animation to the decoAsset
			decoAsset = new MovieClip();
			decoAsset.addChild(animatedBitmap);
			addAndSyncDecoAsset();
		}
		
		private function addAndSyncDecoAsset():void {
			addChildAt(decoAsset, 0);
			syncRendererWithModel();
			TSFrontController.instance.resnapMiniMap();
		}
		
		private function createTF():void {
			if (_tf) return;

			// get from pool
			_tf = EnginePools.TextFieldPool.borrowObject();
			
			TFUtil.prepTF(_tf, true);
			addChild(_tf);
		}
		
		private function destroyTF():void {
			if (!_tf) return;
			
			if (_tf.parent) removeChild(_tf);
			
			// return to pool
			EnginePools.TextFieldPool.returnObject(_tf);
			_tf = null;
		}
		
		/** You may call init() again after dispose() to reuse */
		public function dispose():void {			
			
			if (!inited) return;
			inited = false;
			
			if (animatedBitmap) animatedBitmap.dispose();

			name = '';
			_deco = null;
			
			// filters must be set to null before cacheAsBitmap
			filters = null;
			cacheAsBitmap = false;
			
			if (decoAsset) {
				if (decoAsset.parent) removeChild(decoAsset);
				// decos are loaded from in-memory ByteArrays and can be stopped
				if (decoAsset.loaderInfo) {
					decoAsset.loaderInfo.loader.unloadAndStop();
				}
				decoAsset = null;
			}
			
			if (_tf) destroyTF();
			
			CONFIG::locodeco {
				TSModelLocator.instance.stateModel.unRegisterCBProp(editingChangeHandler, 'editing');
			}
		}
		
		// from IPoolableObject
		public function reset():void {
			dispose();
		}
		
		/** When editing, draw an invisible bounding box for hit detection */
		CONFIG::locodeco private function editingChangeHandler(editing:Boolean):void {
			graphics.clear();
			if (editing) {
				const a:Number = (decoAsset) ? 0 : 0.8;
				graphics.beginFill(0xcc0000, a);
				graphics.drawRect(-w/2, -h, w, h);
			}
		}

		/**
		 * Will load a new copy of the deco sprite_class for this DecoRenderer;
		 * use reset()/init() if you want to use a cached deco asset.
		 */
		public function reloadDecoAsset():void {
			// remember some stuff
			var was_deco:Deco = _deco;
			var was_filters:Array = filters;
			
			reset();
			init(was_deco, null);
			this.filters = was_filters;
		}
		
		/** from IDecoRendererContainer */
		CONFIG::locodeco private var _highlight:Boolean;
		CONFIG::locodeco public function get highlight():Boolean { return _highlight; }
		CONFIG::locodeco public function set highlight(value:Boolean):void { _highlight = value; }
		
		/** from IDecoRendererContainer */
		public function syncRendererWithModel():void {
			if (!inited || !_deco) return;
			
			x = _deco.x;
			y = _deco.y;
			rotation = _deco.r;

			w = _deco.w;
			h = _deco.h;
			scaleX = 1;
			
			if (_deco.sign_txt) {
				if (!_tf) createTF();
			} else if (_tf) {
				destroyTF();
			}
			
			if (decoAsset) {
				const swf_dims:Object = DecoAssetManager.getDimensions(_deco.sprite_class);
				scaleX = _deco.h_flip ? -1 : 1;
				decoAsset.scaleX = w/swf_dims.width;
				decoAsset.scaleY = h/swf_dims.height;
				decoAsset.x = -Math.round(w/2);
				decoAsset.y = -h;
				
				if (_deco.animated) {
					MCUtil.recursivePlay(decoAsset);
				} else {
					MCUtil.recursiveGotoAndStop(decoAsset, 0);
				}
			} else {
				// when editing, editingChangeHandler will draw in a red box
			}
			
			if (_tf) {
				_tf.htmlText = '<p class="'+_deco.sign_css_class+'">'+_deco.sign_txt+'</p>';
				_tf.width = w;
				_tf.height = h;
				if (_deco.h_flip) {
					_tf.scaleX = -1;
					_tf.x = Math.round(_tf.width/2);
				} else {
					_tf.scaleX = 1;
					_tf.x = -Math.round(_tf.width/2);
				}
				_tf.y = -Math.round((_tf.height/2))-Math.round(h/2);
			}
			
			CONFIG::locodeco {
				editingChangeHandler(TSModelLocator.instance.stateModel.editing);
			}
		}
		
		/** from IDecoRendererContainer */
		public function getModel():AbstractPositionableLocationEntity {
			return _deco;
		}
		
		/** from IDecoRendererContainer */
		public function getRenderer():DisplayObject {
			return this;
		}

		public function get tf():TextField {
			return _tf;
		}

		public function get deco():Deco {
			return _deco;
		}
	}
}