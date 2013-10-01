package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.SDBItemInfo;
	
	import flash.display.Sprite;

	public class ItemSellersUI extends Sprite
	{
		private var elements:Vector.<ItemSaleUI> = new Vector.<ItemSaleUI>();
		
		private var w:int;
		
		public function ItemSellersUI(w:int){
			this.w = w;
		}
		
		public function show(items:Vector.<SDBItemInfo>):void {
			if(!items) return;
			
			//loop through and show things
			var total:int = elements.length;
			var i:int;
			var item:SDBItemInfo;
			var element:ItemSaleUI;
			var next_y:int;
			
			//clear the pool
			for(i = 0; i < total; i++){
				elements[int(i)].hide();
			}
			
			total = items.length;
			for(i = 0; i < total; i++){
				item = items[int(i)];
				if(elements.length > i){
					element = elements[int(i)];
				}
				else {
					element = new ItemSaleUI(w);
					elements.push(element);
				}
				
				element.show(item, i % 2 == 1, i == total-1);
				element.y = next_y;
				next_y += element.height;
				addChild(element);
			}
		}
	}
}