package com.tinyspeck.debug
{
	import com.bit101.components.HSlider;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.physics.avatar.PhysicsParameter;
	import com.tinyspeck.engine.physics.avatar.PhysicsSettables;
	import com.tinyspeck.engine.physics.avatar.PhysicsSetting;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.ui.Checkbox;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class AdminDialogPhysicsPanel implements IMoveListener {
		private var sp:Sprite;
		private var form_sp:Sprite;
		private var model:TSModelLocator;
		private var settables:PhysicsSettables;
		private var parametersV:Vector.<PhysicsParameter>;
		private var btsV:Vector.<PushButton> = new Vector.<PushButton>();
		private var master_setting:PhysicsSetting;
		private var adj_tf:TextField = new TextField();
		private var adj_cb:Checkbox;
		private var values_tf:TextField = new TextField();
		
		public function AdminDialogPhysicsPanel(){
			//
		}
		
		public function init(sp:Sprite):void {
			this.sp = sp;
			
			model = TSModelLocator.instance;
			
			// get this now if we can
			if (model.worldModel.location && model.worldModel.location.physics_setting) {
				master_setting = model.worldModel.location.physics_setting.clone();
			}
			
			settables = model.physicsModel.settables;
			parametersV = settables.parametersV;
			TSFrontController.instance.registerMoveListener(this);
			model.physicsModel.registerCBProp(onPcAdjustmentsChange, "pc_adjustments");
			model.physicsModel.registerCBProp(onPcAdjustmentsChange, "ignore_pc_adjustments");
			
			form_sp = new Sprite();
			form_sp.visible = !model.moveModel.moving && model.worldModel.location && model.worldModel.location.physics_setting;
			sp.addChild(form_sp);
			
			var label:Label;
			var label2:Label;
			var slider:HSlider;
			var push_bt:PushButton;
			var each_h:int = 25;
			var param:PhysicsParameter;
			
			for (var i:int=parametersV.length-1;i>-1;i--) {
				param = parametersV[int(i)];
				label = new Label(form_sp, 100, (i*each_h));
				label.name = param.name+'_label';
				
				label2 = new Label(form_sp, label.x+180, label.y);
				label2.name = param.name+'_label2';
				
				push_bt = new PushButton(form_sp, label.x+202, label.y+16, 'RESET', function(e:Event):void {
					resetParamFormAndParams(e.currentTarget.name.replace('_bt', ''));
				});
				push_bt.name = param.name+'_bt';
				push_bt.height = 12;
				push_bt.width = 40;
				
				slider = new HSlider(form_sp, label.x, label.y+16, onParamSliderChange);
				slider.name = param.name;
				slider.height = 12;
				slider.width = 200;
				slider.backClick = true;
			}
			
			push_bt = new PushButton(form_sp, 160, 6+((parametersV.length)*each_h), 'CLIPBOARD', function():void {
				System.setClipboard(getCurrentPhysicsForClipboard());
			});
			push_bt.width = 60;
			push_bt.height = 14;
			
			push_bt = new PushButton(form_sp, push_bt.x+push_bt.width+5, push_bt.y, 'SAVE', saveCurrentPhysicsToLocation);
			push_bt.width = 60;
			push_bt.height = 14;
			
			resetParamFormAndParams();
			constructPhysicsSettingsButtons();
			
			adj_cb = new Checkbox({
				x: 0,
				y: push_bt.y + push_bt.height + 5,
				checked: model.physicsModel.ignore_pc_adjustments,
				label: 'ignore pc physics adjustments for testing (not permanent)',
				name: 'adj_cb'
			});
				
			adj_cb.addEventListener(TSEvent.CHANGED, function():void {
				model.physicsModel.ignore_pc_adjustments = adj_cb.checked;
			});
			
			form_sp.addChild(adj_cb);
			
			TFUtil.prepTF(adj_tf, true);
			adj_tf.embedFonts = false;
			adj_tf.autoSize = TextFieldAutoSize.NONE;
			adj_tf.x = 0;
			adj_tf.y = adj_cb.y+adj_cb.h+5;
			form_sp.addChild(adj_tf);
			
			values_tf.defaultTextFormat = new TextFormat('Arial');
			values_tf.x = 0;
			values_tf.y = adj_tf.y;
			values_tf.autoSize = TextFieldAutoSize.LEFT;
			values_tf.multiline = true;
			form_sp.addChild(values_tf);
			
			//let the debug class know about the text field
			PhysicsValueTracker.instance.value_tf = values_tf;
			
			informOfAdjustments();
			
			CONFIG::debugging {
				StageBeacon.mouse_move_sig.add(stageMouseMove);
			}
		}
		
		CONFIG::debugging private function stageMouseMove(e:MouseEvent):void {
			if (!form_sp || !form_sp.visible) {
				Console.removePhysicsTrackedValue('  Location xy');
			}
			const gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			try {
				Console.trackPhysicsValue('  Location xy', 'x:'+gameRenderer.getMouseXinMiddleground(), 'y:'+gameRenderer.getMouseYinMiddleground());
			} catch(err:Error) {}
		}
		
		// IMoveListener funcs
		// -----------------------------------------------------------------
		
		public function moveLocationHasChanged():void {
			
		}
		
		public function moveLocationAssetsAreReady():void {
			if (!sp) return;
			constructPhysicsSettingsButtons();
			switchPhysicsSettingsByName(model.worldModel.location.tsid);
			informOfAdjustments();
		}
		
		public function moveMoveStarted():void {
			if (!model.worldModel.location) return;
			if (!sp) return;
			form_sp.visible = false;
		}
		
		public function moveMoveEnded():void {
			if (!sp) return;
			form_sp.visible = true;
			master_setting = model.worldModel.location.physics_setting.clone();
		}
		
		// -----------------------------------------------------------------
		// END IMoveListener funcs
		
		private function onPcAdjustmentsChange(adjustments:Object):void {
			CONFIG::debugging {
				if (model.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('AdminDialogPhysicsPanel.onPcAdjustmentsChange:\n' +
						'\tadjustments:\n' + StringUtil.deepTrace(adjustments) +
						'\tmaster_setting:\n' + StringUtil.deepTrace(master_setting));
				}
			}
			// a little delay here to make sure we go after PhysicsController's handler
			StageBeacon.waitForNextFrame(TSFrontController.instance.applyPhysicsSettingsFromAdminPanel, master_setting);
			informOfAdjustments();
		}
		
		private var adjustments_are_in_play:Boolean;
		private function informOfAdjustments():void {
			adjustments_are_in_play = false;
			var txt:String = '<b>There are no pc adjustments affecting physics right now.</b>';
			var changed_txt:String = '';
			var adjustments:Object = model.physicsModel.pc_adjustments;
			
			for (var i:int; i<parametersV.length; i++) {
				var name:String = parametersV[int(i)].name;
				var type:String = parametersV[int(i)].type;
				
				if (adjustments && name in adjustments) {
					if (type == PhysicsParameter.TYPE_BOOL) {
						changed_txt+= ' * '+name+' set to '+(adjustments[name]=='1'?true:false)+'<br>';
						
					} else {
						if (adjustments[name] != 1) changed_txt+= ' * '+name+' multiplied by '+adjustments[name]+'<br>';
					}
				}
			}
			
			if (changed_txt) {
				if (model.worldModel.location.no_physics_adjustments) {
					txt = '<b>These pc adjustments would be affecting physics right now, but the location has no_physics_adjustments:true, so they are not:</b><br>'+changed_txt;
				} else {
					if (model.physicsModel.ignore_pc_adjustments) {
						txt = '<b>These pc adjustments would be affecting physics right now, but you\'re ignoring them:</b><br>'+changed_txt;
					} else {
						adjustments_are_in_play = true;
						txt = '<font color="#cc0000"><b>These pc adjustments are affecting physics right now:</b><br>'+changed_txt+'</font>';
					}
				}
				
			}
			
			adj_tf.htmlText = '<font face="Arial">'+txt+'<font>';
			adj_tf.width = 300;
			adj_tf.height = adj_tf.textHeight+4;
			values_tf.y = adj_tf.y+adj_tf.height+10;
		}
		
		private function constructPhysicsSettingsButtons():void {
			if (!sp) return;
			var loc_tsid:String = model.worldModel.location.tsid;
			var push_bt:PushButton;

			CONFIG::debugging {
				Console.warn('setting phys to '+loc_tsid);
			}
			
			var settingNamesA:Array = settables.getSettingNames();
			var setting_name:String;
			for (var i:int = settingNamesA.length-1;i>-1;i--) {
				setting_name = settingNamesA[i];
				push_bt = form_sp.getChildByName(setting_name) as PushButton;
				if (!push_bt) {
					push_bt = new PushButton(form_sp, 0, 0, setting_name.toUpperCase(), switchPhysicsSettingsFromButton);
					push_bt.name = setting_name;
					push_bt.width = 90;
					push_bt.height = 14;
					btsV.push(push_bt);
				}
				
				push_bt.y = 16+((settingNamesA.length-1-i)*17);
			}
			
			form_sp.visible = true;
		}
		
		// no param_name, and it resets them all
		private function resetParamFormAndParams(param_name:String = ''):void {
			if (!model.worldModel.pc.apo) return;
			if (!settables) return;
			if (!master_setting) return;
			var setting:PhysicsSetting = settables.getSettingByName(master_setting.name);
			var param:PhysicsParameter;
			var slider:HSlider;
			var label:Label;
			var label2:Label;
			
			for (var i:int=0;i<parametersV.length;i++) {
				param = parametersV[int(i)];
				//Console.dir(param)
				if (param_name && param.name != param_name) continue;
				
				slider = HSlider(form_sp.getChildByName(param.name));
				slider.minimum = param.min;
				slider.maximum = param.max;
				slider.value = setting[param.name];
				
				label = Label(form_sp.getChildByName(param.name+'_label'));
				label.text = param.label+' ['+param.min +' to '+param.max+'] def: '+slider.value+'';
				
				label2 = Label(form_sp.getChildByName(param.name+'_label2'));
				label2.text = formatNumberForPropSliders(slider.value, param.name);
				
				setParamFromSlider(slider);
			}
			
			TSFrontController.instance.applyPhysicsSettingsFromAdminPanel(master_setting);
		}
		
		private function switchPhysicsSettingsFromButton(e:Event):void {
			switchPhysicsSettingsByName(PushButton(e.currentTarget).name);
		}
		
		private function switchPhysicsSettingsByName(n:String):void {
			var setting:PhysicsSetting = settables.getSettingByName(n);
			master_setting = setting.clone();
			resetParamFormAndParams();
			
			var push_bt:PushButton;
			var settingNamesA:Array = settables.getSettingNames();
			var setting_name:String;
			for (var i:int;i<settingNamesA.length;i++) {
				setting_name = settingNamesA[int(i)];
				push_bt = form_sp.getChildByName(setting_name) as PushButton;
				if (push_bt.name == n) {
					push_bt.filters = StaticFilters.black_GlowA;
				} else {
					push_bt.filters = null;
				}
			}
		}
		
		private function formatNumberForPropSliders(n:Number, name:String):String {
			return String(adjustPhysicsValue(n, name));
		}
		
		private function adjustPhysicsValue(n:Number, name:String):Number {
			var param:PhysicsParameter = settables.getParameterByName(name);
			var type:String = (param) ? param.type : PhysicsParameter.TYPE_NUM;
			switch (type) {
				case PhysicsParameter.TYPE_NUM:
					if (parseInt(String(n)) != n) return Number(n.toFixed(3));
					break;
				
				case PhysicsParameter.TYPE_INT:
					return Math.round(n);
					
				case PhysicsParameter.TYPE_BOOL:
					return (n == 0) ? 0 : 1;
			} 
			
			return n;
		}
		
		private function onParamSliderChange(e:Event):void {
			setParamFromSlider(HSlider(e.currentTarget));
			TSFrontController.instance.applyPhysicsSettingsFromAdminPanel(master_setting);
		}
		
		private function setParamFromSlider(slider:HSlider):void {
			master_setting[slider.name] = adjustPhysicsValue(slider.value, slider.name);
			Label(form_sp.getChildByName(slider.name+'_label2')).text = formatNumberForPropSliders(slider.value, slider.name);
		}
		
		private function getCurrentPhysicsForClipboard():String {
			var str:String = '{\r';
			var param:PhysicsParameter;
			var slider:HSlider;
			for (var i:int=0;i<parametersV.length;i++) {
				
				param = parametersV[int(i)];
				slider = HSlider(form_sp.getChildByName(param.name));
				str+= '\t\''+param.name+'\': '+adjustPhysicsValue(slider.value, param.name);
				if (i<parametersV.length-1) str+=',';
				str+= '\r';
			}
			
			return str+'}';
		}
		
		private function getCurrentPhysicsForLocation():Object {
			var ob:Object = {};
			var param:PhysicsParameter;
			var slider:HSlider;
			for (var i:int=0;i<parametersV.length;i++) {
				param = parametersV[int(i)];
				slider = HSlider(form_sp.getChildByName(param.name));
				ob[param.name] = adjustPhysicsValue(slider.value, param.name);
			}
			return ob;
		}
		
		private function saveCurrentPhysicsToLocationConfirmed(value:*):void {
			if (value === true) saveCurrentPhysicsToLocation(null, true);
		}
		
		private function saveCurrentPhysicsToLocation(ee:Event, proceed:Boolean = false):void {
			
			if (adjustments_are_in_play && !proceed) {
				var txt:String = 'To be clear, you currently have physics adjustments in play. These can be from buffs or what have you. '+
					'So before saving, you may want to uncheck the <b>ignore pc physics adjustments</b> checkbox in the physics panel to make sure '+
					'the settings you are saving are what you want.';
				TSFrontController.instance.confirm(new ConfirmationDialogVO(saveCurrentPhysicsToLocationConfirmed, txt, [
					{value: false, label: 'Don\'t Save'},
					{value: true, label: 'Save'}
				], false));
				return;
			}
			
			var amf:Object = model.worldModel.location.AMF();
			var physics:Object = getCurrentPhysicsForLocation();
			
			TSFrontController.instance.saveLocation(amf, physics, function(success:Boolean):void {
				if (success) {
					
					// the save was succeful
					model.activityModel.growl_message = 'PHYSICS SAVED';
					
					// make this permanent locally
					var setting:PhysicsSetting = settables.getSettingByName(model.worldModel.location.tsid);
					if (setting) {
						PhysicsSetting.updateFromAnonymous(physics, setting);
						master_setting = setting.clone();
						switchPhysicsSettingsByName(model.worldModel.location.tsid);
						
						// update the physics too
						model.worldModel.physics_obs[model.worldModel.location.tsid] = physics;
					} else {
						CONFIG::debugging {
							Console.error('wtf');
						}
					}
				} else {
					// revert ?
				}
			});
		}
	}
}