package com.tinyspeck.engine.view
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	
	import flash.display.Graphics;
	
	public class CheckListView extends TSSpriteWithModel {
		
		private var padd:int = 6;
		
		public function CheckListView(w:int):void {
			super('CheckListView');
			_w = w;
		}
		
		public function addListItem(txt:String):CheckListItemView {
			var cliv:CheckListItemView = new CheckListItemView(txt);
			cliv.y = height+(height?padd:0);
			addChild(cliv);
			draw();
			return cliv;
		}
		
		public function clearListItems():void {
			var cliv:CheckListItemView;
			while (numChildren) {
				cliv = getChildAt(0) as CheckListItemView;
				if (cliv) {
					removeChild(cliv);
					cliv.dispose();
				} else {
					CONFIG::debugging {
						Console.error('wtf')
					}
				}
			}
			draw();
		}
 		
		override public function get h():int {
			return height;
		}
		
		override public function get w():int {
			return _w;
		}
		
		private function draw():void {
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(0, 0);
			g.drawRect(0, 0, _w, height);
		}
		
	}
}
