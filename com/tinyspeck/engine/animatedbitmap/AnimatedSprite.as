package com.tinyspeck.engine.animatedbitmap {
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	
	/**
	 * Sprite which achieves animation by using Graphics.beginBitmapFill to draw pre-defined frames within a "sprite sheet".
	 */
	public class AnimatedSprite extends Sprite {
		
		private const helperMatrix:Matrix = new Matrix();
		
		private var frames:Vector.<AnimatedBitmapFrame>;
		private var loop:Boolean;
		private var currentFrameIndex:uint = 0;
		private var currentFrame:AnimatedBitmapFrame;
		
		private var displayListX:Number = 0; // this DisplayObject's x coordinate without considering animation frame offset
		private var displayListY:Number = 0; // this DisplayObject's y coordinate without considering animation frame offset
		
		private var maxFrameWidth:Number;	// used to determine the animation's width
		private var maxFrameHeight:Number; 	// used to determine the animation's height
		
		private var spriteSheet:BitmapData;
		
		public function AnimatedSprite(bitmapAtlas:BitmapAtlas, loop:Boolean = true) {
			super();
			
			spriteSheet = bitmapAtlas.sheetBMD; 
			
			this.frames = bitmapAtlas.frames;
			this.loop = loop;
			
			maxFrameWidth = bitmapAtlas.maxFrameWidth;
			maxFrameHeight = bitmapAtlas.maxFrameHeight;
			
			showCurrentFrame();
		}
		
		public function play():void {
			addEventListener(Event.ENTER_FRAME, onFrameEntered, false, 0, true);
		}
		
		public function stop():void {
			removeEventListener(Event.ENTER_FRAME, onFrameEntered);
		}
		
		private function onFrameEntered(e:Event):void {
			
			if (currentFrameIndex == frames.length) {
				if (!loop) {
					stop();
					return;
				}				
				currentFrameIndex = 0;
			}			
			
			showCurrentFrame();
			currentFrameIndex++;
		}
		
		/** Draw the current animation frame from the sprite sheet to the canvas */
		private function showCurrentFrame():void {
			currentFrame = frames[currentFrameIndex];
			
			helperMatrix.tx = -currentFrame.scrollRect.x;
			helperMatrix.ty = -currentFrame.scrollRect.y;
			graphics.clear();
			graphics.beginBitmapFill(spriteSheet, helperMatrix, false, true);
			graphics.drawRect(0,0,currentFrame.scrollRect.width, currentFrame.scrollRect.height);
			graphics.endFill();
			
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
	}
}
