package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.net.NetOutgoingInputResponseVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	public class InputDialog extends BigDialog implements IFocusableComponent {
		
		/* singleton boilerplate */
		public static const instance:InputDialog = new InputDialog();
		
		private var Q:Array = [];
		private var payload:Object;
		private var body_sp:Sprite = new Sprite();
		private var foot_sp:Sprite = new Sprite();
		private var submit_bt:Button;
		private var cancel_bt:Button;
		private var input_tf:TextField = new TextField();
		private var desc_tf:TSLinkedTextField = new TSLinkedTextField();
		private var label_tf:TSLinkedTextField = new TSLinkedTextField();
		private const DEFAULT_INPUT_TEXT_SIZE:int = 40;
		private const DEFAULT_INPUT_LINE_HEIGHT:int = 50;
		
		private const SMALL_INPUT_TEXT_SIZE:int = 12;
		private const SMALL_INPUT_LINE_HEIGHT:int = 16;
		private  var newFormat:TextFormat = new TextFormat();
		
		public function InputDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 500;
			_draggable = true;
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			
			prepTextField(label_tf);
			label_tf.multiline = true;
			body_sp.addChild(label_tf);
			
			prepTextField(desc_tf);
			desc_tf.multiline = false;
			body_sp.addChild(desc_tf);
			
			newFormat.color = 0x191919;
			newFormat.size = DEFAULT_INPUT_TEXT_SIZE;
			newFormat.bold = false;
			newFormat.font = 'HelveticaEmbed';
			newFormat.leftMargin = newFormat.rightMargin = 4;
			newFormat.kerning = true;
			
			input_tf.embedFonts = true;
			input_tf.antiAliasType = AntiAliasType.ADVANCED;
			input_tf.type = TextFieldType.INPUT;
			input_tf.selectable = true;
			input_tf.multiline = false;
			input_tf.wordWrap = true;
			input_tf.backgroundColor = 0xffffff;
			input_tf.background = true;
			input_tf.border = true;
			input_tf.borderColor = 0x000000;
			input_tf.name = '_input_tf';
			input_tf.height = DEFAULT_INPUT_LINE_HEIGHT;
			//_input_tf.text = 'test test test test test ';
			input_tf.defaultTextFormat = newFormat;
			body_sp.addChild(input_tf);
			
			submit_bt = new Button({
				label: '',
				name: 'submit_bt',
				value: 'submit',
				y: 15,
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			
			submit_bt.addEventListener(MouseEvent.CLICK, onSubmitClick, false, 0, true);
			
			foot_sp.addChild(submit_bt);
			
			cancel_bt = new Button({
				label: '',
				name: 'cancel_bt',
				value: 'cancel',
				y: 15,
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			
			cancel_bt.addEventListener(MouseEvent.CLICK, onCancelClick, false, 0, true);
				
			foot_sp.addChild(cancel_bt);
		}
		
		public function get request_uid():String {
			if (payload) {
				return payload.uid;
			}
			
			return null;
		}
		
		private function sendCancel():void {
			TSFrontController.instance.genericSend(
				new NetOutgoingInputResponseVO(payload.uid, '', payload.itemstack_tsid || '')
			);
		}
		
		override protected function closeFromUserInput(e:Event=null):void {
			if (payload.cancelable === false) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			sendCancel();
			super.closeFromUserInput(e);
		}
		
		private function onCancelClick(event:MouseEvent):void {
			closeFromUserInput(event);
		}
		
		private function submit(val:String):void {
			if (!val) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			// if it has a handler, then let it handle it. otherwise, assme it is an input request from the GS and sendit back
			if (payload.handler is Function && payload.handler != null) {
				payload.handler(payload, val);
			} else {
				TSFrontController.instance.genericSend(
					new NetOutgoingInputResponseVO(payload.uid, val, payload.itemstack_tsid || '')
				);
			}
			
			end(true);
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		private function onSubmitClick(event:MouseEvent):void {
			submit(input_tf.text);
		}
		
		private function prepTextField(tf:TextField):void {
			tf.embedFonts = true;
			tf.selectable = false;
			tf.styleSheet = CSSManager.instance.styleSheet;
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.border = false;
			tf.borderColor = 0x000000;
			tf.wordWrap = true;
		}
		
		public function startWithPayload(payload:Object):void {
			if (parent || Q.length) {
				Q.push(payload);
				return;
			}
			this.payload = payload;
			start();
		}
		
		public function cancelUID(uid:String):void {
			// remove it if it is in the Q
			for (var i:int=0;i<Q.length;i++) {
				if (Q[i].uid && Q[i].uid == uid) {
					Q.splice(i, 1);
				}
			}
			
			// if this is the current one, end it
			if (payload && payload.uid && payload.uid == uid) {
				sendCancel();
				end(true);
			}
		}
		
		private var multiline:Boolean = false;
		override public function start():void {
			if (parent) return;
			if (!canStart(false)) return;
			if (!payload) return;
			
			/* THIS DOES NOT TAKE FOCUS
			if (!TSFrontController.instance.requestFocus(this)) {
			Console.warn('could not take focus');
			return;
			}*/
			
			_close_bt.disabled = (payload.cancelable === false);
			_close_bt.visible = !_close_bt.disabled;
			
			
			var padd:int = 15;
			var tf_w:int = _w-(6)-(padd*2);
			var next_y:int = padd;
			
			desc_tf.width = tf_w;
			desc_tf.x = padd;
			desc_tf.y = next_y;
			desc_tf.visible = Boolean(payload.input_description);
			desc_tf.htmlText = '<p class="shrine_intro">'+payload.input_description+'</p>';
			next_y = (desc_tf.visible) ? desc_tf.y+desc_tf.height+10 : desc_tf.y;
			
			label_tf.width = tf_w;
			label_tf.x = padd;
			label_tf.y = next_y;
			label_tf.visible = Boolean(payload.input_label);
			label_tf.htmlText = '<p class="shrine_intro"><b>'+payload.input_label+'</b></p>';
			next_y = (label_tf.visible) ? label_tf.y+label_tf.height : label_tf.y;
			
			var line_height:int;
			var max_rows:int;
			if (payload.input_text_size == 'small') {
				newFormat.size = SMALL_INPUT_TEXT_SIZE;
				line_height = SMALL_INPUT_LINE_HEIGHT;
				max_rows = 17;
			} else {
				newFormat.size = DEFAULT_INPUT_TEXT_SIZE;
				line_height = DEFAULT_INPUT_LINE_HEIGHT;
				max_rows = 5;
			}
			
			if (parseInt(payload.input_rows) > 1) {
				multiline = input_tf.multiline = true;
				input_tf.height = line_height*Math.min(payload.input_rows, max_rows);
			} else {
				multiline = input_tf.multiline = false;
				input_tf.height = line_height;
			}
			
			input_tf.defaultTextFormat = newFormat;
			
			input_tf.width = tf_w;
			input_tf.x = padd;
			input_tf.y = next_y;
			input_tf.restrict = payload.input_restrict || null;
			input_tf.maxChars = payload.input_max_chars || 0;
			input_tf.text = payload.input_value || '';
			input_tf.addEventListener(FocusEvent.FOCUS_IN, inputFocusHandler);
			input_tf.addEventListener(FocusEvent.FOCUS_OUT, inputBlurHandler);
			
			if (payload.check_user_name) {
				input_tf.addEventListener(Event.CHANGE, onInputChange, false, 0, true);
			} else {
				input_tf.removeEventListener(Event.CHANGE, onInputChange);
			}
			
			if (input_tf.text || payload.input_focus) {
				focusOnInput();
			}
			
			var g:Graphics;
			g = body_sp.graphics;
			g.clear();
			g.beginFill(0xcc0000, 0);
			g.drawRect(0, 0, _w, input_tf.y+input_tf.height+padd);
			g.endFill();
			
			g = foot_sp.graphics;
			g.clear();
			g.beginFill(0x00cc00, 0);
			g.drawRect(0, 0, _w, 54);
			g.endFill();
			
			submit_bt.label = payload.submit_label || 'Submit';
			submit_bt.x = _w - submit_bt.width - 10;
			cancel_bt.label = payload.cancel_label || 'Cancel';
			cancel_bt.x = submit_bt.x - cancel_bt.width - 10;
			cancel_bt.visible = (payload.cancelable !== false);
			submit_bt.y = cancel_bt.y = Math.round((50 - cancel_bt.height)/2);
			
			_setTitle(payload.title || 'No title provided');
			_setSubtitle(payload.subtitle || '');
			_setBodyContents(body_sp);
			_setFootContents(foot_sp);

			_jigger();
			_draw();
			_place();
			
			TSFrontController.instance.getMainView().addView(this);
			
			transitioning = true;
			scaleX = scaleY = .02;
			var pt:Point = YouDisplayManager.instance.getHeaderCenterPt();
			x = pt.x;
			y = pt.y;
			var self:InputDialog = this;
			TSTweener.removeTweens(self);
			TSTweener.addTween(self, {y:dest_y, x:dest_x, scaleX:1, scaleY:1, time:.3, transition:'easeInCubic', onComplete:function():void{
				self.transitioning = false;
				self._place();
			}});
			
		}
		
		protected function onInputChange(event:Event = null):void {			
			const input_txt:String = input_tf.text;
		}
		
		private function inputFocusHandler(e:FocusEvent = null):void {
			if (!has_focus) {
				if (!TSFrontController.instance.requestFocus(this)) {
					CONFIG::debugging {
						Console.warn('could not take focus');
					}
					// you cannot blur an input during the hanlder for its focusing
					StageBeacon.waitForNextFrame(_blurInput);
					return;
				}
			}
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, inputEnterKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.TAB, inputTabKeyHandler);
			input_tf.backgroundColor = 0xf5f5ce;
			refresh();
		}
		
		private function inputEnterKeyHandler(e:KeyboardEvent):void {
			if (multiline) return;
			submit(input_tf.text);
		}
		
		private function inputTabKeyHandler(e:KeyboardEvent):void {
			// maybe put focus on buttons here. not sure. this thing does not take focus unless focus is in input, so it does not steal kb focus from tsmainview until you start interacting with it
		}
		
		private function inputBlurHandler(e:Event):void {
			if (has_focus) {
				TSFrontController.instance.releaseFocus(this);
			}
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, inputEnterKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.TAB, inputTabKeyHandler);
			input_tf.backgroundColor = 0xffffff;
		}
		
		private function _blurInput(e:Event = null):void {
			if (StageBeacon.stage.focus != input_tf) return;
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		public function focusOnInput():void {
			if (StageBeacon.stage.focus == input_tf) return;
			StageBeacon.stage.focus = input_tf;
			input_tf.setSelection(0, input_tf.text.length);
		}
		
		override public function end(release:Boolean):void {
			payload = null;
			if (release && !transitioning) {
				transitioning = true;
				var self:InputDialog = this;
				TSTweener.removeTweens(self);
				var pt:Point = YouDisplayManager.instance.getHeaderCenterPt();
				TSTweener.addTween(self, {y:pt.y, x:pt.x, scaleX:.02, scaleY:.02, time:.3, transition:'easeOutCubic', onComplete:function():void{
					self.end(true);
					self.scaleX = self.scaleY = 1;
					self.transitioning = false;
					// get rid of these, so the next opening is in the middle of the screen again
					self.last_x = NaN;
					self.last_y = NaN;
					//onInvalidate();
				}});
			} else {
				_setGraphicContents(null);
				_setFootContents(null);
				_setBodyContents(null);
				_setSubtitle('');
				
				if (parent) parent.removeChild(this);
				if (release) TSFrontController.instance.releaseFocus(this);
				
				if (Q.length) {
					StageBeacon.waitForNextFrame(function():void {
						if (!Q.length) return;
						payload = Q.shift();
						start();
					});
				}
			}
		}
	}
}