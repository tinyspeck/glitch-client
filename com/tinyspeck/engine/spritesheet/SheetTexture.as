package com.tinyspeck.engine.spritesheet
{
	import flash.display.BitmapData;

	public class SheetTexture
	{
		
		public var bitmapData:BitmapData;
		public var width:int;
		public var height:int;
		public var x:int;
		public var y:int;
		public var longestEdge:int;
		public var area:int;
		public var flipped:Boolean;
		public var placed:Boolean;
			
		public function SheetTexture(bitmapData:BitmapData)
		{
			this.bitmapData = bitmapData;
			this.width = bitmapData.width+1;
			this.height = bitmapData.height+1;
			init();
		}
		
		private function init():void
		{
			x = 0;
			y = 0;
			flipped = false;
			placed = false
			area = width*height;
			if(width > height){
				longestEdge = width;
			}else{
				longestEdge = height;
			}
		}
				
		public function place(x:int,y:int,flipped:Boolean):void
		{
			this.x = x;
			this.y = y;
			this.flipped = flipped;
			this.placed = true;
		}		
	}
}