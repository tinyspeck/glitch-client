package com.tinyspeck.engine.view.ui.favor
{
	import com.tinyspeck.engine.data.giant.GiantFavor;
	
	import flash.display.Sprite;

	public class GiantFavorUI extends Sprite
	{
		protected var progress_bars:Vector.<FavorProgressUI> = new Vector.<FavorProgressUI>();
		protected var current_favor:Vector.<GiantFavor>;
		
		protected var gap_w:int = 28;
		protected var gap_h:int = 20;
		protected var max_rows:uint = 6;
		
		public function GiantFavorUI(){}
		
		public function show(favor_ob:Object):void {
			//break it down and sort them by most favor
			current_favor = GiantFavor.parseMultiple(favor_ob);
			
			var i:int;
			var next_x:int;
			var next_y:int;
			var total:int = progress_bars.length;
			var favor_pb:FavorProgressUI;
			
			//reset the pool
			for(i = 0; i < total; i++){
				progress_bars[int(i)].hide();
			}
			
			//build it out
			total = current_favor.length;
			for(i = 0; i < total; i++){
				if(i < progress_bars.length){
					favor_pb = progress_bars[int(i)];
				}
				else {
					//make a new one
					favor_pb = new FavorProgressUI();
					progress_bars.push(favor_pb);
				}
				
				//show it
				favor_pb.show(current_favor[int(i)]);
				
				if(i > 0 && i % max_rows == 0){
					next_y = 0;
					next_x += favor_pb.width + gap_w;
				}
				
				favor_pb.x = next_x;
				favor_pb.y = next_y;
				next_y += favor_pb.height + gap_h;
				
				addChild(favor_pb);
			}
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
	}
}