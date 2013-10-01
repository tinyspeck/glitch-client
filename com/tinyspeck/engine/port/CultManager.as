package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.house.Cultivations;
	import com.tinyspeck.engine.data.house.CultivationsChoice;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.ContiguousPlatformLineSet;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingCultivationPurchaseVO;
	import com.tinyspeck.engine.net.NetOutgoingCultivationStartVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackNudgeVO;
	import com.tinyspeck.engine.net.NetOutgoingNudgeryStartVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.geom.Range;
	import com.tinyspeck.engine.view.CultCarryUI;
	import com.tinyspeck.engine.view.CultLifespanIndicator;
	import com.tinyspeck.engine.view.CultPickerUI;
	import com.tinyspeck.engine.view.CultPointer;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.LocationSpinner;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.geo.ContiguousPlatformLineSetView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.ui.furniture.CultButton;
	
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	public class CultManager implements IFocusableComponent, IMoveListener, IRefreshListener, ILocItemstackAddDelConsumer, ILocItemstackUpdateConsumer {
		/* singleton boilerplate */
		public static const instance:CultManager = new CultManager();
		
		public static const WIDTH_OF_CONFIG_UI:uint = 190;
		
		private var inited:Boolean;
		private var wm:WorldModel;
		private var model:TSModelLocator;
		private var right_pointer:CultPointer = new CultPointer(CultPointer.DIRECTION_RIGHT);
		private var left_pointer:CultPointer = new CultPointer(CultPointer.DIRECTION_LEFT);
		private var picker_ui:CultPickerUI;
		private var carry_ui:CultCarryUI;
		private var spinner:LocationSpinner;
		private var cancel_cdVO:ConfirmationDialogVO;
		private var fail_cdVO:ConfirmationDialogVO;
		private var warning_cdVO:ConfirmationDialogVO;
		private var game_renderer:LocationRenderer;
		private var last_y_diff:int = 0;
		private var picker_local_pt:Point;
		private var picker_global_pt:Point;
		private var waiting_on_pc_on_movement:Boolean;
		private var cpls_to_cplsv_map:Dictionary;
		private var itemstack_tsid_to_cli_map:Dictionary = new Dictionary(true);
		private var current_choice:CultivationsChoice;
		private var current_proto_item:Item;
		public var carrying:Boolean;
		public var waiting_on_item:Item;
		
		public function CultManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init():void {
			if (inited) return;
			inited = true;
			model = TSModelLocator.instance;
			wm = model.worldModel;
			game_renderer = TSFrontController.instance.getMainView().gameRenderer;
			registerSelfAsFocusableComponent();
			carry_ui = new CultCarryUI();
			picker_ui = new CultPickerUI();
			picker_ui.init();
			picker_local_pt = new Point(WIDTH_OF_CONFIG_UI + 30 + CultButton.WIDTH/2, 0);
			TSFrontController.instance.registerMoveListener(this);
			
			spinner = new LocationSpinner();
			
			fail_cdVO = new ConfirmationDialogVO();
			fail_cdVO.title = 'Failure!!!'
			fail_cdVO.choices = [
				{value: true, label: 'Darn'}
			];
			
			//confirm dialog
			cancel_cdVO = new ConfirmationDialogVO();
			cancel_cdVO.title = 'Save Your Changes?';
			cancel_cdVO.txt = "You\'re cancelling, but I am thinking maybe you meant to save your changes first?";
			cancel_cdVO.choices = [
				{value: true, label: 'Yes, Save!'},
				{value: false, label: 'No, Discard'}
			];
			cancel_cdVO.escape_value = false;
			cancel_cdVO.callback =	onConfirm;
			
			
			//confirm dialog
			warning_cdVO = new ConfirmationDialogVO();
			warning_cdVO.title = 'Are you sure?';
			warning_cdVO.choices = [
				{value: true, label: 'Yes, Do It!!'},
				{value: false, label: 'No, Forget It'}
			];
			warning_cdVO.escape_value = false;
			warning_cdVO.callback =	onWarningConfirm;
		}
		
		public function start():Boolean {
			if (!HouseManager.instance.cultivations || !HouseManager.instance.cultivations.choices.length) {
				return false;
			}
			
			updateChoicesForCurrenPCStats();
			updateChoicesForSpace();
			
			if (!picker_ui.start()) {
				return false;
			}
			
			/*if (!TSFrontController.instance.requestFocus(this)) {
				return false;
			}*/
			
			// reset
			//picker_ui.setButtonToCorrectState();
			
			//hide the pack
			PackDisplayManager.instance.changeVisibility(false, 'CultManager');
			
			// add the picker
			TSFrontController.instance.getMainView().main_container.addChildAt(picker_ui, 0);
			
			//listen to the refreshings
			TSFrontController.instance.registerRefreshListener(this);
			refresh();
			
			
			TSFrontController.instance.disableLocationInteractions();
			
			wm.registerCBProp(onStatsChanged, "pc", "stats");
			
			// must be on a timeout so that model.stateModel.cult_mode=true when it runs
			StageBeacon.waitForNextFrame(showCLIs);
			
			StageBeacon.enter_frame_sig.add(onEnterFrame);
			
			return true;
		}

		public function refresh():void {
			if (!inited) return;
			picker_ui.y = model.layoutModel.loc_vp_h;
			picker_ui.refresh();
			
			left_pointer.x = 10;
			right_pointer.x = model.layoutModel.loc_vp_w+(-right_pointer.width)+(-10);
			
			left_pointer.y = right_pointer.y = model.layoutModel.loc_vp_h-100;
		}
		
		// ONLY EVER TO BE CALLED FROM TSFC.setCultivateMode (use TSFC.stopCultivateMode() to end this properly)
		public function end():void {
			_platform_lines = null;
			StageBeacon.enter_frame_sig.remove(onEnterFrame);
			stopCarry();
			destroyCLIs();
			picker_ui.end();
			PackDisplayManager.instance.changeVisibility(true, 'CultManager');
			if (picker_ui.parent) picker_ui.parent.removeChild(picker_ui);
			stopWaitingForItemAddition();
			stopWaitingForPcMovement();
			TSFrontController.instance.releaseFocus(this, 'ended');
			TSFrontController.instance.resetCameraCenter();
			TSFrontController.instance.furnitureUpgradeEnded();
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			TSFrontController.instance.enableLocationInteractions();
			
			wm.unRegisterCBProp(onStatsChanged, "pc", "stats");
			TSFrontController.instance.saveHomeImg();
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			updateStuffAfterSomeCostRelatedChange();
		}
		
		private function updateStuffAfterSomeCostRelatedChange():void {
			updateChoicesForCurrenPCStats();
			picker_ui.updateButtons();
			
			if (current_choice) {
				if (!current_choice.client::need_imagination && !current_choice.client::need_level && current_choice.client::will_fit) {
					carry_ui.good();
				} else {
					carry_ui.bad();
				}
			}
		}
		
		private function updateChoicesForCurrenPCStats():void {
			const cults:Cultivations = HouseManager.instance.cultivations;
			var choice:CultivationsChoice;
			var pc:PC = wm.pc;
			
			var testing:Boolean = false;
			
			for each (choice in cults.choices) {
				if (testing || pc.stats.imagination >= choice.imagination_cost) {
					choice.client::need_imagination = 0;
				} else {
					choice.client::need_imagination = choice.imagination_cost - pc.stats.imagination;
				}
				
				if (testing || pc.stats.level >= choice.min_level) {
					choice.client::need_level = 0;
				} else {
					choice.client::need_level = choice.min_level;
				}
				/*
				CONFIG::debugging {
					Console.info(choice.class_id+' need_imagination:'+choice.client::need_imagination );
					Console.info(choice.class_id+' need_level:'+choice.client::need_level );
				}
				*/
			}
		}
		
		private var _platform_lines:Vector.<PlatformLine>;
		private function get platform_lines():Vector.<PlatformLine> {
			return wm.location.mg.platform_lines;
			
			if (!_platform_lines) {
				_platform_lines = new <PlatformLine>[];
				for each (var pl:PlatformLine in wm.location.mg.platform_lines) {
					if (pl.start.y >= wm.location.l && pl.start.x <= wm.location.r) {		
						_platform_lines.push(pl);
					}
				}
			}
			
			return _platform_lines;
		}
		
		private function updateChoicesForSpace():void {
			const cults:Cultivations = HouseManager.instance.cultivations;
			var choice:CultivationsChoice;
			var pc:PC = wm.pc;
			var pl_to_cpls_map:Dictionary;
			
			for each (choice in cults.choices) {
				pl_to_cpls_map = ContiguousPlatformLineSet.getPLtoCPLSDictionary(platform_lines, choice.class_id);
				
				choice.client::will_fit = false;
				for each (var cpls:ContiguousPlatformLineSet in pl_to_cpls_map) {
					cpls.calculateRanges(choice.class_id);
					if (cpls.valid_ranges.length) {
						// there is at least one!
						choice.client::will_fit = true;
						break;
					}
				}
				/*
				if (choice.class_id == 'proto_patch') {
					choice.client::will_fit = false;
				}
				*/
				/*
				CONFIG::debugging {
					Console.info(choice.class_id+' will_fit:'+choice.client::will_fit);
				}
				*/
			}
			
			if (current_choice) {
				createcplsvMap();
			}
		}
		
		private function removeCPLSVs():void {
			var k:Object;
			var cplsv:ContiguousPlatformLineSetView;
			MiniMapView.instance.clearRangesFromCPLSes();
			
			if (cpls_to_cplsv_map) {
				for (k in cpls_to_cplsv_map) {
					cplsv = cpls_to_cplsv_map[k];
					if (cplsv) {
						if (cplsv.parent) {
							cplsv.parent.removeChild(cplsv);
						}
						cplsv.dispose();
					}
				}
				cpls_to_cplsv_map = null;
			}
		}
		
		// this gets called from end(), sure, but when running, you should call picker_ui.setChoice(null);
		public function stopCarry(cancelling:Boolean=true):void {
			removeCPLSVs();
			carrying = false;
			if (current_nudge_liv) {
				if (cancelling) {
					current_nudge_liv.itemstack.x = revert_nudge_pt.x;
					current_nudge_liv.itemstack.y = revert_nudge_pt.y;
				}
				current_nudge_liv.enableGSMoveUpdates();
				current_nudge_liv.changeHandler(true);
				
				var linked_itemstack_liv:LocationItemstackView;
				for (var k:Object in nudge_linked_itemstacks_diff_pts) {
					linked_itemstack_liv = k as LocationItemstackView;
					if (cancelling) {
						linked_itemstack_liv.itemstack.x = revert_nudge_pt.x - nudge_linked_itemstacks_diff_pts[k].x;
						linked_itemstack_liv.itemstack.y = revert_nudge_pt.y - nudge_linked_itemstacks_diff_pts[k].y;
					}
					linked_itemstack_liv.enableGSMoveUpdates();
					linked_itemstack_liv.changeHandler(true);
				}
				
				// this makes sure we position the CLI where it should be after it has been moved back
				StageBeacon.setTimeout(showCLIs, 350);
			}
			for (k in nudge_linked_itemstacks_diff_pts) delete nudge_linked_itemstacks_diff_pts[k];
			current_choice = null;
			current_nudge_itemstack = null;
			current_nudge_liv = null;
			current_proto_item = null;
			cpls_to_cplsv_map = null;
			CONFIG::debugging {
				Console.info('removed it');
			}
			
			if (carry_ui.parent) carry_ui.parent.removeChild(carry_ui);
			
			game_renderer.locationView.middleGroundRenderer.showPCs();
			
			showCLIs();

			right_pointer.showing = false;
			left_pointer.showing = false;
			if (right_pointer.parent) right_pointer.parent.removeChild(right_pointer);
			if (left_pointer.parent) left_pointer.parent.removeChild(left_pointer);
		}
		
		private var placement_pointers_start_time:int;
		private var current_nudge_itemstack:Itemstack;
		private var current_nudge_liv:LocationItemstackView;
		private var nudge_linked_itemstacks_diff_pts:Dictionary = new Dictionary(true);
		private function startCarry():void {
			if (!current_choice && !current_nudge_itemstack) {
				CONFIG::debugging {
					Console.error('no choice? this is bad! call picker_ui.setChoice(null) to stop carrying');
				}
				return;
			}
			
			var ignore_itemstack_tsidsA:Array;
			is_good_once_for_this_item = false;
			placement_pointers_start_time = 0;
			TSFrontController.instance.getMainView().main_container.addChild(right_pointer);
			TSFrontController.instance.getMainView().main_container.addChild(left_pointer);
			
			stopWaitingForItemAddition();
			stopWaitingForPcMovement();
			
			hideCLIs();
			
			carrying = true;
			
			game_renderer.locationView.middleGroundRenderer.hidePCs();
			
			carry_ui.start(current_choice, current_proto_item, current_nudge_itemstack);
			game_renderer.placeOverlayInSCHTop(carry_ui, 'CultMan.setCultChoice');

			CONFIG::debugging {
				Console.info(current_proto_item.tsid);
			}
			
			if (current_nudge_itemstack) {
				ignore_itemstack_tsidsA = [current_nudge_liv.tsid];
			}
			
			// create a new map each time, just in case
			current_pl_to_cpls_map = ContiguousPlatformLineSet.getPLtoCPLSDictionary(
				platform_lines,
				current_proto_item.tsid,
				(current_nudge_itemstack) ? ignore_itemstack_tsidsA : null
			);
			createcplsvMap();
			onEnterFrame();
			TipDisplayManager.instance.goAway();
		}
		
		public function startCultivate(choice:CultivationsChoice):void {
			if (carrying) {
				picker_ui.setChoice(null);
				stopCarry();
			}
			
			current_choice = choice;
			current_proto_item = current_choice.client::item;
			
			startCarry();
		}
		
		public function nudgeAbilityChanged():void {
			if (!model.stateModel.cult_mode) return;
			if (!itemstack_tsid_to_cli_map) return;
			for each(var cli:CultLifespanIndicator in itemstack_tsid_to_cli_map) {
				cli.showHideNudgeAffordance();
			}
		}
		
		private var revert_nudge_pt:Point = new Point;
		public function startNudging(itemstack:Itemstack):void {
			if (!wm.pc.can_nudge_cultivations) {
				return;
			}
			
			CONFIG::debugging {
				Console.info(itemstack.item.proto_item_tsidA)
			}
			
			// we need to figure out what proto item to use here
			if (!itemstack.item.proto_item_tsidA || itemstack.item.proto_item_tsidA.length != 1) {
				if (!itemstack.itemstack_state.lifespan_config || !itemstack.itemstack_state.lifespan_config.proto_item_tsid) {
					CONFIG::debugging {
						Console.error('No idea what the proto class is here :(');
					}	
					return;
				}
			}
			
			if (carrying) {
				picker_ui.setChoice(null);
				stopCarry();
			}

			TSFrontController.instance.moveAvatarToLIVandDoVerbOrAction(
				game_renderer.getItemstackViewByTsid(itemstack.tsid),
				function():void {
					model.worldModel.pc.apo.triggerResetVelocityX = true;
					
					current_nudge_itemstack = itemstack;
					TSFrontController.instance.genericSend(
						new NetOutgoingNudgeryStartVO(itemstack.tsid),
						onNudgeStart,
						onNudgeStart
					);
				}
			);
		}
		
		private function onNudgeStart(rm:NetResponseMessageVO):void {
			if (!rm.success) {
				current_nudge_itemstack = null;
				model.activityModel.growl_message = 'Could not start nudging';
				return;
			}
			
			if (current_nudge_itemstack.item.proto_item_tsidA && current_nudge_itemstack.item.proto_item_tsidA.length == 1) {
				current_proto_item =  wm.getItemByTsid(current_nudge_itemstack.item.proto_item_tsidA[0]);
			} else {
				current_proto_item = wm.getItemByTsid(current_nudge_itemstack.itemstack_state.lifespan_config.proto_item_tsid);
			}
			current_nudge_liv = game_renderer.getItemstackViewByTsid(current_nudge_itemstack.tsid);
			current_nudge_liv.disableGSMoveUpdates();
			
			for (var k:Object in nudge_linked_itemstacks_diff_pts) delete nudge_linked_itemstacks_diff_pts[k];
			
			// TODO figure out how to get the list of stacks that should move along with current_nudge_itemstack
			if (rm.payload.linked_itemstacks) {
				var A:Array = rm.payload.linked_itemstacks;
				var linked_itemstack_liv:LocationItemstackView;
				for (var i:int=0;i<A.length;i++) {
					linked_itemstack_liv = game_renderer.getItemstackViewByTsid(A[i]);
					linked_itemstack_liv.disableGSMoveUpdates();
					nudge_linked_itemstacks_diff_pts[linked_itemstack_liv] = new Point(
						current_nudge_itemstack.x-linked_itemstack_liv.x,
						current_nudge_itemstack.y-linked_itemstack_liv.y
					);
				}
			}
			
			revert_nudge_pt.x = model.worldModel.pc.x = current_nudge_itemstack.x;
			revert_nudge_pt.y = model.worldModel.pc.y = current_nudge_itemstack.y;
			
			startCarry();
		}
		
		private var current_pl_to_cpls_map:Dictionary;
		private function createcplsvMap():void {
			removeCPLSVs();
			var pl:PlatformLine;
			var k:Object;
			var cpls:ContiguousPlatformLineSet;
			var cplsv:ContiguousPlatformLineSetView;
			
			cpls_to_cplsv_map = new Dictionary(true);
			
			// go over each key (which are pls) and make them all visible
			for (k in current_pl_to_cpls_map) {
				pl = (k as PlatformLine);
				cpls = current_pl_to_cpls_map[pl];
				
				// if we dot already have a renderer for this cpls, make it!
				if (!cpls_to_cplsv_map[cpls]) {
					cplsv = cpls_to_cplsv_map[cpls] = new ContiguousPlatformLineSetView(cpls);
					
					// this w shows as best as possible the placement plats indicators such that
					// when the edges of the carry ui's item are within the plat's bounds.
					// the ui for placing is enabled
					var w:int = current_proto_item.placement_w-carry_ui.art_w;
					w = 0; // undoing the above as I think we want to show the whole width
					cplsv.draw((w)/2);
					MiniMapView.instance.drawRangesFromCPLS(cpls/*, item.placement_w/2*/);
					game_renderer.placeOverlayInSCH(cplsv, 'CultMan.createcplsvMap');
				}
			}
		}
		
		private function stopWaitingForPcMovement():void {
			TSFrontController.instance.resetCameraCenter();
			waiting_on_pc_on_movement = false;
		}
		
		private var is_good_once_for_this_item:Boolean;
		private function onEnterFrame(ms_elapsed:int=0):void {
			if (waiting_on_pc_on_movement) {
				if (Math.abs(wm.pc.apo.vx) > 2 || Math.abs(wm.pc.apo.vy) > 2) {
					stopWaitingForPcMovement();
				}
			}
			
			if (!carrying) return;
			var cpls:ContiguousPlatformLineSet;
			
			var left_limit:int = wm.location.l+(current_proto_item.placement_w/2);
			var right_limit:int = wm.location.r-(current_proto_item.placement_w/2);
			
			if (wm.pc.x < left_limit) {
				wm.pc.x = left_limit;
			} else if (wm.pc.x > right_limit) {
				wm.pc.x = right_limit;
			}
			
			const find_x:int = wm.pc.x;
			const find_y:int = wm.pc.y;
			
			var one_to_left:Boolean;
			var one_to_right:Boolean;
			
			if (!is_good_once_for_this_item && (!placement_pointers_start_time || getTimer() - placement_pointers_start_time < 5000)) {
				for each (cpls in current_pl_to_cpls_map) {
					for (var i:int=0;i<cpls.valid_ranges.length;i++) {
						var range:Range = cpls.valid_ranges[i];
						if (range.x2 < find_x+(current_proto_item.placement_w/2)) {
							one_to_left = true;
						}
						
						if (range.x1 > find_x-(current_proto_item.placement_w/2)) {
							one_to_right = true;
						}
					}
					
					if (one_to_left && one_to_right) {
						break;
					}
				}
			}
			
			const closest:Object = PlatformLine.getClosestToXYObject(
				PlatformLine.getPlacementPlatsForItemClass(
					platform_lines,
					current_proto_item.tsid
				),
				find_x,
				find_y
			);
			
			var y:int = find_y+last_y_diff; // if we get a closest, we'll change this value, but this tries to make sure the default position is good
			var good:Boolean = false;
			
			if (closest) {
				cpls = current_pl_to_cpls_map[closest.pl];
				if (cpls) {
					y = Math.round(cpls.yIntersection(closest.x));
					last_y_diff = y-find_y;
					good = Boolean(cpls.getValidRangeForX(find_x, current_proto_item.placement_w));
					
					if (good) {
						is_good_once_for_this_item = true;
						if (!placement_pointers_start_time) {
							// 5 secs from being in a palceable area, the placement pointers will go away to not return until
							placement_pointers_start_time = getTimer();
						}
					}
				}
			}

			positionCarryUI(
				find_x,
				y
			);
			
			if (current_choice) {
				if (good && !current_choice.client::need_imagination && !current_choice.client::need_level && current_choice.can_place) {
					carry_ui.good();
				} else {
					carry_ui.bad();
				}
			} else {
				if (good) {
					carry_ui.good();
				} else {
					carry_ui.bad();
				}
			}
			
			right_pointer.showing = one_to_right;
			left_pointer.showing = one_to_left;
		}

		private function positionCarryUI(cx:int, cy:int):void {
			if (!carry_ui.parent) return;
			carry_ui.x = cx;
			carry_ui.y = cy;
			
			if (current_nudge_liv) {
				current_nudge_liv.x = current_nudge_liv.itemstack.x = cx;
				current_nudge_liv.y = current_nudge_liv.itemstack.y = cy;
				
				var linked_itemstack_liv:LocationItemstackView;
				for (var k:Object in nudge_linked_itemstacks_diff_pts) {
					linked_itemstack_liv = k as LocationItemstackView;
					linked_itemstack_liv.x = linked_itemstack_liv.itemstack.x = current_nudge_liv.x - nudge_linked_itemstacks_diff_pts[k].x;
					linked_itemstack_liv.y = linked_itemstack_liv.itemstack.y = current_nudge_liv.y - nudge_linked_itemstacks_diff_pts[k].y;
				}
				
				// not needed now that tower chassis are showing the icon
				//if (current_nudge_liv.item.tsid == 'furniture_tower_chassis') {
				//	FancyDoor.instance.placeDoor(current_nudge_liv.itemstack);
				//}
			}
		}
		
		private function moveIt():void {
			if (current_nudge_itemstack && carry_ui.is_good) {
				TSFrontController.instance.genericSend(
					new NetOutgoingItemstackNudgeVO(
						current_nudge_itemstack.tsid,
						current_nudge_itemstack.x,
						current_nudge_itemstack.y
					),
					onMove, 
					onMove
				);
			} else {
				picker_ui.setChoice(null);
				stopCarry();
			}
		}
		
		private function onMove(rm:NetResponseMessageVO):void {
			if (rm.success) {
				TSFrontController.instance.showCheckmark(current_nudge_itemstack.x, current_nudge_itemstack.y);
			} else {
				model.activityModel.growl_message = 'Nudging failed';
			}
			
			picker_ui.setChoice(null);
			var cancelling:Boolean = !rm.success;
			stopCarry(cancelling);
		}
		
		private function onWarningConfirm(is_yes:Boolean):void {
			if (is_yes) {
				purchaseIt(true);
			} else {
				escKeyHandler();
			}
		}
		
		private function purchaseIt(proceed:Boolean=false):void {
			if (current_choice && carry_ui.is_good) {
				
				if (!proceed) {
					if (current_choice.placement_warning) {
						warning_cdVO.txt = current_choice.placement_warning;
						TSFrontController.instance.confirm(warning_cdVO);
					} else {
						proceed = true;
					}
				}
				
				if (!proceed) {
					return;
				}
				
				var place_x:int = carry_ui.x;
				var place_y:int = carry_ui.y;
				var place_class:String = current_proto_item.tsid;
				
				// in a second, send message
				StageBeacon.setTimeout(function():void {
					if (model.stateModel.cult_mode) {
						TSFrontController.instance.genericSend(
							new NetOutgoingCultivationPurchaseVO(place_class+'', place_x, place_y),
							onPurchase,
							onPurchase
						);
						waiting_on_pc_on_movement = true;
					}
				}, 2000); // <-- this must be long enough to allow the avatar to get to place_x, place_y
				
				startWaitingForItemAddition(current_proto_item, place_x, place_y);
			}
			
			picker_ui.setChoice(null);
			stopCarry();
		}

		private function onPurchase(rm:NetResponseMessageVO):void {
			if (rm.success) {
				TSFrontController.instance.genericSend(new NetOutgoingCultivationStartVO(), onCultStart, onCultStart);
			} else {
				fail_cdVO.txt = "I am sorry to report that hrmmm, that failed";
				if (rm.payload.error && rm.payload.error.msg) {
					fail_cdVO.txt+= '.<br>The error was: '+rm.payload.error.msg;
				} else {
					fail_cdVO.txt+= ' for an unknown reason';
				}
				
				TSFrontController.instance.confirm(fail_cdVO);
				stopWaitingForItemAddition();
				stopWaitingForPcMovement();
			}
		}
		
		private function onCultStart(nrm:NetResponseMessageVO):void {
			if (nrm.success) {
				//_cultivations = Cultivations.fromAnonymous(nrm.payload);
				const cults:Cultivations = HouseManager.instance.cultivations;
				var choices_ob:Object = nrm.payload.choices;
				
				if (!cults.choices || !cults.choices.length) {
					// ????
				} else {
					var choice:CultivationsChoice;
					
					for each (choice in cults.choices) {
						if (choices_ob[choice.class_id]) {
							choice = CultivationsChoice.updateFromAnonymous(choices_ob[choice.class_id], choice);
						}
					}
				}
				
				updateStuffAfterSomeCostRelatedChange();
			}
		}
		
		private function startWaitingForItemAddition(item:Item, place_x:int, place_y:int):void {
			if (!TSFrontController.instance.requestFocus(this)) {
				return;
			}
			
			waiting_on_item = item;
			spinner.alpha = 0;
			TSTweener.addTween(spinner, {alpha:1, time:1, transition:'easeInExpo'});
			spinner.x = place_x;
			spinner.y = place_y-1;
			spinner.setLabel('HOLD ON A SEC');
			game_renderer.placeOverlayInSCH(spinner, 'CultMan.startWaitingForItemAddition');
			
			TSFrontController.instance.setCameraCenter(null, null, new Point(place_x, place_y));
			
			// move avatar to side of placed item
			const dist:int = Math.max(120, current_proto_item.placement_w/2);
			if (wm.pc.x > wm.location.l+((wm.location.r-wm.location.l)/2)) {
				TSFrontController.instance.startMovingAvatarOnGSPath(new Point(wm.pc.x-dist, 0), 'right');
			} else {
				TSFrontController.instance.startMovingAvatarOnGSPath(new Point(wm.pc.x+dist, 0), 'left');
			}
		}
		
		private function stopWaitingForItemAddition():void {
			TSFrontController.instance.releaseFocus(this);
			waiting_on_item = null;
			if (spinner.parent) spinner.parent.removeChild(spinner);
		}
		
		private function shouldShowCLIForStack(itemstack:Itemstack):Boolean {
			if (itemstack.itemstack_state.lifespan_config) return true;
			if (itemstack.class_tsid == 'furniture_tower_chassis') return true;
			return false;
		}
		
		private function showCLIs():void {
			if (!model.stateModel.cult_mode) return;
			if (carrying) return;
			var lis_view:LocationItemstackView;
			var cli:CultLifespanIndicator;
			for (var i:int=0;i<game_renderer.lis_viewV.length;i++) {
				lis_view = game_renderer.lis_viewV[i];
				if (!shouldShowCLIForStack(lis_view.itemstack)) continue;
				//if (!lis_view.itemstack.itemstack_state.lifespan_config) continue;
				
				cli = itemstack_tsid_to_cli_map[lis_view.tsid];
				if (!cli) {
					cli = createCLI(lis_view);
					cli.visible = false;
				} else {
					cli.update();
					placeCLIByLIZS(cli, lis_view);
				}
				
				if (!cli.visible) {
					cli.alpha = 0;
					TSTweener.addTween(cli, {alpha:1, time:.3, delay:.5, transition:'easeInExpo'});
				}
				
				cli.visible = true;
			}
		}
		
		private function createCLI(lis_view:LocationItemstackView):CultLifespanIndicator {
			var cli:CultLifespanIndicator = itemstack_tsid_to_cli_map[lis_view.tsid] = new CultLifespanIndicator(lis_view.itemstack);
			game_renderer.placeOverlayInSCH(cli, 'CultMan.createCLI');
			placeCLIByLIZS(cli, lis_view);
				
			if (lis_view.is_loaded) {
				cli.holder.visible = true;
			} else {
				lis_view.loadCompleted_sig.add(onLISLoadedForCLI);
			}
			
			return cli;
		}
		
		private function onLISLoadedForCLI(lis:LocationItemstackView):void {
			var cli:CultLifespanIndicator = (itemstack_tsid_to_cli_map) ? itemstack_tsid_to_cli_map[lis.tsid] : null;
			if (cli) {
				cli.holder.visible = true;
				placeCLIByLIZS(cli, lis);
			}
			lis.loadCompleted_sig.remove(onLISLoadedForCLI);
		}
		
		private function placeCLIByLIZS(cli:CultLifespanIndicator, lis_view:LocationItemstackView):void {
			cli.x = lis_view.x;
			cli.y = lis_view.y+Math.max(-240, lis_view.getYAboveDisplay());
		}
		
		private function hideCLIs():void {
			for each(var cli:CultLifespanIndicator in itemstack_tsid_to_cli_map) {
				cli.visible = false;
			}
		}
		
		private function destroyCLIs():void {
			for each(var cli:CultLifespanIndicator in itemstack_tsid_to_cli_map) {
				if (cli.parent) cli.parent.removeChild(cli);
			}
			itemstack_tsid_to_cli_map = new Dictionary(true);
		}
		
		public function getPickerPt():Point {
			//returns the top/left corner of the picker
			if(picker_ui){
				picker_global_pt = picker_ui.localToGlobal(picker_local_pt);
				return picker_global_pt;
			}
			else {
				return new Point();
			}
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
		//////// ILocItemstackAddDelConsumer ///////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function onLocItemstackAdds(tsids:Array):void {
			if (!model.stateModel.cult_mode) return;
			
			updateChoicesForSpace();
			picker_ui.updateButtons();
			
			if (!carrying) {
				// brute force!
				showCLIs();
				if (waiting_on_item) {
					seeIfThePurchasedItemWasAdded(tsids);
				}
			}
		}
		
		private function seeIfThePurchasedItemWasAdded(tsids:Array):void {
			if (!waiting_on_item) return;
			
			var itemstack:Itemstack;
			var lis_view:LocationItemstackView;
			for (var i:int=0;i<tsids.length;i++) {
				itemstack = wm.getItemstackByTsid(tsids[int(i)]);
				//Console.info(itemstack.class_tsid+' proto_item_tsid:'+itemstack.item.proto_item_tsidA+' waiting_on_item:'+waiting_on_item.tsid)
				if (itemstack && ((itemstack.class_tsid == waiting_on_item.tsid) || (itemstack.item.proto_item_tsidA && itemstack.item.proto_item_tsidA.indexOf(waiting_on_item.tsid) > -1))) {
					lis_view = game_renderer.getItemstackViewByTsid(itemstack.tsid);
					if (lis_view) {
						if (lis_view.is_loaded || !lis_view is LocationItemstackView) {
							stopWaitingForItemAddition();
						} else {
							var lis:LocationItemstackView = lis_view as LocationItemstackView;
							lis.loadCompleted_sig.add(onLISLoadedForAdd);
						}
					} else {
						stopWaitingForItemAddition();
						CONFIG::debugging {
							Console.error('WTF?');
						}
					}
					return;
				}
			}
			
			CONFIG::debugging {
				Console.info('we are wating for an item with proto_item_tsidA containing:'+waiting_on_item.tsid+' but did not get one yet');
			}
		}
		
		private function onLISLoadedForAdd(lis:LocationItemstackView):void {
			stopWaitingForItemAddition();
			lis.loadCompleted_sig.remove(onLISLoadedForAdd);
		}
		
		public function onLocItemstackDels(tsids:Array):void {
			if (!model.stateModel.cult_mode) return;
			
			updateChoicesForSpaceIfNeeded(tsids);
			
			// remove the cli!
			var cli:CultLifespanIndicator;
			for (var i:int=0;i<tsids.length;i++) {
				cli = itemstack_tsid_to_cli_map[tsids[int(i)]];
				if (!cli) continue;
				
				if (cli.parent) cli.parent.removeChild(cli);
				delete itemstack_tsid_to_cli_map[tsids[int(i)]];
				
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// ILocItemstackUpdateConsumer ///////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		private function updateChoicesForSpaceIfNeeded(tsids:Array):void {
			var i:int
			var itemstack:Itemstack;
			
			// if one of these factors into placement, update everything.
			for (i=0;i<tsids.length;i++) {
				itemstack = wm.getItemstackByTsid(tsids[int(i)]);
				if (itemstack.item.placement_w) {
					updateChoicesForSpace();
					picker_ui.updateButtons();
					break;
				}
			}
		}
		
		public function onLocItemstackUpdates(tsids:Array):void {
			if (!model.stateModel.cult_mode) return;
			
			updateChoicesForSpaceIfNeeded(tsids);
			
			if (!carrying) {
				var lis_view:LocationItemstackView;
				var cli:CultLifespanIndicator;
				for (var i:int=0;i<tsids.length;i++) {
					lis_view = game_renderer.getItemstackViewByTsid(tsids[int(i)]);
					if (!lis_view) continue;
					if (!shouldShowCLIForStack(lis_view.itemstack)) continue;
					//if (!lis_view.itemstack.itemstack_state.lifespan_config) continue;
					
					cli = itemstack_tsid_to_cli_map[tsids[int(i)]];
					if (!cli) {
						cli = createCLI(lis_view);
					} else {
						cli.update();
						placeCLIByLIZS(cli, lis_view);
					}
				}
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// Handlers //////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function escKeyHandler(e:KeyboardEvent=null):void {
			if (carrying) {
				picker_ui.setChoice(null);
				stopCarry();
			} else {
				closeFromUserInput();
			}
		}
		
		public function enterKeyHandler(e:KeyboardEvent=null):void {
			if (carrying) {
				if (carry_ui.is_good) {
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					if (current_choice) {
						purchaseIt();
					} else {
						moveIt();
					}
				} else {
					SoundMaster.instance.playSound('CLICK_FAILURE');
				}
			}
		}
		
		public function closeFromUserInput():void {
			// check for what user is doing before closing
			TSFrontController.instance.stopCultMode();
		}
		
		private function onConfirm(is_yes:Boolean):void {
			

		}
		
		private function startListeningForControlEvts():void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			
			TSFrontController.instance.startListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function stopListeningForControlEvts():void {
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
			TSFrontController.instance.stopCultMode();
		}
		
		public function moveMoveEnded():void {
		}
	}
}