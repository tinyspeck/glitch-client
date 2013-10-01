package com.tinyspeck.engine.port {
	
	import com.tinyspeck.bootstrap.BootUtil;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.FormElement;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.Timer;
	
	
	public class QuantityPickerSpecial extends FormElement {
		
		private var plus_bt:Button;
		private var minus_bt:Button;
		private var go_bt:Button;
		
		private var button_wh:int;
		private var button_padd:int;
		private var button_offset:int;
		private var input_border_size:int;
		private var input_border_color:Number;
		private var outside_border_size:int;
		private var outside_border_c:uint;
		private var outside_border_c2:uint;
		
		private var bg_holder:Sprite = new Sprite();
		private var bg_mask:Sprite = new Sprite(); //because the tf is autosized it can wrap in the blink of an eye
		
		private var count_tf:TextField = new TextField();
		
		private var change_timer:Timer = new Timer(700);
		
		private var _max_value:int;
		private var _min_value:int;
		private var _show_go_option:Boolean;
		
		public function QuantityPickerSpecial(init_ob:Object):void {
			super(init_ob);
			
			buttonMode = false;
			useHandCursor = false;
			mouseEnabled = true;
			mouseChildren = true;
			
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			
			input_border_size = (_init_ob.input_border_size) ? _init_ob.input_border_size : 1;
			outside_border_size = (_init_ob.outside_border_size) ? _init_ob.outside_border_size : 0;
			outside_border_c = (_init_ob.outside_border_c) ? _init_ob.outside_border_c : 0x000000;
			outside_border_c2 = (_init_ob.outside_border_c2) ? _init_ob.outside_border_c2 : outside_border_c;
			input_border_color = (_init_ob.input_border_color) ? _init_ob.input_border_color : 0xaccbd3;
			button_wh = (_init_ob.button_wh) ? _init_ob.button_wh : 20;
			button_padd = (_init_ob.button_padd) ? _init_ob.button_padd : 3;
			_max_value = (_init_ob.max_value) ? _init_ob.max_value : 100000;
			_min_value = (_init_ob.min_value) ? _init_ob.min_value : 0;
			_value = _value || _min_value;
			_show_go_option = _init_ob.hasOwnProperty('show_go_option') ? _init_ob.show_go_option : false;
			
			x = _init_ob.x || 0;
			y = _init_ob.y || 0;
			
			_w = _w || 200;
			_h = _h || 60;
			
			//inner shadow
			var inner_ds:DropShadowFilter = new DropShadowFilter();
			inner_ds.inner = true;
			inner_ds.angle = 90;
			inner_ds.distance = 2;
			inner_ds.blurX = inner_ds.blurY = 3;
			inner_ds.alpha = .15;
			inner_ds.knockout = true;
			bg_holder.filters = [inner_ds];
			
			addChild(bg_holder);
			
			mask = bg_mask;
			addChild(bg_mask);
			
			if(_init_ob.minus_graphic is AssetManager.instance.assets.minus_red_small){
				//this helps with the small buttons being vertically aligned
				button_offset = 1;
			}
			
			minus_bt = new Button({
				graphic: _init_ob.minus_graphic,
				label: '',
				name: '_minus_bt',
				value: 'minus',
				size: Button.SIZE_QTY_MAX,
				type: Button.TYPE_QTY
			});
			minus_bt.w = minus_bt.h = button_wh;
			addChild(minus_bt);
			minus_bt.addEventListener(MouseEvent.CLICK, onMinusClick, false, 0, true);
			
			plus_bt = new Button({
				graphic: _init_ob.plus_graphic,
				label: '',
				name: '_plus_bt',
				value: 'plus',
				size: Button.SIZE_QTY_MAX,
				type: Button.TYPE_QTY
			});
			plus_bt.w = plus_bt.h = button_wh;
			addChild(plus_bt);
			plus_bt.addEventListener(MouseEvent.CLICK, onPlusClick, false, 0, true);
			
			go_bt = new Button({
				label: 'go',
				name: '_go_bt',
				value: 'go',
				size: Button.SIZE_QTY_GO,
				type: Button.TYPE_QTY_GO
			})
			addChild(go_bt);
			go_bt.addEventListener(MouseEvent.CLICK, onGoClick, false, 0, true);
			
			//can't prep this TF since it's INPUT and CSS shits the bed
			count_tf.multiline = false;
			count_tf.wordWrap = true;
			count_tf.embedFonts = true;
			count_tf.antiAliasType = AntiAliasType.ADVANCED;
			count_tf.type = TextFieldType.INPUT;
			count_tf.restrict = '0-9'
			addChild(count_tf);
			
			count_tf.addEventListener(FocusEvent.FOCUS_IN, _inputFocusHandler, false, 0, true);
			count_tf.addEventListener(FocusEvent.FOCUS_OUT, _inputBlurHandler, false, 0, true);
			
			change_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			
			boundAndSetValue(value);
			updateCountTfAndButtons(false, false);
			
			_draw();
		}
		
		public function focusAndSelectAll():void {
			focus();
			StageBeacon.waitForNextFrame(updateCountTfAndButtons, true, true);
		}
		
		public function focusAndCursorAtEnd():void {
			focus();
			StageBeacon.waitForNextFrame(updateCountTfAndButtons, true, false);
		}
		
		override public function focus():void {
			var was_focused:Boolean = _focused;
			super.focus();
			if (was_focused) return;
			go_bt.focus();
			_draw();
		}
		
		override public function blur():void {
			super.blur();
			_draw();
			if (count_tf && StageBeacon.stage.focus == count_tf) {
				StageBeacon.stage.focus = StageBeacon.stage;
			}
			go_bt.blur();
		}
		
		override protected function _overHandler(e:MouseEvent):void {
			
		}
		
		override protected function _outHandler(e:MouseEvent):void {
			// keep the go button higlighted
			if (e.target == go_bt) {
				go_bt.focus();
			}
		}
		
		private function onTimerTick(event:TimerEvent):void {
			change_timer.stop();
			dispatchEvent(new TSEvent(TSEvent.QUANTITY_CHANGE, this));
		}
		
		private function onMaxClick(event:MouseEvent):void {
			value = _max_value;
		}
		
		private function onGoClick(event:MouseEvent):void {
			//Console.warn('GO')
		}
		
		private function _inputFocusHandler(e:FocusEvent):void {
			count_tf.addEventListener(KeyboardEvent.KEY_UP, _inputAnyKeyHandler);
		}
		
		private function _inputBlurHandler(e:FocusEvent):void {
			count_tf.removeEventListener(KeyboardEvent.KEY_UP, _inputAnyKeyHandler);
			if (count_tf.text == '') {
				value = _min_value;
			}
		}
		
		private function _inputAnyKeyHandler(e:KeyboardEvent = null):void {
			if (count_tf.text != '') {
				value = parseInt(count_tf.text);
				change_timer.reset();
				if(!change_timer.running) change_timer.start();
			}
		}
		
		private function updateCountTfAndButtons(take_focus:Boolean, select_all:Boolean):void {
			if (parseInt(count_tf.text) != _value && visible) { // only visible, because what's the point
				count_tf.htmlText = '<p align="center"><font face="VAGRoundedBoldEmbed" size="'+getFontSize()+'" color="#495e5e"><b>'+_value+'</b></font></p>';
				count_tf.height = count_tf.textHeight + 4;
				count_tf.y = int((_h+input_border_size)/2 - count_tf.height/2) + 1;
				
			}
			if (visible && take_focus) {
				StageBeacon.stage.focus = count_tf;
				count_tf.setSelection(select_all?0:count_tf.text.length, count_tf.text.length);
			}
			
			plus_bt.disabled = (_value == _max_value);
			plus_bt.disabled ? plus_bt.alpha = .6 : plus_bt.alpha = 1;
			
			minus_bt.disabled = (_value == _min_value);
			minus_bt.disabled ? minus_bt.alpha = .6 : minus_bt.alpha = 1;
		}
		
		private function onPlusClick(event:MouseEvent):void {
			incrementValue();
		}
		
		public function incrementValue():Boolean {
			if (_value < _max_value) {
				value = value+1;
				
				change_timer.reset();
				if(!change_timer.running) change_timer.start();
				return true;
			}
			return false;
		}
		
		private function onMinusClick(event:MouseEvent):void {
			decrementValue()
		}
		
		public function decrementValue():Boolean {
			if (_value > _min_value) {
				value = value-1;
				
				change_timer.reset();
				if(!change_timer.running) change_timer.start();
				return true;
			}
			
			return false;
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
		}
		
		override protected function _draw():void {
			//Console.warn('QuantityPickerSpecial._draw started _h:'+_h+' _minus_bt.h:'+_minus_bt.h+' _button_wh:'+_button_wh+' _button_padd:'+_button_padd);
			
			var w:int = _w + input_border_size;
			var h:int = _h + input_border_size;
			
			minus_bt.x = button_padd + input_border_size;
			minus_bt.y = int(h/2 - minus_bt.height/2) + button_offset;
			plus_bt.x = int(w - plus_bt.width) - button_padd - input_border_size;
			plus_bt.y = minus_bt.y;
			
			var draw_outside_border:Boolean = _focused && outside_border_size;
			var outside_border_sizex2:int = outside_border_size*2;
			
			var fill_c:uint = 0xffffff;
			
			var g:Graphics = graphics;
			g.clear();
			
			if (draw_outside_border) {
				g.beginFill(outside_border_c);
				g.drawRoundRect(-outside_border_size, -outside_border_size, w+outside_border_sizex2, h+outside_border_sizex2, 7.5+outside_border_size);
				
				// one pixel of a lighter color just outside the grey border
				if (outside_border_size > 1 && outside_border_c2 != outside_border_c) {
					g.beginFill(outside_border_c2);
					g.drawRoundRect(-(outside_border_size-1), -(outside_border_size-1), w+(outside_border_sizex2-2), h+(outside_border_sizex2-2), 7.5+(outside_border_size-1));
				}
			}
			
			var bc:uint = (draw_outside_border && outside_border_c) ? outside_border_c : input_border_color;
			g.beginFill(input_border_color);
			g.drawRoundRect(0, 0, w, h, 7.5);
			g.beginFill(fill_c);
			g.drawRoundRect(input_border_size, input_border_size, w-input_border_size*2, h-input_border_size*2, 6.5);
			
			g = bg_holder.graphics;
			g.clear();
			g.beginFill(fill_c);
			g.drawRoundRect(input_border_size/2, input_border_size/2, w-(input_border_size/2)*2, h-(input_border_size/2)*2, 6.5);
			
			g = bg_mask.graphics;
			g.clear();
			g.beginFill(0);
			
			if (draw_outside_border) {
				g.drawRoundRect(-outside_border_size, -outside_border_size, w+outside_border_sizex2, h+outside_border_sizex2, 7.5+outside_border_size);
			} else {
				g.drawRoundRect(0, 0, w, h, 7.5);
			}
			
			go_bt.visible = _show_go_option;
			go_bt.x = int(w - go_bt.width - button_padd - input_border_size) - 2;
			go_bt.y = int(h/2 - go_bt.height/2);
			if(_show_go_option){
				//move the plus button to the left of the max button
				plus_bt.x = go_bt.x - plus_bt.width - 2;
			}
			
			count_tf.height = count_tf.textHeight + 4;
			count_tf.x = int(minus_bt.x + minus_bt.width);
			count_tf.y = int((_h+input_border_size)/2 - count_tf.height/2) + 1;
			count_tf.width = int(plus_bt.x - count_tf.x);
		}
		
		private function getFontSize():int {
			return _h - (_h >= 30 ? 17 : 8);
		}
		
		private function boundAndSetValue(new_value:int):void {
			if (new_value > _max_value) new_value = _max_value;
			if (new_value < _min_value) new_value = _min_value;
			_value = new_value;
		}
		
		override public function set value(new_value:*):void {
			if(isNaN(new_value)) return;
			var was_value:int = _value;
			
			boundAndSetValue(new_value);
			updateCountTfAndButtons(false, false);
			
			if (_value != was_value) {
				//Console.warn(was_value+' -> '+_value)
				dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
			}
		}
		
		public function set max_value(new_max:int):void {
			_max_value = new_max;
			if(_value > _max_value) value = _max_value;
			plus_bt.disabled = (_value == _max_value) ? true : false;
			plus_bt.disabled ? plus_bt.alpha = .6 : plus_bt.alpha = 1;
		}
		
		public function set min_value(new_min:int):void {
			_min_value = new_min;
			if (_value < _min_value) value = _min_value;
		}
		
		override public function dispose():void {
			count_tf.removeEventListener(FocusEvent.FOCUS_IN, _inputFocusHandler, false);
			count_tf.removeEventListener(FocusEvent.FOCUS_OUT, _inputBlurHandler, false);
			
			if (count_tf && StageBeacon.stage.focus == count_tf) {
				StageBeacon.stage.focus = StageBeacon.stage;
			}
			
			super.dispose();
		}
	}
}