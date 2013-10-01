package com.tinyspeck.engine.spritesheet
{
	public class SSGenOptions
	{
		public static var TYPE_MULTIPLE_BITMAPS:int = 0;
		public static var TYPE_SINGLE_BITMAP:int = 1;
				
		public var max_h:int = 0;
		public var max_w:int = 0;
		public var type:int = 0;
		public var scale:Number;
		public var rotation:Number;
		public var filters:Array;
		public var movieWidth:Number;
		public var movieHeight:Number;
		public var frame_padd:int = 0;
		public var transparent:Boolean = true;
		public var double_measure:Boolean = false;
		
		public function SSGenOptions(type:int = 0, movieWidth:Number = -1, movieHeight:Number = -1, scale:Number = 1, rotation:Number = 0, filters:Array = null) {
			this.type = type;
			this.movieWidth = movieWidth;
			this.movieHeight = movieHeight;
			this.scale = scale;
			this.rotation = rotation;
			this.filters = filters;
		}
		
		public function toString():String {
			return "SSGenOptions[" +
				'type:' + (type == TYPE_SINGLE_BITMAP ? 'SINGLE' : 'MULTI') + ', ' +
				'movieWidth:' + movieWidth + ', ' +
				'movieHeight:' + movieHeight + ', ' +
				'scale:' + scale + ', ' +
				'rotation:' + rotation + ', ' +
				'filters:' + filters +
				']';
		}
	}
}