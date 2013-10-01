package com.tinyspeck.engine.view
{
	import com.tinyspeck.bootstrap.control.BootStrapController;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.FakeFriends;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.debug.PerfLogger;
	import com.tinyspeck.engine.Version;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.control.engine.FancyDoor;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.loader.SmartThreader;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.MoveModel;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.pack.FurnitureBagUI;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.pack.PackTabberUI;
	import com.tinyspeck.engine.perf.PerformanceMonitor;
	import com.tinyspeck.engine.port.ACLDialog;
	import com.tinyspeck.engine.port.CabinetDialog;
	import com.tinyspeck.engine.port.ChassisManager;
	import com.tinyspeck.engine.port.ConversationManager;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.GardenManager;
	import com.tinyspeck.engine.port.GetInfoDialog;
	import com.tinyspeck.engine.port.HouseManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.InfoManager;
	import com.tinyspeck.engine.port.InputDialog;
	import com.tinyspeck.engine.port.InputTalkBubble;
	import com.tinyspeck.engine.port.InventorySearchManager;
	import com.tinyspeck.engine.port.JS_interface;
	import com.tinyspeck.engine.port.LocationSelectorDialog;
	import com.tinyspeck.engine.port.MailDialog;
	import com.tinyspeck.engine.port.NoteDialog;
	import com.tinyspeck.engine.port.PrefsDialog;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.port.QuestsDialog;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.RookManager;
	import com.tinyspeck.engine.port.ScoreManager;
	import com.tinyspeck.engine.port.SkillManager;
	import com.tinyspeck.engine.port.StoreDialog;
	import com.tinyspeck.engine.port.StoreEmbed;
	import com.tinyspeck.engine.port.TradeDialog;
	import com.tinyspeck.engine.port.TrophyCaseDialog;
	import com.tinyspeck.engine.port.TrophyCaseManager;
	import com.tinyspeck.engine.port.TrophyGetInfoDialog;
	import com.tinyspeck.engine.sound.SoundManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ContainersUtil;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.BaseScreenView;
	import com.tinyspeck.engine.view.gameoverlay.BaseSplashScreenView;
	import com.tinyspeck.engine.view.gameoverlay.BuffViewManager;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.CameraManView;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.gameoverlay.DisconnectedScreenView;
	import com.tinyspeck.engine.view.gameoverlay.FlashBulbView;
	import com.tinyspeck.engine.view.gameoverlay.FlashUnfocusedView;
	import com.tinyspeck.engine.view.gameoverlay.GrowlView;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.LoadingLocationView;
	import com.tinyspeck.engine.view.gameoverlay.LocationCanvasView;
	import com.tinyspeck.engine.view.gameoverlay.LocationCheckListView;
	import com.tinyspeck.engine.view.gameoverlay.PromptView;
	import com.tinyspeck.engine.view.gameoverlay.SnapTravelView;
	import com.tinyspeck.engine.view.gameoverlay.ThrottledScreenView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.UICalloutView;
	import com.tinyspeck.engine.view.gameoverlay.UnFocusedScreenView;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.renderer.DecoByteLoader;
	import com.tinyspeck.engine.view.renderer.LocationInputHandler;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocPcAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocPcUpdateConsumer;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.GrowlQueue;
	import com.tinyspeck.engine.view.ui.Hotkeys;
	import com.tinyspeck.engine.view.ui.InteractionMenu;
	import com.tinyspeck.engine.view.ui.RookIncidentHeaderView;
	import com.tinyspeck.engine.view.ui.chat.InputField;
	import com.tinyspeck.engine.view.ui.garden.GardenView;
	import com.tinyspeck.engine.view.ui.glitchr.GlitchrSavedDialog;
	import com.tinyspeck.engine.view.ui.glitchr.GlitchrSnapshotView;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationYourLooksUI;
	import com.tinyspeck.engine.view.ui.map.MapChatArea;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.getQualifiedClassName;
	
	import net.hires.debug.Stats;

	CONFIG::god { import asunit.core.TextCore; }
	CONFIG::god { import com.tinyspeck.engine.admin.AdminDialog; }
	CONFIG::god { import com.tinyspeck.engine.admin.HandOfGod; }
	CONFIG::god { import com.tinyspeck.engine.control.BenchmarkUnitTestRunner; }
	CONFIG::god { import com.tinyspeck.engine.data.item.Item; }
	CONFIG::god { import com.tinyspeck.engine.event.TSEvent; }
	CONFIG::god { import com.tinyspeck.engine.EngineAllTests; }
	CONFIG::god { import com.tinyspeck.engine.view.gameoverlay.ViewportScaleSliderView; }
	CONFIG::god { import com.tinyspeck.engine.view.renderer.debug.PhysicsLoopRenderer; }
	CONFIG::god { import com.tinyspeck.engine.view.renderer.debug.PhysicsMovementRenderer; }
	CONFIG::god { import com.tinyspeck.engine.view.renderer.debug.PhysicsRenderer; }
	CONFIG::god { import com.tinyspeck.engine.view.ui.chrome.GodButtonView; }
	CONFIG::god { import com.tinyspeck.engine.view.ui.supersearch.SuperSearch; }
	CONFIG::god { import com.tinyspeck.engine.view.ui.supersearch.SuperSearchElementItem; }
	CONFIG::perf { import com.tinyspeck.engine.perf.PerfTestManager; }
	CONFIG::locodeco { import com.tinyspeck.engine.admin.locodeco.LocoDecoSideBar; }
	CONFIG::locodeco { import com.tinyspeck.engine.admin.locodeco.GroundYView; }
	CONFIG::locodeco { import locodeco.LocoDecoGlobals; }
	
	public class TSMainView extends AbstractTSView implements IMainView, IMoveListener, IFocusableComponent, ILocItemstackAddDelConsumer, ILocPcAddDelConsumer, ILocPcUpdateConsumer, ILocItemstackUpdateConsumer
	{
		CONFIG::locodeco public var ldsb:LocoDecoSideBar;
		
		public var pdm:PackDisplayManager;
		public var gameRenderer:LocationRenderer;
		
		public var main_container:Sprite = new Sprite();
		public var rook_damage_container:Sprite = new Sprite();
		public var rook_attack_container:Sprite = new Sprite();
		public var masked_container:Sprite = new Sprite();
		
		protected var do_render:Boolean = false;
		protected var start_time:int;
		protected var count_frames:int;
		protected var model:TSModelLocator;
		
		CONFIG::god private const superSearch:SuperSearch = new SuperSearch();
		
		protected var vp_dims_in_use:String = '1200x800';
		
		private const perf_graph:Stats = new Stats();
		private const perf_graph_container:Sprite = new Sprite();
		private const key_report_tf:TextField = new TextField();
		
		private const version_holder:Sprite = new Sprite();
		
		private var has_focus:Boolean;
		private var inited:Boolean;
		
		private var firstTimeStuffPerformed:Boolean = false;
		
		private var renderer_report_tf:TextField = new TextField();
		
		private function cleanup():void {
			var A:Array = [];
			for (var k:String in model.worldModel.itemstacks) {
				// this first line is I think not nec, as all stacks must be in location.itemstack_tsid_list or pc.itemstack_tsid_list, even if in a container
				//if (model.worldModel.getItemstackByTsid(k).container_tsid) continue; // let's just leave these for now; presumably they are in trophy cases or storage cabinets? 
				if (model.worldModel.location.itemstack_tsid_list[k]) continue;
				if (model.worldModel.pc.itemstack_tsid_list[k]) continue;
				
				A.push(k);
				delete model.worldModel.itemstacks[k];
			}
			if (A.length) Benchmark.addCheck('deleted itemstacks: '+A);
		}
		
		public function init():void {
			if (inited) return;
			inited = true;
			
			BootError.mainView = this;
			BootError.confirmCallback = TSFrontController.instance.reportConfirm;
			
			contextMenu = BootStrap.menu;
			
			model = TSModelLocator.instance;
			registerSelfAsFocusableComponent();
			
			//Setup callbacks for model changes.
			CONFIG::god {
				model.stateModel.registerCBProp(editingChangedHandler, 'editing');
				model.stateModel.registerCBProp(handOfGodChangedHandler, 'hand_of_god');
			}
			TSFrontController.instance.registerMoveListener(this);
			
			model.worldModel.registerCBProp(onLocPcUpdates, "loc_pc_updates");
			model.worldModel.registerCBProp(onLocPcAdds, "loc_pc_adds");
			model.worldModel.registerCBProp(onLocPcDels, "loc_pc_dels");
			model.worldModel.registerCBProp(onBuffUpdates, "buff_updates");
			model.worldModel.registerCBProp(onBuffAdds, "buff_adds");
			model.worldModel.registerCBProp(onBuffDels, "buff_dels");
			model.worldModel.registerCBProp(onLocItemstackUpdates, "loc_itemstack_updates");
			model.worldModel.registerCBProp(onLocItemstackAdds, "loc_itemstack_adds");
			model.worldModel.registerCBProp(onLocItemstackDels, "loc_itemstack_dels");
			
			StageBeacon.focus_in_sig.add(focusInOutHandler);
			StageBeacon.focus_out_sig.add(focusInOutHandler);
			StageBeacon.mouse_down_sig.add(stageMouseDownHandler);
			StageBeacon.key_down_sig.add(maybeShowStats);
			
			// removing for now to see if it removes client errors like: http://staging.glitch.com/god/client_error.php?id=67799
			//setInterval(cleanup, model.flashVarModel.cleanup_ms);
			
			//get the right side setup
			RightSideManager.instance.init();
			
			updateVPDimsMinMax();
			
			addChild(main_container);
			main_container.addChild(masked_container);
			
			masked_container.mask = new Shape();
			main_container.addChild(masked_container.mask);
			
			gameRenderer = new LocationRenderer(this);
			masked_container.addChild(gameRenderer);
			if (!model.flashVarModel.run_mv_from_aph) {
				StageBeacon.enter_frame_sig.add(gameRenderer.onEnterFrame);
			}
			
			LocationInputHandler.instance.locationRenderer = gameRenderer;
			UnFocusedScreenView.instance.setRollover(gameRenderer);
			StoreEmbed.instance.init(gameRenderer);
			
			masked_container.addChild(FlashBulbView.instance);
			
			CONFIG::locodeco {
				ldsb = LocoDecoSideBar.instance;
				ldsb.visible = false;
			}
			
			pdm = PackDisplayManager.instance;
			
			masked_container.addChild(LocationCanvasView.instance);
			masked_container.addChild(UnFocusedScreenView.instance);
			masked_container.addChild(CameraManView.instance);
			masked_container.addChild(FlashUnfocusedView.instance);
			masked_container.addChild(LoadingLocationView.instance);
			CONFIG::locodeco {
				masked_container.addChild(GroundYView.instance);
			}
			pdm.refresh();
			
			CONFIG::locodeco {
				main_container.addChild(ldsb);
			}
			main_container.addChild(GrowlView.instance);
			main_container.addChild(LocationCheckListView.instance);
			main_container.addChild(PromptView.instance);
			main_container.addChild(MiniMapView.instance);
			CONFIG::god {
				main_container.addChild(GodButtonView.instance);
				main_container.addChild(ViewportScaleSliderView.instance);
			}
			main_container.addChild(BuffViewManager.instance);
			
			StageBeacon.stage.addChild(LoginProgressView.instance);
			
			addChild(pdm);
			addChild(YouDisplayManager.instance);
			
			CabinetDialog.instance.init();
			DecoAssetManager.init();
			DecoByteLoader.init();
			
			//DON'T DELETE THESE UNLESS WE MAKE AN INFO MANAGER THAT WILL HANDLE THE CALL BACKS!!!
			GetInfoDialog.instance.init();
			TrophyGetInfoDialog.instance.init();
			
			addChild(TipDisplayManager.instance);
			
			CONFIG::god {
				HandOfGod.instance.init();
			}
			ChassisManager.instance.init();
			CultManager.instance.init();
			ConversationManager.instance.init();
			QuestManager.instance.init();
			
			rook_damage_container.mouseEnabled = false;
			rook_attack_container.mouseEnabled = false;
			rook_damage_container.mouseChildren = false;
			rook_attack_container.mouseChildren = false;
			rook_damage_container.cacheAsBitmap = true;
			rook_attack_container.cacheAsBitmap = true;
			addChild(rook_damage_container);
			addChild(rook_attack_container);
			
			addChild(GlitchrSnapshotView.instance);
			
			CONFIG::god {
				initBuildNumber();
				addChild(version_holder);
			}
			
			addChild(perf_graph_container);
			
			// for DEV/DEBUG users, start stats up immediately, even if not visible
			if (CONFIG::debugging) {
				primePerformanceGraph();
			}
			
			// show stats if necessary
			var can_see_stats:Boolean;
			CONFIG::god {
				can_see_stats = LocalStorage.instance.getUserData(LocalStorage.IS_OPEN_STATS);
			}
			
			CONFIG::perf {
				can_see_stats = can_see_stats && !model.flashVarModel.run_automated_tests;
			}
			performanceGraphVisible = can_see_stats;
			
			// setup RenderMode and change handling.
			LocationCommands.setupRenderMode();
			
			CONFIG::god {
				main_container.addChild(PhysicsRenderer.instance);
				main_container.addChild(PhysicsMovementRenderer.instance);
				main_container.addChild(PhysicsLoopRenderer.instance);
				
				// init the super search
				superSearch.init(SuperSearch.TYPE_ITEMS, 3, 'Summon an item named...');
				superSearch.width = 400;
				superSearch.show_images = true;
				superSearch.addEventListener(TSEvent.CHANGED, onSearchChange);
				
				if (!(CONFIG::locodeco)) {
					StageBeacon.key_down_sig.add(maybeUseBitmapRenderMode);
					StageBeacon.key_down_sig.add(maybeUseVectorRenderMode);
				}
			}
		}
		
		private function initBuildNumber():void {
			const version_tf:TextField = new TextField();
			TFUtil.prepTF(version_tf, false);
			version_tf.embedFonts = false;
			version_tf.mouseEnabled = false;
			version_tf.htmlText = '<span class="version">build ' + engineVersion + '</span>';
			version_holder.addChild(version_tf);
		}
		
		public function addChoicesDialogToDefaultLocation():void {
			if (ChoicesDialog.instance.parent != this) {
				addView(ChoicesDialog.instance);
			}
		}
		
		public function addInteractionMenuToDefaultLocation():void {
			if (InteractionMenu.instance.parent != this) {
				addView(InteractionMenu.instance);
			}
		}
		
		/**
		 * this dude should be called to add all dynamic view things to the stage. All Dialogs go through here, etc, etc
		 * @param DO
		 * @param add_to_bottom puts the DO UNDER the tip_index (useful when you don't want to cover full screen overlays)
		 */		
		public function addView(DO:DisplayObject, add_to_bottom:Boolean = false):void {
			var tip_index:int = getChildIndex(TipDisplayManager.instance);
			
			CONFIG::god {
				if (DO is AdminDialog) {
					addChildAt(DO, tip_index);
					
					//if the tooltip z order is below the admin dialog, then flip em!
					if(getChildIndex(DO) > getChildIndex(TipDisplayManager.instance)){
						swapChildren(DO, TipDisplayManager.instance);
					}
					return;
				}
			}
			
			//don't let it go over metabolics
			tip_index = getChildIndex(YouDisplayManager.instance);
			
			if (DO is ChoicesDialog) {
				addChildAt(DO, tip_index);
			} else if (DO is ThrottledScreenView) {
				addChild(DO);
				changeDialogsZ(DO);
			} else if (DO is RookIncidentHeaderView) {
				addChildAt(DO, tip_index);
				changeDialogsZ(DO);
			} else if (DO is BaseScreenView) {
				addChildAt(DO, tip_index);
				changeDialogsZ(DO);
			} else if (DO is BaseSplashScreenView) {
				//these get added to the container
				tip_index = main_container.getChildIndex(RightSideManager.instance.right_view);
				main_container.addChildAt(DO, tip_index);
				
				//because we are adding this to the viewport, we need to kill any dialogs that are up so it's not covered
				//this *should* be ok, but it may also break some shit, guess we'll wait and see!
				closeDialogs();
			} else if (DO is GrowlQueue) {
				//these get added to the container
				tip_index = main_container.getChildIndex(RightSideManager.instance.right_view);
				main_container.addChildAt(DO, tip_index);
			} else if(DO is Dialog && model.stateModel.screen_view_open && !SnapTravelView.instance.parent){
				//when we have the snap travel view up, we want them to be able to click a player's name to see the dialog
				addChildAt(DO, Math.max(tip_index-1, 0));
			} else if(add_to_bottom){
				addChildAt(DO, tip_index);
			} else {
				addChild(DO);
			}
		}
		
		private function changeDialogsZ(top_DO:DisplayObject):void {
			//when a full screen overlay shows up it'll want to push the dialogs under it
			var i:int;
			var child:DisplayObject;
			
			for(i; i < numChildren; i++){
				child = getChildAt(i);
				if(child is Dialog){
					CONFIG::god {
						if(child is AdminDialog) continue;
					}
					setChildIndex(child, getChildIndex(top_DO));
				}
			}
		}
		
		private function closeDialogs(and_admin:Boolean = false):void {
			//this will close any dialogs that are open, useful when showing a splash screen to the view port so it's not covered
			var i:int;
			var child:DisplayObject;
			
			for(i; i < numChildren; i++){
				child = getChildAt(i);
				if(child is Dialog){
					CONFIG::god {
						if(child is AdminDialog && !and_admin) continue;
					}
					(child as Dialog).end(true);
				}
			}
		}
		
		private function letUrlOverrideMaxDims():void {
			const lm:LayoutModel = model.layoutModel;
			
			// check the url for an override of max dims
			var max_vp_dims_overrideA:Array = model.flashVarModel.max_vp_dims.toUpperCase().split('X');
			if (max_vp_dims_overrideA.length == 2) {
				vp_dims_in_use = model.flashVarModel.max_vp_dims;
				lm.max_vp_w = max_vp_dims_overrideA[0];
				lm.max_vp_h = max_vp_dims_overrideA[1];
				lm.min_vp_w = 0;
				lm.min_vp_w = 0;
			}
		}
		
		private function updateVPDimsMinMax():void {
			const lm:LayoutModel = model.layoutModel;
			// even with the max/min changes below, mind you, the location viewport will never get bigger than stage size minus right column and bottom row (pack)
			
			letUrlOverrideMaxDims();
			
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) {
					if (model.stateModel.editing) {
						; // satisfy compiler
						CONFIG::locodeco {
							// make the max size as requested by LD
							lm.max_vp_w = LocoDecoGlobals.instance.viewportWidth;
							lm.max_vp_h = LocoDecoGlobals.instance.viewportHeight;
						}
					} else if (model.stateModel.hand_of_god) {
						// make the max size as big as possible
						lm.max_vp_w = int.MAX_VALUE;
						lm.max_vp_h = int.MAX_VALUE;
					}
					
					// but no larger than the smallest layer in the current location
					for each (var layer:Layer in model.worldModel.location.layers) {
						lm.max_vp_w = Math.min(lm.max_vp_w, layer.w);
						lm.max_vp_h = Math.min(lm.max_vp_h, layer.h);
					}
				} else {
					// reset to CSS max
					lm.max_vp_w = lm.max_vp_w_css;
					lm.max_vp_h = lm.max_vp_h_css;
					letUrlOverrideMaxDims();
				}
			}
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur')
			}
			has_focus = false;
			
			if (model.stateModel.about_to_be_focused_component.stops_avatar_on_focus) {
				CONFIG::debugging {
					Console.log(99, 'stopAvatar');
				}
				TSFrontController.instance.stopAvatar('TSMV.blur 1 '+getQualifiedClassName(model.stateModel.about_to_be_focused_component), true);
			} else {
				CONFIG::debugging {
					Console.log(99, 'stopAvatarKeyControl')
				}
				TSFrontController.instance.stopAvatarKeyControl('TSMV.blur 2 '+getQualifiedClassName(model.stateModel.about_to_be_focused_component));
			}

			LocationInputHandler.instance.stopListeningForControlEvts();

			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus')
			}
			has_focus = true;
			// this is hacky, but we don't want to start avatar if we're moving.
			if (!model.moveModel.moving) TSFrontController.instance.startAvatar('TSMV.focus');
			
			LocationInputHandler.instance.startListeningForControlEvts();

			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
		}
		
		private function compNeedsKeys(focused_comp:IFocusableComponent):Boolean {
			if (focused_comp is BaseSplashScreenView) return true;
			if (focused_comp is InputDialog) return true;
			if (focused_comp is InteractionMenu) return true;
			if (focused_comp is ChoicesDialog) return true;
			if (focused_comp is NoteDialog) return true;
			if (focused_comp is InputField) return true;
			if (focused_comp is InputTalkBubble) return true;
			if (focused_comp is GardenView) return true;
			if (focused_comp is MailDialog) return true;
			if (focused_comp is CameraMan) return true;
			if (focused_comp is InfoManager) return true;
			if (focused_comp is GlitchrSnapshotView) return true;
			if (focused_comp is GlitchrSavedDialog) return true;
			if (focused_comp is LocationSelectorDialog) return true;
			return false;
		}
		
		private function focusInOutHandler(e:FocusEvent):void {
			var ia:Object;
			
			if (e.type == FocusEvent.FOCUS_IN) {
				ia = e.target;
			} else if (e.type == FocusEvent.FOCUS_OUT) {
				ia = e.relatedObject;
			}
			//Console.warn(e.type+' '+StringUtil.getShortClassName(ia))
			if (!ia) {
				//Console.warn('WTF' +e.type);
			}
			
			//this something we can type in?
			model.stateModel.focus_is_in_input = (ia is TextField && TextField(ia).type == TextFieldType.INPUT);
			
			CONFIG::debugging {
				Console.trackValue('TSMV focus', getQualifiedClassName(ia));
			}
			//if (ia is TextField) Console.warn(TextField(ia).type) else Console.warn(getQualifiedClassName(ia));
			
			if (model.stateModel.focus_is_in_input) {
				model.stateModel.focused_input = TextField(ia);
			} else {
				model.stateModel.focused_input = null;
			}
			
			if (compNeedsKeys(model.stateModel.focused_component) || model.stateModel.focus_is_in_input) {
				//Console.warn('stop keys')
				stopListeningtoKeys();
			} else {
				//Console.warn('start keys')
				startListeningtoKeys();
			}
		}
		
		private var listening_to_keys:Boolean;
		private function startListeningtoKeys():void {
			if (listening_to_keys) return;
			KeyBeacon.instance.addEventListener(KeyBeacon.ALT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.TAB, altTabKeyDownHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.ALT_PLUS_+KeyBeacon.KEY_UP_+Keyboard.TAB, altTabKeyUpHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.M, mKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.L, lKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.B, bKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.C, cKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.COMMA, commaKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.I, iKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.C, shiftCKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.S, shiftSKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.T, shiftTKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.M, shiftMKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.K, shiftKKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.L, shiftLKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.D, shiftDKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.F, shiftFKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.BACKQUOTE, shiftFKeyHandler); //same as inventory search
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.SLASH, shiftSlashKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_UP_+Keyboard.SLASH, shiftSlashKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.U, uKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.X, xKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.Z, zKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_, allKeyHandler); // arugably this shoudl only be added in focis, like esc key handler
			TSFrontController.instance.startListeningToZoomKeys(zoomKeyHandler);
			CONFIG::god {
				KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.SPACE, showSuperSearch);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, hideSuperSearch);
				CONFIG::locodeco {
					KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.E, shiftEKeyHandler);
				}
			}
			listening_to_keys = true;
			CONFIG::debugging {
				Console.trackValue('TSMV listening_to_keys', listening_to_keys);
			}
		}
		
		private function stopListeningtoKeys():void {
			if (!listening_to_keys) return;
			KeyBeacon.instance.removeEventListener(KeyBeacon.ALT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.TAB, altTabKeyDownHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.ALT_PLUS_+KeyBeacon.KEY_UP_+Keyboard.TAB, altTabKeyUpHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.M, mKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.L, lKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.B, bKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.C, cKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.COMMA, commaKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.I, iKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.C, shiftCKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.S, shiftSKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.T, shiftTKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.M, shiftMKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.K, shiftKKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.L, shiftLKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.D, shiftDKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.F, shiftFKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.BACKQUOTE, shiftFKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.SLASH, shiftSlashKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_UP_+Keyboard.SLASH, shiftSlashKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.U, uKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.X, xKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.Z, zKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_, allKeyHandler);
			TSFrontController.instance.stopListeningToZoomKeys(zoomKeyHandler);
			CONFIG::god {
				KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.SPACE, showSuperSearch);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, hideSuperSearch);
				CONFIG::locodeco {
					KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.E, shiftEKeyHandler);
				}
			}
			
			listening_to_keys = false;
			CONFIG::debugging {
				Console.trackValue('TSMV listening_to_keys', listening_to_keys);
			}
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			if (compNeedsKeys(focused_comp) || model.stateModel.focus_is_in_input) {
				stopListeningtoKeys();
			} else {
				startListeningtoKeys();
			}
			UnFocusedScreenView.instance.focusChanged(focused_comp, was_focused_comp);
			InventorySearchManager.instance.focusChanged(focused_comp, was_focused_comp);
		}
		
		private function zoomKeyHandler(e:KeyboardEvent):void {
			// it's important that we don't add shared listeners directly to TSFC
			// because where one class has started listening, another might
			// remove the same listener by accident, so the first class fails
			TSFrontController.instance.zoomKeyHandler(e);
		}

		private function mKeyHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			if (!MiniMapView.instance.visible) return;
			if (!model.worldModel.location.show_hubmap) return;
			TSFrontController.instance.toggleHubMapDialog();
		}
		
		private function altTabKeyUpHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) return;
			}
			if (!MiniMapView.instance.visible) return;
			if (!HubMapDialog.instance.parent) return;
			if (!model.worldModel.location.show_hubmap) return;
			TSFrontController.instance.toggleHubMapDialog();
		}
		
		private function altTabKeyDownHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) return;
			}
			if (!MiniMapView.instance.visible) return;
			if (HubMapDialog.instance.parent) return;
			if (!model.worldModel.location.show_hubmap) return;
			TSFrontController.instance.toggleHubMapDialog();
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_UP_+Keyboard.ALTERNATE, tabUpAfterAltTabDown);
		}
		
		private function tabUpAfterAltTabDown(e:KeyboardEvent):void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_UP_+Keyboard.ALTERNATE, tabUpAfterAltTabDown);
			
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) return;
			}
			if (!MiniMapView.instance.visible) return;
			if (!HubMapDialog.instance.parent) return;
			if (!model.worldModel.location.show_hubmap) return;
			TSFrontController.instance.toggleHubMapDialog();
		}
		
		private function lKeyHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			// no opening the quest log until you get your first quest
			if (model.worldModel.location.no_imagination && (!model.worldModel.quests || model.worldModel.quests.length == 0)) {
				return;
			}
			TSFrontController.instance.toggleQuestsDialog();
		}
		
		private function cKeyHandler(e:KeyboardEvent):void {			
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) return;
			}
			
			if (model.stateModel.decorator_mode || model.stateModel.chassis_mode || model.stateModel.cult_mode) return;

			
			TSFrontController.instance.goNotAFK();
			TSFrontController.instance.maybeStartCameraManUserMode('TSMV.cKeyHandler');
		}
		
		CONFIG::locodeco private function shiftEKeyHandler(e:KeyboardEvent):void {
			TSFrontController.instance.setEditMode(!model.stateModel.editing);
		}
		
		private function commaKeyHandler(e:KeyboardEvent):void {			
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) return;
			}
			
			if (!PrefsDialog.instance.is_open) {
				PrefsDialog.instance.start();
			}
		}
		
		private function shiftCKeyHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//cultivation mode
			if (model.stateModel.cult_mode) {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				TSFrontController.instance.stopCultMode();
			} else {
				HouseManager.instance.startCultivation();
			}
		}
		
		private function shiftDKeyHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//decorate mode
			if (model.stateModel.decorator_mode) {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				TSFrontController.instance.stopDecoratorMode();
			} else {
				TSFrontController.instance.startDecoratorMode();
			}
		}
		
		private function shiftFKeyHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			if (!InventorySearchManager.instance.canStart()) return;
			
			//inventory search
			YouDisplayManager.instance.pack_tabber.showInventorySearch();
		}
		
		private function bKeyHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing) return;
				if (KeyBeacon.instance.pressed(Keyboard.Q)) return;
			}
			
			//make sure we can see the pack
			if(!pdm.is_viz || pdm.getOpenTabName() != PackTabberUI.TAB_PACK) return;
			
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			TSFrontController.instance.togglePackDisplayManagerFocus();
		}
		
		private function iKeyHandler(e:KeyboardEvent):void {
			//make sure we can see the imagination menu
			if(model.worldModel.location.no_imagination) return;
			
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) return;
			}
			
			// allow only InfoManager to close it with the I key
			if (model.stateModel.info_mode) return; 
			
			if (model.stateModel.decorator_mode || model.stateModel.chassis_mode || model.stateModel.cult_mode) return;
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//info mode
			if (model.stateModel.info_mode) {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				TSFrontController.instance.stopInfoMode();
			} else {
				TSFrontController.instance.startInfoMode();
			}
		}
		
		private function shiftSKeyHandler(e:KeyboardEvent):void {
			CONFIG::locodeco {
				if (model.stateModel.editing) {
					TSFrontController.instance.saveLocoDecoChanges();
				}
			}
			
			//make sure we can see the imagination menu
			if(model.worldModel.location.no_imagination) return;
			
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//open the skill cloud
			if(!ImgMenuView.instance.parent){
				ImgMenuView.instance.cloud_to_open = Cloud.TYPE_SKILLS;
				ImgMenuView.instance.show();
			}
		}
		
		private function shiftTKeyHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//toggle the teleport dialog
			RightSideManager.instance.setChatMapTab(MapChatArea.TAB_TELEPORT);
		}
		
		private function shiftMKeyHandler(e:KeyboardEvent):void {
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//show the chat map
			const tab_name:String = RightSideManager.instance.right_view.getChatMapTab();
			if(!tab_name || tab_name != MapChatArea.TAB_MAP){
				RightSideManager.instance.setChatMapTab(MapChatArea.TAB_MAP);
			}
			else if(tab_name == MapChatArea.TAB_MAP){
				//hide it
				RightSideManager.instance.setChatMapTab(MapChatArea.TAB_NOTHING);
			}
		}
		
		private function shiftSlashKeyHandler(e:KeyboardEvent):void {
			//make sure we can see the imagination menu
			if(model.worldModel.location.no_imagination) return;
			
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//figure out what we're doing
			if(e.type.indexOf('KEY_DOWN') > 0){
				Hotkeys.instance.show();
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_UP_+Keyboard.SHIFT, shiftSlashKeyHandler, false, 0, true);
			}
			else {
				Hotkeys.instance.hide();
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_UP_+Keyboard.SHIFT, shiftSlashKeyHandler);
			}
		}
		
		private function shiftKKeyHandler(e:KeyboardEvent):void {
			//make sure we can see the imagination menu
			if(model.worldModel.location.no_imagination) return;
			
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//open the keys
			if(!ACLDialog.instance.parent){
				ACLDialog.instance.start();
			}
			else {
				ACLDialog.instance.end(true);
			}
		}
		
		private function shiftLKeyHandler(e:KeyboardEvent):void {
			//make sure we can see the imagination menu
			if(model.worldModel.location.no_imagination) return;
			
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//open your looks
			if(!ImaginationYourLooksUI.instance.parent){
				ImgMenuView.instance.cloud_to_open = Cloud.TYPE_YOUR_LOOKS;
				ImgMenuView.instance.show();
			}
		}
		
		private function uKeyHandler(e:KeyboardEvent):void {
			//make sure we can see the imagination menu
			if(model.worldModel.location.no_imagination) return;
			
			CONFIG::god {
				if (model.stateModel.editing) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			//open the upgrade cards
			if(!ImgMenuView.instance.parent){
				ImgMenuView.instance.cloud_to_open = Cloud.TYPE_UPGRADES;
				ImgMenuView.instance.show();
			}
		}
		
		private function xKeyHandler(e:KeyboardEvent):void {
			//make sure we can see the imagination menu
			if(model.worldModel.location.no_imagination) return;
			
			CONFIG::god {
				if (model.stateModel.editing) return;
				if (KeyBeacon.instance.pressed(Keyboard.Q)) return;
			}
			
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			if(ImgMenuView.instance.parent){
				ImgMenuView.instance.hide();
			}
			else {
				ImgMenuView.instance.show();
			}
		}
		
		private function zKeyHandler(e:KeyboardEvent):void {
			//make sure we can see the player face/mood
			if(model.worldModel.location.no_mood) return;
			
			CONFIG::god {
				if (model.stateModel.editing) return;
				if (KeyBeacon.instance.pressed(Keyboard.Q)) return;
			}
			if (checkAndCorrectIfInputFieldIsStageFocus()) return;
			
			TSFrontController.instance.togglePlayerMenu();
		}
		
		CONFIG::god public function get superSearchVisible():Boolean {
			return (superSearch.parent && superSearch.visible);
		}
		
		CONFIG::god private function showSuperSearch(event:Event):void {
			superSearch.x = model.layoutModel.gutter_w + (model.layoutModel.loc_vp_w - superSearch.width)/2;
			superSearch.y = model.layoutModel.header_h + (model.layoutModel.loc_vp_h - superSearch.height)/2;
			StageBeacon.stage.addChild(superSearch);
			superSearch.show(true, "Summon an item named...");
		}
		
		CONFIG::god private function onSearchChange(event:TSEvent):void {
			const tsid:String = event && event.data ? (event.data as SuperSearchElementItem).value : null;
			if(tsid){
				const item:Item = TSModelLocator.instance.worldModel.getItemByTsid(tsid);
				if(item) {
					AdminDialog.instance.startStampDraggingItem(item.tsid, 0, '1');
					// hide item search box
					if (superSearch.parent) {
						superSearch.parent.removeChild(superSearch);
						superSearch.hide();
					}
				}
			}
		}
		
		/** Returns true if the box was showing and is now hidden */
		CONFIG::god private function hideSuperSearch(event:Event):void {
			// abort if we are currently stamping itemstacks (escape stops it)
			if (model.stateModel.is_stamping_itemstacks) {
				return;
			}
			
			// hide item search box
			if (superSearch.parent) {
				superSearch.parent.removeChild(superSearch);
				superSearch.hide();
			}
		}
		
		private function escKeyHandler(event:KeyboardEvent):void {
			if (!hasFocus()) return;
			
			// since CultManager does not always take focus, we must listen here for ESC key to cancel
			if (model.stateModel.cult_mode) {
				CultManager.instance.escKeyHandler(event);
				return;
			}
			
			// decide if any non-modal Dialogs are active and should be closed
			var highestZ:int = -1;
			var highestDialog:Dialog = null;
			
			var dialogZ:int;
			var dialog:Dialog;
			var dialogParent:DisplayObjectContainer;
			
			// add to this anything you want to be able to escape out of
			const dialogs:Array = [HubMapDialog.instance, QuestsDialog.instance];
			if (!model.flashVarModel.ok_on_info) {
				dialogs.push(GetInfoDialog.instance);
			}
			
			for each (dialog in dialogs) {
				dialogParent = dialog.parent;
				if (dialogParent) {
					dialogZ = dialogParent.getChildIndex(dialog);
					if (dialogZ > highestZ) {
						highestZ = dialogZ;
						highestDialog = dialog;
					}
				}
			}
			if (highestDialog) {
				CONFIG::debugging {
					Console.info(getQualifiedClassName(highestDialog)+' closed by esc key in TSMainView');
				}
				highestDialog.escKeyHandler(event);
			}
		}
		
		// return true when stage focus in a textField
		private function checkAndCorrectIfInputFieldIsStageFocus(report_it:Boolean=false):Boolean {
			CONFIG::god {
				// the focus shit does not work so well with locodeco enabled
				if (model.stateModel.editing || model.stateModel.hand_of_god) return false;
			}
			
			if (StageBeacon.stage.focus && StageBeacon.stage.focus is TextField && TextField(StageBeacon.stage.focus).type == TextFieldType.INPUT) {
				if (report_it) {
					Benchmark.addCheck('why are we listening to keys?');
					Benchmark.addCheck('-model.stateModel.focused_input:'+StringUtil.DOPath(model.stateModel.focused_input));
					Benchmark.addCheck('-StageBeacon.stage.focus:'+StringUtil.DOPath(StageBeacon.stage.focus as DisplayObject));
				}
				var inf:InputField = InputField.getInputFieldParentOfTF(StageBeacon.stage.focus as TextField);
				var intb:InputTalkBubble = InputTalkBubble.getInputTalkBubbleParentOfTF(StageBeacon.stage.focus as TextField);
				
				if (inf) {
					if (report_it) Benchmark.addCheck('-textfield focused IS in InputField ');
					if (model.stateModel.focused_component != inf) {
						if (report_it) Benchmark.addCheck('-InputField is NOT model.stateModel.focused_component, this is:'+StringUtil.getShortClassName(model.stateModel.focused_component));
						inf.focusOnInput();
					} else {
						if (report_it) Benchmark.addCheck('-InputField IS model.stateModel.focused_component');
					}
					
				} else if (intb) {
					if (report_it) Benchmark.addCheck('-textfield focused IS in RenameBubble ');
					if (model.stateModel.focused_component != intb) {
						if (report_it) Benchmark.addCheck('-RenameBubble is NOT model.stateModel.focused_component, this is:'+StringUtil.getShortClassName(model.stateModel.focused_component));
						InputTalkBubble.getInputTalkBubbleParentOfTF(StageBeacon.stage.focus as TextField).focusOnInput();
					} else {
						if (report_it) Benchmark.addCheck('-RenameBubble IS model.stateModel.focused_component');
					}
					
				} else {
					if (report_it) Benchmark.addCheck('-textfield focused is NOT in InputField or RenameBubble');
				}
				//<eric> scott, try commenting out TSMV line 1163 for now, and let me know if you see any actual problems caused by the issue 
				//(like if pressing keys while focussed in the QP does things it shoudl not)
				//if (report_it) BootError.handleError('checkAndCorrectIfInputFieldIsStageFocus found a bad situ!', new Error('WHY LISTENING TO KEYS??'), ['focus'], !CONFIG::god);
				
				return true;
			}
			
			return false;
		}
		
		private function allKeyHandler(e:KeyboardEvent):void {
			if (checkAndCorrectIfInputFieldIsStageFocus(true)) return;
			if (model.flashVarModel.do_single_interaction_sp_keys) {
				TSFrontController.instance.applyKeyCodeToSingleInteractionSP(e.keyCode);
			}
		}
		
		private function stageMouseDownHandler(e:MouseEvent):void {
			var focused_cl:Class;
			
			if (model.stateModel.focused_component is InteractionMenu) focused_cl = InteractionMenu as Class;
			if (model.stateModel.focused_component is ChoicesDialog) focused_cl = ChoicesDialog as Class;
			if (model.stateModel.focused_component is PackDisplayManager) focused_cl = PackDisplayManager as Class;
			if (!focused_cl) return;
			
			var click_was_in_interaction_menu:Boolean;
			var click_was_in_choices_dialog:Boolean;
			var click_was_in_location:Boolean;
			var element:DisplayObject = e.target as DisplayObject;
			while (element && element != StageBeacon.stage) {
				if (element is InteractionMenu) click_was_in_interaction_menu = true;
				if (element is ChoicesDialog) click_was_in_choices_dialog = true;
				if (element.name == 'choices_dialog_buttons_sprite') click_was_in_choices_dialog = true;
				
				if (element is LocationRenderer) {
					if (model.stateModel.focused_component is ChoicesDialog && ChoicesDialog.instance.click_loc_to_cancel) {
						if (!click_was_in_choices_dialog) ChoicesDialog.instance.goAway();
					}
				} 
				
				if (element is LocationRenderer || element is PackDisplayManager) { // in these two click cases, we know we want to end things
					if (focused_cl == InteractionMenu) InteractionMenu.instance.goAway();
					if (focused_cl == PackDisplayManager) {
						TSFrontController.instance.releaseFocus(PackDisplayManager.instance);
					}
					return;
				}
				element = element.parent;
			}
			
			// ok, we went all the up the tree; if we found the click was not in the InteractionMenu and the InteractionMenu is focused, end it
			if (focused_cl == InteractionMenu && !click_was_in_interaction_menu) {
				InteractionMenu.instance.goAway();
			}
		}
		
		// Engine responds to stage resize events, and calls this.
		public function resizeToStage():void {
			if (!gameRenderer) return;
			
			//right side sets it's width dynamically and updates the layout model
			RightSideManager.instance.right_view.refresh();
			
			TSFrontController.instance.setCameraOffset();
			
			const lm:LayoutModel = model.layoutModel;
			const ui_allowance_w:int = stage.stageWidth - (lm.min_gutter_w*2);
			var ui_allowance_h:int = stage.stageHeight - lm.min_header_h;
			
			const loc_vp_w:int = MathUtil.clamp(lm.min_vp_w, lm.max_vp_w, (ui_allowance_w - lm.right_col_w));
			var loc_vp_h:int = ui_allowance_h - TSEngineConstants.MIN_PACK_HEIGHT - 6;
			CONFIG::god {
				// make it take up the full height without the pack
				if (model.stateModel.editing || model.stateModel.hand_of_god) loc_vp_h = ui_allowance_h - 20;
			}
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					// make it take up the full height without the pack
					loc_vp_h = ui_allowance_h - 20;
				}
			}
			loc_vp_h = MathUtil.clamp(lm.min_vp_h, lm.max_vp_h, loc_vp_h);
			
			// find the dimensions of the smallest layer
			const loc:Location = model.worldModel.location;
			var smallestLayerW:int = int.MAX_VALUE;
			var smallestLayerH:int = int.MAX_VALUE;
			if (loc) {
				smallestLayerW = (loc.r - loc.l);
				smallestLayerH = (loc.b - loc.t);
				for each (var layer:Layer in loc.layers) {
					smallestLayerW = Math.min(smallestLayerW, layer.w);
					smallestLayerH = Math.min(smallestLayerH, layer.h);
				}
				// limit the vp height by the height of the smallest layer
				loc_vp_h = Math.min(loc_vp_h, smallestLayerH);
			}
			
			// update layout model with values needed to refresh all views
			lm.loc_vp_h = loc_vp_h;
			lm.loc_vp_w = loc_vp_w;
			lm.overall_w = lm.right_col_w + lm.loc_vp_w;
			lm.gutter_w = Math.max(lm.min_gutter_w, Math.round((stage.stageWidth-lm.overall_w)/2));
			lm.header_h = lm.min_header_h;
			
			// recompute location zoom bounds
			lm.max_loc_vp_scale = model.flashVarModel.max_zoom;
			lm.min_loc_vp_scale = Math.max(model.flashVarModel.min_zoom, (lm.loc_vp_h / smallestLayerH), (lm.loc_vp_w / smallestLayerW));
			lm.min_loc_vp_scale = Math.min(lm.max_loc_vp_scale, lm.min_loc_vp_scale);
			// re-set the scale just in case it needs to change due to above
			TSFrontController.instance.setViewportScale(lm.loc_vp_scale, 0);
			
			main_container.x = lm.gutter_w;
			main_container.y = lm.header_h;
			
			// bottom right corner
			perf_graph_container.x = StageBeacon.stage.stageWidth - Stats.WIDTH;
			perf_graph_container.y = StageBeacon.stage.stageHeight - Stats.HEIGHT;
			version_holder.x = StageBeacon.stage.stageWidth - version_holder.width;
			version_holder.y = StageBeacon.stage.stageHeight - version_holder.height;
			
			rook_damage_container.scrollRect = new Rectangle(0, 0, StageBeacon.stage.stageWidth, StageBeacon.stage.stageHeight);
			rook_attack_container.scrollRect = new Rectangle(0, 0, StageBeacon.stage.stageWidth, StageBeacon.stage.stageHeight);

			refreshViews();
		}
	
		public function refreshViews():void {
			const lm:LayoutModel = model.layoutModel;
			
			//figure out if the chat should snap down or not
			lm.pack_is_wide = lm.loc_vp_w <= pdm.root_container_width + 5;
			
			LoginProgressView.instance.refresh();
			YouDisplayManager.instance.refresh();
			RightSideManager.instance.right_view.refresh();
			
			var g:Graphics = Shape(masked_container.mask).graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(0);
			g.drawRoundRect(0, 0, lm.overall_w, lm.loc_vp_h, lm.loc_vp_elipse_radius*2);
			
			g = graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(model.layoutModel.bg_color);
			g.drawRect(0, 0, StageBeacon.stage.stageWidth, StageBeacon.stage.stageHeight);
			
			CONFIG::locodeco {
				if (ldsb) ldsb.refresh();
				GroundYView.instance.refresh();
			}
			LoadingLocationView.instance.refresh();
			LocationCanvasView.instance.refresh();
			FlashUnfocusedView.instance.refresh();
			CameraManView.instance.refresh();
			GlitchrSnapshotView.instance.refresh();
			FlashBulbView.instance.refresh();
			
			gameRenderer.refresh();
			
			CONFIG::god {
				PhysicsRenderer.instance.setSize(lm.loc_vp_w, lm.loc_vp_h);
				PhysicsMovementRenderer.instance.setSize(lm.loc_vp_w, lm.loc_vp_h);
				PhysicsLoopRenderer.instance.setSize(lm.loc_vp_w, lm.loc_vp_h);
			}
			
			MiniMapView.instance.refresh();
			CONFIG::god {
				GodButtonView.instance.refresh();
				ViewportScaleSliderView.instance.refresh();
			}
			
			PromptView.instance.refresh();
			BuffViewManager.instance.refresh();
			
			pdm.refresh();
			
			CabinetDialog.instance.refresh();
			TrophyCaseDialog.instance.refresh();

			InputTalkBubble.instance.refresh();
			ChoicesDialog.instance.refresh();
			
			DisconnectedScreenView.instance.refresh();
			UnFocusedScreenView.instance.refresh();
			if (model.flashVarModel.throttle_swf) {
				ThrottledScreenView.instance.refresh();
			}
			
			RookManager.instance.showPts();
			RookIncidentHeaderView.instance.refresh();
			ScoreManager.instance.refresh();
			
			//dispatch all the IRefreshListeners
			TSFrontController.instance.dispatchRefreshListeners();
			
			UICalloutView.instance.refresh();
			
			if (model.flashVarModel.show_buildtime) {
				const buildometer:DisplayObject = StageBeacon.stage.getChildByName('buildometer');
				buildometer.x = 3;
				buildometer.y = StageBeacon.stage.stageHeight - buildometer.height - 3;
			}
		}
		
		public function onLocPcAdds(tsids:Array):void {
			MiniMapView.instance.onLocPcAdds(tsids);
			gameRenderer.onLocPcAdds(tsids);
			TSFrontController.instance.cleanUpPcAdds();
		}
		
		public function onLocPcDels(tsids:Array):void {
			MiniMapView.instance.onLocPcDels(tsids);
			gameRenderer.onLocPcDels(tsids);
			TSFrontController.instance.cleanUpPcDels();
		}
		
		public function onLocPcUpdates(tsids:Array):void {
			if (model.worldModel.location) MiniMapView.instance.onLocPcUpdates(tsids);
			gameRenderer.onLocPcUpdates(tsids);
			TSFrontController.instance.cleanUpPcUpdates();
		}
		
		public function onBuffAdds(tsids:Array):void {
			BuffViewManager.instance.onBuffAdds(tsids);
			TSFrontController.instance.cleanUpBuffAdds();
		}
		
		public function onBuffDels(tsids:Array):void {
			BuffViewManager.instance.onBuffDels(tsids);
			TSFrontController.instance.cleanUpBuffDels();
		}
		
		public function onBuffUpdates(tsids:Array):void {
			BuffViewManager.instance.onBuffUpdates(tsids);
			TSFrontController.instance.cleanUpBuffUpdates();
		}
		
		public function onLocItemstackUpdates(tsids:Array):void {
			var As:Object = ContainersUtil.getItemstackTsidAsGroupedByContainer(tsids, model.worldModel.itemstacks);
			CabinetDialog.instance.onLocItemstackUpdates(tsids);
			TrophyCaseManager.instance.updateTrophiesOnCase(tsids);
			TrophyCaseDialog.instance.onLocItemstackUpdates(tsids);
			GardenManager.instance.update(tsids);
			HandOfDecorator.instance.onLocItemstackUpdates(tsids);
			FancyDoor.instance.onLocItemstackUpdates(tsids);
			if (model.worldModel.location) MiniMapView.instance.onLocItemstackUpdates(tsids);
			gameRenderer.onLocItemstackUpdates(As.root);
			CultManager.instance.onLocItemstackUpdates(As.root);
			TSFrontController.instance.cleanUpLocItemstackUpdates();
		}
		
		public function onLocItemstackAdds(tsids:Array):void {
			var As:Object = ContainersUtil.getItemstackTsidAsGroupedByContainer(tsids, model.worldModel.itemstacks);
			CabinetDialog.instance.onLocItemstackAdds(tsids);
			TrophyCaseManager.instance.updateTrophiesOnCase(tsids);
			TrophyCaseDialog.instance.onLocItemstackAdds(tsids);
			HandOfDecorator.instance.onLocItemstackAdds(tsids);
			FancyDoor.instance.onLocItemstackAdds(tsids);
			MiniMapView.instance.onLocItemstackAdds(tsids);
			gameRenderer.onLocItemstackAdds(As.root);
			CultManager.instance.onLocItemstackAdds(As.root);
			TSFrontController.instance.cleanUpLocItemstackAdds();
		}
		
		public function onLocItemstackDels(tsids:Array):void {
			CONFIG::god {
				HandOfGod.instance.onLocItemstackDels(tsids);
			}
			var As:Object = ContainersUtil.getItemstackTsidAsGroupedByContainer(tsids, model.worldModel.itemstacks);
			CultManager.instance.onLocItemstackDels(As.root);
			MiniMapView.instance.onLocItemstackDels(tsids);
			gameRenderer.onLocItemstackDels(As.root);
			CabinetDialog.instance.onLocItemstackDels(tsids);
			TrophyCaseManager.instance.updateTrophiesOnCase(tsids);
			TrophyCaseDialog.instance.onLocItemstackDels(tsids);
			GardenManager.instance.remove(tsids);
			HandOfDecorator.instance.onLocItemstackDels(tsids);
			FancyDoor.instance.onLocItemstackDels(tsids);
			TSFrontController.instance.cleanUpLocItemstackDels();
		}
		
		public function onPcItemstackAdds(tsids:Array):void {
			pdm.onPcItemstackAdds(tsids);
			TrophyCaseDialog.instance.onPcItemstackAdds(tsids);
			TradeDialog.instance.onPcItemstackAdds(tsids);
			FurnitureBagUI.instance.onPcItemstackAdds(tsids);
			TSFrontController.instance.cleanUpPcItemstackAdds();
			StoreDialog.instance.updateBuyBtTips();
		}
		
		public function onPcItemstackUpdates(tsids:Array):void {
			pdm.onPcItemstackUpdates(tsids);
			TrophyCaseDialog.instance.onPcItemstackUpdates(tsids);
			TradeDialog.instance.onPcItemstackUpdates(tsids);
			FurnitureBagUI.instance.onPcItemstackUpdates(tsids);
			TSFrontController.instance.cleanUpPcItemstackUpdates();
			StoreDialog.instance.updateBuyBtTips();
		}
		
		public function onPcItemstackDels(tsids:Array):void {
			pdm.onPcItemstackDels(tsids);
			TrophyCaseDialog.instance.onPcItemstackDels(tsids);
			TradeDialog.instance.onPcItemstackDels(tsids);
			FurnitureBagUI.instance.onPcItemstackDels(tsids);
			TSFrontController.instance.cleanUpPcItemstackDels();
			StoreDialog.instance.updateBuyBtTips();
		}
		
		private function makeVisibleFirstTime():void {
			if (visible) return;
			visible = true;
			alpha = 0;
			
			Benchmark.addCheck('TSMV.makeVisibleFirstTime');
			
			if (!model.flashVarModel.no_bug) {
				if (stage.getChildByName('bug')) stage.removeChild(stage.getChildByName('bug'));
			}
			
			if (BootStrapController.instance.loadingViewHolder) {
				TSTweener.addTween(BootStrapController.instance.loadingViewHolder, {alpha:0, transition:'linear', time:.2, onComplete:function():void {
					BootStrapController.instance.dispose();
					
					//fade out the sound
					if(SoundManager.instance.music_volume){
						SoundManager.instance.stopSound('OPENING_SCREEN_MUSIC', BootStrapController.AUDIO_FADE_TIME);
					}
					
					//play the first loading screen sound
					if(SoundManager.instance.sfx_volume){
						SoundManager.instance.playSound('FIRST_STREET_LOADING', SoundManager.instance.sfx_volume);
					}
					
				}});
			}
			var delay:Number = .2;
			TSTweener.addTween(this, {alpha:1, transition:'linear', time:.2, delay:delay});
		}
		
		protected function doFirstTimeStuff(location:Location):void {
			// load er up
			RookManager.instance.init();
			
			if (model.flashVarModel.display_performance_tips) {
				PerformanceMonitor.init(StageBeacon.stage);
			}
			
			StageBeacon.setTimeout(function():void {
				PromptView.instance.checkForNewPrompts();
				if (model.flashVarModel.fake_prompts) PromptView.instance.startFakingPrompts();
			}, 15000);
			
			TSFrontController.instance.requestFocus(this);
			YouDisplayManager.instance.init();
			InventorySearchManager.instance.init();
			MiniMapView.instance.init();
			BuffViewManager.instance.refresh();
			SkillManager.instance.init();
			
			TSFrontController.instance.runAvatarController();
			
			pdm.init(gameRenderer);
			
			model.worldModel.registerCBProp(onPcItemstackUpdates, "pc_itemstack_updates");
			model.worldModel.registerCBProp(onPcItemstackAdds, "pc_itemstack_adds");
			model.worldModel.registerCBProp(onPcItemstackDels, "pc_itemstack_dels");
			
			//build it the first time
			RightSideManager.instance.right_view.init();
			
			CONFIG::locodeco {
				ldsb.init();
			}
			
			AnnouncementController.instance.init();
			
			/*CONFIG::god {
			// test here for local data to see if it was open at last client close
			if (model.flashVarModel.show_help) {
			setTimeout(function():void {
			AdminDialog.instance.start();
			}, 1000)
			}
			}*/
			
			CONFIG::god {
				// run unit test suite
				Benchmark.addCheck('Running unit tests...');
				var core:TextCore = new TextCore();
				core.addListener(new BenchmarkUnitTestRunner());
				core.textPrinter.hideLocalPaths = true;
				core.start(EngineAllTests, null, null);
			}
			
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					PerfTestManager.init(StageBeacon.stage);
				}
			}
			
			StageBeacon.setTimeout(
				TSFrontController.instance.maybeTalkToFamiliar,
				2000
			);
			
			
			if (model.flashVarModel.reload_hourly) {
				StageBeacon.setTimeout(
					TSFrontController.instance.simulateIncomingMsg,
					60000*60,
					{
						type: MessageTypes.FORCE_RELOAD,
						at_next_move: true,
						msg: 'This is your scheduled hourly reload!'
					}
				)
			}
			
			firstTimeStuffPerformed = true;
		}
		
		// IMoveListener funcs
		// -----------------------------------------------------------------
		
		public function moveMoveStarted():void {
			const tsfc:TSFrontController = TSFrontController.instance;
			tsfc.goNotAFK();
			
			tsfc.stopAvatar('TSMV.moveMoveStarted');
			RookManager.instance.onMovement(true);
			tsfc.changeTeleportDialogVisibility();
			tsfc.changeMiniMapVisibility();
			tsfc.changeHubMapVisibility();
			tsfc.changePCStatsVisibility();
			
			// just hide it in all cases for now
			tsfc.hideLocationCheckListView();

			if (CabinetDialog.instance.visible) {
				CabinetDialog.instance.end();
			}
			
			if (InputTalkBubble.instance.request_uid) {
				InputTalkBubble.instance.forceCancel();
			}
			
			// one hopes this does not fuck everthing up!
			AnnouncementController.instance.cancelAllOverlaysWeCan();
			
			if (model.moveModel.to_tsid && model.worldModel.locations[model.moveModel.to_tsid]) {
				
				// avoid visual artifacts while the LoadingLocationView fades in
				gameRenderer.pause();
				
				FakeFriends.instance.onMoveStarted();
				
				StageBeacon.setTimeout(function():void {
					TipDisplayManager.instance.pause();
					//force a refresh of the dialogs; if they detect that we are moving, they will close (and can set close_on_move = false to stay open during a move)
					refreshViews();
					
					// ChoicesDialog is a special case dialog
					ChoicesDialog.instance.goAway(); // I hope this does not cause trouble!
					
					tsfc.endFamiliarDialog();
					
					tsfc.endCameraManUserMode();
					
					// show the loading screen now!
					LoadingLocationView.instance.fadeIn();
					
					if (!visible) makeVisibleFirstTime();
					
					// until this point in loading client, UnFocusedScreenView.instance.opacity has been zero. so it is not ugly during initial load
					if (false) UnFocusedScreenView.instance.opacity = .1;
					
					LocationCanvasView.instance.hide();
				}, model.moveModel.delay_loading_screen_ms);
				
				// reset this, as it is meant as a per move thing
				model.moveModel.delay_loading_screen_ms = 0;
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					if (model.moveModel.to_tsid) {
						model.activityModel.growl_message = 'DEBUG: move started, but I do not have a location object yet';
					} else {
						model.activityModel.growl_message = 'DEBUG: move started, but I do not have a location tsid yet';
					}
					Console.error('!!!move started, but I do not have a location object yet!!!');
				}
			}
			
			// the new location might affect the sizing of UI
			// e.g. if it is shorter than the height of the viewport
			resizeToStage();
		}
		
		public function moveMoveEnded():void {
			const tsfc:TSFrontController = TSFrontController.instance;
			tsfc.goNotAFK();
			
			//Console.warn('moveMoveEnded model.moveModel.moving_to_new_location: '+model.moveModel.moving_to_new_location);
			//Console.warn('moveMoveEnded model.moveModel.move_failed: '+model.moveModel.move_failed);
			
			refreshViews();
			
			// is this ok to simply bail? it seems to be
			// TSFrontController.instance.startAvatar is called when tsmv gets focus, so we're ok there
			// gameRenderer.updateDynamic(); is not necessary, since the loc never gets destroyed
			
			if (model.moveModel.move_failed) return;
			
			tsfc.resetCameraOffset();
			tsfc.resetCameraCenter();
			
			//Console.info('moveMoveEnded')
			// if this has focus, we should go ahead and start avatar up again
			if (model.stateModel.focused_component is TSMainView) {
				tsfc.startAvatar('TSMV.moveMoveEnded 1');
			} else if (!model.stateModel.focused_component.stops_avatar_on_focus) {
				tsfc.startAvatar('TSMV.moveMoveEnded 2');
				tsfc.stopAvatarKeyControl('TSMV TSMainView not focused');
			}
			
			tsfc.getOffLadder();
			
			gameRenderer.updateDynamic();
			gameRenderer.visible = true;
			
			FancyDoor.instance.onMoveEnded();
			
			tsfc.startPhyicsOnOtherPcs();
			
			// the new location might affect the sizing of UI
			// e.g. if it is shorter than the height of the viewport
			// do this before doing zoom stuff as they're dependent
			resizeToStage();
			
			tsfc.resetViewportOrientation();
			
			const loc:Location = model.worldModel.location;
			if (loc.home_type) {
				NewxpLogger.log('move_ending_home_'+loc.home_type, loc.newxp_log_string);
			} else if (loc.instance_template_tsid &&  model.stateModel.newxp_location_keys[loc.instance_template_tsid]) {
				NewxpLogger.log('move_ending_'+model.stateModel.newxp_location_keys[loc.instance_template_tsid], loc.newxp_log_string);
			} else {
				NewxpLogger.log('move_ending', loc.newxp_log_string);
			}

			if (!loc.allow_zoom) {
				// reset zoom level if we enter a no_zoom location
				tsfc.resetViewportScale(0);
			} else {
				// re-set the scale just in case it needs to change
				// due to this location's dimensions being smaller
				tsfc.setViewportScale(model.layoutModel.loc_vp_scale, 0);
			}
			
			CONFIG::god {
				GodButtonView.instance.refresh();
				ViewportScaleSliderView.instance.refresh();
			}
			
			tsfc.refreshLocationPath();
			toggleVisibilityOnMove();
			BuffViewManager.instance.refresh();
			
			tsfc.updatePCLoggingData();
			
			if (loc.is_template) {
				if (CONFIG::god || model.worldModel.pc.is_admin) {
					var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
					cdVO.title = 'HEY! You\'re in a template!'
					cdVO.txt = 'If you\'re planning to edit the location, or add or remove any items,'
						+' or basically do anything but look around, then you sure as shit better know what you\'re doing because otherwise'
						+' you\'re going to fuck things up.';
					cdVO.choices = [
						{value: true, label: 'I WILL NOT BREAK ANYTHING'}
					];
					cdVO.escape_value = false;
					tsfc.confirm(cdVO);
				} else {
					BootError.handleError(model.worldModel.location.tsid+' is marked as a template, what is this user doing here?', new Error('NON DEV CLIENT / GOD USER IN TEMPLATE??'), ['security'], true)
				}
			}
			
			// orient avatar towards middle of location, if within 600 pixels of sides
			var pc:PC = model.worldModel.pc;
			if (pc.x < loc.l+600) {
				gameRenderer.getAvatarView().faceRight();
			} else if (pc.x > loc.r-600) {
				gameRenderer.getAvatarView().faceLeft();
			}
			gameRenderer.getAvatarView().rescale();
			
			// this needs to run now, before the timer below, so that the layers gets parallax positioned properly as soon as possible
			// (else things like overlays that depend on being able to measure position relative to stage get fucked)
			gameRenderer.resume();
			
			//RH : Let's stop putting these setTimeout's and anonymous functions everywhere, they are slow, and hard to debug as well as just find.
			//EC: kiss!
			StageBeacon.setTimeout(function():void {
				TSFrontController.instance.resnapMiniMap(true);
				LoadingLocationView.instance.fadeOut();
				RookManager.instance.onMovement(false);
				// send performance updates only when we're not loading:
				PerfLogger.startLogging();
			}, 200);
			
			// If at home and in newxp (no_imagination==true) then snap the location after giving some seconds to load the chassis
			if (model.worldModel.pc.home_info.playerIsAtHome() && model.worldModel.location.no_imagination) {
				StageBeacon.setTimeout(TSFrontController.instance.saveHomeImg, 5000);
			}
			
			TipDisplayManager.instance.resume();
		}
		
		public function moveLocationHasChanged():void {
			var location:Location = model.worldModel.location;
			CONFIG::debugging {
				Console.log(945, 'moveLocationHasChanged');
			}
			
			if (CONFIG::perf) {
				// don't fuck with the renderer mode between location loads
				// because testing will drive what renderer we are using
			} else {
				// update the render mode state incase the previous location failed to build.
				LocationCommands.setupRenderMode();
			}
			
			// this will load the location SWF if necessary
			DecoAssetManager.loadLocationSWFs(location);
			
			toggleVisibilityOnMove();
		}
		
		public function moveLocationAssetsAreReady():void {
			var location:Location = model.worldModel.location;
			CONFIG::debugging {
				Console.log(945, 'moveLocationAssetsAreReady');
			}
			
			Benchmark.addCheck('TSMainView.moveLocationAssetsAreReady ENTERED '+location.tsid+' '+location.label);
			
			CONFIG::debugging {
				Console.info('ENTERED '+location.tsid+' '+location.label);
			}
			
			gameRenderer.visible = false;
			gameRenderer.updateLocation();
			
			if (!firstTimeStuffPerformed) {// this is a hacky way to detect the first time moveLocationAssetsAreReady happens
				doFirstTimeStuff(location);
			}
			
			toggleVisibilityOnMove();
		}
		
		// -----------------------------------------------------------------
		// END IMoveListener funcs
		
		private function toggleVisibilityOnMove():void {
			const tsfc:TSFrontController = TSFrontController.instance;
			tsfc.changeTipsVisibility(!model.worldModel.location.no_tips, 'gs_says_so');
			tsfc.changeStatusBubbleVisibility();
			tsfc.changePCStatsVisibility();
			tsfc.changeMiniMapVisibility();
			tsfc.changeHubMapVisibility();
			tsfc.changeAvatarVisibility();
			tsfc.changeTeleportDialogVisibility();
			tsfc.changePackVisibility();
		}
		
		// renderer calls back to this when a new location is built.
		public function locationBuilt():void {
			Benchmark.addCheck('TSMainView.locationBuilt');
			CONFIG::debugging {
				Console.log(945, 'TSMainView.locationBuilt');
			}

			// this can happen when we rebuild the location or a layer dynamically
			if (!model.moveModel.moving) return;
			
			if (model.moveModel.move_type == MoveModel.LOGIN_MOVE) {
				TSFrontController.instance.preloadYourAva();
			} else {
				// now that the location is built, we can finish the move	
				TSFrontController.instance.sendEndMoveMsg();
			}
		}
		
		CONFIG::god private function handOfGodChangedHandler(enabled:Boolean):void {
			const tsfc:TSFrontController = TSFrontController.instance;
			
			tsfc.changeStatusBubbleVisibility();
			tsfc.changePCStatsVisibility();
			tsfc.changeMiniMapVisibility();
			tsfc.changeHubMapVisibility();
			tsfc.changeAvatarVisibility();
			tsfc.changeTeleportDialogVisibility();
			
			updateVPDimsMinMax();
			resizeToStage();
			
			//force a refresh of the dialogs; if they detect that we are editing, they will close (and can set close_on_editing= false to stay open during editing)
			refreshViews();
		}
		
		CONFIG::god private function editingChangedHandler(editing:Boolean):void {
			if(RightSideManager.instance.right_view) RightSideManager.instance.right_view.visible = !editing;
			CONFIG::locodeco {
				ldsb.visible = editing;
			}
			handOfGodChangedHandler(editing);
		}
		
		override public function dispose():void {
			super.dispose();
			CONFIG::god {
				model.stateModel.unRegisterCBProp(editingChangedHandler, 'editing');
				model.stateModel.unRegisterCBProp(handOfGodChangedHandler, 'hand_of_god');
			}
			model.worldModel.unRegisterCBProp(onLocPcUpdates, "loc_pc_updates");
			model.worldModel.unRegisterCBProp(onLocPcAdds, "loc_pc_adds");
			model.worldModel.unRegisterCBProp(onLocPcDels, "loc_pc_dels");
			model.worldModel.unRegisterCBProp(onBuffUpdates, "buff_updates");
			model.worldModel.unRegisterCBProp(onBuffAdds, "buff_adds");
			model.worldModel.unRegisterCBProp(onBuffDels, "buff_dels");
			model.worldModel.unRegisterCBProp(onLocItemstackUpdates, "loc_itemstack_updates");
			model.worldModel.unRegisterCBProp(onLocItemstackAdds, "loc_itemstack_adds");
			model.worldModel.unRegisterCBProp(onLocItemstackDels, "loc_itemstack_dels");
			gameRenderer.dispose();
		}
		
		/** LocoDeco calls this when layer dims change so we can size the viewport correctly */
		CONFIG::locodeco public function layerDimensionsChanged():void {
			updateVPDimsMinMax();
			resizeToStage();
			refreshViews();
		}	
		
		CONFIG::god private function maybeUseBitmapRenderMode(e:KeyboardEvent):void {
			if (KeyBeacon.instance.pressed(Keyboard.Q)) {
				if (e.keyCode == Keyboard.B) {		
					LocationCommands.changeRenderMode(RenderMode.BITMAP);
				}
			}
		}

		CONFIG::god private function maybeUseVectorRenderMode(e:KeyboardEvent):void {
			if (KeyBeacon.instance.pressed(Keyboard.Q)) {
				if (e.keyCode == Keyboard.V) {
					LocationCommands.changeRenderMode(RenderMode.VECTOR);
				}
			}
		}
		
		private function maybeShowStats(e:KeyboardEvent):void {
			if (KeyBeacon.instance.pressed(Keyboard.Q)) {
				if(e.keyCode == Keyboard.P){//Responds to "p pressed while q is down";
					performanceGraphVisible = !performanceGraphVisible;
				}
			}
		}
		
		// from IMainView
		public function primePerformanceGraph():void {
			if (perf_graph_container.numChildren == 0) {
				// lazy load Stats so it doesn't run if never open
				perf_graph_container.addChild(perf_graph);
				perf_graph_container.addChild(key_report_tf);
				key_report_tf.background = true;
				key_report_tf.backgroundColor = 0;
				key_report_tf.multiline = key_report_tf.wordWrap = false;
				key_report_tf.width = Stats.WIDTH;
				key_report_tf.height = 18;
				key_report_tf.y = -key_report_tf.height;
				var f:TextFormat = new TextFormat();
				f.color = 0xffffff;
				f.size = 10;
				f.bold = false;
				f.font = '_sans';
				f.leftMargin = f.rightMargin = 1;
				f.kerning = true;
				key_report_tf.defaultTextFormat = f;
				KeyBeacon.instance.addKeyReportTF(key_report_tf);
				
				// displays which renderer is being used in performance tool
				renderer_report_tf.height = 18;
				renderer_report_tf.y = -renderer_report_tf.height;
				renderer_report_tf.defaultTextFormat = f;
				perf_graph_container.addChild(renderer_report_tf);
				renderer_report_tf.x = 120;
				renderer_report_tf.text = renderer_report_tf.text;
			}
		}
		
		public function updatePerformanceRendererInfo(rendererName:String):void {
			renderer_report_tf.text = "Renderer: " + rendererName;
		}
		
		// from IMainView
		public function set performanceGraphVisible(viz:Boolean):void {
			if (viz) primePerformanceGraph();
			perf_graph_container.visible = viz;
			CONFIG::debugging {
				LocalStorage.instance.setUserData(LocalStorage.IS_OPEN_STATS, perf_graph_container.visible, true);
			}
		}
		
		// from IMainView
		public function get performanceGraphVisible():Boolean {
			return perf_graph_container.visible;
		}

		// from IMainView
		public function get performanceGraph():Stats {
			return perf_graph;
		}
		
		// from IMainView
		public function get assetDetailsForBootError():String {
			return DecoAssetManager.toString();
		}
		
		// from IMainView
		public function get assetLoadingReport():String {
			return SmartThreader.load_report
		}
		
		// from IMainView
		public function get currentRendererForBootError():String {
			try {
				return model.stateModel.render_mode.name;
			} catch (e:Error) {
				//
			}
			return 'n/a';
		}
		
		// from IMainView
		public function get engineVersion():String {
			return Version.revision;
		}
	}
}