package com.tinyspeck.engine.view.ui {
	import flash.display.Sprite;
	
	public class TabbedPaneContent extends Sprite {
		
		private var pagesA:Array = [];
		
		public function TabbedPaneContent() {
			super();
		}
		
		public function getPage(page_index:int):Sprite {
			if (page_index > pagesA.length-1) {
				pagesA[page_index] = new Sprite();
				addChild(pagesA[page_index]);
			}
			
			return pagesA[page_index];
		}
	
	}
}