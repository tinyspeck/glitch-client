package com.tinyspeck.engine.view
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.port.ChassisManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.chat.InputField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class TowerNameUI extends TSSpriteWithModel
	{
		private static const WIDTH:uint = 615;
		private static const HEIGHT:uint = 122;
		private static const PADD:uint = 18;
		private static const MAX_CHARS:uint = 25;
		private static const RESTRICT_CHARS:String = ' A-Z0-9\'"&$!@#~()+\\-?_./\\\\'; //lol @ needing 4 backslashes to allow backslash
		private static const INPUT_H:uint = 32;
		
		public var input_field:InputField = new InputField(false, true, MAX_CHARS);
		private var revert_bt:Button;
		private var save_bt:Button;
		
		private var bg_holder:Sprite = new Sprite();
		private var edit_holder:Sprite = new Sprite();
		
		private var name_tf:TextField = new TextField();
		private var chars_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		private var show_save_bt:Boolean;
		private var dm:DecorateModel;
		private var picker_ui:ChassisPickerUI;
		
		public function TowerNameUI(){
			super();
			dm = model.decorateModel;
			show_save_bt = model.flashVarModel.more_towers;
		}
		
		private function buildBase():void {
			var g:Graphics = bg_holder.graphics;
			g.clear();
			g.beginFill(0xd8e0e2);
			g.drawRoundRect(0, 0, WIDTH, HEIGHT, 10);
			bg_holder.filters = StaticFilters.copyFilterArrayFromObject({blurX:2}, StaticFilters.black3px90DegreesInner_DropShadowA);
			addChild(bg_holder);
			
			//label
			TFUtil.prepTF(name_tf, false);
			name_tf.htmlText = '<p class="tower_name">Your tower name:</p>';
			name_tf.x = PADD;
			name_tf.y = PADD - 4;
			bg_holder.addChild(name_tf);
			
			//input
			input_field.addEventListener(KeyBeacon.KEY_DOWN_, onKeyDown, false, 0, true);
			TFUtil.setTextFormatFromStyle(input_field.input_tf, 'tower_name_input');
			input_field.input_tf.restrict = RESTRICT_CHARS;
			input_field.input_tf.embedFonts = true;
			input_field.input_tf.height = input_field.input_tf.textHeight + 4;
			input_field.x = PADD;
			input_field.y = int(name_tf.y + name_tf.height + 4);
			input_field.width = WIDTH - PADD*2;
			input_field.height = INPUT_H;
			input_field.input_tf.y += 2; //visual tweak
			input_field.addEventListener(TSEvent.FOCUS_IN, onInputFocus, false, 0, true);
			input_field.addEventListener(TSEvent.FOCUS_OUT, onInputFocus, false, 0, true);
			input_field.addEventListener(TSEvent.CHANGED, updateCharCount, false, 0, true);
			bg_holder.addChild(input_field);
			
			//editing
			TFUtil.prepTF(chars_tf, false);
			chars_tf.x = PADD;
			chars_tf.y = 6;
			edit_holder.addChild(chars_tf);
			
			save_bt = new Button({
				name: 'save',
				label: 'Save tower name',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			save_bt.x = int(WIDTH - PADD - save_bt.width);
			save_bt.addEventListener(TSEvent.CHANGED, onSaveClick, false, 0, true);
			
			revert_bt = new Button({
				name: 'revert',
				label: show_save_bt?'cancel':'Revert Name',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR_INVIS
			});
			
			if (show_save_bt) {
				edit_holder.addChild(save_bt);
				revert_bt.x = int(save_bt.x - revert_bt.width - 7);
			} else {
				revert_bt.x = int(WIDTH - PADD - revert_bt.width);
			}
			
			revert_bt.addEventListener(TSEvent.CHANGED, onRevertClick, false, 0, true);
			edit_holder.addChild(revert_bt);			
			
			edit_holder.y = int(input_field.y + input_field.height + 6);
			bg_holder.addChild(edit_holder);
			
			is_built = true;
		}
		
		private function onKeyDown(event:KeyboardEvent):void {
			//did they mash enter?
			if(event.keyCode == Keyboard.ENTER && !event.ctrlKey){
				input_field.blurInput();
				if (model.flashVarModel.more_towers) {
					ChassisManager.instance.doneWithNaming();
				}
			}
		}
		
		public function show(picker_ui:ChassisPickerUI, and_focus:Boolean=false):void {
			this.picker_ui = picker_ui;
			if(!is_built) buildBase();
			
			//reset
			if (!model.flashVarModel.more_towers) {
				edit_holder.visible = false;
			}
			save_bt.disabled = false;
			revert_bt.disabled = false;
			input_field.enabled = true;
			visible = true;
			
			//set the input to be the current name
			if (!dm.has_name_changed) setInputValue(dm.was_name);
			
			if (and_focus) {
				input_field.focusOnInput();
			}
			
			//update
			updateCharCount();
		}
		
		public function hide():void {
			visible = false;
			
			//this forces a refresh so that the pack width is proper
			TSFrontController.instance.getMainView().refreshViews();
		}
		
		private function setInputValue(val:String):void {
			input_field.text = val;
			ChassisManager.instance.updateTowerSign(input_field.text);
		}
		
		private function updateCharCount(event:Event = null):void {
			const remaining:int = MAX_CHARS - input_field.text.length;
			const remain_txt:String = remaining >= 0 ? remaining.toString() : '<span class="tower_name_too_many">'+remaining+'</span>';
			chars_tf.htmlText = '<p class="tower_name"><span class="tower_name_chars">Characters remaining: <b>'+remain_txt+'</b></span></p>';
			
			save_bt.disabled = remaining < 0;

			ChassisManager.instance.updateTowerSign(input_field.text);
			
			dm.has_name_changed = (dm.was_name != input_field.text);
			picker_ui.setButtonToCorrectState();
		}
		
		private function onSaveClick(event:TSEvent):void {
			SoundMaster.instance.playSound(save_bt.disabled ? 'CLICK_FAILURE' : 'CLICK_SUCCESS');
			if(save_bt.disabled) return;
			save_bt.disabled = true;
			revert_bt.disabled = true;
			input_field.enabled = false;
			
			if (model.flashVarModel.more_towers) {
				ChassisManager.instance.doneWithNaming();
			}
		}
		
		public function revert():void {
			setInputValue(dm.was_name);
			
			dm.has_name_changed = false;
			picker_ui.setButtonToCorrectState();
			
			if (model.flashVarModel.more_towers) {
				ChassisManager.instance.doneWithNaming();
			} else {
				edit_holder.visible = false;
			}
		}
		
		private function onRevertClick(event:TSEvent):void {
			SoundMaster.instance.playSound(revert_bt.disabled ? 'CLICK_FAILURE' : 'CLICK_SUCCESS');
			if(revert_bt.disabled) return;
			revert();
		}
		
		private function onInputFocus(event:TSEvent):void {
			if (model.flashVarModel.more_towers) return; 
			//figure out if we need to show/hide the edit controls
			//NOTE right now this is also detecting a focus OUT event, so if the text is the same
			//and they click save, it just hides and doesn't dispatch the onSaveClick since it's the same thing
			const in_focus:Boolean = event.type == TSEvent.FOCUS_IN;
			edit_holder.visible = in_focus || (!in_focus && input_field.text != dm.was_name);
		}
	}
}