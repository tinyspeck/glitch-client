package com.tinyspeck.engine.view.ui {
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.TSSprite;
	
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class FormElement extends TSSprite {
		
		protected var _value:*;
		protected var _init_ob:Object;
		protected var _label_tf:TextField = new TextField();
		protected var _label_size:int = 12;
		protected var _label_bold:Boolean = false;
		protected var _label_face:String = 'HelveticaEmbed';
		protected var _c:Number = 0xdbdbdb;
		protected var _c2:Number = 0xdbdbdb;
		protected var _focused_c:Number = 0xdbdbdb;
		protected var _focused_c2:Number = 0xdbdbdb;
		protected var _disabled_c:Number = 0xf5f5f5;
		protected var _disabled_c2:Number = 0xf5f5f5;
		protected var _disabled_focused_c:Number = 0xfafafa;
		protected var _disabled_focused_c2:Number = 0xfafafa;
		protected var _label_c:Number = 0x000000;
		protected var _label_disabled_c:Number = 0x989898;
		protected var _label_normal_c:Number = 0x000000;
		protected var _label_hover_c:Number = 0x000000;
		protected var _label_disabled_normal_c:Number = 0x989898;
		protected var _label_disabled_hover_c:Number = 0x989898;
		protected var _high_c:Number = 0xececec;
		protected var _shad_c:Number = 0xcecece;
		protected var _border_c:uint = 0x535e5e;
		protected var _disabled_border_c:uint = 0xadadad;
		protected var _disabled_focus_border_c:uint = 0xadadad;
		protected var _focus_border_c:uint = 0x516c73;
		protected var _border_alpha:Number = 1;
		protected var _focus_border_alpha:Number = 1;
		protected var _disabled_border_alpha:Number = 1;
		protected var _disabled_focused_border_alpha:Number = 1;
		protected var _border_width:int = 0; //don't draw a border unless someone wants to
		protected var _focused:Boolean = false;
		protected var _disabled:Boolean = false;
		protected var _use_hand_cursor_always:Boolean;
		protected var _offset_x:int;
		
		public function FormElement(init_ob:Object):void {
			super();
			
			buttonMode = true;
			useHandCursor = true;
			mouseEnabled = true;
			mouseChildren = false;
			
			_init_ob = init_ob;
			
			CONFIG::debugging {
				if (!_init_ob.hasOwnProperty('name')) {
					Console.warn('FormElement constructor w/out _init_ob.name');
					Console.dir(_init_ob);
				}
			}
			
			if (!_init_ob.hasOwnProperty('value')) {
				_init_ob.value = null;
			}
			
			_value = _init_ob.value;
			name = init_ob.name;
			
			if (_init_ob.hasOwnProperty('w')) _w = _init_ob.w;
			if (_init_ob.hasOwnProperty('h')) _h = _init_ob.h;
			if (_init_ob.hasOwnProperty('c')) _c = _c2 = _focused_c = _focused_c2 = _init_ob.c;
			if (_init_ob.hasOwnProperty('disabled_c')) _disabled_c = _disabled_c2 = _init_ob.disabled_c;
			if (_init_ob.hasOwnProperty('focused_c')) _focused_c = _focused_c2 = _init_ob.focused_c;
			if (_init_ob.hasOwnProperty('high_c')) _high_c = _init_ob.high_c;
			if (_init_ob.hasOwnProperty('shad_c')) _shad_c = _init_ob.shad_c;
			if (_init_ob.hasOwnProperty('label_size')) _label_size = _init_ob.label_size;
			if (_init_ob.hasOwnProperty('label_bold')) _label_bold = _init_ob.label_bold;
			if (_init_ob.hasOwnProperty('label_face')) _label_face = _init_ob.label_face;
			if (_init_ob.hasOwnProperty('label_c')) _label_c = _label_normal_c = _label_hover_c = _init_ob.label_c;
			if (_init_ob.hasOwnProperty('label_hover_c')) _label_hover_c = _init_ob.label_hover_c;
			if (_init_ob.hasOwnProperty('label_disabled_c')) _label_disabled_c = _init_ob.label_disabled_c;
			if (_init_ob.hasOwnProperty('border_c')) _border_c = _focus_border_c = _init_ob.border_c;
			if (_init_ob.hasOwnProperty('focus_border_c')) _focus_border_c = _init_ob.focus_border_c;
			if (_init_ob.hasOwnProperty('border_alpha')) _border_alpha = _focus_border_alpha = _disabled_border_alpha = _init_ob.border_alpha;
			if (_init_ob.hasOwnProperty('focus_border_alpha')) _focus_border_alpha = _init_ob.focus_border_alpha;
			if (_init_ob.hasOwnProperty('disabled_border_alpha')) _disabled_border_alpha = _disabled_focused_border_alpha = _init_ob.disabled_border_alpha;
			if (_init_ob.hasOwnProperty('disabled_focus_border_alpha')) _disabled_focused_border_alpha = _init_ob.disabled_focus_border_alpha;
			if (_init_ob.hasOwnProperty('border_width')) _border_width = _init_ob.border_width;
			if (_init_ob.hasOwnProperty('use_hand_cursor_always')) _use_hand_cursor_always = _init_ob.use_hand_cursor_always;
			if (_init_ob.hasOwnProperty('offset_x')) _offset_x = _init_ob.offset_x;
			
			_disabled = (_init_ob.disabled === true);
			
		}
		
		protected function _clickHandler(e:MouseEvent):void {}
		
		protected function _downHandler(e:MouseEvent):void {
			StageBeacon.mouse_up_sig.add(_upHandler);
		}
		
		protected function _upHandler(e:MouseEvent):void {
			StageBeacon.mouse_up_sig.remove(_upHandler);
		}
		
		protected function _overHandler(e:MouseEvent):void {
			focus();
			if(_use_hand_cursor_always){
				useHandCursor = true;
			}
			else {
				useHandCursor = !_disabled;
			}
		}
		
		protected function _outHandler(e:MouseEvent):void {
			blur();
		}
		
		public function focus():void {
			_focused = true;
		}
		
		public function blur():void {
			_focused = false;
		}
		
		override protected function _construct():void {
			addEventListener(MouseEvent.CLICK, _clickHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_OVER, _overHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_OUT, _outHandler, false, 0, true);
			addEventListener(MouseEvent.MOUSE_DOWN, _downHandler, false, 0, true);
			super._construct();
		}
		
		public function get disabled():Boolean {
			return (_disabled === true);
		}
		
		public function set disabled(disabled:Boolean):void {
			if (disabled === _disabled) return;
			_disabled = disabled;
			if(_disabled) blur();
			label = _init_ob.label || '';
			_draw();
		}
		
		public function set value(val:*):void {
			_value = val;
		}
		
		public function get value():* {
			return _value;
		}
		
		public function set w(w:int):void {
			_w = w;
			label = _init_ob.label || '';
			_draw();
		}
		
		public function set h(h:int):void {
			_h = h;
			_draw();
		}
		
		public function get label_tf():TextField {
			return _label_tf;
		}
		
		public function set label(lab:String):void {
			if (_label_bold) lab = '<b>'+lab+'</b>';
			_label_tf.htmlText = '<font face="Arial" size="'+_label_size+'" color="#000000">'+lab+'</font>';
			_draw();
		}
		
		public function set label_color(value:uint):void {
			_label_c = _label_normal_c = value;
			_draw();
		}
		
		public function set label_color_disabled(value:uint):void {
			_label_disabled_c = value;
			_draw();
		}
		
		public function set label_color_hover(value:uint):void {
			_label_hover_c = _label_disabled_hover_c = value;
			_draw();
		}
		
		public function set label_x(value:int):void {
			_offset_x = value;
			_draw();
		}
		
		public function get focused():Boolean { return _focused; }
	}
}