package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.geom.Rectangle;

	public class TSScrollPager extends Sprite
	{
		private static const SCROLL_BT_W:uint = 22; //left and right scroll buttons
		private static const SCROLL_BT_PADD:uint = 6; //how much the holder overlaps the buttons
		
		private var left_scroll:Button;
		private var right_scroll:Button;
		
		private var holder:Sprite = new Sprite();
		private var content_sp:Sprite = new Sprite();
		private var masker:Sprite = new Sprite();
		
		private var filters_A:Array = new Array();
		private var content_rect:Rectangle;
		
		private var left_shadow:DropShadowFilter = new DropShadowFilter();
		private var right_shadow:DropShadowFilter = new DropShadowFilter();
		
		private var current_page:int;
		
		private var _w:int;
		private var _h:int;
		private var _element_width:int;
		private var _x_offset:int;
		
		public function TSScrollPager(h:int){
			_h = h;
			
			//buttons
			left_scroll = new Button({
				name: 'scroll_left',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_PACK_SCROLL,
				graphic: new AssetManager.instance.assets.furn_scroll(),
				graphic_disabled: new AssetManager.instance.assets.furn_scroll_disabled(),
				graphic_placement: 'left',
				graphic_padd_l: 8,
				w: SCROLL_BT_W + SCROLL_BT_PADD,
				h: _h + 1,
				y: -1
			});
			left_scroll.addEventListener(TSEvent.CHANGED, onScrollClick, false, 0, true);
			addChild(left_scroll);
			
			//flip em
			const furn_scroll:DisplayObject = new AssetManager.instance.assets.furn_scroll();
			const furn_scroll_disabled:DisplayObject = new AssetManager.instance.assets.furn_scroll_disabled();
			furn_scroll.scaleX = -1;
			furn_scroll_disabled.scaleX = -1;
			
			right_scroll = new Button({
				name: 'scroll_right',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_PACK_SCROLL,
				graphic: furn_scroll,
				graphic_disabled: furn_scroll_disabled,
				graphic_placement: 'right',
				graphic_padd_r: -2,
				w: SCROLL_BT_W + SCROLL_BT_PADD,
				h: _h + 1,
				y: -1
			});
			right_scroll.addEventListener(TSEvent.CHANGED, onScrollClick, false, 0, true);
			addChild(right_scroll);
			
			//holder
			holder.addChild(masker);
			holder.addChild(content_sp);
			holder.x = SCROLL_BT_W;
			content_sp.mask = masker;
			addChild(holder);
			
			//setup the left and right shadows
			left_shadow.alpha = .2;
			left_shadow.distance = 2;
			left_shadow.angle = 0;
			left_shadow.inner = true;
			left_shadow.blurY = 0;
			left_shadow.blurX = 3;
			
			right_shadow.alpha = .2;
			right_shadow.distance = 2;
			right_shadow.angle = 180;
			right_shadow.inner = true;
			right_shadow.blurY = 0;
			right_shadow.blurX = 3;
		}
		
		public function setContent(sp:Sprite, reset_x:Boolean = true):void {
			SpriteUtil.clean(content_sp);
			content_sp.addChild(sp);
			refresh(reset_x);
		}
		
		public function refresh(reset_x:Boolean = false):void {
			//just check the scrolling without animating it
			if(reset_x) current_page = 0;
			checkScroll(false);
		}
		
		/**
		 * Will jump to a given page 
		 * @param page_number THIS IS NOT ZERO BASED. So the first page is "1"
		 */		
		public function gotoPage(page_number:uint):void {
			current_page = page_number-1;
			checkScroll(false);
		}
		
		private function draw():void {
			var g:Graphics = holder.graphics;
			g.clear();
			g.beginFill(0xd8e0e2);
			g.drawRoundRect(0, 0, _w, _h, 10);
			
			g = masker.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, _w, _h, 10);
			
			//move the right scroll button
			right_scroll.x = _w + SCROLL_BT_W - SCROLL_BT_PADD;
			refresh();
		}
		
		private function checkScroll(animate:Boolean = true):void {
			//is the content where it should be? If not, animate it there!
			
			//reset the filters
			filters_A.length = 0;
			
			//do we have any left padding to deal with?
			content_rect = content_sp.getBounds(content_sp);
			const content_padd:int = content_sp.numChildren ? content_sp.getChildAt(0).x : 0;
			const content_w:int = (content_rect.x + content_rect.width - content_padd) + content_padd*2;
			const max_pages:int = Math.max(Math.ceil(content_w/_w) - 1, 0); //0-based
			
			//if we are over page 0, but the width is no longer larger, reset that sucker
			if(current_page > 0 && content_w <= _w){
				current_page = 0;
			}
			//make sure that we set the right amount of pages, since a big change in width may bunk things up
			else if(current_page > max_pages){
				current_page = max_pages;
			}
			
			var end_x:int = -(current_page * _w);
			if(element_width){
				const viewable_element_w:int = Math.floor((_w-content_padd)/element_width) * element_width;
				end_x = -(current_page * viewable_element_w)
			}
			
			//account for the x_offset
			end_x -= x_offset;
			
			if(content_w > _w && end_x + content_w <= _w){
				//make sure that we don't go off too far to the right
				end_x = _w - content_w;
			}
			else if(x_offset && end_x < 0 && content_w && content_w <= _w){
				//we've applied an offset, but the content is less wide than the viewable area. Set it to 0
				end_x = 0;
				current_page = 0;
			}
			else if(end_x > 0){
				//we went a bit beyond our x_offset, so reset it
				end_x = 0;
				_x_offset = 0;
				current_page = 0;
			}
			
			//left clickable?
			left_scroll.disabled = end_x == 0;
			if(!left_scroll.disabled) filters_A.push(left_shadow);
			
			//right clickable
			right_scroll.disabled = end_x + content_w <= _w;
			if(!right_scroll.disabled) filters_A.push(right_shadow);
			
			if(animate){
				TSTweener.addTween(content_sp, {x:end_x, time:.2});
			}
			else {
				content_sp.x = end_x;
			}
			
			//set the filters
			holder.filters = filters_A.concat(StaticFilters.black3px90DegreesInner_DropShadowA);
		}
		
		private function onScrollClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			if(bt.disabled) return;
			
			//we going left or right?
			if(bt == left_scroll){
				current_page--;
			}
			else {
				current_page++;
			}
			
			//make sure things get checked, then tween the sucker
			checkScroll();
		}
		
		/**
		 * Tells the pager how large the elements are so it knows if it's cutting any off, and if so to start at the cut off value 
		 * @param value
		 */
		public function set element_width(value:int):void {
			_element_width = value;
			checkScroll(false);
		}
		public function get element_width():int { return _element_width; }
		
		/**
		 * You can offset the content by a set amount if you wish (handy for the swatch UI to show only the last 5 of your owned swatches)
		 * @param value
		 */		
		public function set x_offset(value:int):void {
			_x_offset = value;
			checkScroll(false);
		}
		public function get x_offset():int { return _x_offset; }
		
		override public function get width():Number { return _w; }
		override public function set width(value:Number):void {
			_w = value - SCROLL_BT_W*2;
			draw();
		}
		override public function get height():Number { return _h; }
	}
}