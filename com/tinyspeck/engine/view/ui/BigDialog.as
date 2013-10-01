package com.tinyspeck.engine.view.ui {
	
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class BigDialog extends Dialog {
		
		protected var _head_sp:Sprite = new Sprite();
		protected var _head_graphic:Sprite = new Sprite();
		protected var _body_sp:Sprite = new Sprite();
		protected var _foot_sp:Sprite = new Sprite();
		
		protected var _title_tf:TextField = new TextField();
		protected var _subtitle_tf:TSLinkedTextField = new TSLinkedTextField();
		
		protected var _scroller:TSScroller;
		
		protected var _scroller_bar_wh:int = 16;
		protected var _scroller_bar_alpha:Number = 1;
		protected var _divider_h:int = 1;
		protected var _head_h:int = 0;
		protected var _head_min_h:int = 35;
		protected var _body_h:int = 0;
		protected var _body_min_h:int = 20;
		protected var _foot_h:int = 0;
		protected var _foot_min_h:int = 7;
		protected var _foot_max_h:int = 7;
		protected var _head_padd_bottom:int = 10;
		protected var _graphic_padd_top:int = 12;
		protected var _graphic_padd_side:int = 15;
		protected var _head_padd_top:int = 10;
		protected var _body_max_h:int = 400; // eventually maybe need to figure this dynamically (avail_h - foot_h - head_h etc etc)
		protected var _title_padd_left:int = -9999; //default value used to check if it was set or not
		
		protected var _body_border_c:Number = 0xd2d2d2;
		protected var _body_fill_c:Number = 0xececec;
		
		protected var _center_close_bt_y_in_head:Boolean = false;
		protected var _center_graphic_y_in_head:Boolean = true;
		protected var _show_scroller_gradient:Boolean = false;
		protected var _scrolltrack_always:Boolean = false;
		
		protected var _title_html:String = '';
		protected var _subtitle_html:String = '';
		
		override protected function _construct():void {
			super._construct();
			
			// to hold all the head elements			
			addChild(_head_sp);
			
			// keep it on top
			if (_close_bt && _close_bt.parent) _close_bt.parent.addChild(_close_bt);
			
			// graphic in head
			_setGraphicContents(null);
			_head_sp.addChild(_head_graphic);
			_head_sp.mouseEnabled = false;
			_head_sp.mouseChildren = true;
			_head_graphic.mouseEnabled = _head_graphic.mouseChildren = false;
			
			// title tf
			TFUtil.prepTF(_title_tf, false);
			_title_tf.mouseEnabled = false;
			_setTitle(_title_html);
			_head_sp.addChild(_title_tf);
			
			// subtitle tf
			TFUtil.prepTF(_subtitle_tf);
			_setSubtitle(_subtitle_html);
			_head_sp.addChild(_subtitle_tf);
			
			// to hold all the body elements			
			addChild(_body_sp);
			_scroller = new TSScroller({
				name: '_scroller',
				bar_wh: _scroller_bar_wh,
				bar_alpha: _scroller_bar_alpha,
				w: _w-(_border_w*2),
				bar_handle_min_h: 50,
				body_color: 0x00cc00,
				body_alpha: 0,
				scrolltrack_always: _scrolltrack_always,
				do_gradient: _show_scroller_gradient,
				gradient_c: _body_fill_c,
				use_children_for_body_h: true
			});
			_scroller.x = _border_w;
			_scroller.y = _divider_h;
			
			_body_sp.addChild(_scroller);
			
			// to hold all the foot elements	
			_setFootContents(null);
			addChild(_foot_sp);
			
			_head_sp.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownInHeaderHandler, false, 0, true);
		}
				
		protected function _setTitle(html:String):void {
			_title_html = html || 'Needs a title';
			const vag_ok:Boolean = StringUtil.VagCanRender(_title_html);
			_title_tf.embedFonts = vag_ok;
			if(vag_ok){
				_title_tf.htmlText = '<p class="big_dialog_title">'+_title_html+'</p>';
			}
			else {
				_title_tf.htmlText = '<p class="big_dialog_title_no_embed">'+_title_html+'</p>';
			}
			invalidate();
		}
		
		protected function _setSubtitle(html:String):void {
			_subtitle_html = html;
			if(_subtitle_html){
				//make sure we have something to show, and if VAG can show it
				const vag_ok:Boolean = StringUtil.VagCanRender(_subtitle_html);
				_subtitle_tf.embedFonts = vag_ok;
				if(vag_ok){
					_subtitle_tf.htmlText = '<p class="big_dialog_sub_title">'+_subtitle_html+'</p>';
				}
				else {
					_subtitle_tf.htmlText = '<p class="big_dialog_sub_title_no_embed">'+_subtitle_html+'</p>';
				}
			}
			_subtitle_tf.visible = (_subtitle_html != '');
			_subtitle_tf.mouseEnabled = (html.indexOf('<a') != -1);
			invalidate();
		}
		
		protected function _setGraphicContents(graphic:DisplayObject):void {
			while (_head_graphic.numChildren) _head_graphic.removeChildAt(0);
			if (graphic) {
				_head_graphic.addChild(graphic);
				_head_graphic.visible = true;
			} else {
				_head_graphic.visible = false;
			}
			invalidate();
		}
		
		protected function _setBodyContents(contents:DisplayObject):void {
			while (_scroller.body.numChildren) _scroller.body.removeChildAt(0);
			if (contents is DisplayObject) {
				_scroller.body.addChild(contents);
				_scroller.refreshAfterBodySizeChange(true);
				_body_sp.visible = true;
			} else {
				_body_sp.visible = false;
			}
			invalidate();
		}
		
		protected function _setFootContents(contents:DisplayObject):void {
			while (_foot_sp.numChildren) _foot_sp.removeChildAt(0);
			if (contents) {
				_foot_sp.addChild(contents);
				_foot_sp.visible = true;
			} else {
				_foot_sp.visible = false;
			}
			invalidate();
		}
		
		/* allow subclasses to decide what to null out.
		override public function end(release:Boolean):void {
			_setGraphicContents(null);
			_setFootContents(null);
			_setBodyContents(null);
			_setSubtitle('');
			super.end(release);
		}
		*/
		
		override protected function _jigger():void {
			super._jigger();
			
			var subtitle_y_minus:int = 2; // for snugging the subtitle up closer to the title
			var graphic_h:int = (_head_graphic.visible) ? _head_graphic.height : 0;
			_close_bt.x = _w - _close_bt.width - _close_bt_padd_right;
			
			if (_head_graphic.visible) {
				_head_graphic.x = _graphic_padd_side; // not _head_padd_top, because it can be set to zero to body to get nesteld up to head
				_title_tf.x = _head_graphic.x + _head_graphic.width + _graphic_padd_side;
			} else {
				_title_tf.x = _title_padd_left != -9999 ? _title_padd_left : _base_padd;
			}
			
			//if our text is too large, turn on wrapping and give it the max width it can be
			const max_title_w:int = _close_bt.x - _title_tf.x;
			_title_tf.multiline = _title_tf.wordWrap = false;
			if(_title_tf.width > max_title_w){
				_title_tf.multiline = _title_tf.wordWrap = true;
				_title_tf.width = max_title_w;
			}
			
			_subtitle_tf.x = _title_tf.x;
			
			var titles_h:int = _title_tf.height;
			
			if (_subtitle_tf.visible) {
				_subtitle_tf.width = _w - _subtitle_tf.x - 10 - (_w-_close_bt.x);
				_subtitle_tf.height = _subtitle_tf.textHeight+4;
				titles_h+= (_subtitle_tf.height - subtitle_y_minus);
			}
			
			_head_h = Math.max(Math.max(titles_h, graphic_h)+(_head_padd_top+_head_padd_bottom), _head_min_h);
			
			if (_center_close_bt_y_in_head) {
				_close_bt.y = int((_head_h - _close_bt.width)/2);
			}
			
			if (_head_graphic.visible) {
				if (_center_graphic_y_in_head) {
					_head_graphic.y = int(_head_h/2 - _head_graphic.height/2);
				} else {
					_head_graphic.y = _graphic_padd_top;
				}
			}
		
			_title_tf.y = int((_head_h-titles_h)/2);
			_subtitle_tf.y = _title_tf.y + _title_tf.height - subtitle_y_minus;
			
			_body_sp.y = _head_h;
			if (_body_sp.visible) {
				_body_h = Math.min(_body_max_h, _scroller.body_h+(_divider_h*2))
				_body_h = Math.max(_body_h, _body_min_h);
				_scroller.h = _body_h-(_divider_h*2);
			} else {
				_body_h = 0;
			}
			
			_foot_h = _foot_sp.height;
			_foot_sp.y = _head_h + _body_h;
			_foot_h = Math.max(_foot_h, _foot_min_h) + _border_w;
			
			_h = _head_h + _body_h + _foot_h;
		}
		
		override protected function _draw():void {
			super._draw();
			var g:Graphics = window_border.graphics;
			
			if (_body_sp.visible) {
				// body, border color
				g.beginFill(_body_border_c, 1);
				if(_foot_h > 0){
					g.drawRect(_border_w, _head_h, _w-(_border_w*2), _body_h);
				}else{
					g.drawRect(_border_w, _head_h, _w-(_border_w*2), 1);
				}
				
				// body, fill color, covering all but the top and botton pixel
				g.beginFill(_body_fill_c, 1);
				if(_foot_h > 0){
					g.drawRect(_border_w, _head_h+1, _w-(_border_w*2), _body_h-2);
				}else{
					g.drawRoundRectComplex(_border_w, _head_h+1, _w-(_border_w*2), _body_h-_border_w-1, 0, 0, 2, 2);
				}
			}
			
			g = _head_sp.graphics;
			g.clear();
			g.beginFill(0xcc0000, 0);
			g.drawRect(0, 0, _w, _head_h);
			g.endFill();
			
			/*
			// for debugging
			g = _body_sp.graphics;
			g.clear();
			g.beginFill(0x00cc00, 0);
			g.drawRect(0, 0, _w, _body_h);
			g = _foot_sp.graphics;
			g.clear();
			g.beginFill(0x0000cc, 0);
			g.drawRect(0, 0, _w, _foot_h);
			*/
		}
		
	}
}