package com.tinyspeck.engine.port {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class ConfirmationDialog extends Dialog implements IMoveListener {
		
		/* singleton boilerplate */
		public static const instance:ConfirmationDialog = new ConfirmationDialog();
		
		private const ICON_WH:uint = 50;
		private const DEFAULT_WIDTH:uint = 450;
		
		public var uid:String; //allows a UID to be stored when dealing with prompts mostly
		
		private var Q:Vector.<ConfirmationDialogVO> = new Vector.<ConfirmationDialogVO>();
		private var title_tf:TextField = new TextField();
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var icon_view:ItemIconView;
		private var cdVO:ConfirmationDialogVO;
		private var buttonsV:Vector.<Button> = new Vector.<Button>();
		
		private var bt_sp:Sprite = new Sprite();
		private var graphic_holder:Sprite = new Sprite();
		
		private var current_choice_i:int;
		
		public function ConfirmationDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_close_bt_padd_right = 8;
			_close_bt_padd_top = 8;
			_base_padd = 20;
			_w = DEFAULT_WIDTH;
			_draggable = false;
			close_on_editing = false;
			close_on_move = false;
			_construct();
		}
		
		override protected function _construct() : void {
			super._construct();
			//title TF
			TFUtil.prepTF(title_tf, false);
			title_tf.y = _base_padd;
			title_tf.htmlText = '';
			addChild(title_tf);
			
			// body tf
			TFUtil.prepTF(body_tf, true/*, {textDecoration:'underline'}*/);
			body_tf.embedFonts = false;
			addChild(body_tf);
			
			addChild(bt_sp);
			bt_sp.addEventListener(MouseEvent.CLICK, clickHandler);
			bt_sp.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			bt_sp.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
			
			_close_bt.visible = false;
			_close_bt.disabled = true;
			TSFrontController.instance.registerMoveListener(this);
		}
		
		// IMoveListener funcs
		// -----------------------------------------------------------------
		
		public function moveLocationHasChanged():void {
		
		}
		
		public function moveLocationAssetsAreReady():void {
		
		}
		public function moveMoveStarted():void {
			this.visible = false;
		}
		
		public function moveMoveEnded():void {
			this.visible = true;
		}
		
		// -----------------------------------------------------------------
		// END IMoveListener funcs
		
		override protected function closeFromUserInput(e:Event=null):void {
			for (var i:int;i<cdVO.choices.length;i++) {
				if (cdVO.escape_value !== null) {
					CONFIG::debugging {
						Console.warn(cdVO.escape_value)
					}
					submitValue(cdVO.escape_value);
					return;
				}
			}
		}
		
		private function submitValue(value:*):void {
			if (!cdVO) return;
			
			StageBeacon.stage.focus = StageBeacon.stage;
			if (cdVO.callback != null) cdVO.callback(value);
			cdVO = null;
			end(true);
		}
		
		override public function end(release:Boolean):void {
			current_choice_i = -1;
			buttonsV.length = 0;
			cdVO = null;
			SpriteUtil.clean(bt_sp);
			super.end(release);
			
			if (Q.length) {
				StageBeacon.waitForNextFrame(startWithVO, Q.shift());
			}
		}
		
		public function startWithVO(vo:ConfirmationDialogVO):Boolean {
			//are we already showing this VO? If so bail.
			if(vo && cdVO == vo) return true;
			
			if (vo) {
				focus_details = vo.title+' '+vo.txt;
			} else {
				CONFIG::debugging {
					Console.warn('no vo')
				}
				return false;
			}
			
			if (!canStart(true)) {
				CONFIG::debugging {
					Console.warn('could not canStart');
				}
				return false
			}
			
			if (!vo) {
				CONFIG::debugging {
					Console.error('no vo passed');
				}
				return false;
			}
			
			if (cdVO) {
				CONFIG::debugging {
					Console.info('Qing CDVO');
				}
				Q.push(vo);
				TSFrontController.instance.getMainView().addView(this);
				return true;
			}
			
			cdVO = vo;
			start();
			return true;
		}
		
		override public function start():void {
			
			if (!cdVO) {
				CONFIG::debugging {
					Console.warn('no cdVO')
				}
				return;
			}
			
			if (!cdVO.choices || cdVO.choices.length == 0) {
				CONFIG::debugging {
					Console.error('no cdVO choices')
				}
				return;
			}
			
			if(!canStart(true)) return;
			
			//are we overriding the width?
			_w = cdVO.max_w > 0 ? cdVO.max_w : DEFAULT_WIDTH;
			
			title_tf.htmlText = '<p class="confirm_title">'+cdVO.title+'</p>';
			
			// escape key Should work?
			_close_bt.disabled = (cdVO.escape_value == null);
			
			SpriteUtil.clean(bt_sp);
			
			var bt:Button;
			for (var i:int;i<cdVO.choices.length;i++) {
				bt = new Button({
					label: cdVO.choices[int(i)].label,
					name: i+'',
					size: Button.SIZE_TINY,
					type: Button.TYPE_MINOR,
					disabled: cdVO.choices[int(i)].disabled_reason && cdVO.choices[int(i)].disabled_reason != '',
					tip: cdVO.choices[int(i)].disabled_reason && cdVO.choices[int(i)].disabled_reason != '' 
						? {txt:cdVO.choices[int(i)].disabled_reason, pointer:WindowBorder.POINTER_BOTTOM_CENTER}
						: null
				});
				bt_sp.addChild(bt);
				buttonsV.push(bt);
			}
			
			_setBodyContentsText(cdVO.txt);
			
			// destroy the old one if we need to
			if (icon_view && (cdVO.item_class != icon_view.tsid || cdVO.graphic)) {
				if (icon_view.parent) {
					icon_view.parent.removeChild(icon_view);
				}
				icon_view.dispose();
				icon_view = null;
			}
			
			/// make a new one if we need to 
			if (!icon_view && !cdVO.graphic) {
				var state:String = (cdVO.icon_state) ? cdVO.icon_state : (cdVO.item_class == 'pet_rock') ? 'idle' : null;
				icon_view = new ItemIconView(cdVO.item_class, ICON_WH, state);//, 'default', true);
			}
			
			//add the graphic to the holder
			if(cdVO.graphic){
				while(graphic_holder.numChildren) graphic_holder.removeChildAt(0);
				graphic_holder.addChild(cdVO.graphic);
			}
			else if(graphic_holder.parent){
				//make sure it's gone
				graphic_holder.parent.removeChild(graphic_holder);
			}
			
			if(icon_view){
				addChild(icon_view);
			}
			else if(cdVO.graphic){
				addChild(graphic_holder);
			}
			
			focusDefaultChoice();
			
			super.start();
		}
		
		override public function blur():void {
			
			super.blur();
		}
		
		override public function focus():void {
			
			super.focus();
		}
		
		private function _setBodyContentsText(txt:String):void {
			body_tf.htmlText = '<p class="confirm">'+txt+'</p>';

			_jigger();
		}
		
		override protected function _jigger():void {
			
			title_tf.x = ICON_WH+(_base_padd*2);
			
			body_tf.width = _w-body_tf.x-_base_padd;
			body_tf.x = ICON_WH+(_base_padd*2);
			body_tf.y = title_tf.y + title_tf.height;
			
			bt_sp.y = body_tf.y+body_tf.height+_base_padd;
			
			var start_x:int = _w;
			var bt:Button;
			for (var i:int=bt_sp.numChildren-1;i>=0;i--) {
				start_x = (bt) ? start_x - 10 : start_x-_base_padd;
				bt = bt_sp.getChildAt(i) as Button;
				start_x = bt.x = start_x-bt.width;
			}
			
			_h = (_base_padd)+bt_sp.y+bt_sp.height;
			_h = Math.max(_h, (_base_padd*2)+ICON_WH);
			
			super._jigger();
			if (icon_view) {
				icon_view.x = _base_padd;
				icon_view.y = _base_padd;
			}
			else if(graphic_holder.parent){
				graphic_holder.x = _base_padd;
				graphic_holder.y = _base_padd;
			}
			_draw();
		}
		
		
		
		
		
		
		private function getDefaultChoiceIndex():int {
			return buttonsV.length-1;
		}
		
		override protected function upArrowKeyHandler(e:KeyboardEvent):void {
			
		}
		
		override protected function rightArrowKeyHandler(e:KeyboardEvent):void {
			focusNextChoice()	
		}
		
		override protected function downArrowKeyHandler(e:KeyboardEvent):void {
			
		}
		
		override protected function leftArrowKeyHandler(e:KeyboardEvent):void {
			focusPrevChoice();
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			if (!buttonsV.length) return;
			makeChoice();
		}
		
		private function mouseOverHandler(e:Event):void {
			if (e.target is Button) {
				focusChoice(getIndexOfButton(e.target as Button));
			}
		}
		
		private function clickHandler(e:Event):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			if (e.target is Button) {
				focusChoice(getIndexOfButton(e.target as Button));
				makeChoice(true);
			}
		}
		
		private function mouseOutHandler(e:Event):void {
			if (e.target is Button) {
				focusChoice(current_choice_i);
			}
		}
		
		private function makeChoice(by_click:Boolean = false):void {
			if (current_choice_i < 0 || current_choice_i > buttonsV.length-1) return;
			onButtonChosen(buttonsV[current_choice_i]);
		}
		
		private function onButtonChosen(bt:Button):void {
			if(bt && !bt.disabled){
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				submitValue(cdVO.choices[parseInt(bt.name)].value);
			} else {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		private function getIndexOfButton(bt:Button):int {
			return buttonsV.indexOf(bt);
		}
		
		private function getButtonAtIndex(i:int):Button {
			if (i<0 || i>buttonsV.length-1) {
				CONFIG::debugging {
					Console.error('i out of range:'+i+' '+(buttonsV.length-1));
				}
				return null;
			}
			return buttonsV[int(i)];
		}
		
		//------------------------------------------------------------
		// CHOICE BUTTON FOCUS METHODS
		
		private function focusDefaultChoice():void {
			focusChoice(getDefaultChoiceIndex());
		}
		
		private function focusChoice(i:int):void {
			if (current_choice_i != i) {
				if (current_choice_i != -1) getButtonAtIndex(current_choice_i).blur();
				current_choice_i = i;
			}
			
			if (getButtonAtIndex(i)) {
				getButtonAtIndex(i).focus();
				updateAfterButtonFocus();
			}
		}
		
		private function updateAfterButtonFocus():void {
			
		}
		
		private function focusNextChoice():void {
			if (!buttonsV.length) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (current_choice_i+1 >= buttonsV.length) {
				focusChoice(0);
			} else {
				focusChoice(current_choice_i+1);
			}
		}
		
		private function focusPrevChoice():void {
			if (!buttonsV.length) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (current_choice_i-1 < 0) {
				focusChoice(buttonsV.length-1);
			} else {
				focusChoice(current_choice_i-1);
			}
		}
		
		// END CHOICE BUTTON FOCUS METHODS
		//------------------------------------------------------------
		
		
	}
}