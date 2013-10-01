package com.tinyspeck.engine.view.ui {
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;

	public class DoorIcon extends MovieClip {
		public static const SIZE:int = 50;
		
		private var holder_sp:Sprite = new Sprite();
		private var mask_sh:Shape = new Shape();
		private var pc:PC;
		private var is_built:Boolean;
		
		public function DoorIcon(pc:PC){
			this.pc = pc;
		}
		
		private function build():void {
			mask_sh.graphics.lineStyle(0, 0, 0);
			mask_sh.graphics.beginFill(0, 1);
			mask_sh.graphics.drawCircle(SIZE/2, SIZE/2, SIZE/2);
			addChild(mask_sh);
			
			holder_sp.graphics.lineStyle(0, 0, 0);
			holder_sp.graphics.beginFill(0xffffff, 1);
			holder_sp.graphics.drawRect(0, 0, SIZE, SIZE);
			holder_sp.mask = mask_sh;
			
			addChild(holder_sp);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) build();
			
			//load the single if it's different
			if (pc.singles_url && holder_sp.name != pc.singles_url) {
				while(holder_sp.numChildren) holder_sp.removeChildAt(0);
				holder_sp.name = pc.singles_url;
				AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_172.png', bmLoaded, 'DoorIcon');
			}
		}
		
		private function bmLoaded(filename:String, bm:Bitmap):void {
			if (!bm) {
				return;
			}
			//just in case
			while(holder_sp.numChildren) holder_sp.removeChildAt(0);
			
			bm.smoothing = true;
			bm.x = 5;

			// trim the given BitmapData down to SIZE
			const scale:Number = (SIZE / bm.width);
			const trimmedBMD:BitmapData = new BitmapData(SIZE, SIZE, true, 0);
			
			var m:Matrix = EnginePools.MatrixPool.borrowObject();
			m.scale(scale, scale);
			trimmedBMD.draw(bm, m);
			EnginePools.MatrixPool.returnObject(m);
			m = null;
			
			bm.bitmapData.dispose();
			bm.bitmapData = trimmedBMD;
			
			holder_sp.addChild(bm);
		}
	}
}