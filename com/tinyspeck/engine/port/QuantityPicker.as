package com.tinyspeck.engine.port {
	
	import com.tinyspeck.bootstrap.BootUtil;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
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
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	
	public class QuantityPicker extends FormElement {
		
		private var plus_bt:Button;
		private var minus_bt:Button;
		private var max_bt:Button;
		
		private var button_wh:int;
		private var button_padd:int;
		private var input_border_size:int;
		private var input_border_color:Number;
		
		private var bg_holder:Sprite = new Sprite();
		private var bg_mask:Sprite = new Sprite(); //because the tf is autosized it can wrap in the blink of an eye
		
		private var count_tf:TextField = new TextField();
		
		private var change_timer:Timer = new Timer(700);
		
		private var _max_value:int;
		private var _min_value:int;
		private var _show_all_option:Boolean;
		
		public function QuantityPicker(init_ob:Object):void {
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
			input_border_color = (_init_ob.input_border_color) ? _init_ob.input_border_color : 0xaccbd3;
			button_wh = (_init_ob.button_wh) ? _init_ob.button_wh : 20;
			button_padd = (_init_ob.button_padd) ? _init_ob.button_padd : 3;
			_max_value = (_init_ob.max_value) ? _init_ob.max_value : 100000;
			_value = _min_value = (_init_ob.min_value) ? _init_ob.min_value : 0;
			_show_all_option = _init_ob.hasOwnProperty('show_all_option') ? _init_ob.show_all_option : false;
			
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
			minus_bt.addEventListener(MouseEvent.CLICK, _decrementValue, false, 0, true);
			
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
			plus_bt.addEventListener(MouseEvent.CLICK, _incrementValue, false, 0, true);
			
			max_bt = new Button({
				label: 'Max',
				name: '_max_bt',
				value: 'max',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_QTY_MAX
			})
			addChild(max_bt);
			max_bt.addEventListener(MouseEvent.CLICK, onMaxClick, false, 0, true);
			
			//set the text format
			TFUtil.prepTF(count_tf, false);
			TFUtil.setTextFormatFromStyle(count_tf, 'quantity_picker');
			const format:TextFormat = count_tf.defaultTextFormat;
			format.size = getFontSize();
			count_tf.defaultTextFormat = format;
			count_tf.selectable = true;
			count_tf.type = TextFieldType.INPUT;
			count_tf.autoSize = TextFieldAutoSize.NONE;
			count_tf.restrict = '0-9'
			addChild(count_tf);
			
			count_tf.addEventListener(FocusEvent.FOCUS_IN, _inputFocusHandler, false, 0, true);
			count_tf.addEventListener(FocusEvent.FOCUS_OUT, _inputBlurHandler, false, 0, true);
			count_tf.addEventListener(MouseEvent.CLICK, onInputClick, false, 0, true);
			
			change_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			
			_draw();
		}
		
		private function onTimerTick(event:TimerEvent):void {
			change_timer.stop();
			dispatchEvent(new TSEvent(TSEvent.QUANTITY_CHANGE, this));
		}
		
		private function onMaxClick(event:MouseEvent):void {
			value = _max_value;
		}
		
		private function onInputClick(event:MouseEvent):void {
			if(!_value) count_tf.setSelection(0, count_tf.text.length);
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
		
		private function _inputAnyKeyHandler(e:* = null):void {
			if (count_tf.text != '') {
				value = parseInt(count_tf.text);
				change_timer.reset();
				if(!change_timer.running) change_timer.start();
			}
		}
		
		private function _updateCountTfAndButtons():void {
			if (parseInt(count_tf.text) != _value) {
				count_tf.text = String(_value);
				count_tf.height = count_tf.textHeight + 4;
				count_tf.y = int((_h+input_border_size)/2 - count_tf.height/2) + 1;
				
				// only take focus if visible, because what's the point
				if(visible){
					count_tf.setSelection(count_tf.text.length, count_tf.text.length);
					StageBeacon.stage.focus = count_tf;
				}
			}
			
			plus_bt.disabled = (_value == _max_value);
			plus_bt.disabled ? plus_bt.alpha = .6 : plus_bt.alpha = 1;
			
			minus_bt.disabled = (_value == _min_value);
			minus_bt.disabled ? minus_bt.alpha = .6 : minus_bt.alpha = 1;
		}
		
		private function _incrementValue(event:MouseEvent):void {
			if (_value < _max_value) {
				value = value+1;
				
				change_timer.reset();
				if(!change_timer.running) change_timer.start();
			}
		}
		
		private function _decrementValue(event:MouseEvent):void {
			if (_value > _min_value) {
				value = value-1;
				
				change_timer.reset();
				if(!change_timer.running) change_timer.start();
			}
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
		}
		
		override protected function _clickHandler(e:MouseEvent):void {
			
		}
		
		override protected function _draw():void {
			//Console.warn('QuantityPicker._draw started _h:'+_h+' _minus_bt.h:'+_minus_bt.h+' _button_wh:'+_button_wh+' _button_padd:'+_button_padd);
			
			var w:int = _w + input_border_size;
			var h:int = _h + input_border_size;
			
			minus_bt.x = button_padd + input_border_size - 1;
			minus_bt.y = int(h/2 - minus_bt.height/2);
			plus_bt.x = int(w - plus_bt.width) - button_padd - input_border_size - 1;
			plus_bt.y = minus_bt.y;
			
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(input_border_color);
			g.drawRoundRect(0, 0, w, h, 7.5);
			g.beginFill(0xffffff);
			g.drawRoundRect(input_border_size, input_border_size, w-input_border_size*2, h-input_border_size*2, 6.5);
			
			g = bg_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(input_border_size/2, input_border_size/2, w-(input_border_size/2)*2, h-(input_border_size/2)*2, 6.5);
			
			g = bg_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, w, h, 7.5);
			
			max_bt.visible = _show_all_option;
			max_bt.x = int(w - max_bt.width - button_padd - input_border_size) - 2;
			max_bt.y = int(h/2 - max_bt.height/2);
			if(_show_all_option){
				//move the plus button to the left of the max button
				plus_bt.x = max_bt.x - plus_bt.width - 2;
			}
			
			count_tf.height = count_tf.textHeight + 4;
			count_tf.x = int(minus_bt.x + minus_bt.width - 1);
			count_tf.y = int((_h+input_border_size)/2 - count_tf.height/2) + 1;
			count_tf.width = int(plus_bt.x - count_tf.x + 1);
		}
		
		private function getFontSize():int {
			return _h - (_h >= 30 ? 17 : 8);
		}
		
		override public function set value(new_value:*):void {
			if(isNaN(new_value)) return;
			
			var was_value:int = _value;
			if (new_value > _max_value) new_value = _max_value;
			if (new_value < _min_value) new_value = _min_value;
			_value = new_value;
			_updateCountTfAndButtons();
			
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
		
		public function set show_all_option(value:Boolean):void {
			_show_all_option = value;
			_draw();
		}
	}
}