package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	public class CurrencyInput extends Sprite
	{
		public static const CURRANCY_SYMBOL:String = '₡';
		private static const HEIGHT:uint = 26;
		private static const DEFAULT_TF_WIDTH:uint = 125;
		
		private var label_tf:TextField = new TextField();
		private var symbol_tf:TextField = new TextField();
		private var input_tf:TextField = new TextField();
		private var border_color:uint = 0xb0bfc2;
		private var save_bt:Button;
		
		private var _is_input:Boolean = true;
		private var _value:int;
		private var _max_value:int = -1;
		private var _hide_save_button:Boolean;
		
		public function CurrencyInput() {
			construct();
		}
		
		private function construct():void {
			//this allows the focus to not be stolen on start
			visible = false;
			
			TFUtil.prepTF(label_tf, false);
			addChild(label_tf);
						
			TFUtil.prepTF(symbol_tf, false);
			symbol_tf.htmlText = '<span class="currency_input_symbol">'+CURRANCY_SYMBOL+'</span>';
			addChild(symbol_tf);
			
			TFUtil.prepTF(input_tf, false);
			TFUtil.setTextFormatFromStyle(input_tf, 'currency_input_amount');
			input_tf.autoSize = TextFieldAutoSize.NONE;
			input_tf.type = TextFieldType.INPUT;
			input_tf.selectable = true;
			input_tf.restrict = '0-9';
			input_tf.width = DEFAULT_TF_WIDTH;
			input_tf.height = HEIGHT - 2;
			input_tf.y = 1;
			input_tf.addEventListener(FocusEvent.FOCUS_IN, onInputFocus, false, 0, true);
			input_tf.addEventListener(FocusEvent.FOCUS_OUT, onInputBlur, false, 0, true);
			input_tf.addEventListener(Event.CHANGE, onInputChange);
			input_tf.addEventListener(MouseEvent.CLICK, onInputClick, false, 0, true);
			addChild(input_tf);
			
			//set the value to 0
			value = 0;
			
			//create the little save button
			save_bt = new Button({
				label: 'Save',
				name: 'save_bt',
				size: Button.SIZE_MICRO,
				type: Button.TYPE_MINOR,
				h: HEIGHT - 6
			});
			save_bt.visible = false;
			save_bt.addEventListener(MouseEvent.CLICK, onInputBlur, false, 0, true);
			addChild(save_bt);
			
			//set the border color
			border_color = CSSManager.instance.getUintColorValueFromStyle('currency_input', 'borderColor', border_color);
			
			jigger();
		}
		
		private function onInputChange(e:Event):void {			
			const txt_val:Number = parseInt(input_tf.text);
			if(!isNaN(txt_val)){
				value = validateValue(txt_val);
			}
			else {
				//no number, set the value to 0 and throw out an event
				_value = 0;
				dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
			}
		}
		
		private function validateValue(val:int):int {
			if (val <= 0) {
				return 0;
			}
			return (val > _max_value && _max_value > -1) ? _max_value : val;
		}
		
		private function onInputFocus(event:FocusEvent):void {			
			if(_is_input){
				StageBeacon.stage.focus = input_tf;
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_UP_, onInputKey, false, 0, true);
			}
		}
		
		private function onInputKey(event:KeyboardEvent):void {						
			if(event.keyCode == Keyboard.ENTER){
				onInputBlur(event);
			}
		}
		
		private function onInputBlur(event:Event):void {
			if(_is_input) KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_UP_, onInputKey);
			
			value = input_tf.text == '' ? 0 : validateValue(parseInt(input_tf.text));
			
			dispatchEvent(new TSEvent(TSEvent.FOCUS_OUT, this));
			
			if(save_bt) save_bt.visible = false;
		}
		
		private function onInputClick(event:MouseEvent):void {
			if(_is_input && !_value) input_tf.setSelection(0, input_tf.text.length);
		}
		
		private function jigger():void {
			symbol_tf.x = label_tf.text ? int(label_tf.width + 15) : 5;
			symbol_tf.y = int(HEIGHT/2 - symbol_tf.height/2 + 1);
			
			label_tf.y = int(HEIGHT/2 - label_tf.height/2);
			
			input_tf.x = int(symbol_tf.x + symbol_tf.width + 2);
			
			save_bt.x = int(input_tf.x + input_tf.width - save_bt.width - 4);
			save_bt.y = int(HEIGHT/2 - save_bt.height/2);
			
			const bg_x:int = label_tf.text ? int(label_tf.width + 10) : 0;
			const bg_w:int = input_tf.x + input_tf.width - bg_x;
			
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xffffff, ((_is_input) ? 1 : 0));
			g.lineStyle(1, border_color, ((_is_input) ? 1 : 0), true, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			g.drawRoundRect(bg_x, 0, bg_w, HEIGHT, 6);
		}
				
		public function get value():int { return parseInt(input_tf.text); }
		public function set value(new_value:int):void {
			var was_value:int = _value;
			_value = validateValue(new_value);
			input_tf.text = String(_value);
			
			if (_value != was_value) {
				dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
				if(save_bt && _is_input && visible && !_hide_save_button) save_bt.visible = true;
			}
		}
		
		public function set max_value(new_max:int):void {
			_max_value = new_max;
			if (_value > _max_value) value = _max_value;
		}
		
		public function set label_txt(txt:String):void {
			label_tf.htmlText = '<span class="currency_input_label">'+txt+'</span>';
			jigger();
		}
		
		public function set is_input(value:Boolean):void {
			_is_input = value;
			input_tf.selectable = value;
			input_tf.type = value ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
			
			if(!value && input_tf.hasEventListener(FocusEvent.FOCUS_IN)){
				input_tf.removeEventListener(FocusEvent.FOCUS_IN, onInputFocus);
				input_tf.removeEventListener(FocusEvent.FOCUS_OUT, onInputBlur);
			}else if(!input_tf.hasEventListener(FocusEvent.FOCUS_IN)){
				input_tf.addEventListener(FocusEvent.FOCUS_IN, onInputFocus, false, 0, true);
				input_tf.addEventListener(FocusEvent.FOCUS_OUT, onInputBlur, false, 0, true);
			}
			
			jigger();
		}
		
		public function set hide_save_button(value:Boolean):void {
			_hide_save_button = value;
		}
		
		override public function set width(value:Number):void {
			input_tf.width = value - input_tf.x;
			jigger();
		}
	}
}