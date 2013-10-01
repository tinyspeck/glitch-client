package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.input.InputRequest;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingInputResponseVO;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.itemstack.PackItemstackView;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	public class InputTalkBubble extends Sprite implements IFocusableComponent
	{
		/* singleton boilerplate */
		public static const instance:InputTalkBubble = new InputTalkBubble();
		
		public static function getInputTalkBubbleParentOfTF(tf:TextField):InputTalkBubble {
			if (!tf) return null;
			var p:DisplayObjectContainer = tf.parent;
			while (p) {
				if (p is InputTalkBubble) return p as InputTalkBubble;
				p = p.parent;
			}
			return null;
		}
		
		private var chat_bubble:ChatBubble;
		private var current_request:InputRequest;
		private var model:TSModelLocator;
		private var main_view:TSMainView;
		private var submit_bt:Button;
		private var cancel_bt:Button;
		
		private var itemstack_pt:Point = new Point();
		
		private var all_holder:Sprite = new Sprite();
		private var input_holder:Sprite = new Sprite();
		
		private var input_tf:TextField = new TextField();
		private var currants_symbol_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		private var has_focus:Boolean;
		
		public function InputTalkBubble(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			main_view = TSFrontController.instance.getMainView();
			registerSelfAsFocusableComponent();
		}
		
		private function buildBase():void {
			chat_bubble = new ChatBubble();
			chat_bubble.showing_sig.addOnce(refreshAfterBubbleLoad);
			addChild(chat_bubble);
			
			//input bg
			var g:Graphics = input_holder.graphics;
			g.lineStyle(1, 0xd6d6b1);
			g.beginFill(0xe4e4bf);
			g.drawRoundRectComplex(0, 0, 162, 33, 4, 0, 4, 0);
			g.lineStyle(0,0,0);
			g.beginFill(0xf5f5ce);
			g.drawRoundRectComplex(1, 3, 161, 30, 4, 0, 4, 0);
			all_holder.addChild(input_holder);
			
			//currantt synbol TF			
			TFUtil.prepTF(currants_symbol_tf, false);
			TFUtil.setTextFormatFromStyle(currants_symbol_tf, 'rename_bubble_currants');
			currants_symbol_tf.embedFonts = false;
			currants_symbol_tf.mouseEnabled = true;
			currants_symbol_tf.selectable = true;
			currants_symbol_tf.autoSize = TextFieldAutoSize.NONE;
			currants_symbol_tf.type = TextFieldType.INPUT;
			currants_symbol_tf.text = '₡';
			currants_symbol_tf.width = currants_symbol_tf.textHeight + 4;
			currants_symbol_tf.height = currants_symbol_tf.textHeight + 4;
			currants_symbol_tf.y = int(input_holder.height/2 - currants_symbol_tf.height/2) + 1;
			currants_symbol_tf.x = 5;
			input_holder.addChild(currants_symbol_tf);
			
			//input TF			
			TFUtil.prepTF(input_tf, false);
			TFUtil.setTextFormatFromStyle(input_tf, 'rename_bubble_input');
			input_tf.embedFonts = false;
			input_tf.mouseEnabled = true;
			input_tf.selectable = true;
			input_tf.autoSize = TextFieldAutoSize.NONE;
			input_tf.type = TextFieldType.INPUT;
			input_tf.text = 'placeholder';
			input_tf.height = input_tf.textHeight + 4;
			input_tf.y = int(input_holder.height/2 - input_tf.height/2) + 1;
			input_holder.addChild(input_tf);
			
			//accept bt
			submit_bt = new Button({
				name: 'accept',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_INPUT_ACCEPT,
				w: 37,
				x: input_holder.width - 2,
				y: -1,
				graphic: new AssetManager.instance.assets.input_check(),
				graphic_disabled: new AssetManager.instance.assets.input_check_disabled(),
				graphic_hover: new AssetManager.instance.assets.input_check_hover()
			});
			submit_bt.addEventListener(TSEvent.CHANGED, onSubmitClick, false, 0, true);
			submit_bt.h = 35;
			all_holder.addChild(submit_bt);
			
			//cancel bt
			cancel_bt = new Button({
				name: 'close',
				graphic: new AssetManager.instance.assets.close_x_small(),
				graphic_placement: 'center',
				draw_alpha: 0,
				x: submit_bt.x + submit_bt.width + 6,
				w: 13,
				h: submit_bt.height
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, onCancelClick, false, 0, true);
			all_holder.addChild(cancel_bt);
			
			is_built = true;
		}
		
		private function sizeAndPlaceInputTF():void {
			if (!current_request) return;
			
			var offset:int = -16;
			if (current_request.is_currants) {
				offset = -50;
				currants_symbol_tf.visible = true;
			} else {
				currants_symbol_tf.visible = false;
			}
			
			// ideally we would make the input bigger but that is harder
			if (!cancel_bt.visible) {
				input_holder.x = 9;
			} else {
				input_holder.x = 0;
			}
			
			input_tf.width = input_holder.width + offset;
			input_tf.x = int(input_holder.width/2 - input_tf.width/2);
		}
		
		public function start(payload:Object):void {
			//if one is still up, cancel it first
			if(parent && current_request) onCancelClick();
			
			if(!TSFrontController.instance.requestFocus(this)) {
				CONFIG::debugging {
					Console.warn('could not take focus');
				}
				return;
			}
			
			if(!payload) return;
			if(!is_built) buildBase();
			
			current_request = InputRequest.fromAnonymous(payload, 'input_request');
			
			//reset the input
			input_tf.text = current_request.input_value;
			input_tf.restrict = current_request.input_restrict;
			input_tf.maxChars = current_request.input_max_chars;
			
			if (current_request.cancelable) {
				cancel_bt.visible = true;
			} else {
				cancel_bt.visible = false;
			}
			
			sizeAndPlaceInputTF();
			
			//see if we need to check for a min char amount
			if((current_request.input_min_chars || current_request.check_user_name) && !input_tf.hasEventListener(Event.CHANGE)){
				input_tf.addEventListener(Event.CHANGE, onInputChange, false, 0, true);
			}
			onInputChange();
			
			if(input_tf.text || current_request.input_focus) {
				focusOnInput();
			}
			
			//show the bubble			
			current_desc = current_request.input_label;
			if(current_desc == '') current_desc = 'What do you want to name me, then?';
			
			default_extra_line = null;
			
			if (current_request.check_user_name && current_request.input_min_chars && current_request.input_max_chars) {
				default_extra_line = '<font color="#999999">' +
					'(between '+current_request.input_min_chars+' and '+current_request.input_max_chars+' characters)' +
					'</font>';
			}
			
			changeDescText();
			
			main_view.addView(this);
			
			refresh();
		}
		
		private function changeDescText(extra_line:String=null):void {
			if (!current_request) return;
			var desc:String = current_desc;
			extra_line = extra_line || default_extra_line;
			if (extra_line) {
				desc+='<br>'+extra_line;
			}
			chat_bubble.show('<span class="rename_bubble_body">'+desc+'</span>', null, all_holder);
		}
		
		private var current_desc:String;
		private var default_extra_line:String;
		
		private function refreshAfterBubbleLoad():void {
			refresh();
		}
		
		private function setItemstackPt():void {		
			//reset
			itemstack_pt.x = 0;
			itemstack_pt.y = 0;
			
			//look in the world for the itemstack
			const liv:LocationItemstackView = main_view.gameRenderer.getItemstackViewByTsid(current_request.itemstack_tsid);
			if(liv) {
				itemstack_pt = liv.localToGlobal(new Point(0, liv.getYAboveDisplay()));
				if (!liv.is_loaded) {
					visible = false;
					liv.loadCompleted_sig.add(onLivLoaded);
				}
			}
			
			//not in the world, how about the pack?
			const piv:PackItemstackView = PackDisplayManager.instance.getItemstackViewByTsid(current_request.itemstack_tsid);
			if(piv){
				//put it in the middle of the icon, but take into account the "opener" on the left of the slot
				const offset_x:int = (model.layoutModel.pack_slot_wide_w-model.layoutModel.pack_slot_w)/2;
				itemstack_pt = piv.localToGlobal(new Point(piv.width/2 - offset_x, 0));
			}
		}
		
		public function onLivLoaded(liv:LocationItemstackView):void {
			if (!current_request) return;
			if (liv.tsid != current_request.itemstack_tsid) return;
			StageBeacon.setTimeout(refresh, 300);
		}
		
		public function refresh():void {
			if(!parent) return;
			
			// we must be moving, so bail!
			if (!main_view.gameRenderer) return;
			
			// bail!
			if (!current_request) return;
			
			visible = true;
			
			//set the point and move this sucker where it needs to go
			setItemstackPt();
			x = int(itemstack_pt.x);
			y = int(itemstack_pt.y);
			chat_bubble.bubble_pointer.x = -3; //visual tweak since 0 pushed it slightly to the right
			
			const stage_bounds:Rectangle = getBounds(StageBeacon.stage);
			const max:int = (model.layoutModel.gutter_w*2 + model.layoutModel.overall_w)-10;
			const min:int = 10;
			
			var adj_x:int = 0;
			if (stage_bounds.right > max) {
				adj_x = max-stage_bounds.right;
			} else if (stage_bounds.left < min) {
				adj_x = min-stage_bounds.left;
			}
			
			if (adj_x) {
				x += adj_x;
				
				//move the point so it's always on top of the thing we are renaming
				chat_bubble.bubble_pointer.x -= adj_x;
			}

			// must set y to zero, as keepInBounds() will -= it.
			chat_bubble.y = 0;
			chat_bubble.keepInBounds();
		}
		
		public function get request_uid():String {
			if (current_request) {
				return current_request.uid;
			}
			
			return null;
		}
		
		private function end():void {
			current_request = null;
			TSFrontController.instance.releaseFocus(this, 'InputTalkBubble releasing');
			if (chat_bubble) {
				chat_bubble.hide(cleanUp);
			} else {
				cleanUp();
			}
		}
		
		private function cleanUp():void {
			if(parent) parent.removeChild(this);
		}
		
		public function forceCancel():void {
			cancel();
		}
		
		private function onCancelClick(event:Event = null):void {
			if(current_request && !current_request.cancelable){
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			cancel();
		}
		
		private function cancel():void {
			StageBeacon.waitForNextFrame(blurInput);
			
			if (current_request) {
				if(current_request.close_function == null){
					//tell the server "nevermind"
					TSFrontController.instance.genericSend(
						new NetOutgoingInputResponseVO(current_request.uid, '', current_request.itemstack_tsid)
					);
				}
				else {
					current_request.close_function();
				}
			}
			
			end();
		}
		
		private function onSubmitClick(event:Event):void {
			//send it off to the server!
			if(!current_request || input_tf.text == '' || submit_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			if(current_request.submit_function == null){
				
				// call the api with this name change, and wait for response before 
				if (current_request.check_user_name) {
					submit_bt.disabled = true;
					StageBeacon.stage.focus = StageBeacon.stage;
					NewxpLogger.log('setting_name', input_tf.text);
					API.setPlayerName(input_tf.text, onNameSet);
					return;
				}
				
				TSFrontController.instance.genericSend(
					new NetOutgoingInputResponseVO(current_request.uid, input_tf.text, current_request.itemstack_tsid)
				);
			}
			else {
				current_request.submit_function(input_tf.text);
			}
						
			end();
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		private function onNameSet(ok:Boolean, rsp:Object):void {
			if (!current_request) return;
			if (ok) {
				NewxpLogger.log('set_name', input_tf.text);
				TSFrontController.instance.genericSend(
					new NetOutgoingInputResponseVO(current_request.uid, input_tf.text, current_request.itemstack_tsid)
				);
				end();
				StageBeacon.stage.focus = StageBeacon.stage;
			} else {
				onInputChange();
				var txt:String = (rsp && rsp.error) ? rsp.error : 'unspecified';
				//TSFrontController.instance.quickConfirm('Hmmm, we failed to set your name. The error was "'+txt+'". Try again please.');
				BootError.handleError('Failed to save newbie name', new Error('InputTalkBubble error from API:'+txt), ['InputTalkBubble'], true, true);
			}
		}
		
		private var check_tim:int;
		private function onInputChange(event:Event = null, name_ok:int=-1):void {		
			const input_txt:String = input_tf.text;
			
			submit_bt.disabled = false;
			
			var tip_txt:String;
			var enough_chars:Boolean = !current_request.input_min_chars || (input_txt.length >= current_request.input_min_chars);
			
			if (current_request.check_user_name) {
				if (enough_chars) {
					if (name_ok == -1) {
						submit_bt.disabled = true;
						changeDescText('<font color="#999999">Checking availability...</font>');
						tip_txt = 'Checking user name...';
						if (check_tim) StageBeacon.clearTimeout(check_tim);
						check_tim = StageBeacon.setTimeout(API.checkPlayerName, 500, StringUtil.trim(input_txt), onNameCheck);
					} else if (name_ok == 0) {
						submit_bt.disabled = true;
						changeDescText('<font color="#c10707">That name is already taken :(</font>');
						tip_txt = 'That user name is already taken!';
					} else {
						changeDescText('<font color="#019e26">That name is available!</font>');
					}
				} else {
					changeDescText();
				}
			}
			
			if (!enough_chars && !submit_bt.disabled){
				tip_txt = 'Must be at least '+current_request.input_min_chars+' '+(current_request.input_min_chars != 1 ? 'characters' : 'character');
				submit_bt.disabled = true;
			}
			
			if (submit_bt.disabled) {
				submit_bt.tip = {
					txt:tip_txt, 
					pointer:WindowBorder.POINTER_BOTTOM_CENTER
				};
			} else {
				submit_bt.tip = null;
			}
		}
		
		private function onNameCheck(ok:Boolean, rsp:Object):void {
			if (!current_request) return;	
			if (StringUtil.trim(input_tf.text) != StringUtil.trim(rsp.name)) return;
			
			if (ok) {
				NewxpLogger.log('good_name', StringUtil.trim(rsp.name));
				onInputChange(null, 1);
			} else {
				NewxpLogger.log('bad_name', StringUtil.trim(rsp.name));
				onInputChange(null, 0);
			}
		}
		
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
			
			if(input_tf.text || (current_request && current_request.input_focus)) {
				focusOnInput();
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
			StageBeacon.waitForNextFrame(input_tf.setSelection, 0, input_tf.text.length);
		}
		
		private function blurInput():void {
			if (StageBeacon.stage.focus != input_tf) return;
			StageBeacon.stage.focus = StageBeacon.stage;
		}
	}
}