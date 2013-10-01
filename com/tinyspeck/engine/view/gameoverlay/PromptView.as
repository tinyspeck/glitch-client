package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.prompt.Prompt;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingPromptChoiceVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.ConfirmationDialog;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class PromptView extends AbstractTSView {
		
		/* singleton boilerplate */
		public static const instance:PromptView = new PromptView();
		
		private const MAX_BUTTON_WIDTHS:uint = 100;
		
		private var model:TSModelLocator;
		private var padd:int = 7;
		private var overall_w:int = 300;
		private var all_holder:Sprite = new Sprite();
		private var active_holder:Sprite = new Sprite();
		private var deleted_holder:Sprite = new Sprite();
		private var removeables:Array = [];
		private var over:Boolean = false;
		private var out_timer:uint;
		
		public function PromptView():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			addChild(all_holder);
			all_holder.addChild(deleted_holder);
			all_holder.addChild(active_holder);
			
			model.activityModel.registerCBProp(checkForNewPrompts, "prompts");
			model.activityModel.registerCBProp(removePromptByUid, "prompt_del");
			this.addEventListener(MouseEvent.ROLL_OVER, onRollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onRollOut);
			StageBeacon.setInterval(checkForNewPrompts, 5000);
		}
		
		public function startFakingPrompts():void {
			if (model.flashVarModel.fake_prompts) {
				var c:int = 0;
				var text:String = "In that flash example, be sure to roll over the blue part of the button to really see the difference(note that the blue rectangle is inside the black rectangle movieClip, not just over). In the MOUSE_OVER example, the event is fired for every children of the display object that the listener was added to.";
				StageBeacon.setInterval(function():void {
					/*model.activityModel.addPrompt(Prompt.fromAnonymous({
						uid: new Date().getTime()+c,
						timeout: 4,
						txt: (c++)+text.substr(0, Math.ceil(Math.random()*text.length-1)),
						icon_buttons: true,
						timeout_value: '',
						choices: [{
							value: 'yes',
							label: 'Yes'
						}, {
							value: 'no',
							label: 'No'
						}]
					}));
					*/model.activityModel.addPrompt(Prompt.fromAnonymous({
						uid: new Date().getTime()+c,
						timeout: 0,
						is_modal: true,
						escape_value:'fucj',
						txt: (c++)+text.substr(0, Math.ceil(Math.random()*text.length-1)),
						icon_buttons: false,
						choices: [{
							value: 'yes',
							label: 'Yes'
						}, {
							value: 'no',
							label: 'No'
						}]
					}));
					/*model.activityModel.addPrompt(Prompt.fromAnonymous({
						uid: new Date().getTime()+c,
						timeout: 3,
						txt: (c++)+text.substr(0, Math.ceil(Math.random()*text.length-1)),
						icon_buttons: true,
						timeout_value: 'DID TIMEOUT',
						choices: [{
							value: 'yes',
							label: 'Yes'
						}, {
							value: 'no',
							label: 'No'
						}]
					}))*/
				}, 5000);
			}
		}
		
		private function onRollOut(e:MouseEvent):void {
			over = false;
			out_timer = StageBeacon.setTimeout(function():void {
				while (removeables.length) {
					removePromptAndSendChoice(removeables.shift());
				}
			}, 2000);
		}
		
		private function onRollOver(e:MouseEvent):void {
			TipDisplayManager.instance.goAway();
			over = true;
			StageBeacon.clearTimeout(out_timer);
		}
		
		private function clickHandler(e:MouseEvent):void {
			if (e.target is Button) {
				TipDisplayManager.instance.goAway();
				var bt:Button = Button(e.target);
				var sp:Sprite = bt.parent as Sprite;
				if (sp.parent == deleted_holder) {
					SoundMaster.instance.playSound('CLICK_FAILURE');
					return;
				} else {
					SoundMaster.instance.playSound('CLICK_SUCCESS');
				}
				
				
				
				//model.activityModel.removePrompt(sp.name);
				var prompt:Prompt = model.activityModel.getPromptByUid(sp.name);
				var choice:Object = prompt.choices[int(bt.name)];
				
				removePromptAndSendChoice(sp, choice.value);
			}
		}
		
		private function removePromptIfNotOver(sp:Sprite):void {
			if (over) {
				if (removeables.indexOf(sp) == -1) removeables.push(sp);
			} else {
				removePromptAndSendChoice(sp);
			}
		}
		
		private function removePromptByUid(uid:String):void {
			var sp:Sprite = active_holder.getChildByName(uid) as Sprite;
			if (sp) {
				removePrompt(sp)
			}
		}
		
		private function sendChoice(prompt:Prompt, value_to_send:String):void {
			
			if (!prompt) { // it might have been removed
				return;
			}
			
			// we were not passed a value_to_send, so let's get the default value from the prompt
			if (value_to_send === null) {
				value_to_send = prompt.timeout_value;
			}
			
			// if we have any value, send it
			if (value_to_send) {
				TSFrontController.instance.genericSend(new NetOutgoingPromptChoiceVO(prompt.uid, value_to_send));
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('not sending value');
				}
			}
			
		}
		
		private function removePromptAndSendChoice(sp:Sprite, value_to_send:String = null):void {
			var prompt:Prompt = model.activityModel.getPromptByUid(sp.name);
			sendChoice(prompt, value_to_send);
			
			if (sp && sp.parent) removePrompt(sp);
		}
		
		private function removePrompt(sp:Sprite):void {
			deleted_holder.addChild(sp);
			if (sp.parent) TSTweener.addTween(sp, {alpha:0, time:.1, transition:'linear'});
			StageBeacon.setTimeout(function():void {
				if (sp.parent) sp.parent.removeChild(sp);
				sp.removeEventListener(MouseEvent.MOUSE_OVER, overHandler);
				sp.removeEventListener(MouseEvent.MOUSE_OUT, outHandler);
				reflow();
				checkForNewPrompts();
			}, 200);
		}
		
		private function addPrompt(prompt:Prompt):void {
			if(!prompt.txt) {
				CONFIG::debugging {
					Console.warn('WTF null prompt');
				}
				return;
			}
			
			prompt.displayed = true;
			
			var sp:Sprite = new Sprite();
			sp.y = 0;
			sp.name = String(prompt.uid);
			var tf:TSLinkedTextField = new TSLinkedTextField();
			TFUtil.prepTF(tf);
			tf.name = 'tf';
			sp.addChild(tf);
			sp.addEventListener(MouseEvent.CLICK, clickHandler);
			
			var prompt_txt:String = prompt.txt;
			const vag_ok:Boolean = StringUtil.VagCanRender(prompt_txt);
			if(!vag_ok){
				prompt_txt = '<font face="Arial">'+prompt_txt+'</font>';
			}
			
			tf.embedFonts = vag_ok;
			tf.width = overall_w-(padd*2);
			tf.htmlText = '<span class="prompt_default">'+prompt_txt+'</span>';
			tf.x = padd;
			tf.y = padd;
			tf.borderColor = 0xffffff;
			tf.border = false;
			tf.filters = StaticFilters.prompt_DropShadowA;
			
			var icon_button_w:int = 24;
			var icon_button_h:int = CSSManager.instance.getNumberValueFromStyle('button_tiny', 'height', 25);
			var shadow_offset:int = CSSManager.instance.getNumberValueFromStyle('button_tiny', 'shadowOffset', 1);
			shadow_offset = shadow_offset < 0 ? -shadow_offset : shadow_offset; //make sure it's possitive
			var choice:Object;
			var i:int;
			var bt:Button;
			var button_widths:int;
			
			if (prompt.icon_buttons && prompt.choices.length == 2) {
				// make some space at the right for the icon buttons
				tf.width = tf.width-((icon_button_w*2)+(padd*2));
				
				// add the icon buttons
				for (i=prompt.choices.length-1;i>-1;i--) {
					choice = prompt.choices[int(i)];
					bt = new Button({
						tip: {
							txt: ''+choice.label+'',
							pointer: WindowBorder.POINTER_BOTTOM_CENTER	
						},
						graphic: (i==0) ? new AssetManager.instance.assets.prompt_check() : new AssetManager.instance.assets.prompt_x(),
						name: i,
						value: choice.value,
						w: icon_button_w,
						y: int(Math.max(padd, tf.y+tf.height-icon_button_h)),
						x: int(overall_w - padd - shadow_offset - ((icon_button_w-2)*(2-i))),
						size: Button.SIZE_TINY,
						type: (i==0) ? Button.TYPE_LEFT : Button.TYPE_RIGHT
					});
					
					sp.addChild(bt);
					if(i == 0){
						var icon_div:Sprite = createButtonDivider(icon_button_h-2);
						icon_div.x = overall_w - padd - icon_button_w + 2;
						icon_div.y = bt.y+1;
						sp.addChild(icon_div);
					}
				}
			} else {
				// add normal buttons
				var start_x:int = overall_w;
				var bt_type:String = Button.TYPE_MIDDLE;
				
				for (i=prompt.choices.length-1;i>-1;i--) {
					if(prompt.choices.length == 1){
						bt_type = Button.TYPE_SINGLE;
					}else if(i == 0){
						bt_type = Button.TYPE_LEFT;
					}else if(i == prompt.choices.length - 1){
						bt_type = Button.TYPE_RIGHT;
					}
					choice = prompt.choices[int(i)];
					bt = new Button({
						label: choice.label,
						name: i,
						value: choice.value,
						size: Button.SIZE_TINY,
						type: bt_type
					});
					
					button_widths += bt.width;
					
					bt.y = int(tf.y + tf.height - bt.height + padd*2);
					bt.x = start_x-padd-bt.width-shadow_offset;
					sp.addChild(bt);
					start_x = bt.x + 7;
					
					if(i < prompt.choices.length - 1 && prompt.choices.length > 1){
						var norm_div:Sprite = createButtonDivider(icon_button_h-2);
						norm_div.x = bt.x + bt.width + 1;
						norm_div.y = bt.y + 1;
						norm_div.name = 'divider'+i;
						sp.addChild(norm_div);
					}
				}
				
				tf.width = tf.width-(button_widths+padd*2);
			}
			
			//re-position text and buttons if the width of the buttons is big
			if(button_widths > MAX_BUTTON_WIDTHS){
				tf.width = overall_w-(padd*2);

				for (i=prompt.choices.length-1;i>-1;i--) {
					bt = sp.getChildByName(i.toString()) as Button;
					bt.y = Math.round(tf.y+tf.height+padd);
					
					var divider:Sprite = sp.getChildByName('divider'+i) as Sprite;
					if(divider) divider.y = bt.y + 1;
				}					
			}
			
			//play a sound if there is one
			if(prompt.sound) SoundMaster.instance.playSound(prompt.sound);
			
			drawNotification(sp);
			
			sp.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
			sp.addEventListener(MouseEvent.MOUSE_OUT, outHandler);
			
			sp.alpha = .1;
			TSTweener.addTween(sp, {alpha:1, time:.1, delay:0, transition:'linear'});
			active_holder.addChildAt(sp, 0);
			reflow();
			
			var ms:int = prompt.timeout*1000;

			if (ms) {
				StageBeacon.setTimeout(removePromptIfNotOver, ms, sp);
			}
		}
		
		private function overHandler(e:*):void {
			drawNotification(Sprite(e.currentTarget), true);
		}
		
		private function outHandler(e:*):void {
			drawNotification(Sprite(e.currentTarget), false);
		}
		
		private function drawNotification(sp:Sprite, over:Boolean = false):void {
			var tf:TextField = TextField(sp.getChildByName('tf'));
			var back_color:uint = CSSManager.instance.getUintColorValueFromStyle('prompt_background', 'color', 0x393b32);
			var back_alpha:Number = CSSManager.instance.getNumberValueFromStyle('prompt_background', 'alpha', .9);
			
			sp.graphics.clear();
			var h:int = sp.height+(padd*2);
			
			sp.graphics.beginFill(back_color, back_alpha);
			sp.graphics.drawRoundRect(0, 0, overall_w, h, 12);
		}
		
		private function reflow():void {
			var sp:DisplayObject;
			var next_y:int = 0;
			for (var i:int=0;i<active_holder.numChildren;i++) {
				if (sp) next_y+= sp.height+padd;
				sp = active_holder.getChildAt(i);
				TSTweener.addTween(sp, {y:next_y, time:.1, transition:'easeOutCubic'});
			}
			
			var dest_y:int = 0;
			if (sp) {
				dest_y = -(next_y+sp.height);
			}
			
			TSTweener.removeTweens(all_holder);
			TSTweener.addTween(all_holder, {y:dest_y, time:.1, transition:'easeOutCubic'});
			
			var g:Graphics = this.graphics;
			g.clear();
			g.beginFill(0x000000, 0);
			g.drawRect(0, 0, overall_w, dest_y);
			
			refresh();
			
			//if we have any active prompts, we need to hide the gps
			MiniMapView.instance.showHideGPS(active_holder.numChildren > 0);
		}
		
		private function createButtonDivider(h:int):Sprite {
			var divider:Sprite = new Sprite();
			divider.mouseEnabled = false;
			var g:Graphics = divider.graphics;
			g.beginFill(0x838383, 1);
			g.drawRect(0, 0, 1, h);
			g.beginFill(0xFFFFFF, 1);
			g.drawRect(1, 0, 1, h);
			
			return divider;
		}
		
		public function refresh():void {
			x = model.layoutModel.loc_vp_w-overall_w-30;
			y = model.layoutModel.loc_vp_h-30;
			visible = (!model.moveModel.moving);
			CONFIG::god {
				visible &&= (!model.stateModel.editing && !model.stateModel.hand_of_god);
			}
			
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					visible = false;
				}
			}
		}
		
		public function checkForNewPrompts(prompts:Array = null):void {		
			prompts = prompts || model.activityModel.prompts;
			var prompt:Prompt;
			for (var i:int;i<prompts.length;i++) {
				prompt = prompts[int(i)];
				
				// always do modal ones
				if (prompt.is_modal) {
					if (!prompt.displayed && !ConfirmationDialog.instance.parent && !model.moveModel.moving) {
						// here do a modal dialog
						var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
						cdVO.item_class = prompt.item_class || cdVO.item_class;
						cdVO.callback =	function(value:*):void {
							//get the prompt based on the dialog name because the 'prompt' could be changed before the dialog
							//has a parent. race conditions FTW.
							prompt = model.activityModel.getPromptByUid(ConfirmationDialog.instance.uid);
							if(prompt && prompt.displayed){
								sendChoice(prompt, value);
							}
							else if(!prompt){
								;//weeee
								CONFIG::debugging {
									Console.warn('Could not find prompt for UID: '+ConfirmationDialog.instance.uid);
								}
							}
						};
						cdVO.txt = prompt.txt;
						cdVO.choices = prompt.choices;
						cdVO.escape_value = prompt.escape_value;
						cdVO.max_w = prompt.max_w;
						if (prompt.title) cdVO.title = prompt.title;
						if (TSFrontController.instance.confirm(cdVO)) {
							prompt.displayed = true;
							
							//store the UID in the dialog
							ConfirmationDialog.instance.uid = prompt.uid;
						}
					}
					continue;
				}
				
				// only do normal ones if there is room
				if (height<model.layoutModel.loc_vp_h/2 || prompt.is_modal) {
					if (!prompt.displayed) {
						addPrompt(prompt);
					}
				};
			}
		}
	}
}