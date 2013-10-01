package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	public class InputFieldSubmit extends TSSpriteWithModel implements IFocusableComponent
	{
		//this is in other things with TFs that take focus, so throwing this here cause I bet it makes Eric happy
		public static function getInputTalkBubbleParentOfTF(tf:TextField):InputFieldSubmit {
			if (!tf) return null;
			var p:DisplayObjectContainer = tf.parent;
			while (p) {
				if (p is InputFieldSubmit) return p as InputFieldSubmit;
				p = p.parent;
			}
			return null;
		}
		
		private static const MIN_PADD:uint = 12;
		
		private var input_tf:TextField = new TextField();
		
		private var all_holder:Sprite = new Sprite();
		private var input_holder:Sprite = new Sprite();
		
		private var submit_bt:Button;
		private var cancel_bt:Button;
		
		private var is_built:Boolean;
		private var has_focus:Boolean;
		
		public function InputFieldSubmit(){
			registerSelfAsFocusableComponent();
			buildBase();
		}
		
		public function set maxChars(val:int):void {
			input_tf.maxChars = val;
		}
		
		private function buildBase():void {
			//input TF			
			TFUtil.prepTF(input_tf, false);
			TFUtil.setTextFormatFromStyle(input_tf, 'input_field_submit');
			input_tf.embedFonts = false;
			input_tf.mouseEnabled = true;
			input_tf.selectable = true;
			input_tf.autoSize = TextFieldAutoSize.NONE;
			input_tf.type = TextFieldType.INPUT;
			input_tf.text = 'placeholder';
			input_tf.height = input_tf.textHeight + 4;
			input_tf.x = 4;
			input_holder.addChild(input_tf);
			
			var input_filtersA:Array = StaticFilters.copyFilterArrayFromObject({color:0xd5d6b6, inner:true}, StaticFilters.black_GlowA);
			input_filtersA = input_filtersA.concat(
				StaticFilters.copyFilterArrayFromObject({blurY:4, distance:2, alpha:.15}, StaticFilters.black3px90DegreesInner_DropShadowA)
			);
			input_holder.filters = input_filtersA;
			input_holder.x = MIN_PADD;
			all_holder.addChild(input_holder);
			
			//submit bt
			submit_bt = new Button({
				name: 'accept',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_INPUT_ACCEPT,
				w: 37,
				graphic: new AssetManager.instance.assets.input_check(),
				graphic_disabled: new AssetManager.instance.assets.input_check_disabled(),
				graphic_hover: new AssetManager.instance.assets.input_check_hover()
			});
			submit_bt.addEventListener(TSEvent.CHANGED, onSubmitClick, false, 0, true);
			all_holder.addChild(submit_bt);
			
			//cancel bt
			cancel_bt = new Button({
				name: 'close',
				graphic: new AssetManager.instance.assets.close_x_small(),
				graphic_placement: 'center',
				draw_alpha: 0,
				w: 13
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, onCancelClick, false, 0, true);
			all_holder.addChild(cancel_bt);
			
			all_holder.filters = StaticFilters.copyFilterArrayFromObject({blurX:12, blurY:12, alpha:.1}, StaticFilters.black_GlowA);
			addChild(all_holder);
			
			is_built = true;
		}
		
		public function show(str:String = null):void {
			if(!TSFrontController.instance.requestFocus(this)) {
				CONFIG::debugging {
					Console.warn('could not take focus');
				}
				return;
			}
			
			input_tf.text = str || '';
			if(input_tf.text){
				StageBeacon.waitForNextFrame(focusOnInput);
			}
			draw();
		}
		
		public function hide():void {
			TSFrontController.instance.releaseFocus(this);
			if(parent) parent.removeChild(this);
		}
		
		private function draw():void {
			const input_w:int = width - MIN_PADD*2 - submit_bt.width - cancel_bt.width;
			const input_h:int = height - MIN_PADD*2;
			
			//all holder
			var g:Graphics = all_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, width, height, 10);
			
			//input bg
			input_holder.y = int(height/2 - input_h/2);
			g = input_holder.graphics;
			g.clear();
			g.beginFill(0xf5f5ce);
			g.drawRoundRectComplex(0, 0, input_w, input_h, 4, 0, 4, 0);
			
			input_tf.width = int(input_w - input_tf.x*2);
			input_tf.y = int(input_holder.height/2 - input_tf.height/2) + 1;
			
			submit_bt.x = int(input_holder.x + input_holder.width - 2);
			submit_bt.y = input_holder.y - 1;
			submit_bt.h = input_h + 1;
			
			cancel_bt.x = int(submit_bt.x + submit_bt.width + 6);
			cancel_bt.y = input_holder.y;
			cancel_bt.h = input_h;
		}
		
		private function onSubmitClick(event:Event = null):void {
			if(submit_bt.disabled) return;
			dispatchEvent(new TSEvent(TSEvent.CHANGED, text));
		}
		
		private function onCancelClick(event:Event = null):void {
			hide();
			dispatchEvent(new TSEvent(TSEvent.CLOSE));
		}
		
		public function get text():String { return input_tf.text; }
		
		override public function get width():Number { return _w; }
		override public function set width(value:Number):void {
			_w = value;
			draw();
		}
		
		override public function get height():Number { return _h; }
		override public function set height(value:Number):void {
			_h = value;
			draw();
		}
		
		/*****************************
		 * Focus things
		 ****************************/
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onCancelClick, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onSubmitClick, false, 0, true);
			
			if(input_tf.text){
				StageBeacon.waitForNextFrame(focusOnInput);
			}
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			has_focus = false;
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onCancelClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onSubmitClick);
			blurInput();
			
			/*
			maybe??
			if (!input_tf.text) {
			end();
			}
			*/
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focusOnInput():void {
			if (!has_focus) return;
			if (StageBeacon.stage.focus == input_tf) return;
			StageBeacon.stage.focus = input_tf;
			input_tf.setSelection(0, input_tf.text.length);
			//why this no work sometimes? the log below shows the input is focused, but cursor not there and typing no types
			//Console.warn(StageBeacon.stage.focus == input_tf)
		}
		
		private function blurInput(e:Event = null):void {
			if (StageBeacon.stage.focus != input_tf) return;
			StageBeacon.stage.focus = StageBeacon.stage;
		}
	}
}