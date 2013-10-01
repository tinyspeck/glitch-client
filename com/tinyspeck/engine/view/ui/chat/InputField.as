package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	public class InputField extends TSSpriteWithModel implements IFocusableComponent
	{
		public static const MAX_CHARS:uint = 1000;
		
		private static const DEFAULT_HEIGHT:uint = 25;
		private static const X_PADD:uint = 4;
		
		public static function getInputFieldParentOfTF(tf:TextField):InputField {
			if (!tf) return null;
			var p:DisplayObjectContainer = tf.parent;
			while (p) {
				if (p is InputField) return p as InputField;
				p = p.parent;
			}
			return null;
		}
		
		private var bg:Sprite = new Sprite();
		private var highlight:Sprite = new Sprite();
		
		public var input_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var vert_arrow_repeat_cnt:int;
		
		private var display_txts:Array;
		private var client_links:Array;
		
		private var has_focus:Boolean;
		private var is_enabled:Boolean = true;
		private var _is_for_chat:Boolean;

		public function get is_for_chat():Boolean {
			return _is_for_chat;
		}

		
		public function InputField(is_for_chat:Boolean, listen_for_changes:Boolean=false, max_chars:int=0){
			_is_for_chat = is_for_chat;
			filters = StaticFilters.inputDropA;
			
			_h = DEFAULT_HEIGHT;
			
			addChild(bg);
			addChild(highlight);
			// a lot of code depends on the input_tf being a child of the InputField, so DON't MOVE THIS
			addChild(input_tf);
			
			highlight.alpha = 0;
			
			//prep the TF
			TFUtil.prepTF(input_tf, false);
			TFUtil.setTextFormatFromStyle(input_tf, 'input_field');
			input_tf.embedFonts = false;
			input_tf.selectable = true;
			input_tf.autoSize = TextFieldAutoSize.NONE;
			input_tf.maxChars = max_chars || MAX_CHARS;
			input_tf.type = TextFieldType.INPUT;
			input_tf.height = input_tf.textHeight + 4;
			input_tf.x = X_PADD;
			input_tf.y = int(_h/2 - input_tf.height/2);
			input_tf.addEventListener(FocusEvent.FOCUS_IN, onInputFocus, false, 0, true);
			input_tf.addEventListener(FocusEvent.FOCUS_OUT, onInputBlur, false, 0, true);
			
			//listen to the mouse
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			
			//let the state model know who we are
			model.stateModel.registerFocusableComponent(this);
			
			//maybe listen for changes
			this.listen_for_changes = listen_for_changes;
			
			draw();
		}
		
		private function draw():void {
			var g:Graphics = bg.graphics;
			g.clear();
			g.lineStyle(1, 0xb3c4cd, 1, true);
			g.beginFill(0xe7ecee);
			g.drawRoundRect(0, 0, _w, _h, 7);
			
			g = highlight.graphics;
			g.clear();
			g.lineStyle(1, 0xc3c38e, 1, true);
			g.beginFill(0xf5f5ce);
			g.drawRoundRect(0, 0, _w, _h, 7);
			
			input_tf.width = _w - X_PADD*2;
			input_tf.selectable = is_enabled;
		}
		
		public function onRollOver(event:MouseEvent = null):void {
			if(!is_enabled) return;
			TSTweener.removeTweens(highlight);
			TSTweener.addTween(highlight, {alpha:1, time:.2, transition:'linear'});
		}
		
		public function onRollOut(event:MouseEvent = null):void {
			if(has_focus) return;
			
			TSTweener.removeTweens(highlight);
			TSTweener.addTween(highlight, {alpha:0, time:.2, transition:'linear'});
		}
		
		private function onKeyDown(event:KeyboardEvent):void {
			dispatchEvent(event);
		}
		
		private function onEscape(event:KeyboardEvent):void {
			dispatchEvent(event);
			blurInput();
		}
		
		private function onInputFocus(event:FocusEvent = null):void {
			/*CONFIG::debugging {
				Console.warn(name+' onInputFocus '+is_enabled+' '+has_focus);
			}*/
			if(!is_enabled) return;
			if(!has_focus) {
				/*CONFIG::debugging {
					Console.warn('onInputFocus now calls requestFocus');
				}*/
				if(!TSFrontController.instance.requestFocus(this, 'input name: '+name)) {
					CONFIG::debugging {
						Console.warn('could not take focus');
					}
					// you cannot blur an input during the hanlder for its focusing
					StageBeacon.waitForNextFrame(blurInput);
				}
			}
			onRollOver();
			dispatchEvent(new TSEvent(TSEvent.FOCUS_IN, this));
		}
		
		private function onInputBlur(e:FocusEvent):void {
			if (has_focus) {
				if (e.relatedObject && e.relatedObject is Button) {
					// We optimistically think focus is switching because
					// of a mousedown on a button, so let's waut until mouse goes up
					// to actually releaseFocus, so we don't get nasty quick
					// blinks of focus going back to MainView in between the mouse down
					// and the actual click event
					StageBeacon.mouse_up_sig.add(onMouseUp);
				} else {
					TSFrontController.instance.releaseFocus(this, 'onInputBlur()');
				}
				dispatchEvent(new TSEvent(TSEvent.FOCUS_OUT, this));
			}
			onRollOut();
		}
		
		private function onMouseUp(e:MouseEvent):void {
			StageBeacon.mouse_up_sig.remove(onMouseUp);
			TSFrontController.instance.releaseFocus(this, 'mouse up');
			onRollOut();
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur '+this.name);
			}
			has_focus = false;
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_UP_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_UP_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscape);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_, onKeyDown);
			blurInput();
			filters = StaticFilters.inputDropA;
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus '+this.name);
			}
			has_focus = true;
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_UP_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_UP_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscape);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_, onKeyDown);
			focusOnInput();
			filters = null;
		}
		
		private function arrowHandler(event:KeyboardEvent):void {
			//check for the up/down arrow
			if(event.type == KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.UP || event.type == KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN){
				if (vert_arrow_repeat_cnt % 5 == 0) { // only act on every 5th event
					dispatchEvent(event);
				}
				vert_arrow_repeat_cnt++;
				return;
			}
			
			if (event.type == KeyBeacon.KEY_UP_+Keyboard.UP || event.type == KeyBeacon.KEY_UP_+Keyboard.DOWN) {
				focusOnInput(); // this works because in handleHistory, called on key down, we changes focus to stage
				vert_arrow_repeat_cnt = 0;
				return;
			}
			
			var txt:String = input_tf.text;
			if (txt) return;
			if (event.type == KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT || event.type == KeyBeacon.KEY_DOWN_+Keyboard.RIGHT
				|| event.type == KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT || event.type == KeyBeacon.KEY_DOWN_+Keyboard.LEFT) {
				onEscape(event);
			}
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focusOnInput():void {
			if (StageBeacon.stage.focus != input_tf) {
				StageBeacon.stage.focus = input_tf;
				input_tf.setSelection(input_tf.text.length, input_tf.text.length);
			}
			onRollOver();
			
			// Do this just to make sure it actually fires, in case the component focus changing code somehow keeps the FocusEvent.FOCUS_IN event from calling onInputFocus
			if (model.stateModel.focused_component != this) {
				onInputFocus();
			}
		}
		
		public function blurInput():void {
			if(StageBeacon.stage.focus != input_tf) return;
			StageBeacon.stage.focus = StageBeacon.stage;
			if (has_focus) TSFrontController.instance.releaseFocus(this, 'blurInput()');
			onRollOut();
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		override public function set width(value:Number):void {
			_w = value;
			draw();
		}
		
		override public function set height(value:Number):void {
			_h = value;
			draw();
		}
		
		public function get enabled():Boolean { return is_enabled; }
		public function set enabled(value:Boolean):void {
			if(has_focus && !value) blur();
			is_enabled = value;
			alpha = is_enabled ? 1 : .5;
			draw();
		}
		
		public function get text():String { 
			var final_txt:String = input_tf.text;
			
			if(display_txts){
				var i:int;
				var txt:String;
				var link_index:int;
				
				for(i; i < display_txts.length; i++){
					txt = display_txts[int(i)];
					link_index = final_txt.indexOf(txt);
					
					//make sure we still have it in our string
					if(link_index >= 0){						
						//alright, now replace this with the client link
						final_txt = RightSideManager.instance.createClientLink(final_txt, txt, client_links[int(i)]);
					}
				}
			}
			
			return final_txt;
		}
		
		public function set text(value:String):void {
			//check to see if we have client links in here
			input_tf.text = RightSideManager.instance.parseClientLink(value, this);
			
			//OVERRIDE FLASH'S BUILT IN ARROW KEY SHIT
			StageBeacon.waitForNextFrame(input_tf.setSelection, input_tf.text.length, input_tf.text.length);
			
			//clear out the display_txts if we are empty
			if(!value && display_txts){
				display_txts.length = 0;
				client_links.length = 0;
			}
		}
		
		public function setLinkText(display_txt:String, client_link:String, set_text:Boolean = true):void {
			if(set_text) text = input_tf.text + '['+display_txt+']';
			
			if(!display_txts){
				display_txts = new Array();
				client_links = new Array();
			}
			
			display_txts.push('['+display_txt+']');
			client_links.push(client_link+'|'+display_txt);
		}
		
		public function setSelection(start_index:int, end_index:int):void {
			//wait a sec and highlight the text (gets around the putting the carat at the end when setting text)
			StageBeacon.setTimeout(input_tf.setSelection, 40, start_index, end_index);
		}
		
		public function set restrict(str:String):void {
			input_tf.restrict = str;
		}
		
		/**
		 * Anytime the inputfield changes it will dispatch a changed event 
		 * @param value
		 */		
		public function set listen_for_changes(value:Boolean):void {
			if(value && !input_tf.hasEventListener(Event.CHANGE)){
				input_tf.addEventListener(Event.CHANGE, onInputChange, false, 0, true);
			}
			else if(!value && input_tf.hasEventListener(Event.CHANGE)){
				input_tf.removeEventListener(Event.CHANGE, onInputChange);
			}
		}
		
		private function onInputChange(event:Event):void {
			//let whoever is listening know!
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
			
			//clear out the display_txts if we are empty
			if(!input_tf.text && display_txts){
				display_txts.length = 0;
				client_links.length = 0;
			}
		}
	}
}