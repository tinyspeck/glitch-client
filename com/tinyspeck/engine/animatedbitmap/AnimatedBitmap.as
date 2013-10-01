package com.tinyspeck.engine.animatedbitmap {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * Bitmap which achieves animation by using copyPixels to draw pre-defined frames within a "sprite sheet" to a canvas.
	 */
	public class AnimatedBitmap extends Bitmap {
		
		private const helperPoint:Point = new Point();
		private const clearRect:Rectangle = new Rectangle();
		
		private var frames:Vector.<AnimatedBitmapFrame>;
		private var _totalFrames:uint;
		private var loop:Boolean;
		private var currentFrameIndex:uint = 0;
		private var currentFrame:AnimatedBitmapFrame;
		
		private var displayListX:Number = 0; // this DisplayObject's x coordinate without considering animation frame offset
		private var displayListY:Number = 0; // this DisplayObject's y coordinate without considering animation frame offset
		
		private var maxFrameWidth:Number;	// used to determine the animation's width
		private var maxFrameHeight:Number; 	// used to determine the animation's height
		
		private var spriteSheet:BitmapData;
		private var canvas:BitmapData;
		
		private var disposed:Boolean = false;
		private var isPlaying:Boolean = false;
		
		public function AnimatedBitmap(bitmapAtlas:BitmapAtlas, loop:Boolean = true, pixelSnapping:String="auto", smoothing:Boolean=false) {
			super(null, pixelSnapping, smoothing);
			
			spriteSheet = bitmapAtlas.sheetBMD; 
			
			frames = bitmapAtlas.frames;
			_totalFrames = frames.length;
			this.loop = loop;
			
			maxFrameWidth = bitmapAtlas.maxFrameWidth;
			maxFrameHeight = bitmapAtlas.maxFrameHeight;
			
			canvas = new BitmapData(maxFrameWidth, maxFrameHeight, true, 0);
			bitmapData = canvas;
			
			clearRect.width = maxFrameWidth;
			clearRect.height = maxFrameHeight;
			
			showCurrentFrame();
		}
		
		public function play():void {
			if (_totalFrames == 1) return;
			
			isPlaying = true;
			addEventListener(Event.ENTER_FRAME, onFrameEntered, false, 0, true);
		}
		
		public function stop():void {
			if (_totalFrames == 1) return;
			
			isPlaying = false;
			removeEventListener(Event.ENTER_FRAME, onFrameEntered);
		}
		
		private function onFrameEntered(e:Event):void {
			if (disposed) return;
			
			if (visible) showCurrentFrame();
			
			currentFrameIndex++;
			if (currentFrameIndex == _totalFrames) {
				if (!loop) {
					stop();
					return;
				}				
				currentFrameIndex = 0;
			}			
		}
		
		/** Draw the current animation frame from the sprite sheet to the canvas */
		private function showCurrentFrame():void {
			currentFrame = frames[currentFrameIndex];
						
			canvas.fillRect(clearRect, 0);
			canvas.copyPixels(spriteSheet, currentFrame.scrollRect, helperPoint);
			
			updateX();
			updateY();
		}		
		
		/** The actual X coordinate must consider the left offset of the current frame */
		private function updateX():void {
			super.x = displayListX + currentFrame.displayListX * scaleX;
		}
		
		/** The actual Y coordinate must consider the top offset of the current frame */
		private function updateY():void {
			super.y = displayListY + currentFrame.displayListY * scaleY;
		}
		
		/** Return the unmodified x coord */
		override public function get x():Number { return displayListX; }
		
		/** Keep track of unmodified x, and update the actual x with consideration of frame offset */ 
		override public function set x(value:Number):void { 
			displayListX = value;
			updateX();
		}
		
		/** Return unmodified y coord */
		override public function get y():Number { return displayListY; }
		
		/** Keep track of unmodified y, and update the actual y with consideration of frame offset */
		override public function set y(value:Number):void { 
			displayListY = value;
			updateY();
		}
		
		/** Don't return the width of the entire sprite sheet, instead return the animation's dimensions */
		override public function get width():Number { return maxFrameWidth * scaleX; }	
		
		/** Make sure the animation's width changes, not the width of the entire sprite sheet */
		override public function set width(value:Number):void {
			scaleX = value / maxFrameWidth;
		}
		
		/** Dont't return the height of the entire sprite sheet, instead return the animation's dimensions */
		override public function get height():Number { return maxFrameHeight * scaleY; }
		
		/** Make sure the animation's height changes, not the height of the entire sprite sheet */
		override public function set height(value:Number):void {
			scaleY = value / maxFrameHeight;
		}
		
		public function dispose():void {
			if (isPlaying) stop();
			
			canvas.dispose();
			disposed = true;
		}

		public function get totalFrames():uint {
			return _totalFrames;
		}
	}
}
