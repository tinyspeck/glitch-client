package com.tinyspeck.engine.view.geo {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.Center;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.Surface;
	import com.tinyspeck.engine.memory.ClientOnlyPools;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.renderer.DecoRenderer;
	import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	public class SurfaceView extends TSSpriteWithModel implements IAbstractDecoRenderer {
		public var surface:Surface;
		public var loc_tsid:String;
		public var tiling:Sprite = new Sprite();
		
		protected var _cap_0:Sprite = new Sprite();
		protected var _cap_1:Sprite = new Sprite();
		protected var _center:Sprite = new Sprite();
		protected var _graphics:Sprite = new Sprite();
		protected var _orient:String;
		
		public function SurfaceView(surface:Surface, loc_tsid:String):void {
			super(surface.tsid);
			mouseChildren = false;
			this.surface = surface;
			this.loc_tsid = loc_tsid;
			_construct();
			cacheAsBitmap = true;
		}
		
		/** from IDecoRendererContainer */
		CONFIG::locodeco private var _highlight:Boolean;
		CONFIG::locodeco public function get highlight():Boolean { return _highlight; }
		//TODO PERF this should dirty the deco for faster filtering
		CONFIG::locodeco public function set highlight(value:Boolean):void { _highlight = value; }
		
		/** from IDecoRendererContainer */
		public function syncRendererWithModel():void {
			x = surface.x;
			y = surface.y;
			tile();
		}
		
		/** from IDecoRendererContainer */
		public function getModel():AbstractPositionableLocationEntity {
			return surface;
		}
		
		/** from IDecoRendererContainer */
		public function getRenderer():DisplayObject {
			return this;
		}
		
		// used for the loco deco to draw it
		public function get wh_edit_border():Object {
			return {
				w: (_orient == 'vert') ? 10 : _width,
				h: (_orient == 'horiz') ? 10 : _height
			}
		}
		
		protected function get _width():int { // width
			if (_orient == 'vert') return 1;
			if (_orient == 'horiz') return surface.w;
			return 0;
		}
		
		protected function get _height():int { // height
			if (_orient == 'vert') return surface.h;
			if (_orient == 'horiz') return 1;
			return 0;
		}
		
		protected function get _length():int { // length
			if (_orient == 'vert') return _height;
			if (_orient == 'horiz') return _width;
			return 0;
		}
		
		protected function _getVerticalMin():int {
			return 0;
		}
		
		protected function _getVerticalMax():int {
			return (_orient == 'horiz') ? 0 : _length;
		}
		
		override protected function _construct():void {
			super._construct();
			addChild(tiling);
			tiling.addChild(_cap_0);
			tiling.addChild(_center);
			tiling.addChild(_cap_1);
			addChild(_graphics);
		}
		
		private var can_tile:Boolean;
		private var centers_good_indexesA:Array;
		
		// called when added to stage
		override protected function _draw():void {
			var loc:Location = model.worldModel.locations[loc_tsid];
			var deco:Deco;
			var center_deco:Deco;
			var decoAsset:DisplayObject;
			
			if (!surface.tiling) {
				syncRendererWithModel();
				return;
			}
			
			can_tile = true;
			
			//0 cap
			deco = surface.tiling.cap_0;
			if (_orient == 'horiz') {
				// use a center tile if it stretches to or past the location.l
				if (surface.x <= loc.l && surface.tiling.centers.length>0) {
					deco = surface.tiling.centers[0];
				}
			}
			
			if (!(deco && DecoAssetManager.isAssetAvailable(deco.sprite_class))) {
				can_tile = false;
				syncRendererWithModel();
				return;
			}
			
			//1 cap
			deco = surface.tiling.cap_1;
			if (_orient == 'horiz') {
				// use a center tile if it stretches to or past the location.l
				if (surface.x+_width >= loc.r && surface.tiling.centers.length>0) {
					deco = surface.tiling.centers[0];
				}
			}
			if (!(deco && DecoAssetManager.isAssetAvailable(deco.sprite_class))) {
				can_tile = false;
				syncRendererWithModel();
				return;
			}
			
			//center
			centers_good_indexesA = [];
			var centers:Vector.<Center> = surface.tiling.centers;
			if (centers.length) {
				//get valid keys
				for (var index:int=0; index < centers.length; index++) {
					center_deco = centers[index];
					if (center_deco && DecoAssetManager.isAssetAvailable(center_deco.sprite_class)) {
						centers_good_indexesA.push(index);
					}
				}
			}
			if (!centers_good_indexesA.length > 0) {
				can_tile = false;
				syncRendererWithModel();
				return;
			}
			
			syncRendererWithModel();
		}
		
		protected function tile():void {
			SpriteUtil.clean(_cap_0);
			SpriteUtil.clean(_cap_1);
			SpriteUtil.clean(_center);
			if (!can_tile) return;
			
			var rect:Rectangle;
			var bitmapdata:BitmapData;
			var b:Bitmap;
			
			CONFIG::debugging {
				Console.log(53, 'REDRAWING '+surface.tsid);
			}
			
			// assume tiles are always 50 w or h (depending on plat or wall), and that plats/walls are always some multiple of 50 in length;
			var center_tile_l:int; // must set this, but only if there are centers!
			var loc:Location = model.worldModel.locations[loc_tsid];
			var deco:Deco;
			var center_deco:Deco;
			var decoAsset:MovieClip;
			var decoRenderer:DecoRenderer;
			
			//0 cap --------------------------------------------------------------------------------------------
			deco = surface.tiling.cap_0;
			if (_orient == 'horiz') {
				// use a center tile if it stretches to or past the location.l
				if (surface.x <= loc.l && surface.tiling.centers.length>0) {
					deco = surface.tiling.centers[0];
				}
			}
			
			decoAsset = DecoAssetManager.getTemplate(deco.sprite_class);
			
			if (_orient == 'vert') {
				_cap_0.y = _getVerticalMin();
				_cap_0.x = 0;
				
				bitmapdata =  new BitmapData(deco.w, deco.h, true, 0xffffff);
				bitmapdata.draw(decoAsset);
				
				b = new Bitmap(bitmapdata);
				b.x = -Math.round(deco.w/2);
			} else {
				_cap_0.y = 0;
				_cap_0.x = 0;
				
				decoRenderer = ClientOnlyPools.DecoRendererPool.borrowObject();
				decoRenderer.init(deco, decoAsset);
				
				if (deco.h_flip) {
					decoRenderer.scaleX = -1;
				} else {
					decoRenderer.scaleX = 1;
				}
				
				rect = decoRenderer.getBounds(decoRenderer);
				
				try {
					bitmapdata = new BitmapData(rect.width+.5, rect.height+.5, true, 0xffffff);
				} catch(e:ArgumentError) {
					// may throw: ArgumentError: Error #2015: Invalid BitmapData;
					// need to return to pool before rethrowing so we don't run out of pool space
					decoRenderer.dispose();
					ClientOnlyPools.DecoRendererPool.returnObject(decoRenderer);
					throw e;
				}
				bitmapdata.draw(decoRenderer, new Matrix(1, 0, 0, 1, -rect.x, -rect.y));
				b = new Bitmap(bitmapdata);
				
				b.x = 0;
				b.y = Math.round(-(b.height/2)+((deco.h-decoRenderer.height)/2));
				decoRenderer.dispose();
				ClientOnlyPools.DecoRendererPool.returnObject(decoRenderer);
			}
			_cap_0.addChild(b);
			
			//1 cap --------------------------------------------------------------------------------------------
			deco = surface.tiling.cap_1;
			if (_orient == 'horiz') {
				// use a center tile if it stretches to or past the location.l
				if (surface.x+_width >= loc.r && surface.tiling.centers.length>0) {
					deco = surface.tiling.centers[0];
				}
			}
			
			decoAsset = DecoAssetManager.getTemplate(deco.sprite_class);
			
			if (_orient == 'vert') {
				_cap_1.y = _getVerticalMax()-deco.h;
				_cap_1.x = 0;
				
				bitmapdata =  new BitmapData(deco.w, deco.h, true, 0xffffff);
				bitmapdata.draw(decoAsset);
				
				b = new Bitmap(bitmapdata);
				b.x = -Math.round(deco.w/2);
			} else {
				_cap_1.y = 0;
				_cap_1.x = _length-deco.w;
				
				decoRenderer = ClientOnlyPools.DecoRendererPool.borrowObject();
				decoRenderer.init(deco, decoAsset);
				
				if (deco.h_flip) {
					decoRenderer.scaleX = -1;
				} else {
					decoRenderer.scaleX = 1;
				}
				
				rect = decoRenderer.getBounds(decoRenderer);
				
				try {
					bitmapdata = new BitmapData(rect.width+.5, rect.height+.5, true, 0xffffff);
				} catch(e:ArgumentError) {
					// may throw: ArgumentError: Error #2015: Invalid BitmapData;
					// need to return to pool before rethrowing so we don't run out of pool space
					decoRenderer.dispose();
					ClientOnlyPools.DecoRendererPool.returnObject(decoRenderer);
					throw e;
				}
				
				bitmapdata.draw(decoRenderer, new Matrix(1, 0, 0, 1, -rect.x, -rect.y));
				b = new Bitmap(bitmapdata);
				
				b.x = 0;
				b.y = Math.round(-(b.height/2)+((deco.h-decoRenderer.height)/2));
				decoRenderer.dispose();
				ClientOnlyPools.DecoRendererPool.returnObject(decoRenderer);
			}
			_cap_1.addChild(b);
			
			//center --------------------------------------------------------------------------------------------
			var centers:Vector.<Center> = surface.tiling.centers;
			var center_pattern:String = surface.tiling.center_pattern;
			CONFIG::debugging {
				Console.log(53, 'center_pattern '+center_pattern+' '+centers.length);
			}
			if (centers.length) {
				if (!center_pattern) center_pattern = '';
				
				// now go through and draw the center tiles out, if there are any good ones
				if (centers_good_indexesA.length > 0) {
					center_tile_l = (_orient == 'horiz') ? deco.w : deco.h; // we must assume all centers are the same w or h
					
					if (_orient == 'vert') {
						_center.y = _getVerticalMin()+surface.tiling.cap_0.h;
						_center.x = 0;
					} else {
						_center.y = 0;
						_center.x = surface.tiling.cap_0.w;
					}
					
					var center_patternA:Array = (center_pattern.toString()) ? center_pattern.toString().split(',') : [];
					var actual_center_patternA:Array = [];
					var index:int;
					for (var i:int=0;i<Math.floor((_length-(2*center_tile_l))/center_tile_l);i++) {
						
						///Math.floor(Math.random()*6)   => 0 - 5 (integers)
						
						// if the pattern is long enough, use the next item in it; otherwise, choose a random one
						var rand:int = Math.floor(Math.random()*centers_good_indexesA.length)
						index = (i < center_patternA.length) ? center_patternA[int(i)] : rand;
						
						// only use this index if it is good; otherwise use the first good one
						if (centers_good_indexesA.indexOf(index) == -1) index = centers_good_indexesA[0];
						
						actual_center_patternA.push(index);
						center_deco = centers[index];
						
						decoAsset = DecoAssetManager.getTemplate(center_deco.sprite_class);
						
						CONFIG::debugging {
							Console.log(53, index);
						}
	
						if (_orient == 'vert') {
							bitmapdata =  new BitmapData(center_deco.w, center_deco.h, true, 0xffffff);
							bitmapdata.draw(decoAsset);
							b = new Bitmap(bitmapdata);
							
							b.x = -Math.round(deco.w/2);
							b.y = (i*center_tile_l);
						} else {
							decoRenderer = ClientOnlyPools.DecoRendererPool.borrowObject();
							decoRenderer.init(center_deco, decoAsset);
							
							if (center_deco.h_flip) {
								decoRenderer.scaleX = -1;
							} else {
								decoRenderer.scaleX = 1;
							}
							
							CONFIG::debugging {
								Console.log(53, 'decoRenderer '+decoRenderer);
							}
							
							rect = decoRenderer.getBounds(decoRenderer);
							bitmapdata =  new BitmapData(rect.width+.5, rect.height+.5, true, 0xffffff);
							bitmapdata.draw(decoRenderer, new Matrix(1, 0, 0, 1, -rect.x, -rect.y));
							b = new Bitmap(bitmapdata);
							
							b.x = (i*center_tile_l);
							b.y = Math.round(-(b.height/2)+((center_deco.h-decoRenderer.height)/2));
							decoRenderer.dispose();
							ClientOnlyPools.DecoRendererPool.returnObject(decoRenderer);
						}
						_center.addChild(b);
					}
					
					// assign back to center_pattern what it actually is
					surface.tiling.center_pattern = actual_center_patternA.join(',');
				} 
			}
		}
		
		override public function dispose():void {
			cacheAsBitmap = false;
			super.dispose();
		}
	}
}