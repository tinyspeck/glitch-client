package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.engine.data.acl.ACL;
	import com.tinyspeck.engine.data.acl.ACLKey;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.view.ui.TSScroller;

	public class ACLKeysReceivedUI extends TSSpriteWithModel
	{
		private static const SCROLL_BAR_W:uint = 16;
		private static const ELEMENTS_BEFORE_SCROLL:uint = 4;
		
		private var keys_scroller:TSScroller;
		private var elements:Vector.<ACLKeyReceivedElementUI> = new Vector.<ACLKeyReceivedElementUI>();
		
		private var is_built:Boolean;
		
		public function ACLKeysReceivedUI(w:int){
			_w = w;
		}
		
		private function buildBase():void {
			keys_scroller = new TSScroller({
				name: 'keys',
				bar_wh: SCROLL_BAR_W,
				bar_handle_min_h: 50,
				use_children_for_body_h: true,
				w: _w
			});
			addChild(keys_scroller);
			
			is_built = true;
			
			hide();
		}
		
		public function show():void {
			const acl:ACL = ACLManager.instance.acl;
			if(!acl || (acl && !acl.keys_received.length)) return;
			
			if(!is_built) buildBase();
			
			scaleX = scaleY = 1;
			
			//show the keys
			showKeys(acl.keys_received);
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
			scaleX = scaleY = .05;
		}
		
		private function showKeys(keys_received:Vector.<ACLKey>):void {			
			//show the keys we've got
			var i:int;
			var total:int = elements.length;
			var element:ACLKeyReceivedElementUI;
			var next_y:int;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				element.y = 0;
				element.hide();
			}
			
			//do the keys
			total = keys_received.length;
			for(i = 0; i < total; i++){
				if(elements.length > i){
					element = elements[int(i)];
				}
				else {
					//new one
					element = new ACLKeyReceivedElementUI();
					keys_scroller.body.addChild(element);
					elements.push(element);
				}
				
				element.show(_w - (total > ELEMENTS_BEFORE_SCROLL ? SCROLL_BAR_W : 0), keys_received[int(i)], i < total-1);
				element.y = next_y;
				next_y += element.height;
			}
			
			//set the scroller height
			if(element){
				keys_scroller.h = Math.min(next_y, element.height * ELEMENTS_BEFORE_SCROLL + (total > ELEMENTS_BEFORE_SCROLL ? -element.border_width : 0));
			}
		}
		
		override public function get height():Number {
			return keys_scroller ? keys_scroller.h : 0;
		}
	}
}