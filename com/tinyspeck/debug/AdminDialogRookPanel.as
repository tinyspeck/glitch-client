package com.tinyspeck.debug {
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.RookAttackView;
	import com.tinyspeck.engine.port.RookManager;
	import com.tinyspeck.engine.port.RookPeckDamageView;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.spritesheet.AnimationSequenceCommand;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.ArbitrarySWFView;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	public class AdminDialogRookPanel implements IMoveListener, IFocusableComponent {
		
		private var sp:Sprite;
		private var debug_sh:Shape = new Shape();
		private var roookable_buttons_sp:Sprite = new Sprite();
		private var model:TSModelLocator;
		private var rav:RookAttackView;
		private var rpdv:RookPeckDamageView;
		public var input_tf:TextField = new TextField();
		private var animations_tf:TextField = new TextField();
		private var values_tf:TextField = new TextField();
		private var rookable_types:Array = [{
			value:0,
			name: 'not rookable',
			desc: 'Makes the location unrookable'
		}, {
			value:1,
			name: 'forest',
			desc: 'Makes the location rookable, but no flock will appear'
		}, {
			value:2,
			name: 'normal',
			desc: 'Makes the location rookable, and all rook ambient effects and attacks will run'
		}];
		
		public function AdminDialogRookPanel(){
			
		}
		
		// IMoveListener funcs
		// -----------------------------------------------------------------
		
		public function moveLocationHasChanged():void {
		
		}
		
		public function moveLocationAssetsAreReady():void {
		
		}
		
		public function moveMoveStarted():void {
			if (!model.worldModel.location) return;
			if (!sp) return;
			roookable_buttons_sp.visible = false;
		}
		
		public function moveMoveEnded():void {
			if (!sp) return;
			roookable_buttons_sp.visible = true;
			resetRookableButtons();
		}
		
		// -----------------------------------------------------------------
		// END IMoveListener funcs
		
		private function getRookableBtByValue(value:int):Button {
			var bt:DisplayObject = roookable_buttons_sp.getChildByName('rookable_type_'+value+'_bt');
			if (!bt) {
				CONFIG::debugging {
					Console.error('no rookable button for value:'+value);
				}
				return null;
			}
			return Button(bt);
		}
		
		private function resetRookableButtons():void {
			for (var i:int;i<roookable_buttons_sp.numChildren;i++) {
				Button(roookable_buttons_sp.getChildAt(i)).disabled = false;
			}
			getRookableBtByValue(model.worldModel.location.rookable_type).disabled = true;
		}
		
		private function onRookableButtonsSpClick(e:MouseEvent):void {
			var bt:Button = e.target as Button;
			model.worldModel.location.rookable_type = bt.value;
			saveRookableTypeToLocation();
		}

		private function saveRookableTypeToLocation():void {
			
			var amf:Object = model.worldModel.location.AMF();
			var physics:Object = model.worldModel.physics_obs[model.worldModel.location.tsid];
			
			TSFrontController.instance.saveLocation(amf, physics, function(success:Boolean):void {
				if (success) {
					// the save was successful
					model.activityModel.growl_message = 'ROOKABLE TYPE SAVED';
					resetRookableButtons();
					
				} else {
					// revert ?
					
				}
			});
			
		}
		
		private var peck_cnt:int = 0;
		public function init(sp:Sprite):void {
			this.sp = sp;
			model = TSModelLocator.instance;
			registerSelfAsFocusableComponent();
			TSFrontController.instance.registerMoveListener(this);
			
			var bt:Button;
			for (var i:int;i<rookable_types.length;i++) {
				var r_type:Object = rookable_types[int(i)];
				bt = new Button({
					label: r_type.name+' ('+r_type.value+')',
					name: 'rookable_type_'+r_type.value+'_bt',
					value: r_type.value,
					y: 0,
					x: (bt) ? bt.x+bt.width+5 : 0,
					c: 0xffffff,
					high_c: 0xcecece,
					shad_c: 0xcecece,
					inner_shad_c: 0x69bcea,
					label_size: 10,
					tip: { 
						txt: r_type.name+' ('+r_type.value+')'+': '+r_type.desc,
						pointer: WindowBorder.POINTER_BOTTOM_CENTER
					}
				});
				roookable_buttons_sp.addChild(bt);
			}
			sp.addChild(roookable_buttons_sp);
			roookable_buttons_sp.addEventListener(MouseEvent.CLICK, onRookableButtonsSpClick);
			
			roookable_buttons_sp.visible = false;
			if (!model.moveModel.moving) {
				roookable_buttons_sp.visible = true;
				resetRookableButtons();
			}
			
			
			
			values_tf.defaultTextFormat = new TextFormat('Arial');
			values_tf.x = 0;
			values_tf.width = 320;
			//values_tf.autoSize = TextFieldAutoSize.LEFT;
			values_tf.multiline = true;
			values_tf.wordWrap = true;
			values_tf.border = false;
			sp.addChild(values_tf);
			
			//let the debug class know about the text field
			RookValueTracker.instance.value_tf = values_tf;
			
			input_tf.antiAliasType = AntiAliasType.ADVANCED;
			input_tf.type = TextFieldType.INPUT;
			input_tf.selectable = true;
			input_tf.multiline = false;
			input_tf.wordWrap = true;
			input_tf.backgroundColor = 0xffffff;
			input_tf.background = true;
			input_tf.border = true;
			input_tf.borderColor = 0x000000;
			input_tf.name = '_input_tf'
			input_tf.height = 18;
			input_tf.width = 320;
			input_tf.addEventListener(FocusEvent.FOCUS_IN, inputFocusHandler);
			input_tf.addEventListener(FocusEvent.FOCUS_OUT, inputBlurHandler);
			input_tf.defaultTextFormat = new TextFormat('Arial', 12);
			sp.addChild(input_tf);
			
			animations_tf.antiAliasType = AntiAliasType.ADVANCED;
			animations_tf.selectable = true;
			animations_tf.multiline = true;
			animations_tf.wordWrap = true;
			animations_tf.name = '_animations_tf';
			animations_tf.width = 345;
			animations_tf.defaultTextFormat = new TextFormat('Arial', 12);
			sp.addChild(animations_tf);
			
			rav = new RookAttackView(350);
			CONFIG::debugging {
				rav.addSequenceCompleteCallback(function(asv:ArbitrarySWFView):void {
					//Console.warn('AAAA seq complete, now on: ', asv.mc.animatee.currentFrameLabel+' '+new Date().getTime())
					Console.trackRookValue('AAAA seq complete, now on: ', asv.mc.animatee.currentFrameLabel+' '+new Date().getTime())
				}, false);
			}
			rav.addAnimationStartedCallback(function(asv:ArbitrarySWFView):void {
				//Console.warn('AAAA start', asv.mc.animatee.currentFrameLabel+' '+new Date().getTime())
				CONFIG::debugging {
					Console.trackRookValue('AAAA start', asv.mc.animatee.currentFrameLabel+' '+new Date().getTime())
				}
				var anim:String = asv.mc.animatee.currentFrameLabel;
				var peck_index:int = model.rookModel.rav_peckA.indexOf(anim);
				if (peck_index > -1) {
					peck_cnt++;
					if (peck_cnt <= 8) {
						
						// the fx we want to show
						var fx_anim:String = damage_id+peck_cnt;
						
						// the anim we want to hold on, for X frames
						var hold_anim:String = rpdv.mc.animatee.currentFrameLabel;
						
						// how many frames do we hold it for
						var hold_cnt:int;
						// how many frames do we hold it for
						if (anim.indexOf('scratch') > -1) { // if it is a scratch, wait until the second damage frame
							hold_cnt = model.rookModel.rav_peck_damage_frame2A[peck_index];
						} else {
							hold_cnt = model.rookModel.rav_peck_damage_frame1A[peck_index];
						}
						
						CONFIG::debugging {
							Console.trackRookValue('AAAA fx_anim', fx_anim+' hold_anim:'+hold_anim+':'+hold_cnt);
						}
						rpdv.animate(new AnimationSequenceCommand([hold_anim+':'+hold_cnt, fx_anim], false), null);
					}
				}
			}, false);
			CONFIG::debugging {
				rav.addAnimationCompleteCallback(function(asv:ArbitrarySWFView):void {
					//Console.warn('AAAA anim complete, now on: ', asv.mc.animatee.currentFrameLabel+' '+new Date().getTime())
					Console.trackRookValue('AAAA anim complete, now on: ', asv.mc.animatee.currentFrameLabel+' '+new Date().getTime())
				}, false);
			}
			rav.visible = true;

			rpdv = new RookPeckDamageView(350);
			rpdv.visible = true;
			
			if (rav.loaded) {
				displayRookAttackAnimation();
			} else {
				rav.addEventListener(TSEvent.COMPLETE, function():void {
					displayRookAttackAnimation();
				});
			}
			
			rav.y = rpdv.y = 150;//Math.round(rav.w/2);
			rav.x = rpdv.x = 150;//Math.round(rav.h/2);
			input_tf.y = 300;
			values_tf.y = 320;
			
			// on top
			sp.addChild(rpdv);
			sp.addChild(rav);
			
			sp.addChild(debug_sh);
			debug_sh.y = 25;
			RookManager.instance.addDebugSh(debug_sh);
		}
		
		private var damage_id:String;
		private function displayRookAttackAnimation():void {
			animations_tf.text = 'ANIMATIONS: '+rav.mc.animations.join(',');
			animations_tf.height = animations_tf.textHeight+4;
			animations_tf.y = input_tf.y+20;
			values_tf.y = animations_tf.y+animations_tf.height+15;
			input_tf.text = model.rookModel.rav_damageB_to_peck_animA.join(',');
			damage_id = 'peckFXB';
			CONFIG::debugging {
				Console.trackRookValue('rav animations', rav.mc.animations.join(','));
			}
		}
		
		private function inputFocusHandler(e:FocusEvent = null):void {
			if (this != model.stateModel.focused_component) {
				if (!TSFrontController.instance.requestFocus(this)) {
					CONFIG::debugging {
						Console.warn('could not take focus');
					}
					// you cannot blur an input during the hanlder for its focusing
					StageBeacon.waitForNextFrame(blurInput);
					return;
				}
			}
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, inputEnterKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, inputEscKeyHandler);
			input_tf.backgroundColor = 0xf5f5ce;
		}
		
		private function inputBlurHandler(e:Event):void {
			if (this == model.stateModel.focused_component) {
				TSFrontController.instance.releaseFocus(this);
			}
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, inputEnterKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, inputEscKeyHandler);
			input_tf.backgroundColor = 0xffffff;
		}
		
		private function blurInput(e:Event = null):void {
			if (StageBeacon.stage.focus != input_tf) return;
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		private function inputEscKeyHandler(e:KeyboardEvent):void {
			blurInput(e);
		}
		
		private function inputEnterKeyHandler(e:KeyboardEvent):void {
			if (!rav.loaded) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			var str:String = input_tf.text.replace(/ /g, '');
			if (!str) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			if (str == 'A') {
				input_tf.text = model.rookModel.rav_damageA_to_peck_animA.join(',');
				damage_id = 'peckFXA';
			} else if (str == 'B') {
				input_tf.text = model.rookModel.rav_damageB_to_peck_animA.join(',');
				damage_id = 'peckFXB';
			} else if (str == 'C') {
				input_tf.text = model.rookModel.rav_damageC_to_peck_animA.join(',');
				damage_id = 'peckFXC';
			} else if (str == 'D') {
				input_tf.text = model.rookModel.rav_damageD_to_peck_animA.join(',');
				damage_id = 'peckFXD';
			} else if (str == 'E') {
				input_tf.text = model.rookModel.rav_damageE_to_peck_animA.join(',');
				damage_id = 'peckFXE';
			} else if (str == 'F') {
				input_tf.text = model.rookModel.rav_damageF_to_peck_animA.join(',');
				damage_id = 'peckFXF';
			}
			
			str = input_tf.text;
			
			var A:Array = str.split(',');
			var seqA:Array = [];
			for (var i:int;i<A.length;i++) {
				if (rav.mc.animations.indexOf(A[int(i)].split(':')[0]) > -1) seqA.push(A[int(i)]);
			}
			
			if (!seqA.length) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			input_tf.text = seqA.join(',');
			rav.visible = true;
			
			///Math.floor(Math.random()*6)   => 0 - 5 (integers)
			
			peck_cnt = 0;
			CONFIG::debugging {
				Console.trackRookValue('AAAA fx_anim', 'none')
			}
			rpdv.animate(new AnimationSequenceCommand(['empty'], false), null);
			rav.animate(new AnimationSequenceCommand(seqA, false), null);
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		public function hasFocus():Boolean {
			return false;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		/*
		
		public function showMC():void {
			if (!rook_attack) return;
			if (!sp) return;
			return;
			Console.trackRookValue('1 showMC', true);
			Console.trackRookValue('2 rook_attack', getQualifiedClassName(rook_attack));
			Console.trackRookValue('3 instance rook', rook_attack.rook);
			Console.trackRookValue('4 class rookScreenAttack', rook_attack.loaderInfo.applicationDomain.hasDefinition('rookScreenAttack'));
			Console.trackRookValue('5 itemRun', rook_attack.hasOwnProperty('itemRun'));
			
			if (rook_attack.hasOwnProperty('setConsole')) rook_attack.setConsole(Console);
			if (rook_attack.hasOwnProperty('itemRun')) rook_attack.itemRun();
			
			DisplayDebug.LogCoords(rook_attack, 20)
			sp.addChild(rook_attack);
			
		}*/
		
	}
}