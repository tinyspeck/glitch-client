package com.tinyspeck.engine.view.ui {
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextLineMetrics;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Timer;
	
	public class TSScroller extends TSSpriteWithModel {
		
		private const AUTO_SCROLL_AMOUNT:int = 5;
		private const AUTO_SCROLL_BUFFER:int = 10; //how many pixels to the top/bottom before auto-scroll kicks in
		
		public var body:TSScrollerBody;
		private var _body_gradient_overlay_top:Sprite;
		private var _body_gradient_overlay_bottom:Sprite;
		private var _body_holder:Sprite = new Sprite();
		private var _bar_vert:Sprite = new Sprite();
		private var _bar_vert_track:Sprite = new Sprite();
		private var _bar_vert_handle:Sprite = new Sprite();
		private var button_holder:Sprite = new Sprite();
		
		private var _init_ob:Object;
		
		private var scroll_up_bt:Button;
		private var scroll_down_bt:Button;
		
		private var _scroll_y:int = 0;
		private var _bar_wh:int = 16;
		private var _bar_handle_min_h:int = 20;
		private var _bar_handle_h:int = 20;
		private var _scroll_page_offset:int = 20; // when scrolling by a page, how much less of a page? 20 leaves +- 1 line of text still on screen
		private var _scroll_window_w:int = 180;
		private var _scroll_window_h:int = 200;
		private var _was_body_height:int;
		private var _body_color:Number = 0xffffff;
		private var _body_alpha:Number = 0;
		
		private var bar_blend_mode:String;
		
		private var _gradient_c:Number = 0xa3a3a3;
		private var _bar_color:Number = 0xf5f5f5;
		private var _bar_alpha:Number = 1;
		private var _bar_border_color:Number = 0xa3a3a3;
		private var _bar_border_width:Number = 0;
		private var _bar_padd_top:Number = 0;
		private var _bar_padd_bottom:Number = 0;
		
		private var _bar_handle_color:Number = 0xfefefe;
		private var _bar_handle_border_color:Number = 0xa3a3a3;
		private var _bar_handle_stripes_color:Number = 0xa3a3a3;
		private var _bar_handle_stripes_alpha:Number = 1;
		private var _bar_handle_border_size:Number = 1;
		private var _refresh_interval:int;
		private var auto_scroll_timer:Timer = new Timer(15);
		
		private var _do_gradient:Boolean;
		private var _scrolltrack_always:Boolean;
		private var _dragging_handle:Boolean;
		private var _was_at_max_scroll_y:Boolean;
		private var _maintain_scrolling_at_max_y:Boolean; // if it is scrolled too bottom and content height increases, should we stay at bottom?
		private var _start_scrolling_at_max_y:Boolean; // if content height changes to cause scrollbar appearance, should we scroll to bottom
		private var _listen_to_arrow_keys:Boolean; //will only work if using an input TF in the scroller
		private var _use_children_for_body_h:Boolean; //this will loop through the children to get the body height instead of getBounds. Use this when masking large graphics.
		private var use_auto_scroll:Boolean; //if you want the body mousemove to auto scroll with text
		private var show_arrows:Boolean;
		private var auto_scroll_up:Boolean;
		private var _never_show_bars:Boolean; //use this when you want to never show the scroller. Usefull in BigDialog when you are maintaining other scrollers
		private var use_refresh_timer:Boolean = true; //set this to false if you want to manually refresh when adding content
		private var allow_clickthrough:Boolean; //when true makes the body of the scroller not respond to the mouse so clicks can go through it
		
		private var current_input_tf:TextField;
		
		private var drag_rect:Rectangle = new Rectangle();
		
		public function TSScroller(init_ob:Object):void {
			super();
			
			_w = 200;
			_h = 200;
			_init_ob = init_ob;
			
			if (_init_ob.name) {
				name = _init_ob.name;
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('TSScroller constructor w/out _init_ob.name');
				}
			}
			
			//setup the body
			body = new TSScrollerBody(this);
			
			if (_init_ob.hasOwnProperty('bar_handle_min_h')) _bar_handle_min_h = _init_ob.bar_handle_min_h;
			if (_init_ob.hasOwnProperty('bar_wh')) _bar_wh = _init_ob.bar_wh;
			if (_init_ob.hasOwnProperty('w')) _w = _init_ob.w;
			if (_init_ob.hasOwnProperty('h')) _h = _init_ob.h;
			if (_init_ob.hasOwnProperty('body_alpha')) _body_alpha = _init_ob.body_alpha;
			if (_init_ob.hasOwnProperty('body_color')) _body_color = _init_ob.body_color;
			if (_init_ob.hasOwnProperty('bar_color')) _bar_color = _init_ob.bar_color;
			if (_init_ob.hasOwnProperty('bar_alpha')) _bar_alpha = _init_ob.bar_alpha;
			if (_init_ob.hasOwnProperty('bar_padd_top')) _bar_padd_top = _init_ob.bar_padd_top;
			if (_init_ob.hasOwnProperty('bar_padd_bottom')) _bar_padd_bottom = _init_ob.bar_padd_bottom;
			if (_init_ob.hasOwnProperty('bar_handle_color')) _bar_handle_color = _init_ob.bar_handle_color;
			if (_init_ob.hasOwnProperty('bar_handle_border_color')) _bar_handle_border_color = _init_ob.bar_handle_border_color;
			if (_init_ob.hasOwnProperty('bar_handle_stripes_color')) _bar_handle_stripes_color = _init_ob.bar_handle_stripes_color;
			if (_init_ob.hasOwnProperty('bar_handle_stripes_alpha')) _bar_handle_stripes_alpha = _init_ob.bar_handle_stripes_alpha;
			if (_init_ob.hasOwnProperty('bar_border_color')) _bar_border_color = _init_ob.bar_border_color;
			if (_init_ob.hasOwnProperty('bar_border_width')) _bar_border_width = _init_ob.bar_border_width;
			if (_init_ob.hasOwnProperty('gradient_c')) _gradient_c = _init_ob.gradient_c;
			if (_init_ob.hasOwnProperty('do_gradient')) _do_gradient = (_init_ob.do_gradient == true);
			if (_init_ob.hasOwnProperty('maintain_scrolling_at_max_y')) _maintain_scrolling_at_max_y = _init_ob.maintain_scrolling_at_max_y;
			if (_init_ob.hasOwnProperty('start_scrolling_at_max_y')) _start_scrolling_at_max_y = _init_ob.start_scrolling_at_max_y;
			if (_init_ob.hasOwnProperty('scrolltrack_always')) _scrolltrack_always = _init_ob.scrolltrack_always;
			if (_init_ob.hasOwnProperty('scroll_page_offset')) _scroll_page_offset = _init_ob.scroll_page_offset;
			if (_init_ob.hasOwnProperty('listen_to_arrow_keys')) listen_to_arrow_keys = _init_ob.listen_to_arrow_keys;
			if (_init_ob.hasOwnProperty('use_auto_scroll')) use_auto_scroll = _init_ob.use_auto_scroll;
			if (_init_ob.hasOwnProperty('show_arrows')) show_arrows = _init_ob.show_arrows;
			if (_init_ob.hasOwnProperty('bar_blend_mode')) bar_blend_mode = _init_ob.bar_blend_mode;
			if (_init_ob.hasOwnProperty('use_children_for_body_h')) _use_children_for_body_h = (_init_ob.use_children_for_body_h === true);
			if (_init_ob.hasOwnProperty('never_show_bars')) _never_show_bars = (_init_ob.never_show_bars === true);
			if (_init_ob.hasOwnProperty('use_refresh_timer')) use_refresh_timer = (_init_ob.use_refresh_timer === true);
			if (_init_ob.hasOwnProperty('allow_clickthrough')) allow_clickthrough = (_init_ob.allow_clickthrough === true);
			
			_bar_handle_h = Math.max(_bar_handle_min_h, _bar_handle_h);
			drag_rect.y = _bar_padd_top;
			
			_construct();
		}
		
		public function set bar_color(c:Number):void {
			_bar_color = c;
			_drawBars();
		}
		
		public function setHandleColors(bg_color:uint, border_color:uint, stripes_color:uint):void {
			_bar_handle_color = bg_color;
			_bar_handle_border_color = border_color;
			_bar_handle_stripes_color = stripes_color;
			
			_drawScrollControls();
		}
		
		override protected function _construct():void {
			super._construct();
			
			addChild(_body_holder);
			_body_holder.addChild(body);
			_body_holder.mouseEnabled = _body_holder.mouseChildren = !allow_clickthrough;
			mouseEnabled = !allow_clickthrough;
			if(!allow_clickthrough) _body_holder.addEventListener(MouseEvent.MOUSE_DOWN, onBodyMouseDown, false, 0, true);
			
			if (_do_gradient) {
				_body_gradient_overlay_top = new Sprite();
				_body_gradient_overlay_top.mouseEnabled = false;
				_body_gradient_overlay_bottom = new Sprite();
				_body_gradient_overlay_bottom.mouseEnabled = false;
				addChild(_body_gradient_overlay_bottom);
				addChild(_body_gradient_overlay_top);
			}
			
			//show the scroll up / down buttons
			button_holder.visible = show_arrows;
			if(show_arrows){
				scroll_up_bt = buildScrollButton('up');
				scroll_down_bt = buildScrollButton('down');
				scroll_down_bt.y = int(scroll_up_bt.height);
				
				button_holder.addChild(scroll_up_bt);
				button_holder.addChild(scroll_down_bt);
			}
			
			addChild(_bar_vert);
			_bar_vert_track.mouseEnabled = false;
			_bar_vert.addChild(_bar_vert_track);
			_bar_vert.addChild(button_holder);
			_bar_vert.addChild(_bar_vert_handle);
			_bar_vert_handle.addEventListener(MouseEvent.MOUSE_DOWN, _bar_vert_handleMouseDownHandler);
			_bar_vert_handle.addEventListener(MouseEvent.MOUSE_OVER, _bar_vert_handleMouseOverHandler);
			_bar_vert_handle.addEventListener(MouseEvent.MOUSE_OUT, _bar_vert_handleMouseOutHandler);
			_bar_vert.addEventListener(MouseEvent.CLICK, _bar_vertMouseDownHandler);
			
			//if we have a blend mode for the bar, show it
			if(bar_blend_mode){
				_bar_vert_track.blendMode = bar_blend_mode;
			}
			
			_drawScrollControls();
			
			_refreshAfterWindowSizeChange();
			
			//if we are using the refresh timer, set that up here
			if(use_refresh_timer){
				addEventListener(Event.ADDED_TO_STAGE, onStage, false, 0, true);
				addEventListener(Event.REMOVED_FROM_STAGE, onStage, false, 0, true);
			}
			
			addEventListener(MouseEvent.MOUSE_OVER, _mouseOverHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_OUT, _mouseOutHandler, false, 0, true);
		}
		
		private function buildScrollButton(direction:String):Button {
			var holder:Sprite = new Sprite();
			var arrow:DisplayObject = new AssetManager.instance.assets.scroll_arrow();
			arrow.x = direction == 'up' ? 0 : -arrow.width;
			arrow.y = direction == 'up' ? 0 : -arrow.height;
			arrow.filters = StaticFilters.white1px90Degrees_DropShadowA;
			holder.addChild(arrow);
			holder.rotation = direction == 'up' ? 0 : 180;
			
			var bt:Button = new Button({
				name: direction,
				draw_alpha: 0,
				graphic: holder,
				w: _bar_wh,
				h: _bar_wh
			});
			bt.addEventListener(MouseEvent.MOUSE_DOWN, direction == 'up' ? onScrollUp : onScrollDown, false, 0, true);
			
			return bt;
		}
		
		override protected function _deconstruct():void {
			removeEventListener(MouseEvent.MOUSE_OVER, _mouseOverHandler);
			removeEventListener(MouseEvent.MOUSE_OUT, _mouseOutHandler);
			if(use_refresh_timer){
				removeEventListener(Event.ADDED_TO_STAGE, onStage);
				removeEventListener(Event.REMOVED_FROM_STAGE, onStage);
				if (_refresh_interval) {
					StageBeacon.clearInterval(_refresh_interval);
					_refresh_interval = 0;
				}
			}
			
			StageBeacon.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, _mouseWheelHandler);
			listen_to_arrow_keys = false;
			current_input_tf = null;
			super._deconstruct();
		}
		
		private function onStage(event:Event):void {
			//only run the refresh timer when we can see it
			if (event.type == Event.ADDED_TO_STAGE) {
				if (_refresh_interval == 0) {
					_refresh_interval = StageBeacon.setInterval(_refresh_timerHandler, 500);
				}
			} else {
				if (_refresh_interval) {
					StageBeacon.clearInterval(_refresh_interval);
					_refresh_interval = 0;
				}
			}
		}
		
		private function _refresh_timerHandler():void {
			if (_was_body_height != body_h) {
				refreshAfterBodySizeChange();
			}
		}
		
		private function _needVertScrolling():Boolean {
			if (body_h > _scroll_window_h) {
				return true;
			} else {
				return false;
			}
		}
		
		private function _needVertScrollTrack():Boolean {
			if ((_needVertScrolling() || _scrolltrack_always) && !never_show_bars) return true;
			return false;
		}
		
		private function _figureDims():void {
			_scroll_window_h = _h;
			_scroll_window_w = _w;
			if (_needVertScrollTrack()) _scroll_window_w-= _bar_wh;
		}
		
		private function _bar_vert_handleMouseUpAfterDragHandler(e:Event):void {
			_bar_vert_handle.stopDrag();
			_dragging_handle = false;
			StageBeacon.mouse_up_sig.remove(_bar_vert_handleMouseUpAfterDragHandler);
			StageBeacon.mouse_move_sig.remove(_bar_vert_handleMouseMoveAfterDragHandler);
			StageBeacon.mouse_leave_sig.remove(_bar_vert_handleMouseUpAfterDragHandler);
		}
		
		private function _bar_vert_handleMouseMoveAfterDragHandler(e:MouseEvent):void {
			var perc:Number = _bar_vert_handle.y/_max_handle_y;
			scroll_y = Math.round(perc*max_scroll_y);
		}
		
		private function _mouseOverHandler(e:MouseEvent):void {
			//Console.info('add')
			StageBeacon.stage.addEventListener(MouseEvent.MOUSE_WHEEL, _mouseWheelHandler);
		}
		
		private function _mouseOutHandler(e:MouseEvent):void {
			//Console.info('remove')
			StageBeacon.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, _mouseWheelHandler);
		}
		
		private function _mouseWheelHandler(e:MouseEvent):void {
			if (!_needVertScrolling()) return;
			scroll_y = Math.min(max_scroll_y, _scroll_y-(e.delta*5));
			_repositionHandle();
		}
		
		private function _bar_vert_handleMouseDownHandler(e:MouseEvent):void {
			drag_rect.height = _scroll_window_h-_bar_handle_h-button_holder.height-_bar_padd_bottom-_bar_padd_top;
			_bar_vert_handle.startDrag(false, drag_rect);
			_dragging_handle = true;
			StageBeacon.mouse_up_sig.add(_bar_vert_handleMouseUpAfterDragHandler);
			StageBeacon.mouse_move_sig.add(_bar_vert_handleMouseMoveAfterDragHandler);
			StageBeacon.mouse_leave_sig.add(_bar_vert_handleMouseUpAfterDragHandler);
		}
		
		private function onBodyMouseDown(event:MouseEvent):void {
			if (!_needVertScrolling() || event.target is TextField == false) return;
			//if we have stuff to scroll, let's listen to the mouse movements to see if we have to auto-scroll
			_body_holder.addEventListener(MouseEvent.MOUSE_MOVE, onBodyMouseMove, false, 0, true);
			StageBeacon.mouse_up_sig.add(onBodyMouseUp);
			StageBeacon.mouse_leave_sig.add(onBodyMouseUp);
			auto_scroll_timer.addEventListener(TimerEvent.TIMER, onAutoScroll, false, 0, true);
		}
		
		private function onBodyMouseMove(event:MouseEvent):void {
			if(!use_auto_scroll) return;
			//if our mouse goes above or below our scroll area, let's auto-scroll!
			if(event.localY - AUTO_SCROLL_BUFFER <= _scroll_y){
				//scroll up
				if(!auto_scroll_timer.running) auto_scroll_timer.start();
				auto_scroll_up = true;
			}
			else if(event.localY + AUTO_SCROLL_BUFFER >= _scroll_y+_scroll_window_h && event.localY + AUTO_SCROLL_BUFFER < body_h){
				//scroll down
				if(!auto_scroll_timer.running) auto_scroll_timer.start();
				auto_scroll_up = false;
			}
			else{
				//nothing to scroll, so stop the auto-scrolling timer
				auto_scroll_timer.stop();
			}
			
			_repositionHandle();
		}
		
		private function onBodyMouseUp(event:*):void {
			//kill the listeners
			_body_holder.removeEventListener(MouseEvent.MOUSE_MOVE, onBodyMouseMove);
			StageBeacon.mouse_up_sig.remove(onBodyMouseUp);
			StageBeacon.mouse_leave_sig.remove(onBodyMouseUp);
			auto_scroll_timer.removeEventListener(TimerEvent.TIMER, onAutoScroll);
			auto_scroll_timer.stop();
		}
		
		private function onScrollUp(event:MouseEvent):void {
			StageBeacon.mouse_up_sig.add(autoScrollStop);
			autoScrollUp();
		}
		
		private function onScrollDown(event:MouseEvent):void {
			StageBeacon.mouse_up_sig.add(autoScrollStop);
			autoScrollDown();
		}
		
		private function onAutoScroll(event:TimerEvent):void {
			//figure out which way we need to scroll
			if(auto_scroll_up){
				scroll_y = _scroll_y - AUTO_SCROLL_AMOUNT;
			}else{
				scroll_y = _scroll_y + AUTO_SCROLL_AMOUNT;
			}
			
			if(_scroll_y+_scroll_window_h >= body_h) {
				auto_scroll_timer.stop();
				scroll_y = max_scroll_y;
			}
			
			if(_scroll_y == 0) auto_scroll_timer.stop();
			
			_repositionHandle();
		}
		
		public function scrollUpOnePage():void {
			if (!_needVertScrolling()) return;
			scroll_y = Math.max(0, (_scroll_y - _scroll_window_h + _scroll_page_offset));
			_repositionHandle();
		}
		
		public function scrollDownOnePage():void {
			if (!_needVertScrolling()) return;
			scroll_y = Math.min(max_scroll_y, (_scroll_y + _scroll_window_h - _scroll_page_offset));
			_repositionHandle();
		}
		
		public function scrollUpToTop():void {
			if (!_needVertScrolling()) return;
			scroll_y = 0;
			_repositionHandle();
		}
		
		public function scrollDownToBottom():void {
			if (!_needVertScrolling()) return;
			scroll_y = max_scroll_y;
			_repositionHandle();
		}
		
		public function scrollYToTop(y:int):void {
			if (!_needVertScrolling()) return;
			y = Math.min(max_scroll_y, y);
			scroll_y = y;
			_repositionHandle();
		}
		
		public function autoScrollUp():void {
			if(!auto_scroll_timer.hasEventListener(TimerEvent.TIMER)) {
				auto_scroll_timer.addEventListener(TimerEvent.TIMER, onAutoScroll, false, 0, true);
			}
			if(!auto_scroll_timer.running) auto_scroll_timer.start();
			auto_scroll_up = true;
		}
		
		public function autoScrollDown():void {
			if(!auto_scroll_timer.hasEventListener(TimerEvent.TIMER)) {
				auto_scroll_timer.addEventListener(TimerEvent.TIMER, onAutoScroll, false, 0, true);
			}
			if(!auto_scroll_timer.running) auto_scroll_timer.start();
			auto_scroll_up = false;
		}
		
		public function autoScrollStop(event:MouseEvent = null):void {
			if(event) StageBeacon.mouse_up_sig.remove(autoScrollStop);
			if(auto_scroll_timer.hasEventListener(TimerEvent.TIMER)) {
				auto_scroll_timer.removeEventListener(TimerEvent.TIMER, onAutoScroll);
			}
			auto_scroll_timer.stop();
		}
		
		private function _bar_vertMouseDownHandler(e:MouseEvent):void {
			if (!_needVertScrolling()) return;
			if (e.target != e.currentTarget) return; // because we don't care about clicks on the handle
			
			var click_y:int = e.currentTarget.mouseY;
			if (click_y < _bar_vert_handle.y) {
				scrollUpOnePage();
			} else {
				scrollDownOnePage();
			}
		}
		
		public function refreshAfterBodySizeChange(reset_scroll_y:Boolean = false):void {
			// In dis function, we want to keep the scroll content positioned in the same place as before the change 
			// (relative to the top of the scroll window) which mean leaving _scroll_y the same and moving the handle appropriately,
			//
			// UNLESS the size change causes the bottom of the scroll content to be above the bottom of the scroll window,
			// in which case we want to reposition the content so that the scroll handle is all the way DOWN, and
			//
			// UNLESS the scroll content was already scrolled all the way DOWN, in which case we want to keep it that way, and 
			//
			// UNLESS reset_scroll_y=true, in which case we want to reposition the content so that the scroll handle is all the way UP
			// (and once done, we can treat it just like the default case.)
			
			
			// TODO: account for when this happens while we are dragging handle !!!!
			
			var was_scrolled:Boolean = (_scroll_y > 0);
			
			if (reset_scroll_y) {
				scroll_y = 0;
			}
			
			_standardRefreshCrap();
			
			var body_bottom_y:int = body_h - _scroll_y;
			var is_body_bottom_too_high:Boolean = (body_bottom_y < _scroll_window_h)
			
			if (is_body_bottom_too_high || (_maintain_scrolling_at_max_y && _was_at_max_scroll_y && was_scrolled) || (_start_scrolling_at_max_y && !was_scrolled && _was_at_max_scroll_y)) {
				scroll_y = max_scroll_y;
			}
			
			_repositionHandle();
			
			_was_body_height = body_h;
		}
		
		public function updateHandleWithInputText(input_tf:TextField):void {			
			if(!input_tf && input_tf.type != TextFieldType.INPUT){
				CONFIG::debugging {
					Console.warn('Could not find an input textfield');
				}
				return;
			}
			
			current_input_tf = input_tf;
			
			//where da caret at?
			var line_index:int = input_tf.getLineIndexOfChar(input_tf.caretIndex);
			
			if(line_index == -1){
				//we are at the end, set it to max scroll
				scroll_y = max_scroll_y;
				_repositionHandle();
				return;
			}
			
			//figure out what line we are on to get the Y value
			var line_metrics:TextLineMetrics = input_tf.getLineMetrics(line_index);
			
			//add 1 to the index so it's at the top of the NEXT line
			//TODO make it so it's not ALWAYS at the bottom 
			//(ie. if up/left key pressed then see if caret is higher than the viewbox)
			scroll_y = (line_index+1) * line_metrics.height - _scroll_window_h;
			
			_repositionHandle();
		}
		
		private function onArrowAction(event:KeyboardEvent):void {
			if(current_input_tf 
			   && StageBeacon.stage.focus == current_input_tf
			   && (event.keyCode == Keyboard.UP || event.keyCode == Keyboard.DOWN || event.keyCode == Keyboard.LEFT || event.keyCode == Keyboard.RIGHT)){
				// delay so flash can update it's internal shit
				StageBeacon.waitForNextFrame(updateHandleWithInputText, current_input_tf);
			}
		}
		
		private function _standardRefreshCrap():void {
			_figureDims();
			
			_bar_vert.visible = _needVertScrollTrack();
			
			if (_needVertScrolling()) {
				_bar_vert.buttonMode = true;
				_bar_vert.useHandCursor = true;
				_bar_vert_handle.visible = true;
			} else {
				_bar_vert.buttonMode = false;
				_bar_vert.useHandCursor = false;
				_bar_vert_handle.visible = false;
			}
			
			_refreshScrollRect();
			
			_drawBars();
			_drawBody();
			
			//keep the content at the bottom
			if(_start_scrolling_at_max_y){
				body.y = int(Math.max(_scroll_window_h, body_h) - body.height);
				
				//make sure the scroll_y doesn't go all outta wack
				if(max_scroll_y < scroll_y) scroll_y = max_scroll_y;
			}
		}
		
		private function _refreshAfterWindowSizeChange():void {			
			_standardRefreshCrap();
			
			if (_maintain_scrolling_at_max_y && (_was_at_max_scroll_y || !_bar_vert.visible)) {
				scroll_y = max_scroll_y;
			}
			else if(_scroll_y + _h >= body_h){
				//make sure the scroller behaves when not maintaining Y
				scroll_y = Math.max(0, body_h-_h);
			}
			
			if (_do_gradient) {
			
				// top
				
				var bott_grad_h:int = 30;
				var top_grad_h:int = 20;
				
				var colors:Array = [
					_gradient_c,
					_gradient_c
				];
				
				_body_gradient_overlay_top.y = 0;
				_body_gradient_overlay_top.x = 0;
				
				var gt:Graphics = _body_gradient_overlay_top.graphics;
				gt.clear();
				var alphas:Array = [1, 0];
				var ratios:Array = [10, 255];
				var matrix:Matrix = new Matrix();
				
				matrix.createGradientBox(top_grad_h, top_grad_h, Math.PI/2, 0, 0);
				gt.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, matrix, SpreadMethod.PAD);
				gt.lineStyle(0,0,0)
				gt.drawRect(0, 0, top_grad_h, top_grad_h);
				
				// bottom
				
				_body_gradient_overlay_bottom.y = _h-bott_grad_h;
				_body_gradient_overlay_bottom.x = 0;
				
				gt = _body_gradient_overlay_bottom.graphics;
				gt.clear();
				alphas = [0, 1];
				ratios = [0, 245];
				matrix = new Matrix();
				
				matrix.createGradientBox(bott_grad_h, bott_grad_h, Math.PI/2, 0, 0);
				gt.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, matrix, SpreadMethod.PAD);
				gt.lineStyle(0,0,0)
				gt.drawRect(0, 0, bott_grad_h, bott_grad_h);
				
				// both
				
				_body_gradient_overlay_top.width = _body_gradient_overlay_bottom.width = _w;
			}
			
			_repositionHandle();
		}
		
		private function _repositionHandle():void {
			var perc:Number = _scroll_y/max_scroll_y;
			if (isNaN(perc)) perc = 0;
			if (perc > 1) perc = 1;
			_bar_vert_handle.y = Math.round(perc*_max_handle_y);
		}
		
		private function _drawScrollControls():void {
			var g:Graphics = _bar_vert_handle.graphics;
			g.clear();
			
			var bar_round_radius:int = 6;
			
			// first the border
			g.beginFill(_bar_handle_border_color, 1);
			g.drawRoundRect(0, 0, _bar_wh, _bar_handle_h, bar_round_radius);
			// now the knockout box
			g.beginFill(_bar_handle_color, 1);
			g.drawRoundRect(_bar_handle_border_size, _bar_handle_border_size, _bar_wh-(2*_bar_handle_border_size), _bar_handle_h-(2*_bar_handle_border_size), bar_round_radius);
			
			// now the stripes
			if(_bar_handle_stripes_alpha){
				g.beginFill(_bar_handle_stripes_color, _bar_handle_stripes_alpha);
				var stripe_w:int = Math.floor(_bar_wh*.4);
				var stripe_offset:int = (_bar_wh-stripe_w)/2;
				var stripe_dist:int = Math.max(2, Math.floor(_bar_handle_h*.08));
				g.drawRect(stripe_offset, (_bar_handle_h/2)-stripe_dist, _bar_wh-(stripe_offset*2), 1);
				g.drawRect(stripe_offset, _bar_handle_h/2, _bar_wh-(stripe_offset*2), 1);
				g.drawRect(stripe_offset, (_bar_handle_h/2)+stripe_dist, _bar_wh-(stripe_offset*2), 1);
			}
		}
		
		private function _drawBody():void {
			if(!allow_clickthrough){
				//draw the body if we don't need to click through it
				var g:Graphics = graphics;
				g.clear();
				g.beginFill(_body_color, _body_alpha);
				g.drawRect(0, 0, 
					Math.ceil(_scroll_window_w), 
					Math.ceil(_scroll_window_h)
				);
			}
		}
		
		private function _drawBars():void {
			const bar_round_radius:int = 6;
			
			// first the border
			var g:Graphics = _bar_vert.graphics;
			g.clear();
			g.beginFill(_bar_border_color, _bar_alpha);
			g.drawRoundRect(0, _bar_padd_top, _bar_wh, _scroll_window_h - _bar_padd_bottom - _bar_padd_top, bar_round_radius);
			
			// now the knockout box
			g = _bar_vert_track.graphics;
			g.clear();
			g.beginFill(_bar_color, _bar_alpha);
			g.drawRoundRect(
				_bar_border_width, 
				_bar_border_width + _bar_padd_top, 
				_bar_wh-(2*_bar_border_width), 
				_scroll_window_h-(2*_bar_border_width) - button_holder.height - _bar_padd_bottom - _bar_padd_top, 
				bar_round_radius
			);
			
			//show the arrows?
			if(show_arrows) button_holder.y = _scroll_window_h - button_holder.height;
			
			_bar_vert.x = _w-_bar_wh;
		}
		
		public function get scroll_y():int { return _scroll_y; }
		public function set scroll_y(y:int):void {
			_scroll_y = Math.max(_bar_padd_top, y); // if _scroll_y is neg, then top of body goes below the top of the scroll window: bad
			
			_was_at_max_scroll_y = (max_scroll_y == _scroll_y);// && _needVertScrolling()); //not 100% sure _needVertScrolling() is going to be correct in all cases
			//Console.warn('_max_scroll_y:'+_max_scroll_y+' _scroll_y:'+_scroll_y+' _was_at_max_scroll_y:'+_was_at_max_scroll_y)
			_refreshScrollRect();
		}
		
		private function get _max_handle_y():int {
			// be careful when you measure that you do not include the handle! (because if visible it might lengthen the height momentarily during window resizing)
			return _h - _bar_handle_h - button_holder.height - _bar_padd_bottom - _bar_padd_top;
		}
		
		public function get max_scroll_y():int {
			return Math.max(_bar_padd_top, body_h-_scroll_window_h-_bar_padd_bottom-_bar_padd_top); // this is the most we can scroll down
		}
		
		private function _refreshScrollRect():void {
			_body_holder.scrollRect = new Rectangle(0, _scroll_y, _scroll_window_w, _scroll_window_h);
			//Console.warn(' _refreshScrollRect '+_body_holder.scrollRect)
		}
		
		private function _fixW(w:int):int {
			return Math.max(_bar_handle_min_h, w)
		}
		
		private function _fixH(h:int):int {
			return Math.max(_bar_handle_min_h, h)
		}
		
		public function set w(w:int):void {
			w = _fixW(w);
			if (_w == w) return;
			
			_w = w;
			_refreshAfterWindowSizeChange();
		}
		
		public function set scrolltrack_always(a:Boolean):void {
			var was:Boolean = _scrolltrack_always;
			_scrolltrack_always = a;
			if (a != was) _refreshAfterWindowSizeChange();
		}
		
		public function set h(h:int):void {
			h = _fixH(h);
			if (_h == h) return;
			
			_h = h;
			_refreshAfterWindowSizeChange();
		}
		
		public function set wh(wh:Object):void {
			wh.w = _fixW(wh.w);
			wh.h = _fixH(wh.h);
			if (wh.w ==_w && wh.h == _h) return;
			
			_w = wh.w;
			_h = wh.h;
			_refreshAfterWindowSizeChange();
		}
		
		override public function get w():int {
			var w:int;
			w = _scroll_window_w;
			if (_bar_vert.visible) w+= _bar_wh;
			return w;
		}
		
		public function get scroll_window_w():int {
			return _scroll_window_w;
		}
		
		override public function get h():int {
			return _scroll_window_h;
		}
		
		override public function get height():Number {
			return h;
		}
		
		public function get body_h():int {
			//Console.warn(body.height+' '+body.getBounds(body).y)
			if(!use_children_for_body_h) {
				return body.height + body.getBounds(body).y;
			}
			
			//we use this when the children have masks because flash is a peice of shit and doesn't calculate visible pixels
			var i:int;
			var total:int = body.numChildren;
			var child:DisplayObject;
			var new_body_h:int;
			
			for(i; i < total; i++){
				child = body.getChildAt(i);
				if(child.visible && child.y + child.height > new_body_h){
					new_body_h = child.y + child.height;
				}
			}
			
			return new_body_h;
		}
		
		public function get bar():Sprite {
			return _bar_vert;
		}
		
		public function get listen_to_arrow_keys():Boolean { return _listen_to_arrow_keys; }
		public function set listen_to_arrow_keys(value:Boolean):void {
			if(value){
				addEventListener(KeyboardEvent.KEY_DOWN, onArrowAction, false, 0, true);
			}
			else {
				removeEventListener(KeyboardEvent.KEY_DOWN, onArrowAction);
			}
		}
		
		public function get use_children_for_body_h():Boolean { return _use_children_for_body_h; }
		public function set use_children_for_body_h(value:Boolean):void {
			_use_children_for_body_h = value;
			refreshAfterBodySizeChange();
		}
		
		public function get never_show_bars():Boolean { return _never_show_bars; }
		public function set never_show_bars(value:Boolean):void {
			_never_show_bars = value;
			
			if(value && contains(_bar_vert)){
				removeChild(_bar_vert);
			}
			else if(!value && !contains(_bar_vert)){
				addChild(_bar_vert);
			}
		}
		
		public function set body_mask(value:DisplayObject):void {
			_body_holder.mask = value;
			_body_holder.cacheAsBitmap = value != null ? true : false;
		}
		
		private function _bar_vert_handleMouseOverHandler(e:*):void {
			if (model.stateModel.editing) {
				Mouse.cursor = MouseCursor.HAND;
			}
		}
		
		private function _bar_vert_handleMouseOutHandler(e:*):void {
			Mouse.cursor = MouseCursor.AUTO;
		}
	}
}

/**
 * This is a middle-man class that will auto refresh the scroller when anything is added or removed 
 * @author Scott
 * (whoh cool, it auto put the author in, that's kindda neat)
 */
import com.tinyspeck.engine.view.ui.TSScroller;

import flash.display.DisplayObject;
import flash.display.Sprite;

internal class TSScrollerBody extends Sprite {
	private var scroller:TSScroller;
	
	public function TSScrollerBody(scroller:TSScroller):void {
		this.scroller = scroller;
	}
	
	override public function addChild(child:DisplayObject):DisplayObject {
		super.addChild(child);
		scroller.refreshAfterBodySizeChange();
		return child;
	}
	
	override public function addChildAt(child:DisplayObject, index:int):DisplayObject {
		super.addChildAt(child, index);
		scroller.refreshAfterBodySizeChange();
		return child;
	}
	
	override public function removeChild(child:DisplayObject):DisplayObject {
		super.removeChild(child);
		scroller.refreshAfterBodySizeChange();
		return child;
	}
	
	override public function removeChildAt(index:int):DisplayObject {
		const removed_child:DisplayObject = super.removeChildAt(index);
		scroller.refreshAfterBodySizeChange();
		return removed_child;
	}
}