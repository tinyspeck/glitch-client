package com.tinyspeck.engine.view.ui {
	
	import com.tinyspeck.engine.event.TSEvent;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	
	public class TabbedPane extends Sprite {
		
		private var w:int;
		private var h:int;
		private var tab_h:int;
		private var tab_w:int;
		private var line_c:uint = 0x000000;
		private var bg_c:uint = 0x000000;
		private var bg_alpha:uint = 1;
		private var corner_radius:int = 22;
		private var tab_holder:Sprite = new Sprite();
		private var pane_holder:Sprite = new Sprite();
		private var mask_sp:Sprite = new Sprite();
		
		public function TabbedPane(w:int, h:int, tab_w:int, tab_h:int, line_c:uint, bg_c:uint, bg_alpha:Number, corner_radius:int = -1) {
			super();
			this.w = w;
			this.h = h;
			this.tab_w = tab_w;
			this.tab_h = tab_h;
			this.line_c = line_c;
			this.bg_c = bg_c;
			this.bg_alpha = bg_alpha;
			if (corner_radius > -1) this.corner_radius = corner_radius;
			init();
		}
		
		private function init():void {
			addChild(pane_holder);
			addChild(tab_holder);
			pane_holder.y = tab_h;
			addChild(mask_sp);
			mask_sp.y = tab_h;
			
			draw();
		}
		
		public function getTabContentById(id:String):TabbedPaneContent {
			return pane_holder.getChildByName(id) as TabbedPaneContent;
		}
		
		private function draw():void {
			var g:Graphics = pane_holder.graphics;
			g.clear();
			g.lineStyle(0, line_c, 1, true);
			g.beginFill(bg_c, bg_alpha);
			g.drawRoundRect(0, 0, w, pane_h, corner_radius);
			
			g = mask_sp.graphics;
			g.clear();
			g.lineStyle(0, line_c, 1, true);
			g.beginFill(bg_c, 1);
			g.drawRoundRect(0, 0, w, pane_h, corner_radius);
		}
		
		public function addTab(id:String, label:String, content:TabbedPaneContent):void {
			content.graphics.beginFill(0, 0);
			content.graphics.drawRect(0, 0, w, pane_h);
			content.mask = mask_sp;
			content.name = id;
			var tab:TabbedPaneTab = new TabbedPaneTab(id, label, tab_w, tab_h, line_c, bg_c, bg_alpha, 10);
			tab_holder.addChild(tab);
			placeTabs();
			activateTab(id);
			tab.addEventListener(MouseEvent.CLICK, onTabClick, false, 0, true);
			
			pane_holder.addChild(content);
		}
		
		private function onTabClick(event:MouseEvent):void {
			var tab:TabbedPaneTab = event.target as TabbedPaneTab;
			
			activateTab(tab.name);
		}
		
		public function activateTab(id:String):void {
			var tab:TabbedPaneTab;
			var content:TabbedPaneContent;
			for (var i:int;i<tab_holder.numChildren;i++) {
				tab = tab_holder.getChildAt(i) as TabbedPaneTab;
				if (tab.name == id) {
					tab.makeActive();
				} else {
					tab.makeInActive();
				}
				//bt.disabled = (bt.name != id);
			}
			for (i=0;i<pane_holder.numChildren;i++) {
				content = pane_holder.getChildAt(i) as TabbedPaneContent;
				content.visible = (content.name == id);
			}
			dispatchEvent(new TSEvent(TSEvent.CHANGED, id));
		}
		
		private function placeTabs():void {
			var tabs_w:int;
			var tab:TabbedPaneTab;
			var new_x:int;
			for (var i:int;i<tab_holder.numChildren;i++) {
				if (tab) new_x = tab.x+tab.width;
				tab = tab_holder.getChildAt(i) as TabbedPaneTab;
				tab.x = new_x;
			}
			tab_holder.x = Math.round((w-tab_holder.width)/2);
		}
		
		public function get pane_h():int {
			return h-tab_h;
		}
	}
}