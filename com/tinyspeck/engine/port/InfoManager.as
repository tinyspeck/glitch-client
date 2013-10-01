package com.tinyspeck.engine.port {
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.CameraManView;
	import com.tinyspeck.engine.view.gameoverlay.InfoModeLabel;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.ui.chrome.ItemSearch;
	
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	public class InfoManager implements IFocusableComponent, IDisposableSpriteChangeHandler, IMoveListener {
		/* singleton boilerplate */
		public static const instance:InfoManager = new InfoManager();
		
		private const item_class_to_info_label:Dictionary = new Dictionary();
		private const pc_to_info_label:Dictionary = new Dictionary();
		
		private var infoLabelPool:Vector.<InfoModeLabel> = new Vector.<InfoModeLabel>();
		private var reusableLIVV:Vector.<LocationItemstackView> = new Vector.<LocationItemstackView>();
		private var model:TSModelLocator;
		private var has_focus:Boolean;
		private var wm:WorldModel;
		private var sm:StateModel;
		private var lm:LayoutModel;
		public var item_search:ItemSearch = new ItemSearch();
		
		private var highlighted_lis_view:LocationItemstackView; // shoudl only be set in set highlighted_view()
		private var highlighted_pc_view:PCView; // shoudl only be set in set highlighted_view()
		
		private var _highlighted_view:TSSprite;
		public function get highlighted_view():TSSprite {
			return highlighted_lis_view || highlighted_pc_view;
		}
		public function set highlighted_view(view:TSSprite):void {
			if (!view) {
				highlighted_pc_view = null;
				highlighted_lis_view = null;
			} else if (view is LocationItemstackView) {
				highlighted_pc_view = null;
				highlighted_lis_view = view as LocationItemstackView;
			} else if (view is PCView) {
				highlighted_pc_view = view as PCView;
				highlighted_lis_view = null;
			} else {
				CONFIG::debugging {
					Console.error('WTF is view? '+getQualifiedClassName(view));
				}
			}
		}
		
		public function InfoManager():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			init();
		}
		
		public function init():void {
			model = TSModelLocator.instance;
			wm = model.worldModel;
			sm = model.stateModel;
			lm = model.layoutModel;
			registerSelfAsFocusableComponent();
			TSFrontController.instance.registerMoveListener(this);
		}
		
		public function start():Boolean {
			
			//some rules for not being able to start would go here
			TSFrontController.instance.requestFocus(this);

			TSFrontController.instance.disableLocationInteractions();
			
			sm.camera_control_pt.x = lm.loc_cur_x;
			sm.camera_control_pt.y = lm.loc_cur_y;
			
			// listen for changes to worth renderables
			gameRenderer.lis_view_worth_rendering_sig.add(onLisViewWorthRendering);
			// glow all that worth renderable now
			glowAndShowLabelForClosestLIV();
			
			gameRenderer.pc_view_worth_rendering_sig.add(onPCViewWorthRendering);
			glowAndShowLabelForPCViews();
			
			StageBeacon.mouse_move_sig.add(onMouseMove)
			StageBeacon.mouse_click_sig.add(onMouseClick);
			
			model.activityModel.growl_message = '<p class="camera_man_smaller">'+StringUtil.injectClass(CameraManView.instance.cam_skills_msg, 'a', 'camera_man_link')+'</span></p>';
			
			onMouseMove();
			return true;
		}
		
		private function glowAndShowLabelForPCViews():void {
			var V:Vector.<PCView> = gameRenderer.getPcViewsWorthRendering();
			for each (var pc_view:PCView in V) {
				glowPCV(pc_view);
				maybeShowLabelForPCV(pc_view);
			}
		}
		
		private function glowAndShowLabelForClosestLIV(which_item_class:String=null):void {
			var item_class_to_closest_liv_map:Dictionary = new Dictionary();
			var item_class_to_dist:Dictionary = new Dictionary();
			//var pc_pt:Point = new Point(wm.pc.x, wm.pc.y);
			var stack_pt:Point;
			var dist:Number;
			var item_class:String;
			
			var V:Vector.<LocationItemstackView> = gameRenderer.getLIVsWorthRendering();
			for each (var lis_view:LocationItemstackView in V) {
				item_class = lis_view.itemstack.info_class;
				if (which_item_class && which_item_class != item_class) continue;
				CONFIG::debugging {
					Console.info(lis_view.item.tsid+' '+lis_view.itemstack.info_class);
				}
				if (lis_view.itemstack.info_class) {
					glowLIV(lis_view);
					stack_pt = new Point(lis_view.x, lis_view.y);
					dist = Math.abs(Point.distance(sm.camera_control_pt, stack_pt));
					
					if (item_class_to_closest_liv_map[item_class]) {
						if (dist < item_class_to_dist[item_class]) {
							item_class_to_closest_liv_map[item_class] = lis_view;
							item_class_to_dist[item_class] = dist;
						}
					} else {
						item_class_to_closest_liv_map[item_class] = lis_view;
						item_class_to_dist[item_class] = dist;
					}
				}
			}
			
			// item_class_to_closest_liv_map holds references to the closest livs per item class
			for (var k:String in item_class_to_closest_liv_map) {
				maybeShowLabelForLIV(item_class_to_closest_liv_map[k]);
			}
			
			item_class_to_closest_liv_map = null;
			item_class_to_dist = null;
		}
		
		public function end():void {
			//clean up stuff here
			
			
			StageBeacon.mouse_move_sig.remove(onMouseMove);
			StageBeacon.mouse_click_sig.remove(onMouseClick);
			
			updateHighlightedView(null);
			
			// dont listen for changes to worth renderables
			gameRenderer.lis_view_worth_rendering_sig.remove(onLisViewWorthRendering);
			gameRenderer.pc_view_worth_rendering_sig.remove(onPCViewWorthRendering);
			
			// unglow all now
			var V:Vector.<LocationItemstackView> = gameRenderer.getLIVsWorthRendering();
			for each (var lis_view:LocationItemstackView in V) {
				unglowLIV(lis_view, false);
			}

			var V2:Vector.<PCView> = gameRenderer.getPcViewsWorthRendering();
			for each (var pc_view:PCView in V2) {
				unglowPCV(pc_view);
			}
			
			CameraMan.instance.letCameraSnapBackFast();
			TSFrontController.instance.releaseFocus(this);
			
			TSFrontController.instance.enableLocationInteractions();
		}
		
		private function onPCViewWorthRendering(pc_view:PCView):void {
			if (pc_view.worth_rendering) {
				glowPCV(pc_view);
				maybeShowLabelForPCV(pc_view);
			} else {
				unglowPCV(pc_view);
			}
		}

		private function onLisViewWorthRendering(lis_view:LocationItemstackView):void {
			if (lis_view.worth_rendering && lis_view.itemstack.info_class) {
				glowLIV(lis_view);
				maybeShowLabelForLIV(lis_view);
			} else {
				unglowLIV(lis_view);
			}
		}
		
		private function glowPCV(pc_view:PCView):void {
			pc_view.unglow();
			pc_view.glow();
			
			var info_label:InfoModeLabel = getInfoLabelFromMapForPC(pc_view.tsid);
			if (info_label) {
				if (highlighted_pc_view == pc_view) {
					info_label.hightlight();
				} else {
					info_label.unhighlight();
				}
			}
		}
		
		private function glowLIV(lis_view:LocationItemstackView):void {
			lis_view.unglow();
			lis_view.glow();
			
			var info_label:InfoModeLabel = getInfoLabelForLIV(lis_view);
			if (info_label) {
				// it already has a label
				if (highlighted_lis_view == lis_view) {
					info_label.hightlight();
				} else {
					info_label.unhighlight();
				}
			} else if (lis_view == highlighted_lis_view) {
				// it did not previously show a label, and it is the one we are moused over
				
				info_label = getInfoLabelFromMapForItemClass(lis_view.itemstack.info_class);
				
				// SWITCH THE INFO LABEL TO THE ONE WE ARE HIGHLIGHTING
				if (info_label && info_label.view is LocationItemstackView) {
					// we have a reference to the current info label for this item class now, get rid of it
					removeInfoLabelFromMapForItemClass(lis_view.itemstack.info_class);
					TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, info_label.view as LocationItemstackView);
					info_label.reset(); // removes it from Display list
					infoLabelPool.push(info_label);
					
				}
				info_label = maybeShowLabelForLIV(lis_view);
				info_label.hightlight();
			}
		}
		
		private function getInfoLabel():InfoModeLabel {
			if (infoLabelPool.length) {
				return infoLabelPool.pop();
			}
			return new InfoModeLabel();
		}
		
		private function maybeShowLabelForLIV(lis_view:LocationItemstackView):InfoModeLabel {
			var info_label:InfoModeLabel = getInfoLabelFromMapForItemClass(lis_view.itemstack.info_class);
			if (info_label) {
				// we already have one for this class
				return null;
			}
			
			info_label = getInfoLabel();
			info_label.show(lis_view);
			addInfoLabelToMapForItemClass(info_label, lis_view.itemstack.info_class);
			TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, lis_view);
			return info_label;
		}
		
		private function maybeShowLabelForPCV(pc_view:PCView):void {
			var info_label:InfoModeLabel = getInfoLabelFromMapForPC(pc_view.tsid);
			if (info_label) {
				// we already have one for this pc
				return;
			}

			info_label = getInfoLabel();
			info_label.show(pc_view);
			addInfoLabelToMapForPC(info_label, pc_view.tsid);
			TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, pc_view);
		}
		
		private function unglowPCV(pc_view:PCView):void {
			pc_view.unglow();
			
			var info_label:InfoModeLabel = getInfoLabelFromMapForPC(pc_view.tsid);
			if (!info_label) {
				// there is not one for this pc
				return;
			}
			
			info_label.reset(); // removes it from Display list
			removeInfoLabelFromMapForPC(pc_view.tsid);
			infoLabelPool.push(info_label);
			
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, pc_view);
		}
		
		private function unglowLIV(lis_view:LocationItemstackView, and_and_tracker_for_the_class:Boolean=true):void {
			lis_view.unglow();
			
			var info_label:InfoModeLabel = getInfoLabelForLIV(lis_view);
			if (!info_label) {
				// there is not one for this stack
				return;
			}
			
			infoLabelPool.push(info_label);
			info_label.reset(); // removes it from Display list
			removeInfoLabelFromMapForItemClass(lis_view.itemstack.info_class);
			
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, lis_view);
			
			if (and_and_tracker_for_the_class) glowAndShowLabelForClosestLIV(lis_view.itemstack.info_class);
		}
		
		public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {
			if (sp is LocationItemstackView) {
				positionInfoLabelByLIV(sp as LocationItemstackView);
			} else if (sp is PCView) {
				positionInfoLabelByPCV(sp as PCView);
			}
		}
		
		public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
			if (sp is LocationItemstackView) {
				unglowLIV(sp as LocationItemstackView);
			} else if (sp is PCView) {
				unglowPCV(sp as PCView);
			}
		}
		
		public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
			if (sp is LocationItemstackView) {
				positionInfoLabelByLIV(sp as LocationItemstackView);
			} else if (sp is PCView) {
				positionInfoLabelByPCV(sp as PCView);
			}
		}
		
		private function positionInfoLabelByPCV(pc_view:PCView):void {
			var info_label:InfoModeLabel = getInfoLabelFromMapForPC(pc_view.tsid);
			if (!info_label) {
				// there is not one for this stack
				return;
			}
			
			info_label.x = pc_view.x;
			info_label.y = pc_view.y-45;
			info_label.y = MathUtil.clamp(pc_view.y-240, pc_view.y-10, info_label.y);
		}
		
		private function positionInfoLabelByLIV(lis_view:LocationItemstackView):void {
			var info_label:InfoModeLabel = getInfoLabelForLIV(lis_view);
			if (!info_label) {
				// there is not one for this stack
				return;
			}
			
			info_label.x = lis_view.x;
			info_label.y = lis_view.y+lis_view.getYAboveDisplay()+info_label.height+30;
			info_label.y = MathUtil.clamp(lis_view.y-240, lis_view.y-10, info_label.y);
		}
		
		private function getInfoLabelForLIV(lis_view:LocationItemstackView):InfoModeLabel {
			var info_label:InfoModeLabel = getInfoLabelFromMapForItemClass(lis_view.itemstack.info_class);
			
			if (!info_label) {
				return null;
			}
			
			if (info_label.tsid != lis_view.tsid) {
				return null;
			}
			
			return info_label;
		}
		
		private function addInfoLabelToMapForItemClass(info_label:InfoModeLabel, item_class:String):void {
			if (getInfoLabelFromMapForItemClass(item_class)) {
				CONFIG::debugging {
					Console.error(item_class+' already has a record in the map');
				} 
				return;
			}
			
			item_class_to_info_label[item_class] = info_label;
		}
		
		private function addInfoLabelToMapForPC(info_label:InfoModeLabel, pc_tsid:String):void {
			if (getInfoLabelFromMapForPC(pc_tsid)) {
				CONFIG::debugging {
					Console.error(pc_tsid+' already has a record in the map');
				} 
				return;
			}
			
			pc_to_info_label[pc_tsid] = info_label;
		}
		
		private function removeInfoLabelFromMapForItemClass(item_class:String):void {
			if (!getInfoLabelFromMapForItemClass(item_class)) {
				CONFIG::debugging {
					Console.error(item_class+' has no record in the map');
				} 
				return;
			}
			
			delete item_class_to_info_label[item_class];
		}
		
		private function removeInfoLabelFromMapForPC(pc_tsid:String):void {
			if (!getInfoLabelFromMapForPC(pc_tsid)) {
				CONFIG::debugging {
					Console.error(pc_tsid+' has no record in the map');
				} 
				return;
			}
			
			delete pc_to_info_label[pc_tsid];
		}
		
		private function getInfoLabelFromMapForItemClass(item_class:String):InfoModeLabel {
			return item_class_to_info_label[item_class];
		}
		
		private function getInfoLabelFromMapForPC(pc_tsid:String):InfoModeLabel {
			return pc_to_info_label[pc_tsid];
		}
		
		protected function onEscapeKey(e:KeyboardEvent):void {
			TSFrontController.instance.stopInfoMode();
		}
		
		protected function onTabKey(e:KeyboardEvent):void {
			item_search.focusOnInput(); 
		}
		
		protected function onIKey(e:KeyboardEvent):void {
			if (!hasFocus()) return;
			TSFrontController.instance.stopInfoMode();
		}
		
		private function zoomKeyHandler(e:KeyboardEvent):void {
			// it's important that we don't add shared listeners directly to TSFC
			// because where one class has started listening, another might
			// remove the same listener by accident, so the first class fails
			TSFrontController.instance.zoomKeyHandler(e);
		}
		
		private function startListeningForControlEvts():void {
			var kb:KeyBeacon = KeyBeacon.instance;
			
			kb.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey);
			kb.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.TAB, onTabKey);
			kb.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.I, onIKey);
			
			TSFrontController.instance.startListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function stopListeningForControlEvts():void {
			var kb:KeyBeacon = KeyBeacon.instance;
			
			kb.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey);
			kb.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.TAB, onTabKey);
			kb.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.I, onIKey);
			
			TSFrontController.instance.stopListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function get gameRenderer():LocationRenderer {
			return TSFrontController.instance.getMainView().gameRenderer;
		}
		
		private function onMouseClick(e:MouseEvent):void {
			if (!highlighted_view) {
				onMouseMove(e);
			}
			
			var targetIsInfoModelLabel:Boolean = (e && e.target && (e.target is InfoModeLabel));
			
			if (highlighted_lis_view) {
				if (highlighted_lis_view.itemstack.info_class) {
					item_search.hideResults();
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					TSFrontController.instance.startInteractionWith(highlighted_lis_view);
				} 
			} else if (highlighted_pc_view) {
				item_search.hideResults();
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				PlayerInfoDialog.instance.startWithTsid(highlighted_pc_view.tsid);
			}
		}
		
		private function onMouseMove(e:MouseEvent=null):void {
			// this is to detect when we are dragging from the inventory
			if (sm.focused_component is Cursor) {
				return;
			}
			
			// this is to detect when we are dragging from location
			if (Cursor.instance.drag_DO) {
				return;
			}
			
			if (e) {
				if (e.target is InfoModeLabel) {
					// if mouse is over a label then just ignore the mousemove, we're handling it
					return;
				} else if (!gameRenderer.contains(e.target as DisplayObject)) {
					// if we're hovering over the map or other UI,
					// remove existing highlights and don't highlight anything new
					if (highlighted_lis_view) {
						var was_highlighted_lis_view:LocationItemstackView = highlighted_lis_view;
						highlighted_view = null;
						glowLIV(was_highlighted_lis_view);
						gameRenderer.buttonMode = false;
						gameRenderer.useHandCursor = false;
					}
					return;
				}
			}
			
			// find the object that you are most likely selecting
			const lis_view_to_highlight:LocationItemstackView = gameRenderer.getMostLikelyItemstackUnderCursor();
			const pc_view_to_highlight:PCView = gameRenderer.getMostLikelyPCUnderCursor();
			
			if (lis_view_to_highlight && pc_view_to_highlight) {
				// TODO, decide which one to use? for now use pc_view_to_highlight because in 99% of cases pc will be in front
				updateHighlightedView(pc_view_to_highlight);
			} else if (lis_view_to_highlight) {
				updateHighlightedView(lis_view_to_highlight);
				/*CONFIG::debugging {
					Console.info(lis_view_to_highlight.itemstack.info_class+' '+lis_view_to_highlight.itemstack.info_class);
				}*/
			} else if (pc_view_to_highlight) {
				updateHighlightedView(pc_view_to_highlight);
			} else {
				updateHighlightedView(null);
			}
		}
		
		public function onInfoLabelMouseOver(view:TSSprite):void {
			updateHighlightedView(view);
		}
		
		public function onInfoLabelMouseOut(view:TSSprite):void {
			onMouseMove()
		}
		
		private function updateHighlightedView(view_to_highlight:TSSprite):void {
			var lis_view_to_highlight:LocationItemstackView;
			var pc_view_to_highlight:PCView;
			
			if (view_to_highlight is LocationItemstackView) {
				lis_view_to_highlight = view_to_highlight as LocationItemstackView;
			} else if (view_to_highlight is PCView) {
				pc_view_to_highlight = view_to_highlight as PCView;
			}
			
			// if the new highlight is already highlighted, we're done
			if (view_to_highlight == highlighted_view) return;
			
			// at this point we can be sure that there is a new highlight
			// and it is not over the existing highlight or selection
			if (highlighted_lis_view) {
				var was_highlighted_lis_view:LocationItemstackView = highlighted_lis_view;
				highlighted_view = null;
				glowLIV(was_highlighted_lis_view);
			}
			
			if (highlighted_pc_view) {
				var was_highlighted_pc_view:PCView = highlighted_pc_view;
				highlighted_view = null;
				glowPCV(was_highlighted_pc_view);
			}
			
			if (lis_view_to_highlight && !lis_view_to_highlight.itemstack.info_class) {
				return;
			}
			
			// draw the new highlight
			highlighted_view = lis_view_to_highlight || pc_view_to_highlight;
			
			if (lis_view_to_highlight) {
				glowLIV(lis_view_to_highlight);
				
				// make it apparent that you can click the itemstack
				gameRenderer.buttonMode = true;
				gameRenderer.useHandCursor = true;
				GetInfoDialog.instance.preloadItems([lis_view_to_highlight.itemstack.info_class]);
			} else if (pc_view_to_highlight) {
				glowPCV(pc_view_to_highlight);
				
				// make it apparent that you can click the itemstack
				gameRenderer.buttonMode = true;
				gameRenderer.useHandCursor = true;
			} else {
				gameRenderer.buttonMode = false;
				gameRenderer.useHandCursor = false;
			}
		}
		
		public function onGameLoop(ms_elapsed:int):void {
			if (!hasFocus()) return;
			
			const kb:KeyBeacon = KeyBeacon.instance;
			const inc:int = ((CameraMan.CAM_INCREMENT * Math.max(0, model.worldModel.pc.cam_speed_multiplier)) * (ms_elapsed/1000));
			
			var key_down:Boolean = false;
			if (kb.pressed(Keyboard.RIGHT) || kb.pressed(Keyboard.D)) {
				sm.camera_control_pt.x+= inc;
				key_down = true;
			} else if (kb.pressed(Keyboard.LEFT) || kb.pressed(Keyboard.A)) {
				sm.camera_control_pt.x-= inc;
				key_down = true;
			}
			
			if (kb.pressed(Keyboard.DOWN) || kb.pressed(Keyboard.S)) {
				sm.camera_control_pt.y+= inc;
				key_down = true;
			} else if (kb.pressed(Keyboard.UP) || kb.pressed(Keyboard.W)) {
				sm.camera_control_pt.y-= inc;
				key_down = true;
			}
			
			if (key_down) {
				onMouseMove();
				TSFrontController.instance.goNotAFK();
				CameraMan.instance.boundCameraCameraControlPt();
			}
		}
		
		public function hasFocus():Boolean {
			return has_focus;
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
			
			has_focus = false;
			stopListeningForControlEvts();
			TSFrontController.instance.changeTipsVisibility(true, 'InfoManager');
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
			
			has_focus = true;
			startListeningForControlEvts();
			TSFrontController.instance.changeTipsVisibility(false, 'InfoManager');
			CameraMan.instance.setCameraCenterLimits(true);
			CameraMan.instance.boundCameraCameraControlPt();
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
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
			TSFrontController.instance.stopInfoMode();
		}
		
		public function moveMoveEnded():void {
		}
		
	}
}