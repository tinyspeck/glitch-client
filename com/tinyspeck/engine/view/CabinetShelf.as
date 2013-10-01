package com.tinyspeck.engine.view
{
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	public class CabinetShelf extends MovieClip {
		
		private var end_left:DisplayObject;
		private var end_right:DisplayObject;
		private var center:DisplayObject;
		private var _w:int = 100;

		override public function set width(value:Number):void {
			_w = Math.round(value);
			stretch();
		}

		public function CabinetShelf():void {
			build();
		}
		
		private function build():void {
			end_left = new AssetManager.instance.assets['cabinet_shelf_wood_end_left']();
			center = new AssetManager.instance.assets['cabinet_shelf_wood_center']();
			end_right = new AssetManager.instance.assets['cabinet_shelf_wood_end_right']();
			
			addChild(end_left);
			addChild(center);
			addChild(end_right);
			
			end_left.x = 0;
			center.x = end_left.x+end_left.width;
			stretch();
		}
		
		private function stretch():void {
			center.width = _w-(end_left.width+end_right.width);
			end_right.x = center.x+center.width
		}
		
	}
}
