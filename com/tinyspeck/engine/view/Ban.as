package com.tinyspeck.engine.view {
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	public class Ban extends Sprite {
		
		public static const WIDTH:int = 50;
		
		public function Ban():void {
			var line_size:int = 10;
			var r:int = (WIDTH-line_size)/2;
			var g:Graphics = this.graphics;
			
			g.lineStyle(line_size, 0xcc0000, 1);
			g.drawCircle(WIDTH/2, WIDTH/2, r);
			
			var x:int = (WIDTH/2) + r * Math.cos(Math.PI*-.75)
			var y:int = (WIDTH/2) + r * Math.sin(Math.PI*-.75);
			g.moveTo(x+1,y+1);
			g.lineTo(WIDTH-x+-1,WIDTH-y+-1);
		}
	}
}
