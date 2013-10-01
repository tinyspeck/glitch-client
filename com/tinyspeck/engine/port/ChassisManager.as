package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.FurnUpgradeController;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.data.house.ConfigOption;
	import com.tinyspeck.engine.data.itemstack.SpecialConfig;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingFurnitureSetUserConfigVO;
	import com.tinyspeck.engine.net.NetOutgoingTowerSetNameVO;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ChassisPickerUI;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.ConfiggerUI;
	
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;

	public class ChassisManager implements IFocusableComponent, IMoveListener, IRefreshListener {
		/* singleton boilerplate */
		public static const instance:ChassisManager = new ChassisManager();
		
		public static const WIDTH_OF_CONFIG_UI:uint = 190;
		
		private var inited:Boolean;
		private var dm:DecorateModel;
		private var wm:WorldModel;
		private var model:TSModelLocator;
		private var picker_ui:ChassisPickerUI;
		private var configger_ui:ConfiggerUI;
		private var fuc:FurnUpgradeController;
		private var cancelling_cdVO:ConfirmationDialogVO;
		private var credits_cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
		private var itemstack_pt:Point = new Point();
		private var was_vp_scale:Number;
		private var was_chassis_x:Number;
		
		public function ChassisManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init():void {
			if (inited) return;
			inited = true;
			model = TSModelLocator.instance;
			wm = model.worldModel;
			dm = model.decorateModel;
			registerSelfAsFocusableComponent();
			fuc = new FurnUpgradeController();
			picker_ui = new ChassisPickerUI();
			picker_ui.init(fuc);
			configger_ui = new ConfiggerUI(WIDTH_OF_CONFIG_UI, false);
			configger_ui.change_config_sig.add(changeConfigOptions);
			configger_ui.change_direction_sig.add(changeDirection);
			configger_ui.randomize_sig.add(showRandomConfig);
			configger_ui.namer_sig.add(onNamerButtonClick);
			TSFrontController.instance.registerMoveListener(this);
			
			//confirm dialog
			cancelling_cdVO = new ConfirmationDialogVO();
			cancelling_cdVO.title = 'Save Your Changes?';
			cancelling_cdVO.txt = "You\'re cancelling, but I am thinking maybe you meant to save your changes first?";
			cancelling_cdVO.choices = [
				{value: true, label: 'Yes, Save!'},
				{value: false, label: 'No, Discard'}
			];
			cancelling_cdVO.escape_value = false;
			cancelling_cdVO.callback =	onConfirm;
			
			// confirm credits spend dialog
			credits_cdVO.title = 'You\'re spending credits...'
			credits_cdVO.escape_value = false;
			credits_cdVO.callback = onConfirmCreditsSpend;
			credits_cdVO.choices = [
				{value: false, label: 'No, let me think about it'},
				{value: true, label: 'Yes, I want it!'}
			];
		}
		
		public function start():Boolean {
			
			/*
			if (!wm.pc.home_info || !wm.location.tsid == wm.pc.home_info.exterior_tsid) {
				return;
			}
			*/
			
			if (!setConfigChoices()) {
				return false;
			}
			
			// remember what is was so we can discard changes!
			dm.was_config = ObjectUtil.copyOb(dm.upgrade_itemstack.itemstack_state.furn_config.config) || {};
			dm.has_chassis_changed = false;
			dm.has_config_changed = false;
			dm.has_name_changed = false;
			dm.was_name = '';
			
			var sconfig:SpecialConfig = dm.upgrade_itemstack.itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_TOWER_SIGN);
			if (sconfig) {
				dm.was_name = sconfig.label;
			}
			
			// before we start the picker, so that the button show the current config,
			// set the config on the current upgrade to what the user has it set to
			for (var i:int;i<dm.upgradesV.length;i++) {
				if (dm.upgradesV[i].id == dm.upgrade_itemstack.furn_upgrade_id) {
					dm.upgradesV[i].furniture.config = ObjectUtil.copyOb(dm.was_config);
					break;
				}
			}
			
			const dont_show_picker_choices:Boolean = !model.flashVarModel.more_towers && (dm.upgrade_itemstack.class_tsid == 'furniture_tower_chassis');
			
			if (dm.upgrade_itemstack.class_tsid == 'furniture_tower_chassis') {
				YouDisplayManager.instance.chassis_toolbar.setText('You are in Tower Changing Mode');
			} else {
				YouDisplayManager.instance.chassis_toolbar.setText('You are in House Changing Mode');
			}
			
			if (!picker_ui.start()) {
				return false;
			}
			
			if (dont_show_picker_choices) {
				picker_ui.showNameUI();
			} else {
				picker_ui.hideNameUI();
				configger_ui.enableNamerBt();
			}
			
			if (!TSFrontController.instance.requestFocus(this)) {
				return false;
			}
			
			// reset
			picker_ui.setButtonToCorrectState();
			
			//hide the pack
			PackDisplayManager.instance.changeVisibility(false, 'ChassisManager');
			
			// add the picker
			TSFrontController.instance.getMainView().main_container.addChildAt(picker_ui, 0);
			
			// add the configger
			TSFrontController.instance.getMainView().addView(configger_ui, true);
			
			//listen to the refreshings
			TSFrontController.instance.registerRefreshListener(this);
			
			was_vp_scale = model.layoutModel.loc_vp_scale;
			
			// move it over temporarily
			was_chassis_x = dm.upgrade_itemstack.x; // turn out we don't really need this, since ending custom mode slides it back over to where it shoudl be
			if (dm.upgrade_itemstack.x) {
				var lis:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(dm.upgrade_itemstack.tsid)
				lis.x = Math.max(lis.x, model.worldModel.location.l+400);
			}
			
			refresh();
			
			last_h_needed = 0;
			scaleVP(true);
			
			TSFrontController.instance.getMainView().gameRenderer.locationView.middleGroundRenderer.hidePCs();
			TSFrontController.instance.changeMiniMapVisibility();
			
			return true;
		}
		
		private var scale_tim:uint;
		private var last_h_needed:uint;
		private function scaleVP(proceed:Boolean=false):void {
			// avoid a race condition where you leave chassis mode while it's
			// loading (pressing escape really quickly while zooming out)
			if ((dm.upgrade_itemstack == null) || !hasFocus()) return;
			
			StageBeacon.clearTimeout(scale_tim);
			if (!proceed) {
				scale_tim = StageBeacon.setTimeout(scaleVP, 200, true);
				return;
			}
			
			var offset:int = 135;
			var avail_w:int = model.layoutModel.loc_vp_w-ChassisManager.WIDTH_OF_CONFIG_UI;
			
			// area that allows the tallest and widest chassis
			var w_needed:int = 540;
			var h_needed:int = 720;
			if (dm.upgrade_itemstack.class_tsid == 'furniture_tower_chassis') {
				offset = 100;
				const swf_data:SWFData = ItemSSManager.getSWFDataByUrl(dm.upgrade_itemstack.swf_url);
				var bottom_floor_h:int = 150;
				if (swf_data && swf_data.mc && swf_data.mc.hasOwnProperty('bottom_floor_h')) {
					bottom_floor_h = swf_data.mc.bottom_floor_h || bottom_floor_h;
				}
				var floor_h:int = 66;
				if (swf_data && swf_data.mc && swf_data.mc.hasOwnProperty('floor_h')) {
					floor_h = swf_data.mc.floor_h || floor_h;
				}
				w_needed = 300;
				var extra_floors:int = dm.upgrade_itemstack.itemstack_state.config_for_swf.extra_floors;
				h_needed = (floor_h*extra_floors)+(2*bottom_floor_h)+100;
				
				if (last_h_needed > h_needed) {
					return;
				}
				
				last_h_needed = h_needed;
			}
			
			CONFIG::debugging {
				Console.info('w_needed:'+w_needed+' h_needed:'+h_needed+' floor_h:'+floor_h+' bottom_floor_h:'+bottom_floor_h)
			}
			
			var needed_scale_for_w:Number = (avail_w)/w_needed;
			var needed_scale_for_h:Number = model.layoutModel.loc_vp_h/h_needed;
			
			// choose the smallest one
			var try_scale:Number = Math.min(1, Math.min(needed_scale_for_h, needed_scale_for_w));
			
			var scale:Number = TSFrontController.instance.setViewportScale(try_scale, 1, false, true);
			//Console.info('needed_scale_for_w:'+needed_scale_for_w+' needed_scale_for_h:'+needed_scale_for_h+' try_scale:'+try_scale+' scale:'+scale);
			
			// center the camera x on the vp minus ChassisManager.WIDTH_OF_CONFIG_UI
			itemstack_pt.x = dm.upgrade_itemstack.x-((ChassisManager.WIDTH_OF_CONFIG_UI/2)*(1/scale));
			
			// center the camera where the full height of the tallest chassis is visible
			itemstack_pt.y = dm.upgrade_itemstack.y-(offset*(1/scale));
			
			TSFrontController.instance.setCameraCenter(null, null, itemstack_pt, 0, true);
		}
		
		private function setConfigChoices():Boolean {
			if (!ConfigOption.populateConfigChoicesForItemstack(dm.upgrade_itemstack, dm.chassis_config_options, dm.upgrade_itemstack.itemstack_state.furn_config.config)) {
				return false;
			}
			
			var show_namer:Boolean = (model.flashVarModel.more_towers && dm.upgrade_itemstack.class_tsid == 'furniture_tower_chassis');
			configger_ui.startWithConfigs(dm.chassis_config_options, dm.upgrade_itemstack.itemstack_state.furn_config.facing_right, true, show_namer);
			refresh();
			return true;
		}
		
		// called by ChassisPicker
		public function onChassisSaved():void {
			TSFrontController.instance.stopChassisMode();
		}
		
		// called by ChassisPicker
		public function closeAndDiscard():void {
			if (dm.has_name_changed) {
				updateTowerSign(dm.was_name);
			}
			
			// make sure we flip the tower sign back
			changeDirectionOnLocalItemstackTowerSign(dm.was_furn_config.facing_right);
			wm.loc_itemstack_updates = [dm.upgrade_itemstack.tsid]; // calls a trigger when set
			
			if (dm.has_config_changed) {
				changeConfigOnLocalItemstack(dm.was_config);
			}
			
			fuc.cancel();
			TSFrontController.instance.stopChassisMode();
		}
		
		// called by ChassisPicker, TowerNameUI
		public function save(confirmed:Boolean=false):void {
			if (picker_ui.save_bt.disabled) return;
			
			if (!confirmed) {
				confirmCreditsSpend();
				picker_ui.save_bt.disabled = true;
				return;
			}
			
			picker_ui.save_bt.disabled = true;
			
			if (dm.has_chassis_changed) {
				// call back will be to picker_ui.onSave
				fuc.save();
			} else {
				// must just be config changes, so save and close!
				saveConfigAndClose();
			}
			
			if (dm.has_name_changed) {
				//do the stuff to tell the server of the tower name
				TSFrontController.instance.genericSend(
					new NetOutgoingTowerSetNameVO(dm.upgrade_itemstack.tsid, picker_ui.tower_name_ui.input_field.text)
				);
			}
		}
		
		private function confirmCreditsSpend():void {
			if(dm.chosen_upgrade.credits && !dm.chosen_upgrade.is_owned){
				//we need to confirm the credits purchase!
				
				credits_cdVO.txt = 'That\'ll be <b>'+StringUtil.formatNumberWithCommas(dm.chosen_upgrade.credits)+' '+
					(dm.chosen_upgrade.credits != 1 ? 'credits' : 'credit')+'</b> for this change. ' +
					'Is that ok? (It definitely seems worth it … looks great on your street!)';
				
				TSFrontController.instance.confirm(credits_cdVO);
			}
			else {
				//no credits, just save it
				onConfirmCreditsSpend(true);
			}
		}
		
		private function onConfirmCreditsSpend(is_save:Boolean):void {
			picker_ui.setButtonToCorrectState();
			
			if(is_save){
				ChassisManager.instance.save(true);
			}
		}
		
		//forces it to refresh, for when you have hove chosen a new
		
		public function updateTowerSign(txt:String):void {
			var sconfig:SpecialConfig = dm.upgrade_itemstack.itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_TOWER_SIGN);
			if (sconfig) {
				sconfig.label = txt;
				sconfig.is_dirty = true;
			}
			
			sconfig = dm.upgrade_itemstack.itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_TOWER_SCAFFOLDING);
			if (sconfig) {
				if (sconfig.no_display && txt) {
					sconfig.no_display = false;
					sconfig.is_dirty = true;
				} else if (!sconfig.no_display && !txt) {
					sconfig.no_display = true;
					sconfig.is_dirty = true;
				}
			}
			
			TSModelLocator.instance.worldModel.loc_itemstack_updates = [dm.upgrade_itemstack.tsid]; // calls a trigger when set
		}
		
		// called by ChassisPicker
		public function onChassisChange():void {
			setConfigChoices();
			picker_ui.setButtonToCorrectState();
			if (dm.upgrade_itemstack && dm.upgrade_itemstack.class_tsid == 'furniture_tower_chassis') {
				dm.upgrade_itemstack.itemstack_state.markAllSpecialConfigsDirty()
			}
		}
		
		public function changeDirection(dir:String):void {
			dm.has_config_changed = true;
			picker_ui.setButtonToCorrectState();
			
			if (dm.upgrade_itemstack.itemstack_state.furn_config) {
				dm.user_facing_right = (dir == 'right');
				changeDirectionOnLocalItemstack(dm.user_facing_right);
			} else {
				CONFIG::debugging {
					Console.error('no dm.furn_stack.itemstack_state.furn_config???');
				}
			}
		}
		
		// called by ChassisConfiggerUI
		public function changeConfigOptions(option_names:Array, option_values:Array):void {
			dm.has_config_changed = true;
			picker_ui.setButtonToCorrectState();
			
			var option_name:String;
			var option_value:String;
			
			// set it
			if (dm.upgrade_itemstack.itemstack_state.furn_config) {
				var actual_config:Object = ObjectUtil.copyOb(dm.upgrade_itemstack.itemstack_state.furn_config.config) || {};
				
				for (var i:int=0;i<option_names.length;i++) {
					if (i > option_values.length-1) break;
					option_name = option_names[i];
					option_value = option_values[i];
					actual_config[option_name] = option_value;
				}
				
				// change this value!
				
				changeConfigOnLocalItemstack(actual_config);
				
				// set the config on the current upgrade to what the user has it set to
				if (dm.chosen_upgrade) {
					dm.chosen_upgrade.furniture.config = actual_config;
				}
			} else {
				CONFIG::debugging {
					Console.error('no dm.furn_stack.itemstack_state.furn_config???');
				}
			}
		}
		
		private function saveConfigAndClose():void {
			if (dm.has_config_changed) {
				TSFrontController.instance.genericSend(
					new NetOutgoingFurnitureSetUserConfigVO(
						dm.upgrade_itemstack.tsid,
						dm.chosen_upgrade.furniture.config,
						dm.user_facing_right
					)
				);
			}
			
			TSFrontController.instance.stopChassisMode();
		}
		
		private function changeConfigOnLocalItemstack(c:Object):void {
			dm.upgrade_itemstack.itemstack_state.furn_config.is_dirty = true;
			dm.upgrade_itemstack.itemstack_state.furn_config.config = c;
			dm.upgrade_itemstack.itemstack_state.is_config_dirty = true;
			wm.loc_itemstack_updates = [dm.upgrade_itemstack.tsid]; // calls a trigger when set
		}
		
		private function changeDirectionOnLocalItemstackTowerSign(facing_right:Boolean):void {
			var sconfig:SpecialConfig = dm.upgrade_itemstack.itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_TOWER_SIGN);
			if (sconfig) {
				sconfig.h_flipped = !facing_right;
				sconfig.is_dirty = true;
			}
			
			sconfig = dm.upgrade_itemstack.itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_TOWER_SCAFFOLDING);
			if (sconfig) {
				sconfig.h_flipped = !facing_right;
				sconfig.is_dirty = true;
			}
		}
		
		private function changeDirectionOnLocalItemstack(facing_right:Boolean):void {
			// handle the tower sign
			changeDirectionOnLocalItemstackTowerSign(facing_right);
			
			dm.upgrade_itemstack.itemstack_state.furn_config.facing_right = facing_right;
			dm.upgrade_itemstack.itemstack_state.furn_config.is_dirty = true;
			dm.upgrade_itemstack.itemstack_state.is_config_dirty = true;
			wm.loc_itemstack_updates = [dm.upgrade_itemstack.tsid]; // calls a trigger when set
		}
		
		private function showRandomConfig():void {
			showRandomHouse(false);
		}
		
		public function doneWithNaming():void {
			picker_ui.hideNameUI();
			configger_ui.enableNamerBt();
		}
		
		private function onNamerButtonClick():void {
			picker_ui.showNameUI(true);
			configger_ui.disableNamerBt();
		}
		
		public function showRandomHouse(new_chassis:Boolean, ms:int = 0):void {
			if (!model.stateModel.chassis_mode) {
				return;
			}
			
			if (random_house_cycle_interv) {
				StageBeacon.clearInterval(random_house_cycle_interv);
				random_house_cycle_interv = 0;
			} else {
				randomHouse(new_chassis);
			}
			
			if (ms) {
				random_house_cycle_interv = StageBeacon.setInterval(ChassisManager.instance.randomHouse, ms, new_chassis);
			}
		}
		
		private var random_house_cycle_interv:uint = 0;
		private function randomHouse(new_chassis:Boolean):void {
			if (!model.stateModel.chassis_mode) {
				return;
			}
			
			if (new_chassis) {
				var chassis_index:int = MathUtil.randomInt(0, dm.upgradesV.length-1);
				var upgrade:FurnUpgrade = dm.upgradesV[chassis_index];
				picker_ui.setChosenUpgrade(upgrade);
			}
			
			var random_i:int;
			var option:ConfigOption;
			var option_names:Array = [];
			var option_values:Array = [];
			
			// choose some random options
			for(var i:int=0; i<dm.chassis_config_options.length; i++){
				option = dm.chassis_config_options[int(i)];
				if (!option.choices || !option.choices.length) continue;
				random_i = MathUtil.randomInt(0, option.choices.length-1);
				option_names.push(option.id);
				option_values.push(option.choices[random_i]);
			}
			
			changeConfigOptions(option_names, option_values);
			setConfigChoices();
		}
		
		public function refresh():void {
			if (!inited) return;
			scaleVP();
			configger_ui.refresh();
			configger_ui.x = model.layoutModel.gutter_w;
			configger_ui.y = model.layoutModel.header_h+model.layoutModel.loc_vp_h-configger_ui.height;
			picker_ui.y = model.layoutModel.loc_vp_h;
			picker_ui.refresh();
		}
		
		// ONLY EVER TO BE CALLED FROM TSFC.setChassisMode (use TSFC.stopChassisMode() to end this properly)
		public function end():void {
			TSFrontController.instance.setViewportScale(was_vp_scale, 1, false, true);
			dm.upgrade_itemstack = null;
			picker_ui.end();
			configger_ui.end();
			PackDisplayManager.instance.changeVisibility(true, 'ChassisManager');
			if (configger_ui.parent) configger_ui.parent.removeChild(configger_ui);
			if (picker_ui.parent) picker_ui.parent.removeChild(picker_ui);
			TSFrontController.instance.releaseFocus(this, 'ended');
			TSFrontController.instance.resetCameraCenter();
			TSFrontController.instance.getMainView().gameRenderer.locationView.middleGroundRenderer.showPCs();
			TSFrontController.instance.furnitureUpgradeEnded();
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			if (random_house_cycle_interv) {
				StageBeacon.clearInterval(random_house_cycle_interv);
				random_house_cycle_interv = 0;
			}
			
			StageBeacon.setTimeout(TSFrontController.instance.saveHomeImg, 2000);
		}
		
		
		
		////////////////////////////////////////////////////////////////////////////////
		//////// FOCUS /////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		private var has_focus:Boolean;
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			//
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function blur():void {
			has_focus = false;
			
			// this means we're dragging, so let's keep listening
			if (!(model.stateModel.about_to_be_focused_component is Cursor)) {
				stopListeningForControlEvts();
			}
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			has_focus = true;

			startListeningForControlEvts();
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// Handlers //////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		private function escKeyHandler(e:KeyboardEvent):void {
			if (model.flashVarModel.more_towers && picker_ui.showing_name_ui) {
				picker_ui.tower_name_ui.revert();
				return
			}
			
			closeFromUserInput();
		}
		
		private function enterKeyHandler(e:KeyboardEvent):void {
			save();
		}
		
		public function closeFromUserInput():void {
			if (picker_ui.save_bt.disabled) {
				closeAndDiscard();
			} else {
				//confirm if they want to save or not
				TSFrontController.instance.confirm(cancelling_cdVO);
			}
		}
		
		private function onConfirm(is_yes:Boolean):void {
			if(is_yes && !picker_ui.save_bt.disabled){
				// the user has said they want to save
				save();
			}
			else {
				// the user has said they do not want to save
				closeAndDiscard();
			}
		}
		
		private function startListeningForControlEvts():void {
			//StageBeacon.instance.addEnterHandler(onEnterFrame, this);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			
			TSFrontController.instance.startListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function stopListeningForControlEvts():void {
			//StageBeacon.instance.removeEnterHandler(onEnterFrame, this);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			
			TSFrontController.instance.stopListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function zoomKeyHandler(e:KeyboardEvent):void {
			// it's important that we don't add shared listeners directly to TSFC
			// because where one class has started listening, another might
			// remove the same listener by accident, so the first class fails
			TSFrontController.instance.zoomKeyHandler(e);
		}

		////////////////////////////////////////////////////////////////////////////////
		//////// IMoveListener /////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function moveLocationHasChanged():void {
			//
		}
		
		public function moveLocationAssetsAreReady():void {
			//
		}
		
		public function moveMoveStarted():void {
			if (dm.upgrade_itemstack && model.stateModel.isCompInFocusHistory(this)) {
				closeAndDiscard();
			}
		}
		
		public function moveMoveEnded():void {
		}
	}
}