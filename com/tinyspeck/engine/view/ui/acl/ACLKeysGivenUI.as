package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.engine.data.acl.ACLKey;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;

	public class ACLKeysGivenUI extends Sprite
	{
		private static const NO_KEYS_H:uint = 43;
		private static const GIVEN_KEYS_H:uint = 25;
		private static const SCROLL_BAR_W:uint = 16;
		private static const ELEMENTS_BEFORE_SCROLL:uint = 3;
		
		private var keys_scroller:TSScroller;
		private var elements:Vector.<ACLKeyGivenElementUI> = new Vector.<ACLKeyGivenElementUI>();
		
		private var keys_holder:Sprite = new Sprite();
		private var keys_header:Sprite = new Sprite();
		private var no_keys_holder:Sprite = new Sprite();
		private var no_keys_fill:BitmapData;
		
		private var no_keys_tf:TextField = new TextField();
		private var keys_header_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		
		private var _w:int;
		
		public function ACLKeysGivenUI(w:int){
			_w = w;
		}
		
		private function buildBase():void {
			//keys
			var g:Graphics = keys_header.graphics;
			g.beginFill(0xffffff);
			g.drawRect(0, 0, _w, GIVEN_KEYS_H);
			g.endFill();
			g.beginFill(0xdcdcdc);
			g.drawRect(0, 0, _w, 1);
			g.drawRect(0, GIVEN_KEYS_H-1, _w, 1);
			keys_holder.addChild(keys_header);
			addChild(keys_holder);
			
			TFUtil.prepTF(keys_header_tf, false);
			keys_header_tf.htmlText = '<p class="acl_keys_given_header">Keys you\'ve given out</p>';
			keys_header_tf.x = 10;
			keys_header_tf.y = int(GIVEN_KEYS_H/2 - keys_header_tf.height/2);
			keys_header.addChild(keys_header_tf);
			
			const head_drop:DropShadowFilter = new DropShadowFilter();
			head_drop.angle = 90;
			head_drop.distance = 4;
			head_drop.blurX = 0;
			head_drop.blurY = 4;
			head_drop.alpha = .03;
			
			keys_header.filters = [head_drop];
			
			keys_scroller = new TSScroller({
				name: 'keys',
				bar_wh: SCROLL_BAR_W,
				bar_handle_min_h: 50,
				use_children_for_body_h: true,
				w: _w
			});
			keys_scroller.y = GIVEN_KEYS_H;
			keys_holder.addChildAt(keys_scroller, 0);
			
			//no keys
			createNoKeysFill();
			
			g = no_keys_holder.graphics;
			g.beginBitmapFill(no_keys_fill);
			g.drawRect(0, 0, _w, NO_KEYS_H);
			g.endFill();
			g.beginFill(0xd6d6d6);
			g.drawRect(0, 0, _w, 1);
			addChild(no_keys_holder);
			
			TFUtil.prepTF(no_keys_tf, false);
			no_keys_tf.htmlText = '<p class="acl_keys_given_empty">Keys that you give out will show up here</p>';
			no_keys_tf.x = int(_w/2 - no_keys_tf.width/2);
			no_keys_tf.y = int(NO_KEYS_H/2 - no_keys_tf.height/2);
			no_keys_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			no_keys_holder.addChild(no_keys_tf);
			
			const no_keys_glow:GlowFilter = new GlowFilter();
			no_keys_glow.color = 0;
			no_keys_glow.inner = true;
			no_keys_glow.blurX = no_keys_glow.blurY = 10;
			no_keys_glow.alpha = .05;
			no_keys_holder.filters = [no_keys_glow];
			
			is_built = true;
		}
		
		public function show(keys_given:Vector.<ACLKey>):void {
			if(!is_built) buildBase();
			
			//hide them
			no_keys_holder.visible = false;
			keys_holder.visible = false;
			
			if(!keys_given || (keys_given && !keys_given.length)){
				//no keys given out
				no_keys_holder.visible = true;
			}
			else {
				//list all the keys they've given out
				keys_holder.visible = true;
			}
			
			//show any keys that have been given out
			keys_scroller.scrollUpToTop();
			showKeys(keys_given);
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
		}
		
		private function showKeys(keys_given:Vector.<ACLKey>):void {
			//show the keys we've given out and junk
			var i:int;
			var total:int = elements.length;
			var element:ACLKeyGivenElementUI;
			var next_y:int;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				element.y = 0;
				element.hide();
			}
			
			//no more keys, bail out
			if(!keys_given) return;
			
			//do the keys
			total =  keys_given.length;
			for(i = 0; i < total; i++){
				if(elements.length > i){
					element = elements[int(i)];
				}
				else {
					//new one
					element = new ACLKeyGivenElementUI();
					keys_scroller.body.addChild(element);
					elements.push(element);
				}
				
				element.show(_w - (total > ELEMENTS_BEFORE_SCROLL ? SCROLL_BAR_W : 0), keys_given[int(i)], i < total-1);
				element.y = next_y;
				next_y += element.height;
			}
			
			//set the scroller height
			if(element){
				keys_scroller.h = Math.min(next_y, element.height * ELEMENTS_BEFORE_SCROLL + (total > ELEMENTS_BEFORE_SCROLL ? -element.border_width : 0));
			}
		}
		
		private function createNoKeysFill():void {
			const wh:uint = 6;
			var i:int;
			
			no_keys_fill = new BitmapData(wh, wh, false, 0xe5e5e5);
			no_keys_fill.lock();
			for(i; i < wh; i++){
				no_keys_fill.setPixel(i, i, 0xd2d2d2);
			}
			no_keys_fill.unlock();
		}
		
		override public function get height():Number {
			return no_keys_holder.visible ? no_keys_holder.height : GIVEN_KEYS_H + keys_scroller.h;
		}
	}
}