package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.LocationSelectorDialog;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.chat.InputField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class ElevatorLabelUI extends Sprite
	{
		private static const INPUT_H:uint = 26;
		private static const LABEL_HOVER_ALPHA:Number = .1;
		private static const LABEL_MAX_CHARS:uint = 30;
		private static const TEXT_X:uint = 10;
		
		private var edit_holder:Sprite = new Sprite();
		private var label_holder:Sprite = new Sprite();
		
		private var label_tf:TextField = new TextField();
		
		private var input:InputField = new InputField(false, false, LABEL_MAX_CHARS);
		private var ok_bt:Button;
		private var close_bt:Button;
		
		private var connect_id:String;
		private var default_text:String;
		private var current_text:String;
		
		private var _w:int;
		
		private var is_built:Boolean;
		private var _enabled:Boolean;
		
		public function ElevatorLabelUI(){}
		
		private function buildBase():void {
			//edit
			input.height = INPUT_H;
			input.x = TEXT_X;
			input.restrict = '\u0020-\u007E';
			input.addEventListener(KeyBeacon.KEY_DOWN_, onInputKey, false, 0, true);
			input.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onCloseClick, false, 0, true);
			edit_holder.addChild(input);
			
			ok_bt = new Button({
				name: 'ok',
				label: 'OK',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				h: INPUT_H + 2
			});
			ok_bt.addEventListener(TSEvent.CHANGED, onOkClick, false, 0, true);
			ok_bt.y = -1;
			edit_holder.addChild(ok_bt);
			
			const close_DO:DisplayObject = new AssetManager.instance.assets.chat_close();
			close_DO.transform.colorTransform = ColorUtil.getColorTransform(0xffffff);
			close_DO.alpha = .7;
			close_bt = new Button({
				name: 'close',
				graphic: close_DO,
				w: close_DO.width,
				h: close_DO.height,
				draw_alpha: 0
			});
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			close_bt.y = int(INPUT_H/2 - close_bt.height/2);
			edit_holder.addChild(close_bt);
			
			edit_holder.visible = false;
			addChild(edit_holder);
			
			//label
			TFUtil.prepTF(label_tf);
			label_tf.filters = StaticFilters.black1px270Degrees_DropShadowA;
			label_tf.x = TEXT_X;
			label_holder.addChild(label_tf);
			label_holder.mouseChildren = false;
			addChild(label_holder);
			
			is_built = true;
		}
		
		public function show(connect_id:String, default_text:String, current_text:String):void {
			if(!is_built) buildBase();
			
			this.connect_id = connect_id;
			this.default_text = default_text;
			this.current_text = current_text ? decodeURIComponent(current_text) : null;
			
			//reset
			label_holder.visible = true;
			edit_holder.visible = false;
			
			setText();
			
			draw();
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		private function setText():void {
			var label_txt:String = StringUtil.encodeHTMLUnsafeChars(current_text || default_text);
			const vag_ok:Boolean = StringUtil.VagCanRender(label_txt);
			label_tf.embedFonts = vag_ok;
			if(!vag_ok){
				//show it as arial
				label_txt = '<span class="elevator_label_no_embed">'+label_txt+'</span>';
			}
			label_tf.htmlText = '<p class="elevator_label">'+label_txt+'</p>';
		}
		
		private function draw():void {
			if(!is_built) return;
			
			close_bt.x = _w - close_bt.width;
			ok_bt.x = close_bt.x - ok_bt.width - 6;
			input.width = ok_bt.x - input.x - 3;
			
			//set the label width
			const label_w:int = _w - label_tf.x*2;
			label_tf.width = label_w;
			label_tf.y = Math.max(1, int(INPUT_H/2 - label_tf.height/2));
			onLabelMouse();
		}
		
		private function onLabelMouse(event:MouseEvent = null):void {
			const is_over:Boolean = event && event.type == MouseEvent.ROLL_OVER;
			
			//draw the background
			const draw_h:int = Math.max(INPUT_H, int(label_tf.height + 1));
			const g:Graphics = label_holder.graphics;
			g.clear();
			g.beginFill(0xffffff, is_over ? LABEL_HOVER_ALPHA : 0);
			g.drawRoundRect(0, 0, _w, draw_h, 10);
			
			//make sure the edit holder is in the right place
			edit_holder.y = int(draw_h/2 - edit_holder.height/2);
		}
		
		private function onLabelClick(event:MouseEvent):void {
			//hide the label, and show the editing thingie
			label_holder.visible = false;
			edit_holder.visible = true;
			input.text = current_text || default_text;
			input.enabled = true;
			input.setSelection(0, input.text.length);
			TSFrontController.instance.requestFocus(input, 'Elevator label wants focus');
			ok_bt.disabled = false;
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');			
			
			//hide the other ones
			LocationSelectorDialog.instance.showFloorEditor(connect_id);
		}
		
		public function onCloseClick(event:Event = null):void {
			//hide the editor
			label_holder.visible = true;
			edit_holder.visible = false;
			
			//release the focus if we need to
			if(input.hasFocus()) TSFrontController.instance.releaseFocus(input, 'Elevator label dropping focus');
			
			if(event) SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function onOkClick(event:Event):void {
			SoundMaster.instance.playSound(ok_bt.disabled ? 'CLICK_FAILURE' : 'CLICK_SUCCESS');
			if(ok_bt.disabled) return;
			if(input.text != current_text || !input.text){
				ok_bt.disabled = true;
				
				//release the focus if we need to
				if(input.hasFocus()) TSFrontController.instance.releaseFocus(input, 'Elevator label dropping focus');
				input.enabled = false;
				
				//submit the new label to the server
				LocationSelectorDialog.instance.setFloorName(connect_id, encodeURIComponent((input.text || default_text)));
			}
			else {
				//nothing changed, just close it
				onCloseClick();
			}
		}
		
		private function onInputKey(event:KeyboardEvent):void {
			if(event.keyCode == Keyboard.ENTER){
				onOkClick(event);
			}
		}
		
		override public function set width(value:Number):void {
			_w = value;
			draw();
		}
		
		public function get id():String { return connect_id; }
		
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void {
			_enabled = value;
			draw();
			
			//handle the mouse stuff
			label_holder.buttonMode = label_holder.useHandCursor = value;
			if(value && !label_holder.hasEventListener(MouseEvent.ROLL_OVER)){
				label_holder.addEventListener(MouseEvent.ROLL_OVER, onLabelMouse, false, 0, true);
				label_holder.addEventListener(MouseEvent.ROLL_OUT, onLabelMouse, false, 0, true);
				label_holder.addEventListener(MouseEvent.CLICK, onLabelClick, false, 0, true);
			}
			else if(!value && label_holder.hasEventListener(MouseEvent.ROLL_OVER)){
				label_holder.removeEventListener(MouseEvent.ROLL_OVER, onLabelMouse);
				label_holder.removeEventListener(MouseEvent.ROLL_OUT, onLabelMouse);
				label_holder.removeEventListener(MouseEvent.CLICK, onLabelClick);
			}
		}
	}
}