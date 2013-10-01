package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.loading.LoadingInfo;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.pack.PackTabberUI;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.FamiliarDialog;
	import com.tinyspeck.engine.port.HouseManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.ChassisToolbarUI;
	import com.tinyspeck.engine.view.ui.CultToolbarUI;
	import com.tinyspeck.engine.view.ui.chrome.GameHeaderUI;
	import com.tinyspeck.engine.view.ui.chrome.InfoToolbarUI;
	import com.tinyspeck.engine.view.ui.chrome.PlayerInfoUI;
	import com.tinyspeck.engine.view.ui.decorate.DecorateToolbarUI;
	import com.tinyspeck.engine.view.ui.map.CurrentLocationUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	CONFIG::god { import com.tinyspeck.engine.view.ui.HOGToolbarUI; }
	CONFIG::perf { import com.tinyspeck.engine.perf.PerfTestToolbarUI; }
	
	public class YouDisplayManager extends Sprite implements IMoveListener {
		
		/* singleton boilerplate */
		public static const instance:YouDisplayManager = new YouDisplayManager();
		
		private static const CURRANTS_REG_ALPHA:Number = .3;
		private static const CURRANTS_HOVER_ALPHA:Number = 1;
		
		private var currants_tf:TextField = new TextField();
		private var key_cmds_tf:TextField = new TextField();
		
		private var currants_icon:DisplayObject;
		private var things_to_leave_alone_visibility_wise:Vector.<DisplayObject> = new Vector.<DisplayObject>();
		
		private var currants_holder:Sprite = new Sprite();
		public var dec_cult_bt_holder:Sprite;
		
		private var currants_timer:Timer = new Timer(PlayerInfoUI.TIMER_DELAY);
		
		private var decorate_bt_pt:Point = new Point();
		private var decorate_bt_local_pt:Point = new Point();
		private var tabber_local_pt:Point = new Point();
		private var tabber_global_pt:Point = new Point();
		
		public var decorate_toolbar:DecorateToolbarUI;
		public var pack_tabber:PackTabberUI = new PackTabberUI();
		private var model:TSModelLocator;
		private var player_info:PlayerInfoUI = new PlayerInfoUI();
		private var game_header:GameHeaderUI = new GameHeaderUI();
		private var current_location:CurrentLocationUI = new CurrentLocationUI();
		private var decorate_bt:Button;
		private var cultivate_bt:Button;
		public var chassis_toolbar:ChassisToolbarUI;
		private var cult_toolbar:CultToolbarUI;
		private var info_toolbar:InfoToolbarUI;
		CONFIG::god private var hog_toolbar:HOGToolbarUI;
		
		private var displayed_currants:int;
		private var steps_currants:int;
		private var _w:int;
		private var _h:int;
		
		private var _inited:Boolean;
		private var _is_currants_hidden:Boolean;
		
		public function YouDisplayManager():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			addEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
			
			_h = 23;
		}
		
		public function init():void {
			model = TSModelLocator.instance;
			_inited = true;
			
			construct();
			
			model.worldModel.registerCBProp(pcStatsChangedHandler, "pc", "stats");
			model.stateModel.registerCBProp(onDecorateModeChange, "decorator_mode");
			model.stateModel.registerCBProp(onChassisModeChange, "chassis_mode");
			model.stateModel.registerCBProp(onCultModeChange, "cult_mode");
			model.stateModel.registerCBProp(onInfoModeChange, "info_mode");
			CONFIG::god {
				model.stateModel.registerCBProp(onHODChange, "hand_of_god");
				model.stateModel.registerCBProp(onEditingChange, "editing");
			}
			TSFrontController.instance.registerMoveListener(this);
		}
		
		protected function construct():void {			
			//currants
			currants_icon = new AssetManager.instance.assets.currants_icon();
			currants_holder.addChild(currants_icon);
			
			TFUtil.prepTF(currants_tf);
			currants_tf.wordWrap = false; //autosize for multiline
			currants_holder.addChild(currants_tf);
			addChild(currants_holder);
			
			currants_holder.x = int(-currants_icon.width/2 - 2);
			currants_holder.addEventListener(MouseEvent.ROLL_OVER, onCurrantsMouse, false, 0, true);
			currants_holder.addEventListener(MouseEvent.ROLL_OUT, onCurrantsMouse, false, 0, true);
			currants_tf.x = currants_icon.width + 5;
			currants_tf.y = 2;
			currants_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.8}, StaticFilters.black1px90Degrees_DropShadowA);
			currants_tf.alpha = CURRANTS_REG_ALPHA;
			
			//pack controls
			pack_tabber;
			pack_tabber.x = 4;
			addChild(pack_tabber);
			pack_tabber.visible = false;
			things_to_leave_alone_visibility_wise.push(pack_tabber);
			
			//admin keys
			TFUtil.prepTF(key_cmds_tf, false);
			key_cmds_tf.filters = StaticFilters.youDisplayManager_DropShadowA;
			key_cmds_tf.background = true;
			key_cmds_tf.backgroundColor = 0xc3c3c3;
			key_cmds_tf.visible = false;
			
			//hide the admin keys
			updateKeyCmdsTf();
			
			//player drop down
			player_info.show();
			addChild(player_info);
			
			//game header
			game_header.show();
			addChild(game_header);
			things_to_leave_alone_visibility_wise.push(game_header);
			
			//our current location
			addChild(current_location);
			things_to_leave_alone_visibility_wise.push(current_location);
			
			//currants change timer
			currants_timer.addEventListener(TimerEvent.TIMER, onCurrantsTimerTick, false, 0, true);
			
			dec_cult_bt_holder = new Sprite();
			dec_cult_bt_holder.visible = false;
			dec_cult_bt_holder.y = int(model.layoutModel.header_h/2 - 14);
			addChild(dec_cult_bt_holder);
			things_to_leave_alone_visibility_wise.push(dec_cult_bt_holder);
			
			//create the decorator button
			decorate_bt = new Button({
				name: 'decorate',
				label: 'Decorate',
				size: Button.SIZE_TINY,
				type: Button.TYPE_DECORATE,
				graphic: new AssetManager.instance.assets.decorate_icon(),
				graphic_placement: 'left',
				graphic_padd_l: 10,
				graphic_padd_r: 2,
				graphic_alpha: .7,
				focused_graphic_alpha: .9,
				label_size: 13,
				h: 27
			});
			decorate_bt.addEventListener(TSEvent.CHANGED, onDecorateClick, false, 0, true);
			dec_cult_bt_holder.addChild(decorate_bt);
			
			//decorate toolbar
			decorate_toolbar = new DecorateToolbarUI();
			decorate_toolbar.y = int(model.layoutModel.header_h/2 - decorate_toolbar.height/2);
			things_to_leave_alone_visibility_wise.push(decorate_toolbar);
			
			//create the cultivate button
			cultivate_bt = new Button({
				name: 'cultivate',
				label: 'Cultivate',
				size: Button.SIZE_TINY,
				type: Button.TYPE_DECORATE,
				graphic: new AssetManager.instance.assets.street_cultivate(),
				graphic_placement: 'left',
				graphic_padd_l: 10,
				graphic_padd_r: 2,
				graphic_alpha: .7,
				focused_graphic_alpha: .9,
				label_size: 13,
				h: 27
			});
			cultivate_bt.addEventListener(TSEvent.CHANGED, onCultivateClick, false, 0, true);
			dec_cult_bt_holder.addChild(cultivate_bt);
			
			//cult toolbar
			cult_toolbar = new CultToolbarUI();
			cult_toolbar.y = int(model.layoutModel.header_h/2 - cult_toolbar.height/2);
			things_to_leave_alone_visibility_wise.push(cult_toolbar);
			
			chassis_toolbar = new ChassisToolbarUI();
			chassis_toolbar.y = int(model.layoutModel.header_h/2 - chassis_toolbar.height/2);
			things_to_leave_alone_visibility_wise.push(chassis_toolbar);
			
			//info toolbar
			info_toolbar = new InfoToolbarUI();
			things_to_leave_alone_visibility_wise.push(info_toolbar);
			
			CONFIG::god {
				hog_toolbar = new HOGToolbarUI();
				hog_toolbar.y = int(model.layoutModel.header_h/2 - hog_toolbar.height/2);
				addChild(hog_toolbar);
				things_to_leave_alone_visibility_wise.push(hog_toolbar);
			}
			
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					PerfTestToolbarUI.instance.x = PerfTestToolbarUI.instance.width/2;
					PerfTestToolbarUI.instance.y = int(model.layoutModel.header_h/2 - PerfTestToolbarUI.instance.height/2);
					addChild(PerfTestToolbarUI.instance);
					things_to_leave_alone_visibility_wise.push(PerfTestToolbarUI.instance);
				}
			}
			
			//fire the change handler
			const pc:PC = model.worldModel.pc;
			if(pc && pc.stats) pcStatsChangedHandler(pc.stats);
			
			refresh();
		}
		
		public function updateNewQuestCount():void {
			player_info.quest_count = QuestManager.instance.getUnacceptedQuests().length;
		}
		
		public function updatePCName(pc_tsid:String):void {
			//update your own name
			player_info.updatePCName();
			
			//update any labels in the chat area
			RightSideManager.instance.right_view.chatsUpdate();
			
			//are we in a pol owned by this tsid?
			if(pc_tsid){
				const loc:Location = model.worldModel.location;
				const loading_info:LoadingInfo = model.moveModel.loading_info;
				const pc:PC = model.worldModel.getPCByTsid(pc_tsid);
				
				if(loading_info.owner_tsid == pc_tsid){
					var loc_label:String = StringUtil.nameApostrophe(pc.label)+' ';
					
					if(loc.label.substr(-5) == 'Tower'){
						loc_label += 'Tower';
					}
					else if(loc.label.substr(-5) == 'House'){
						loc_label += 'House';
					}
					else if(loc.label.substr(-6) == 'Street'){
						loc_label += 'Home Street';
					}
					
					//update the name
					loc.label = loc_label;
						
					//update our location
					current_location.show();
					showHideCurrentLocation();
					
					//[sy] TODO: Allow the tooltips on the doors to tower/house to change with the change in player name
				}
			}
		}
		
		public function updateAvatarSS():void {
			player_info.addAvatar();
		}
		
		public function getImaginationCenterPt():Point {
			return player_info.imagination_center_pt;
		}
		
		public function getEnergyGaugeCenterPt():Point {
			return player_info.energy_center_pt;
		}
		
		public function getMoodGaugeCenterPt():Point {
			return player_info.mood_center_pt;
		}
		
		public function getHeaderCenterPt():Point {
			const lm:LayoutModel = model.layoutModel;
			return new Point(lm.gutter_w + lm.loc_vp_w/2, lm.header_h);
		}
		
		public function getFaceBasePt():Point {
			return player_info.player_face_pt;
		}
		
		public function getTimeBasePt():Point {
			return game_header.getDateTimeCenterPt();
		}
		
		public function getVolumeControlBasePt():Point {
			return game_header.getVolumeCenterPt();
		}
		
		public function getHelpIconCenterPt():Point {
			return game_header.getHelpIconCenterPt();
		}
		
		public function getCurrantsCenterPt():Point {
			return currants_holder.localToGlobal(new Point(currants_holder.width + 3, currants_holder.height/2 - 8));
		}
		
		public function getToolbarCloseButtonBasePt():Point {
			if(decorate_toolbar && decorate_toolbar.parent) {
				return decorate_toolbar.getCloseButtonBasePt();
			}
			else if(cult_toolbar && cult_toolbar.parent){
				return cult_toolbar.getCloseButtonBasePt();
			}
			else if(info_toolbar && info_toolbar.parent){
				return info_toolbar.getCloseButtonBasePt();
			}
			else {
				//not built yet, this is just a pre-caution, should never happen
				return new Point();
			}
		}
		
		public function getDecorateButtonBasePt():Point {
			if(decorate_bt && showing_cult_or_deco == 'deco') {
				decorate_bt_local_pt.x = decorate_bt.x + decorate_bt.width/2;
				decorate_bt_local_pt.y = decorate_bt.y + decorate_bt.height;
			}
			else if(cultivate_bt) {
				decorate_bt_local_pt.x = cultivate_bt.x + cultivate_bt.width/2;
				decorate_bt_local_pt.y = cultivate_bt.y + cultivate_bt.height;
			}
			else {
				//not built yet, this is just a pre-caution, should never happen
				return decorate_bt_pt;
			}
			
			decorate_bt_pt = dec_cult_bt_holder.localToGlobal(decorate_bt_local_pt);
			return decorate_bt_pt;
		}
		
		public function getPackTabberCenterPt(tab_name:String):Point {
			//gets a point that's the width of the current displayed pack tabs
			const tab_holder:Sprite = pack_tabber.getTabByName(tab_name);
			if(tab_holder){
				tabber_local_pt.x = int(tab_holder.x + tab_holder.width/2);
				tabber_local_pt.y = int(tab_holder.y + tab_holder.height/2);
				tabber_global_pt = pack_tabber.localToGlobal(tabber_local_pt);
			}
			return tabber_global_pt;
		}
		
		public function getImaginationButtonBasePt():Point {
			return player_info.getImaginationButtonBasePt();
		}
		
		protected function _addedToStageHandler(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
			refresh();
		}
		
		private function pcStatsChangedHandler(stats:PCStats):void {
			player_info.energy = stats.energy.value;
			player_info.mood = stats.mood.value;
			player_info.imagination = stats.imagination;
			player_info.level = stats.level;
			player_info.currants = stats.currants;
		}

		//TODO remove this someday and guard against it elsewhere?
		public function changeTeleportDialogVisibility():void {
			if (!model) return;
			if (!model.worldModel) return;
			if (!model.worldModel.location) return;
			
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					FamiliarDialog.instance.visible = false;
					refresh();
					return;
				}
			}
			
			//TODO awful, but we don't have anywhere else to handle it ATM
			const isVisible:Boolean =
				   (!model.moveModel.moving 
				&& (model.worldModel.location.show_familiar || model.stateModel.showing_greeter_conv || model.stateModel.fam_dialog_open)
				&& (!model.rookModel.rooked_status || (model.rookModel.rooked_status && !model.rookModel.rooked_status.epicentre))
				&& !model.stateModel.editing
				&& !model.stateModel.hand_of_god
				&& !AchievementView.instance.parent
				&& !model.stateModel.decorator_mode
				&& !model.stateModel.chassis_mode
				&& !model.stateModel.info_mode
				&& !model.stateModel.cult_mode);
			
			FamiliarDialog.instance.visible = isVisible;
			refresh();
		}
		
		public function changePackTab(is_furniture:Boolean):void {
			if(!pack_tabber) return;
			if(is_furniture){
				pack_tabber.furnitureShowing();
			}
			else {
				pack_tabber.packShowing();
			}
		}
		
		public function updateKeyCmdsTf(str:String = ''):void {
			if (!model.flashVarModel.do_single_interaction_sp_keys) return;
			if (!key_cmds_tf) return;
			str = StringUtil.trim(str);
			key_cmds_tf.visible = !(str.length == 0);
			key_cmds_tf.htmlText = '<span class="context_verb_desc">'+str+'</span>';
			
			refresh();
		}
		
		public function refresh():void {
			if (!_inited) return;
			_w = 380;
			const lm:LayoutModel = model.layoutModel;
			
			x = lm.gutter_w;
			
			if (model.flashVarModel.do_single_interaction_sp_keys) {
				addChild(key_cmds_tf)
				key_cmds_tf.x = int(lm.loc_vp_w - key_cmds_tf.width - 10);
				key_cmds_tf.y = int(lm.loc_vp_h-key_cmds_tf.height + lm.header_h - 10);
			}
			
			//place the currents holder
			currants_holder.y = lm.header_h + lm.loc_vp_h - currants_icon.height - 36;
			
			//place the current location
			current_location.x = int(lm.loc_vp_w - current_location.width);
			current_location.y = int(lm.header_h/2 - current_location.height/2);
			
			//makes sure that anything else is at least 10px from this
			lm.header_bt_x = current_location.visible ? (current_location.x - (current_location.width ? 10 : 0)) : lm.loc_vp_w;
			
			//decorate button
			if(decorate_bt && cultivate_bt){
				dec_cult_bt_holder.x = int(lm.header_bt_x - (decorate_bt.visible ? decorate_bt.width : cultivate_bt.width));
			}
			
			//make sure the pack tabs are good
			if(pack_tabber) pack_tabber.y = int(lm.header_h + lm.loc_vp_h - pack_tabber.height);
		}
		
		private function onCultivateClick(event:TSEvent):void {
			//kick it into cultivate mode
			HouseManager.instance.startCultivation();
		}
		
		private function onDecorateClick(event:TSEvent):void {
			//kick it into decorator mode
			if(model.stateModel.can_decorate){
				TSFrontController.instance.startDecoratorMode();
			}
			else {
				model.activityModel.activity_message = Activity.createFromCurrentPlayer('Now is not the time to decorate!');
			}
		}
		
		public var showing_cult_or_deco:String = '';
		public function showHideCultDecoButtons():void {
			// if we are in interior or exterior street, show the button holder
			const sm:StateModel = model.stateModel;
			const loc:Location = model.worldModel.location;
			
			var should_show:Boolean =
				!model.moveModel.moving &&
				!sm.cult_mode &&
				!sm.chassis_mode &&
				!sm.decorator_mode &&
				!sm.info_mode &&
				(sm.can_cultivate || sm.can_decorate) &&
				(!loc.no_decorate_button || !loc.no_cultivate_button);
			
			if (should_show != dec_cult_bt_holder.visible) {
				Benchmark.addCheck(
					'YDM should_show dec_cult_bt_holder:'+should_show+' '+
					'model.moveModel.moving:'+model.moveModel.moving+' '+
					'sm.cult_mode:'+sm.cult_mode+' '+
					'sm.decorator_mode:'+sm.decorator_mode+' '+
					'sm.can_cultivate:'+sm.can_cultivate+' '+
					'sm.can_decorate:'+sm.can_decorate+' '+
					'sm.info_mode:'+sm.info_mode+' '+
					'loc.no_decorate_button:'+loc.no_decorate_button+' '+
					'loc.no_cultivate_button:'+loc.no_cultivate_button
				);
			}
			
			dec_cult_bt_holder.visible = should_show;
			
			if (!should_show) return;
			
			const pc:PC = model.worldModel.pc;
			const up_y:int = -50;
			const time:Number = .2;
			
			if (sm.can_decorate) {
				if (pc.x < 0 && loc.tsid == pc.home_info.interior_tsid) {
					// show cultivate
					cultivate_bt.visible = !loc.no_cultivate_button
					if (showing_cult_or_deco != 'cult') {
						showing_cult_or_deco = 'cult';
						if (cultivate_bt.y == 0) cultivate_bt.y = up_y;
						
						TSTweener.addTween(decorate_bt, {y:up_y, time:time});
						TSTweener.addTween(cultivate_bt, {y:0, delay:time, time:time});
					}
				} else {
					// show decorate 
					decorate_bt.visible = !loc.no_decorate_button;
					if (showing_cult_or_deco != 'deco') {
						showing_cult_or_deco = 'deco';
						if (decorate_bt.y == 0) decorate_bt.y = up_y;
						
						TSTweener.addTween(cultivate_bt, {y:up_y, time:time});
						TSTweener.addTween(decorate_bt, {y:0, delay:time, time:time});
					}
				}
			} else if (sm.can_cultivate) {
				cultivate_bt.visible = !loc.no_cultivate_button;
				if (showing_cult_or_deco != 'cult') {
					showing_cult_or_deco = 'cult';
					cultivate_bt.y = 0;
					decorate_bt.visible = false;
				}
			}
		}
		
		private function onDecorateModeChange(is_enabled:Boolean):void {
			//hide the location if we are in deco modes
			showHideCurrentLocation();
			
			showHideCultDecoButtons();
			if(is_enabled){
				addChild(decorate_toolbar);
				decorate_toolbar.show();
			}
			pack_tabber.visible = true;
		}
		
		private function onCultModeChange(is_enabled:Boolean):void {
			//hide the location if we are in deco modes
			showHideCurrentLocation();
			
			showHideCultDecoButtons();
			if(is_enabled){
				addChild(cult_toolbar);
				cult_toolbar.show();
			}
			pack_tabber.visible = !is_enabled;
		}
		
		private function onChassisModeChange(is_enabled:Boolean):void {
			//hide the location if we are in deco modes
			showHideCurrentLocation();
			
			showHideCultDecoButtons();
			if(is_enabled){
				addChild(chassis_toolbar);
				chassis_toolbar.show();
			}
			pack_tabber.visible = !is_enabled;
		}
		
		private function onInfoModeChange(is_enabled:Boolean):void {
			//hide the location
			showHideCurrentLocation();
			
			showHideCultDecoButtons();
			if(is_enabled){
				addChild(info_toolbar);
				info_toolbar.show();
			}
		}
		
		CONFIG::god private function onHODChange(is_enabled:Boolean):void {
			if(is_enabled){
				hog_toolbar.show();
				pack_tabber.visible = false;
			}
			else {
				hog_toolbar.hide();
				pack_tabber.visible = true;
			}
		}
		
		CONFIG::god private function onEditingChange(is_enabled:Boolean):void {
			pack_tabber.visible = !is_enabled;
		}
		
		private function onCurrantsMouse(event:MouseEvent):void {
			if(player_info.is_open || currants_timer.running) return;
			
			const is_over:Boolean = event.type == MouseEvent.ROLL_OVER;
			TSTweener.addTween(currants_tf, {alpha:is_over ? CURRANTS_HOVER_ALPHA : CURRANTS_REG_ALPHA, time:.1, transition:'linear'});
		}
		
		private function onCurrantsTimerTick(event:TimerEvent = null):void {
			//change the current display
			const current_currants:int = model.worldModel.pc.stats.currants;
			if(displayed_currants != current_currants){
				if(displayed_currants < current_currants){
					displayed_currants += steps_currants;
					if(displayed_currants > current_currants) displayed_currants = current_currants;
				}
				else {
					displayed_currants -= steps_currants;
					if(displayed_currants < current_currants) displayed_currants = current_currants;
				}
			}
			else {
				currants_timer.stop();
				TSTweener.addTween(currants_tf, {alpha:CURRANTS_REG_ALPHA, time:.1, delay:PlayerInfoUI.DISPLAY_SECS-.5, transition:'linear'});
			}
			
			//since we don't zoom the currants when they change, let's update the text			
			currants_tf.htmlText = '<p class="you_display_currants_have">'+
									StringUtil.formatNumberWithCommas(displayed_currants)+
									'<br><span class="you_display_currants">Currants</span></p>';
		}
		
		public function updateCurrants(animate:Boolean = true):void {
			if(model && model.worldModel && model.worldModel.pc && model.worldModel.pc.stats){
				
				TSTweener.removeTweens(currants_tf);
				
				if(animate && model.prefsModel.do_stat_count_animations){
					//get the change so we know how many steps we need to hit
					const change_amount:uint = Math.abs(model.worldModel.pc.stats.currants-displayed_currants);
					steps_currants = Math.max(Math.ceil((change_amount*PlayerInfoUI.TIMER_DELAY)/(PlayerInfoUI.DISPLAY_SECS*1000)), 1);
					
					currants_timer.reset();
					currants_timer.start();
					
				}
				else {
					//probably the first load, just show the text
					displayed_currants = model.worldModel.pc.stats.currants;
					onCurrantsTimerTick();
				}
				
				// do this even if !model.prefsModel.do_stat_count_animations
				if (animate) {
					//light it up for a sec, then bring it back down
					TSTweener.addTween(currants_tf, {alpha:CURRANTS_HOVER_ALPHA, time:.1, transition:'linear'});
				}
			}
		}
		
		override public function get visible():Boolean {
			//will see if any of the children that are not part of things_to_leave_alone_visibility_wise are infact visible or not
			var i:int;
			var total:int = numChildren;
			var child:DisplayObject;
			
			for(i; i < total; i++){
				child = getChildAt(i);
				
				if(things_to_leave_alone_visibility_wise.indexOf(child) == -1){
					return child.visible;
				}
			}
			
			//should never get down here, but FB complains
			return currants_holder.visible;
		}
		
		override public function set visible(value:Boolean):void {
			//this allows certain elements to stay visible even though it's set to false
			var i:int;
			var total:int = numChildren;
			var child:DisplayObject;
			
			for(i; i < total; i++){
				child = getChildAt(i);
				
				if(things_to_leave_alone_visibility_wise.indexOf(child) == -1){					
					child.visible = value;
					
					if(child == currants_holder){
						//special case for the times we might not want to show the currants
						is_currants_hidden = !value;
					}
				}
			}
		}
		
		public function set is_currants_hidden(value:Boolean):void {
			if(value == _is_currants_hidden) return;
			if(!value && model.worldModel.location.no_currants) return;
			if(TSTweener.isTweening(currants_holder)) TSTweener.removeTweens(currants_holder);
			
			_is_currants_hidden = value;
			
			TSTweener.addTween(currants_holder, {alpha:(value ? 0 : 1), time:.5, transition:'linear'});
		}
		
		public function hideDecorateToolbar():void {
			if(decorate_toolbar) {
				decorate_toolbar.hide();
				if(decorate_toolbar.parent) decorate_toolbar.parent.removeChild(decorate_toolbar);
			}
		}
		
		public function hideChassisToolbar():void {
			if(chassis_toolbar) {
				chassis_toolbar.hide();
				if(chassis_toolbar.parent) chassis_toolbar.parent.removeChild(chassis_toolbar);
			}
		}
		
		public function hideCultToolbar():void {
			if(cult_toolbar) {
				cult_toolbar.hide();
				if(cult_toolbar.parent) cult_toolbar.parent.removeChild(cult_toolbar);
			}
		}
		
		public function hideInfoToolbar():void {
			if(info_toolbar){
				info_toolbar.hide();
				if(info_toolbar.parent) info_toolbar.parent.removeChild(info_toolbar);
			}
		}
		
		public function togglePlayerMenu():void {
			player_info.toggleMenu();
			TSTweener.addTween(currants_tf, {alpha:player_info.is_open ? CURRANTS_HOVER_ALPHA : CURRANTS_REG_ALPHA, time:.1, transition:'linear'});
		}
		
		public function get player_info_w():Number {
			//how width is this sucker?
			return player_info.energy_w;
		}
		
		public function toggleEnergyText():void {
			//if you want to hide the energy text, this is where that will happen
			var can_show_energy:Boolean = true;
			if(ImgMenuView.instance.parent){
				can_show_energy = false;
			}
			
			player_info.energy_amount_visible = can_show_energy;
		}
		
		public function showHideMood():void {
			//handle the hiding of the mood
			player_info.hide_mood = model.worldModel.location.no_mood;
		}
		
		public function showHideEnergy():void {
			//handle the hiding of the energy
			player_info.hide_energy = model.worldModel.location.no_energy;
		}
		
		public function showHideImagination():void {
			//handle the hiding of the imagination
			player_info.hide_imagination = model.worldModel.location.no_imagination;
			game_header.hide_help = model.worldModel.location.no_imagination;
		}
		
		public function hideImaginationAmount(is_hide:Boolean):void {
			player_info.hide_imagination_amount = is_hide;
		}
		
		public function showHideCurrentLocation(force_hide:Boolean = false):void {
			//make sure we are able to show this
			current_location.visible = !force_hide &&
									   !model.worldModel.location.no_current_location && 
									   !model.stateModel.cult_mode && 
									   !model.stateModel.info_mode && 
									   !model.stateModel.decorator_mode;
			if(current_location.visible) {
				current_location.show();
			}
			
			//redraw
			refresh();
		}
		
		public function get current_location_x():Number {
			return current_location.x;
		}
		
		public function showHideInventorySearch():void {
			//can we search the inventory?
			if(PackDisplayManager.instance.getOpenTabName() == PackTabberUI.TAB_PACK){
				//refreshes the tab
				pack_tabber.packShowing();
			}
		}
		
		private function onEnterFrame(ms_elapsed:int):void {
			showHideCultDecoButtons();
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
			showHideCultDecoButtons();
			StageBeacon.enter_frame_sig.remove(onEnterFrame);
			
			//hide the location
			current_location.visible = false;
		}
		
		public function moveMoveEnded():void {
			showHideCultDecoButtons();
			showHideEnergy();
			showHideMood();
			showHideImagination();
			showHideInventorySearch();
			
			if (model.stateModel.can_decorate) {
				StageBeacon.enter_frame_sig.add(onEnterFrame);
			}
			
			//things might have changed, we might have died or something!
			player_info.updateMoodDisplay();
			
			//update our location
			current_location.show();
			showHideCurrentLocation();
			
			//make sure if the tabber isn't visible we should the regular pack (should only be called once)
			if(!pack_tabber.visible){
				pack_tabber.visible = true;
				PackDisplayManager.instance.hideFurnitureBag();
			}
		}
	}
}