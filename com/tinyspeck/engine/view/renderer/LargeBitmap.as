package com.tinyspeck.engine.view.renderer
{
import com.tinyspeck.engine.memory.EnginePools;
import com.tinyspeck.engine.util.MathUtil;
import com.tinyspeck.engine.util.StringUtil;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * LargeBitmaps provide for arbitrarily sized Bitmaps outside the limitations of
 * Flash. You may draw() directly onto them, and the drawing will occur in
 * the correct position.
 * 
 * Draw speed is optimized by precomputing which bitmaps to draw in, and memory
 * is optimized by not allocating bitmaps until they are needed.
 */
public class LargeBitmap extends Sprite
{
	/** Flash 10+ allows up to 8191 per dimensions on a Bitmap */
	public static const MAX_DIMENSION:int = 8191; //(transparency ? 2880 : 8191);
	public static const MAX_PIXELS:int = 0xFFFFFF;
	private static const ZERO_ZERO:Point = new Point();
	
	private const copyPixelsHelperPoint:Point = new Point();

	private var _segmentDimension:uint = MAX_DIMENSION;
	
	private var _width:int;
	private var _height:int;
	
	private var xOffset:Number = 0;
	private var yOffset:Number = 0;
	
	private var fillColor:uint;
	private var transparency:Boolean;
	private var pixelSnapping:String;
	private var smoothing:Boolean;
	
	/** Represents a row-oriented 2D grid of bitmapdatas: row0, row1, ... */
	private var bitmapDatas:Vector.<BitmapData>;
	private var _bitmaps:Vector.<Bitmap>;
	/** Number of rows in our grid */
	private var rows:int;
	/** Number of cols in our grid */
	private var cols:int;
	/** Width (in pixels) of each BitmapData */
	private var bitmapWidth:int;
	/** Height (in pixels) of each BitmapData */
	private var bitmapHeight:int;
	/** When true, nothing more can be done to LargeBitmap */
	private var finalized:Boolean;
	
	/**
	 * Width and height may only be set during construction.
	 * 
	 * The offsets determine what to add to the coordinates of the Bitmap
	 * children (so you can effectively move the registration point).
	 */
	public function LargeBitmap(width:int, height:int, segmentDimension:uint = 0, xOffset:int=0, yOffset:int=0, transparency:Boolean=true, fillColor:uint=0, 
								pixelSnapping:String="auto", smoothing:Boolean=false) {
		if (segmentDimension) {
			if (segmentDimension > MAX_DIMENSION) {
				throw new Error("Segment dimension can not exceed " + MAX_DIMENSION);
			}
			_segmentDimension = segmentDimension;
		}
		
		_width = width;
		_height = height;
		
		this.xOffset = xOffset;
		this.yOffset = yOffset;
		
		this.transparency = transparency;
		this.fillColor = fillColor;
		
		this.pixelSnapping = pixelSnapping;
		this.smoothing = smoothing;
		
		cols = 1;
		rows = 1;
		bitmapWidth  = width;
		bitmapHeight = height;
		
		// divide layer equally into enough bitmap regions
		// so each is <= MAX_PIXELS pixels and <=8191px
		while (((bitmapWidth*bitmapHeight) > MAX_PIXELS) || (bitmapWidth > _segmentDimension) || (bitmapHeight > _segmentDimension)) {
			if (bitmapWidth > bitmapHeight) {
				cols++;
			} else {
				rows++;
			}
			bitmapWidth  = width / cols;
			bitmapHeight = height / rows;
		}
		
		//if(debug) trace(rows + "x" + cols + " " + bitmapWidth + "x" + bitmapHeight);
		
		// fixed length
		_bitmaps = new Vector.<Bitmap>(rows*cols, true);
		bitmapDatas = new Vector.<BitmapData>(rows*cols, true);
		
		// pre-generate and place all the Bitmaps
		// their BMDs will be lazy-loaded in draw()
		var bm:Bitmap;
		//var debugColor:Boolean = false;
		var row:int;
		var col:int;
		var bmd:BitmapData;
		for (row=0; row<rows; row++) {
			for (col=0; col<cols; col++) {
				//if (debug) {
				//	bmd = new BitmapData(bitmapWidth, bitmapHeight, transparent, fillColor);
				//	bmd.fillRect(bmd.rect, (debugColor ? 0x20000000 : 0x20FF0000));
				//	bitmapDatas[int(row*cols+col)] = bmd;
				//}
				bm = new Bitmap(bmd, pixelSnapping, smoothing);
				_bitmaps[int(row*cols+col)] = bm;
				bm.x = xOffset + col*bitmapWidth;
				bm.y = yOffset + row*bitmapHeight;
				// we'll add it on-demand
				//addChild(bm);
				//debugColor = !debugColor;
			}
			//debugColor = !debugColor;
		}
	}

	/** Setting does nothing */
	override public function set width(w:Number):void {
		//
	}

	/** Setting does nothing */
	override public function set height(h:Number):void {
		//
	}
	
	override public function get width():Number {
		return _width;
	}

	override public function get height():Number {
		return _height;
	}
	
	/** Call this before making multiple calls to draw() for performance */
	public function lockBitmaps():void {
		if (finalized) return;
		for each (var bmd:BitmapData in bitmapDatas) {
			if(bmd) bmd.lock();
		}
	}
	
	/** Call this after making multiple calls to draw() for performance */
	public function unlockBitmaps():void {
		if (finalized) return;
		for each (var bmd:BitmapData in bitmapDatas) {
			if(bmd) bmd.unlock();
		}
	}
	
	/** Frees as much memory as possible but disables further draw()ing */
	//TODO clusters of bitmaps could be merged into a larger bitmap if it meets size reqs and has a better utilization
	public function finalize():void {
		if (finalized) return;
		finalized = true;
		
		//trace('finalizing ' + name);
		
		var bm:Bitmap;
		var bmd:BitmapData;
		var croppedBMD:BitmapData;
		
		var removeable:Boolean;
		var colorBounds:Rectangle;
		
		for (var i:int=0; i<_bitmaps.length; i++) {
			bm = _bitmaps[int(i)];
			// since we're sparse, not all bmds will be non-null
			if (bm) {
				removeable = false;
				bmd = bm.bitmapData;
				if (bmd) {
					colorBounds = bmd.getColorBoundsRect(0xFF000000, 0x00000000, false);
					if (!(colorBounds.width || colorBounds.height)) {
						// no non-transparent pixels
						removeable = true;
					}
				} else {
					// no bitmapData, so totally removable
					removeable = true;
				}
				
				if (removeable) {
					//trace('\tremoving', i);
					
					// bitmap isn't in use, remove it from the stage
					if (bm.parent) removeChild(bm);
					_bitmaps[int(i)] = null;
					
					// kill its bitmapData
					if (bmd) {
						bm.bitmapData = null;
						bmd.dispose();
					}
				} else {
					//trace('\tkeeping', i);
					
					// trim off transparent edges
					if ((colorBounds.width < bmd.width) || (colorBounds.height < bmd.height)) {
						try {
							croppedBMD = new BitmapData(colorBounds.width, colorBounds.height, transparency, fillColor);
						} catch (e:ArgumentError) {
							e.message = ("BitmapData(" + colorBounds.width + ',' + colorBounds.height + ',' + transparency + ',' + fillColor + ')');
							throw e;
						}
						
						// clone and dispose
						croppedBMD.copyPixels(bmd, colorBounds, ZERO_ZERO);
						bm.bitmapData = croppedBMD;
						bmd.dispose();
						bmd = croppedBMD;
						croppedBMD = null;
						
						// reposition the parent bitmap given the crop
						bm.x += colorBounds.x;
						bm.y += colorBounds.y;
					}
					
					// debug: draw edges of each bmd
//					for (var x:int = 0; x < bmd.width; x++) {
//						bmd.setPixel32(x, 0, 0xFFFF0000);
//						bmd.setPixel32(x, bmd.height-1, 0xFFFF0000);
//					}
//					for (var y:int = 0; y < bmd.height; y++) {
//						bmd.setPixel32(0, y, 0xFFFF0000);
//						bmd.setPixel32(bmd.width-1, y, 0xFFFF0000);
//					}
				}
			}
		}
	}

	/** Draws the IBD onto the layer; use blit() if you can (faster) */
	public function draw(source:DisplayObject, transform:Matrix):void {
		if (finalized) return;
		
		var bmd:BitmapData;
		if (bitmapDatas.length == 1) {
			// optimized path for small streets with only one required bmd
			bmd = bitmapDatas[int(0)];
			// lazy-load these since they're costly
			if (!bmd) {
				try {
					bmd = new BitmapData(bitmapWidth, bitmapHeight, transparency, fillColor);
				} catch (e:ArgumentError) {
					e.message = ("BitmapData(" + bitmapWidth + ',' + bitmapHeight + ',' + transparency + ',' + fillColor + ')');
					throw e;
				}
				bitmapDatas[int(0)] = bmd;
				_bitmaps[int(0)].bitmapData = bmd;
				addChild(_bitmaps[int(0)]);
			}
			bmd.draw(source, transform);
		} else {
			// store
			const tx:Number = transform.tx;
			const ty:Number = transform.ty;
			
			////////////////////////////////////////////////////////////////////
			///////// OPTIMIZATION TO REDUCE NUMBER OF BITMAPS DRAWN IN ////////
			////////////////////////////////////////////////////////////////////
			// Idea: Only lazy-instantiate and draw() onto BitmapDatas that the
			//       given DisplayObject could possibly intersect (given a grid)
			// * take the DisplayObject
			// * find its bounds in its own coordinate sapce
			// * transform the bounds according to the given transform matrix
			// * find the top/bottom/left/right-most coordinates
			// * results are the TBLR coordinates of the transformed object
			// * map those coordinates to BitmapData grid cells and draw
			
			// find the bounds of the transformed DisplayObject
			const bounds:Rectangle = source.getBounds(source);
			
			// get from pool
			var TL:Point = EnginePools.PointPool.borrowObject();
			TL.x = bounds.left;
			TL.y = bounds.top;
			var BR:Point = EnginePools.PointPool.borrowObject();
			BR.x = bounds.right;
			BR.y = bounds.bottom;
			var TR:Point = EnginePools.PointPool.borrowObject();
			TR.x = bounds.right;
			TR.y = bounds.top;
			var BL:Point = EnginePools.PointPool.borrowObject();
			BL.x = bounds.left;
			BL.y = bounds.bottom;
			
			// rotate
			const rotTL:Point = transform.transformPoint(TL);
			const rotBR:Point = transform.transformPoint(BR);
			const rotTR:Point = transform.transformPoint(TR);
			const rotBL:Point = transform.transformPoint(BL);
			
			// find the coordinates of the sides of the bounding rectangle
			const rotL:Number = Math.min(rotTL.x, rotTR.x, rotBR.x, rotBL.x);
			const rotT:Number = Math.min(rotTL.y, rotTR.y, rotBR.y, rotBL.y);
			const rotR:Number = Math.max(rotTL.x, rotTR.x, rotBR.x, rotBL.x);
			const rotB:Number = Math.max(rotTL.y, rotTR.y, rotBR.y, rotBL.y);
			
			// determine which BMDs the source intersects and only draw in those
			const rowStart:int = MathUtil.clamp(0, rows-1, Math.floor(rotT / bitmapHeight));
			const rowEnd:int   = MathUtil.clamp(1, rows,    Math.ceil(rotB / bitmapHeight));
			const colStart:int = MathUtil.clamp(0, cols-1, Math.floor(rotL / bitmapWidth));
			const colEnd:int   = MathUtil.clamp(1, cols,    Math.ceil(rotR / bitmapWidth));
			
			// return to pools
			EnginePools.PointPool.returnObject(TL);
			TL = null;
			EnginePools.PointPool.returnObject(TR);
			TR = null;
			EnginePools.PointPool.returnObject(BL);
			BL = null;
			EnginePools.PointPool.returnObject(BR);
			BR = null;
			
			////////////////////////////////////////////////////////////////////
			
			var row:int;
			var col:int;
			for (row=rowStart; row<rowEnd; row++) {
				for (col=colStart; col<colEnd; col++) {
					// since BMDs each start at (0,0), I need to offset the
					// transform up and to the left the further away the BMD
					// is from the top left BMD
					transform.tx = tx - (col * bitmapWidth);
					transform.ty = ty - (row * bitmapHeight);
					bmd = bitmapDatas[int(row*cols+col)];
					// lazy-load these since they're costly
					if (!bmd) {
						try {
							bmd = new BitmapData(bitmapWidth, bitmapHeight, transparency, fillColor);
						} catch (e:Error) {
							throw new Error("Error: LargeBitmap(" + bitmapWidth + ',' + bitmapHeight + ',' + transparency + ',' + fillColor + ')\n' + StringUtil.getShorterStackTrace(e));
						}
						bitmapDatas[int(row*cols+col)] = bmd;
						_bitmaps[int(row*cols+col)].bitmapData = bmd;
						addChild(_bitmaps[int(row*cols+col)]);
					}
					bmd.draw(source, transform);
				}
			}
			
			// restore
			transform.tx = tx;
			transform.ty = ty;
		}
	}
	
	/** Blits the BitmapData into the layer, no transforms */
	public function drawBitmapData(bmd:BitmapData, sourceRect:Rectangle, destPoint:Point):void {
		if (finalized) return;
		//TODO decoBitmapData.copyPixels(bmd, sourceRect, destPoint);
	}
	
	/** Copies pixels from the LargeBitmap's child bitmaps to the destination BitmapData. */ 
	public function copyPixelsTo(destination:BitmapData, sourceTopLeftX:Number, sourceTopLeftY:Number):void {		
		
		const colOffsetX:int = sourceTopLeftX - xOffset;
		const leftCol:int = colOffsetX / bitmapWidth;
		const rightCol:int = (colOffsetX + destination.width) / bitmapWidth;
		if (leftCol < 0 || rightCol < 0) return;
		
		const colOffsetY:int = sourceTopLeftY - yOffset;
		const topRow:int = colOffsetY / bitmapHeight; 
		const bottomRow:int = (colOffsetY + destination.height) / bitmapHeight;
		if (topRow < 0 || bottomRow < 0) return;
		
		var curBitmapData:BitmapData;
		var curBitmap:Bitmap;
		for (var i:uint = topRow; i <= bottomRow; i++) {
			
			for (var j:uint = leftCol; j <= rightCol; j++) {
				
				// if we're copying from outside the LargeBitmap's dimensions, continue;
				var bitmapIndex:uint = i * cols + j;
				if (bitmapIndex >= _bitmaps.length) continue;
				
				curBitmap = _bitmaps[bitmapIndex];
				if (!curBitmap) continue;
				
				curBitmapData = curBitmap.bitmapData;
				if (!curBitmapData) continue;
				
				copyPixelsHelperPoint.x = curBitmap.x - sourceTopLeftX;
				copyPixelsHelperPoint.y = curBitmap.y - sourceTopLeftY;
				
				destination.copyPixels(curBitmapData, curBitmapData.rect, copyPixelsHelperPoint, null, null, true);
			}
		}
	}
	
	public function dispose():void {
		while (numChildren) {
			removeChildAt(0);
		}
		
		for each (var bm:Bitmap in _bitmaps) {
			if(bm) bm.bitmapData = null;
		}
		_bitmaps = null;
		
		for each (var bmd:BitmapData in bitmapDatas) {
			if (bmd) bmd.dispose();
		}
		bitmapDatas = null;
		
		finalized = true;
	}
	
	/** Returns 0 if the point doesn't exist, or an ARGB uint if it does */
	public function getPixel32(point:Point):uint {
		// determine which BMD the source intersects
		//NOTE: this will have to be updated if bitmaps can overlap
		const offsetX:int = (point.x - xOffset);
		const offsetY:int = (point.y - yOffset);

		const col:int = Math.floor(offsetX / bitmapWidth);
		const row:int = Math.floor(offsetY / bitmapHeight);
		
		if ((row >= 0) && (row < rows) && (col >= 0) && (col < cols)) {
			const bmd:BitmapData = bitmapDatas[int(row*cols+col)];
			if (bmd) {
				const bmdX:int = (offsetX - (col*bitmapWidth));
				const bmdY:int = (offsetY - (row*bitmapHeight));
				return bmd.getPixel32(bmdX, bmdY);
			}
		}
		return 0;
	}
	
	public function setPixel32(point:Point, color:uint):void {
		// determine which BMD the source intersects
		//NOTE: this will have to be updated if bitmaps can overlap
		const offsetX:int = (point.x - xOffset);
		const offsetY:int = (point.y - yOffset);
		
		const col:int = Math.floor(offsetX / bitmapWidth);
		const row:int = Math.floor(offsetY / bitmapHeight);
		
		if ((row >= 0) && (row < rows) && (col >= 0) && (col < cols)) {
			const bmd:BitmapData = bitmapDatas[int(row*cols+col)];
			if (bmd) {
				const bmdX:int = (offsetX - (col*bitmapWidth));
				const bmdY:int = (offsetY - (row*bitmapHeight));
				bmd.setPixel32(bmdX, bmdY, color);
			}
		}
	}

	/** Represents a row-oriented 2D grid of bitmaps: row0, row1, ... */
	public function get bitmaps():Vector.<Bitmap> {
		return _bitmaps;
	}

	public function get segmentDimension():uint {
		return _segmentDimension;
	}
}
}
