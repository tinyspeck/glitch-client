package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.view.renderer.DecoRenderer;
	import com.tinyspeck.engine.view.renderer.LargeBitmap;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * Draws DecoRenderer in a LargeBitmap.
	 */ 
	public class DrawDecoInLargeBitmapCmd implements ICommand {
		
		public var decoRenderer:DecoRenderer;
		public var largeBitmap:LargeBitmap;
		public var useMiddleGroundOffsets:Boolean;
		
		private var worldModel:WorldModel;
		private var flashVarModel:FlashVarModel;
		
		private const m:Matrix = new Matrix();
		
		public function DrawDecoInLargeBitmapCmd() {
			flashVarModel = TSModelLocator.instance.flashVarModel;
			worldModel = TSModelLocator.instance.worldModel;
		}

		public function execute():void {
			const deco:Deco = decoRenderer.deco;
			
			// create a bitmap large enough to hold the rotated deco
			var bmd:BitmapData;
			var bitmap:Bitmap;

			// reset matrix
			m.identity();
			
			// apply transforms
			if (deco.h_flip) {
				m.scale(-1, 1);
				m.translate(deco.w, 0);
			}
			
			// not currently supported
			//if (deco.v_flip) {
			//	m.scale(1, -1);
			//	m.translate(0, deco.h);
			//}
			
			m.rotate(deco.r*MathUtil.DEG_TO_RAD);
			
			// some classes have drawing problems (halos show up round gradients), e.g.:
			// glowing_orb_,cloud_fluffy_,purple_mushroom_
			// these problems can be fixed by either drawing onto an intermediate bitmap
			// or simply turning on cacheAsBitmap
			decoRenderer.cacheAsBitmap = true;
			
			// hflip_hack is needed when the matrix scale x is -1 (hflipped)
			// can occur from setting h_flip property or rotating 180 degrees
			var hflip_hack:Boolean = (flashVarModel.hflip_hack && deco.h_flip);
			
			// we can't do these hacks if the deco's dimensions exceed the maximum dimensions of a bitmapdata
			// hopefully it's not one of the decos that crash...
			if (((deco.w*deco.h) > LargeBitmap.MAX_PIXELS) || (deco.w > LargeBitmap.MAX_DIMENSION) || (deco.h > LargeBitmap.MAX_DIMENSION)) {
				hflip_hack = false;
			}
			
			// draw it
			if (hflip_hack) {
				// first create a matrix that converts coordinates in the
				// unrotated DecoRenderer's vector space to rotated
				// coordinates in the bitmap's vector space
				
				// get from pool
				var decoToTarget:Matrix = EnginePools.MatrixPool.borrowObject();
				// apply transforms
				if (deco.h_flip && !flashVarModel.hflip_hack) {
					decoToTarget.scale(-1, 1);
					decoToTarget.translate(deco.w, 0);
				}
				// rotate
				decoToTarget.rotate(deco.r*MathUtil.DEG_TO_RAD);
				
				// find the bounds of the rotated rectangle
				// get from pool
				var ORIGIN:Point = EnginePools.PointPool.borrowObject();
				// implied:
				//ORIGIN.x = 0;
				//ORIGIN.y = 0;
				var TL:Point = EnginePools.PointPool.borrowObject();
				TL.x = Math.floor(-deco.w/2);
				TL.y = -deco.h;
				var BR:Point = EnginePools.PointPool.borrowObject();
				BR.x = Math.floor(deco.w/2);
				BR.y = 0;
				var TR:Point = EnginePools.PointPool.borrowObject();
				TR.x = BR.x;
				TR.y = TL.y;
				var BL:Point = EnginePools.PointPool.borrowObject();
				BL.x = TL.x;
				BL.y = BR.y;
				
				const rotTL:Point = decoToTarget.transformPoint(TL);
				const rotBR:Point = decoToTarget.transformPoint(BR);
				const rotTR:Point = decoToTarget.transformPoint(TR);
				const rotBL:Point = decoToTarget.transformPoint(BL);
				
				const rotL:Number = Math.min(rotTL.x, rotTR.x, rotBR.x, rotBL.x);
				const rotT:Number = Math.min(rotTL.y, rotTR.y, rotBR.y, rotBL.y);
				const rotR:Number = Math.max(rotTL.x, rotTR.x, rotBR.x, rotBL.x);
				const rotB:Number = Math.max(rotTL.y, rotTR.y, rotBR.y, rotBL.y);
				
				const rotW:Number = (rotR - rotL);
				const rotH:Number = (rotB - rotT);
				
				// shift the top-left of the rotated deco into the bottom-right quadrant
				if (rotL < 0) decoToTarget.tx -= rotL;
				if (rotT < 0) decoToTarget.ty -= rotT;
				
				// create a bitmap large enough to hold the rotated deco
				bmd = new BitmapData(rotW, rotH, true, 0);
				bitmap = new Bitmap(bmd);
				
				// find the rotated top-left origin
				const rotOrigin:Point = decoToTarget.transformPoint(ORIGIN);
				
				// apply transforms and draw onto bmd
				
				// the hflip_hack fixes sporadic crashes caused by hflipping bad
				// textures (occurs when using scaleX = -1 or creating a matrix
				// that has the same effect); so the hack rotates the deco the
				// opposite direction so it can naively swap pixels horizontally
				// achieving the same thing as hflipping
				// (in other words: if we were going to rotate the deco
				// -45 degrees and hflip it using scaleX, instead we're
				// going to rotate it +45 degrees and hflip it by swapping
				// pixels from the left and right side of the bitmap)
				
				// now create a matrix that converts coordinates from the
				// original DecoRenderer's vector space to
				// negatively-rotated coordinates in the bitmap vector space
				// (to save work, rotate decoToTarget 180 degrees about
				// its center point)
				
				// get from pool
				var decoToFlippedTarget:Matrix = EnginePools.MatrixPool.borrowObject();
				// clear it
				decoToFlippedTarget.identity();
				// copy decoToTarget
				decoToFlippedTarget.concat(decoToTarget);
				// rotate about center
				decoToFlippedTarget.translate(-rotW/2, -rotH/2);
				decoToFlippedTarget.rotate(-2*deco.r*MathUtil.DEG_TO_RAD);
				decoToFlippedTarget.translate(rotW/2, rotH/2);
				
				bmd.draw(decoRenderer, decoToFlippedTarget);
				
				// return to pools
				EnginePools.MatrixPool.returnObject(decoToFlippedTarget);
				decoToFlippedTarget = null;
				
				
				// return to pools
				EnginePools.MatrixPool.returnObject(decoToTarget);
				decoToTarget = null;
				EnginePools.PointPool.returnObject(TL);
				TL = null;
				EnginePools.PointPool.returnObject(TR);
				TR = null;
				EnginePools.PointPool.returnObject(BL);
				BL = null;
				EnginePools.PointPool.returnObject(BR);
				BR = null;
				EnginePools.PointPool.returnObject(ORIGIN);
				ORIGIN = null;
				
				// flip a bitch
				// optimization copies strips of full height
				const bmdW:int = bmd.width;
				const bmdWD2:int = (bmdW >> 1);
				var bmdStrip:BitmapData = new BitmapData(1, bmd.height, true, 0);
				
				// get from pool
				var rectStrip:Rectangle = EnginePools.RectanglePool.borrowObject();
				// implied:
				//rectStrip.x = 0;
				//rectStrip.y = 0;
				rectStrip.width = 1;
				rectStrip.height = bmdStrip.height;
				
				// get from pool
				var tmpPoint:Point = EnginePools.PointPool.borrowObject();
				// implied:
				//tmpPoint.x = 0;
				//tmpPoint.y = 0;
				for (var j:int=0; j<bmdWD2; j++) {
					// save left strip
					rectStrip.x = j;
					tmpPoint.x = 0;
					bmdStrip.copyPixels(bmd, rectStrip, tmpPoint);
					
					// blit right strip to left strip
					rectStrip.x = (bmdW - j - 1);
					tmpPoint.x = j;
					bmd.copyPixels(bmd, rectStrip, tmpPoint);
					
					// blit left strip to right strip
					rectStrip.x = 0;
					tmpPoint.x = (bmdW - j - 1);
					bmd.copyPixels(bmdStrip, rectStrip, tmpPoint);
				}
				// clean up
				bmdStrip.dispose();
				bmdStrip = null;
				
				// return to pool
				EnginePools.RectanglePool.returnObject(rectStrip);
				rectStrip = null;
				EnginePools.PointPool.returnObject(tmpPoint);
				tmpPoint = null;
				
				
				// position the deco on the bitmapdata
				// take a clean matrix and translate to the unrotated origin
				m.identity();
				m.translate(deco.x, deco.y);
				if (useMiddleGroundOffsets) {
					// translate the origin to (0,0)
					// (bitmapdata don't have negative coordinates)
					m.tx -= worldModel.location.l;
					m.ty -= worldModel.location.t;
				}
				// now correct the origin for rotation
				m.translate(-rotOrigin.x, -rotOrigin.y);
				
				// draw!
				largeBitmap.draw(bitmap, m);
				
				// clean up
				bitmap.bitmapData = null;
				bmd.dispose();
			} else {
				// position the deco on the bitmapdata
				if (useMiddleGroundOffsets) {
					// translate the origin to (0,0)
					// (bitmapdata don't have negative coordinates)
					m.tx = deco.x - worldModel.location.l;
					m.ty = deco.y - worldModel.location.t;
				} else {
					m.tx = deco.x;
					m.ty = deco.y;
				}
				
				largeBitmap.draw(decoRenderer, m);
			}
		}		
	}
}