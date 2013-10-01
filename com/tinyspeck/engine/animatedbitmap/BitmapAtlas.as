package com.tinyspeck.engine.animatedbitmap {
	import flash.display.BitmapData;
	
	/**
	 * Consists of a BitmapData sprite sheet and BitmapAtlasFrames that define regions within the sprite sheet.
	 */
	public class BitmapAtlas {
		
		private var _sheetBMD:BitmapData;
		private var _frames:Vector.<AnimatedBitmapFrame>;
		
		private var _maxFrameWidth:Number;	// largest width out of all frames
		private var _maxFrameHeight:Number; // largest height out of all frames
		
		// if the sprite sheet was scaled down, divide the AnimatedBitmap's dimensions by
		// these scale factors to scale up the resulting animation to the correct dimensions.
		private var _scaleFactorX:Number;
		private var _scaleFatorY:Number;
		
		public function BitmapAtlas(sheetBMD:BitmapData, frames:Vector.<AnimatedBitmapFrame>, maxFrameWidth:Number, maxFrameHeight:Number, scaleFactorX:Number, scaleFactorY:Number) {
			_sheetBMD = sheetBMD;
			_frames = frames;
			_maxFrameWidth = maxFrameWidth;
			_maxFrameHeight = maxFrameHeight;
			_scaleFactorX = scaleFactorX;
			_scaleFatorY = scaleFactorY;
		}

		public function get sheetBMD():BitmapData { return _sheetBMD; }
		public function get frames():Vector.<AnimatedBitmapFrame> { return _frames; }
		public function get maxFrameWidth():Number { return _maxFrameWidth; }
		public function get maxFrameHeight():Number { return _maxFrameHeight; }
		public function get scaleFactorX():Number { return _scaleFactorX; }
		public function get scaleFatorY():Number { return _scaleFatorY; }
	}
}