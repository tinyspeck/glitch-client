package com.tinyspeck.engine.spritesheet {
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.Tim;
	import com.tinyspeck.engine.util.ColorUtil;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Rectangle;

	public class SSMultiBitmapSheet extends SSAbstractSheet	{
		public const bmds:Vector.<BitmapData> = new Vector.<BitmapData>();
		
		private const containerSprite:Sprite = new Sprite();
		
		public function SSMultiBitmapSheet(name:String, options:SSGenOptions, lazySnapFunction:Function, do_not_clean:Boolean) {
			super(name, options, lazySnapFunction, do_not_clean);
		}
		
		override public function stopRecord():void {
			super.stopRecord();
		}
		
		public function getFramesForCollection(name:String):Vector.<SSFrame> {
			var fc:SSFrameCollection = getFrameCollectionByName(name);
			if (!fc) return null;
			return fc.frames;
		}
		
		override internal function snapFrame(displayObject:DisplayObject, frame:SSFrame, options:SSGenOptions):void {
			var bmd:BitmapData;
			var rect:Rectangle;
			
			if (!options) options = ss_options;
			var oldParent:DisplayObjectContainer;
			var oldIndex:int;
			var oldFilters:Array = displayObject.filters;
			
			if (options.filters && options.filters.length > 0) {
				displayObject.filters = options.filters;
			}
			
			if (displayObject.parent is Loader) {
				containerSprite.addChild(displayObject.parent);
			} else {
				if (displayObject.parent) {
					oldParent = displayObject.parent;
					oldIndex = oldParent.getChildIndex(displayObject);
					oldParent.removeChild(displayObject);
				}
				containerSprite.addChild(displayObject);
			}
			
			
			var oldScaleX:Number = displayObject.scaleX;
			var oldScaleY:Number = displayObject.scaleY;
			var oldRotation:Number = displayObject.rotation;
			var oldX:Number = displayObject.x;
			var oldY:Number = displayObject.y;
			displayObject.scaleX = options.scale;
			displayObject.scaleY = options.scale;
			displayObject.rotation = options.rotation;
			displayObject.x = 0;
			displayObject.y = 0;
			
			rect = createBoundingRect(containerSprite);
			//Console.info(rect)
			
			// really ugly temporary way to account for possible filters on the displayObject or its children:
			// TODO: a recursive function that uses generateFilterRect to measure actual bounds of display object, in place of getBounds
			// see: http://stackoverflow.com/questions/466280/get-bounds-of-filters-applied-to-flash-sprite-within-sprite (which does not work for our purposes, but shoudl give some guidance)
			var frame_padd:int = options.frame_padd;
			rect.width+= frame_padd;
			rect.height+= frame_padd;
			rect.x-= Math.floor(frame_padd/2);
			rect.y-= Math.floor(frame_padd/2);
			rect.width = Math.min(2000, Math.max(1, rect.width));
			rect.height = Math.min(2000, Math.max(1, rect.height));

			try {
				
				if (!ss_options.double_measure) {
					
					bmd = new BitmapData(
						rect.width,
						rect.height,
						options.transparent, 
						(options.transparent) ? 0 : ColorUtil.getRandomColor()
					);
					mat.identity();
					mat.translate(-rect.x, -rect.y);
					bmd.lock();
					// THIS IS WHAT TAKES ALL THE TIME
					Tim.stamp(222, 'before draw '+rect);
					bmd.draw(containerSprite, mat, null, null, null, true);
					
					//Console.warn(this.name+' '+rect);
					
				} else {
					
					bmd = new BitmapData(
						rect.width, 
						rect.height, 
						true, 
						0
					);
					mat.identity();
					mat.translate(-rect.x, -rect.y);
					bmd.lock();
					// THIS IS WHAT TAKES ALL THE TIME
					Tim.stamp(222, 'before draw');
					bmd.draw(containerSprite, mat, null, null, null, true);
					
					var bounds:Rectangle = bmd.getColorBoundsRect(0xFFFFFFFF, 0x000000, false);
					rect.x+= bounds.x
					rect.y+= bounds.y;
					rect.width = Math.max(1, bounds.width);
					rect.height = Math.max(1, bounds.height);
					
					bmd = new BitmapData(
						rect.width,
						rect.height,
						options.transparent, 
						(options.transparent) ? 0 : ColorUtil.getRandomColor()
					);
					mat.identity();
					mat.translate(-rect.x, -rect.y);
					bmd.lock();
					// THIS IS WHAT TAKES ALL THE TIME
					Tim.stamp(222, 'before extra draw');
					bmd.draw(containerSprite, mat, null, null, null, true);
				}
				
				
				Tim.stamp(222, 'after draw');
				frame.originalBounds = rect;
				CONFIG::debugging {
					if (!bmd) Console.error('no bmd?')
				}
				frame._bmd_index = bmds.push(bmd as BitmapData)-1;
				
			} catch(err:Error) {
				BootError.addErrorMsg('snapFrame error! rect.width:'+rect.width+' rect.height:'+rect.height + '\n' + err, err, ['spritesheet']);
				return;
			}
			
			//Console.log(113, ''+StringUtil.formatNumber((getTimer()-start_ms)/1000, 4)+'secs');
			
			displayObject.filters = oldFilters;
			while (containerSprite.numChildren) containerSprite.removeChildAt(0);
			displayObject.rotation = oldRotation;
			displayObject.scaleX = oldScaleX;
			displayObject.scaleY = oldScaleY;
			displayObject.x = oldX;
			displayObject.y = oldY;
			
			if (oldParent) {
				oldParent.addChildAt(displayObject, oldIndex);
			}
			
			super.snapFrame(displayObject, frame, options);
		}
		
		override internal function updateViewBitmapData(viewBitmap:SSViewBitmap):void {
			if (viewBitmap._curr_frame) {
				viewBitmap.bitmapData = bmds[viewBitmap._curr_frame._bmd_index];
			} else {
				viewBitmap.bitmapData = bmds[0];
			}
			viewBitmap.smoothing = true;
		}
		
		override public function getBitmapData(sprite:SSViewSprite):BitmapData {
			return bmds[sprite._curr_frame._bmd_index];
		}
		
		override public function getFrame(sprite:SSViewSprite):SSFrame {
			return sprite._curr_frame;
		}
		
		override internal function updateViewSprite(sprite:SSViewSprite):void {
			var frame:SSFrame = sprite._curr_frame;
			var s:Shape;
			
			s = sprite.displayShape;
			s.graphics.clear();
			
			if (!frame.has_bmd) {
				if (lazySnapFunction != null) {
					if (!lazySnapFunction(this, frame)) {
						CONFIG::debugging {
							Console.warn('fail to snap');
						}
						return;
					}
					//Console.warn(frame._bmd_index+' '+frame.originalBounds+' '+sprite.displayShape.graphics);
				} else {
					CONFIG::debugging {
						Console.warn(this._name+' '+this.activeFrameCollection.name+' NO lazySnapFunction!!!');
					}
					BootError.handleError(
						this._name+' '+this.activeFrameCollection.name+' '+sprite._curr_frame_coll+' '+sprite._curr_frame_num+' frame has no bmd',
						new Error('updateViewSprite failure'),
						['spritesheet'], CONFIG::god
					);
					return;
				}
			}
			
			s.graphics.beginBitmapFill(bmds[frame._bmd_index], null, false, sprite.smooth);
			s.graphics.drawRect(0, 0, frame.originalBounds.width, frame.originalBounds.height);
			s.graphics.endFill();
			
			s.x = frame.originalBounds.x;
			s.y = frame.originalBounds.y;
			
			s = sprite.displayFilterShape;
			if (s) {
				//sprite.blendMode = BlendMode.LAYER
				//sprite.displayShape.blendMode = BlendMode.ALPHA
				
				s.transform.colorTransform = color_trans;
				s.graphics.clear();
				s.graphics.beginBitmapFill(bmds[frame._bmd_index], null, false, sprite.smooth);
				s.graphics.drawRect(0, 0, frame.originalBounds.width, frame.originalBounds.height);
				s.graphics.endFill();
				
				s.x = frame.originalBounds.x;
				s.y = frame.originalBounds.y;
			}
		}
		
		override internal function dispose():void {
			return;
			var bitmapData:BitmapData;
			while(bmds.length) {
				bitmapData = bmds.pop();
				bitmapData.dispose();
			}
			super.dispose();
		}
	}
}