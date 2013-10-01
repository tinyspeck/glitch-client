package com.tinyspeck.engine.pack {
	
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.storage.Cabinet;
	import com.tinyspeck.engine.data.storage.TrophyCase;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingInventoryMoveVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.port.CabinetManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.IPackChange;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.TrophyCaseManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ContainersUtil;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.itemstack.PackItemstackView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.interfaces.IPcItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.IPcItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.ui.InteractionMenu;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	public class PackDisplayManager extends TSSpriteWithModel implements IFocusableComponent, IPcItemstackAddDelConsumer, IPcItemstackUpdateConsumer {
		
		/* singleton boilerplate */
		public static const instance:PackDisplayManager = new PackDisplayManager();
		
		public var showing_label_boxes:Boolean = true;
		public var label_box_w:int = 80;
		
		private var root_container_view:PackContainerView;
		private var gameRenderer:LocationRenderer;
		private var last_focused_pack_slot:PackSlot;
		private var dragVO:DragVO = DragVO.vo;
		
		private var focused_slot:int = 0;
		private var margin_top:int = 10;
		
		private var _opened_container_tsid:String = '';
		private var focused_container_tsid:String;
		private var open_tab_name:String = PackTabberUI.TAB_PACK;
		
		private var default_drag_tip:String = '';
		
		private var change_subscribers:Vector.<IPackChange> = new Vector.<IPackChange>();
		
		private var has_focus:Boolean = false;
		private var initial_pis_view_total_cnt:int;
		private var initial_pis_view_loaded_cnt:int;
		private var _is_viz:Boolean = true;
		private var normal_pack_holder:Sprite = new Sprite();
		private var normal_pack_holder_mask:Shape = new Shape();
		private var sub_container_mask:Shape = new Shape();
		private var was_furniture_bag_visible_when_starting_decorator_mode:Boolean;
		
		public function PackDisplayManager():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_h = 72;
			_w = 300;
		}
		
		public function init(gameRenderer:LocationRenderer):void {
			CONFIG::debugging {
				Console.log(945, 'init!');
			}
			registerSelfAsFocusableComponent();
			visible = false;
			
			addChild(normal_pack_holder);
			
			var g:Graphics = normal_pack_holder_mask.graphics;
			g.beginFill(0, 1);
			// this mask needs to be big enough to show the full pack at its largest (-x because of hightlight glow on first slot)
			g.drawRect(-10, 0, 1300, 200);
			normal_pack_holder.mask = normal_pack_holder_mask;
			addChild(normal_pack_holder_mask);
			addChild(sub_container_mask);
			
			addChild(FurnitureBagUI.instance);
			addChild(WallSwatchBagUI.instance);
			addChild(FloorSwatchBagUI.instance);
			addChild(CeilingSwatchBagUI.instance);
			
			this.gameRenderer = gameRenderer;
			root_container_view = new PackContainerView(model.worldModel.pc.pack_slots, 'Backpack');
			root_container_view.name = 'root_container_view';
			normal_pack_holder.addChild(root_container_view);
			root_container_view.y = margin_top;
			root_container_view.init();
			refresh();
			
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, _packDragCompleteHandler);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, _packDragStartHandler);
			
			CabinetManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, _cabinetDragCompleteHandler);
			CabinetManager.instance.addEventListener(TSEvent.DRAG_STARTED, _cabinetDragStartHandler);
			
			HandOfDecorator.instance.addEventListener(TSEvent.DRAG_COMPLETE, _hodDragCompleteHandler);
			HandOfDecorator.instance.addEventListener(TSEvent.DRAG_STARTED, _hodDragStartHandler);
			
			CONFIG::god {
				model.stateModel.registerCBProp(editingChangeHandler, 'editing');
				model.stateModel.registerCBProp(editingChangeHandler, 'hand_of_god');
			}
			
			model.stateModel.registerCBProp(onDecoratorModeChange, 'decorator_mode');
			
			if (LocalStorage.instance.getUserData(LocalStorage.OPEN_CONTAINER_TSID)){
				openContainer(LocalStorage.instance.getUserData(LocalStorage.OPEN_CONTAINER_TSID), false);
			}
		}
		
		private var debug_pack_updates:Boolean;
		
		// called by tsMainView after the location is built
		public function addPISViews():void {
			CONFIG::debugging {
				Console.log(945, 'addPISViews!');
			}
			if (debug_pack_updates) Benchmark.addCheck('PackDisplayManager.addPISViews');
			
			var As:Object = ContainersUtil.getItemstackTsidAsGroupedByContainer(model.worldModel.pc.itemstack_tsid_list, model.worldModel.itemstacks);
			initial_pis_view_total_cnt = (As.root) ? As.root.length : 0;
			var i:int;
			var m:int;
			var container_view:PackContainerView;
			var itemstack:Itemstack;
			
			var unique_item_cnt:int = 0;
			var counted:Object = {};
			if (As.root) {
				for (m=0;m<As.root.length;m++) {
					itemstack = model.worldModel.getItemstackByTsid(As.root[m]);
					if (!itemstack) continue;
					if (!counted[itemstack.class_tsid]) {
						unique_item_cnt++;
						counted[itemstack.class_tsid] = true;
					}
				}
			}
			
			for (i=0;i<normal_pack_holder.numChildren;i++) {
				container_view = normal_pack_holder.getChildAt(i) as PackContainerView;
				if (container_view == root_container_view) continue;
				if (!As[container_view.name]) continue;
				initial_pis_view_total_cnt+= As[container_view.name].length;
				for (m=0;m<As[container_view.name].length;m++) {
					itemstack = model.worldModel.getItemstackByTsid(As[container_view.name][m]);
					if (!itemstack) continue;
					if (!counted[itemstack.class_tsid]) {
						unique_item_cnt++;
						counted[itemstack.class_tsid] = true;
					}
				}
			}
			
			CONFIG::debugging {
				Console.log(945, 'addPISViews will create this many:'+initial_pis_view_total_cnt+' (unique items:'+unique_item_cnt+')');
			}
			
			Benchmark.addCheck('addPISViews will create this many:'+initial_pis_view_total_cnt+' (unique items:'+unique_item_cnt+')');
			
			if (initial_pis_view_total_cnt && !model.flashVarModel.break_item_asset_loading) {
				TSFrontController.instance.startLoadingLocationProgress('unpacking...');
			} else {
				doneInitialLoad(); // none to load, just go ahead!
			}
			
			root_container_view.addPISViews(As.root);
			for (i=0;i<normal_pack_holder.numChildren;i++) {
				container_view = normal_pack_holder.getChildAt(i) as PackContainerView;
				if (container_view == root_container_view) continue;
				container_view.addPISViews(As[container_view.name]);
			}
			
			// do this here, now that we have loaded the pisviews!
			placeContainer(false);
		}
		
		// called by pis_views as they load
		public function onPISViewLoaded():void {
			if (model.flashVarModel.break_item_asset_loading) return;
			
			if (initial_pis_view_loaded_cnt >= initial_pis_view_total_cnt) return; // we've already loaded all the intitial ones
			
			initial_pis_view_loaded_cnt++;
			TSFrontController.instance.updateLoadingLocationProgress(initial_pis_view_loaded_cnt/initial_pis_view_total_cnt);
			
			if (initial_pis_view_loaded_cnt == initial_pis_view_total_cnt) {
				doneInitialLoad();
			}
		}
		
		private function doneInitialLoad():void {
			TSFrontController.instance.doneLoadingPack();
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
			if (has_focus) return;
			has_focus = true;
			
			KeyBeacon.instance.addEventListener(KeyBeacon.CTRL_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.ENTER, cmdPlusEnterHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escapeHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upHandler);
			this.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
			
			highlightFocusedSlot();
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		private function overHandler(e:MouseEvent):void {
			// this causes too much weirdness if you leave your cursor over the pack and open/close bags with key
			// (it breaks up/down opening and closing bags by refocusing no any stack slot you mouse is over as the open/close animations play)
			return;
			
			
			/*if (model.stateModel.menus_prohibited) {
			return;
			}*/
			if (model.stateModel.focused_component is InteractionMenu) return;
			var pack_slot:PackSlot;
			var container_view:PackContainerView;
			var element:DisplayObject = e.target as DisplayObject;
			
			while (!(element is PackContainerView)) {
				if (element is PackSlot) {
					pack_slot = element as PackSlot;
					container_view = getContainerViewForChildPackSlot(pack_slot);
					setFocusedSlot(container_view.name, pack_slot.slot)
					break;
				}
				
				element = element.parent;
			}
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			if (!has_focus) return;
			has_focus = false;
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.CTRL_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.ENTER, cmdPlusEnterHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escapeHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upHandler);
			this.removeEventListener(MouseEvent.MOUSE_OVER, overHandler);
			
			TSFrontController.instance.clearSingleInteractionSP();
			blurFocusedSlot();
		}
		
		private function escapeHandler(e:KeyboardEvent):void {
			TSFrontController.instance.releaseFocus(this);
		}
		
		private function cmdPlusEnterHandler(e:KeyboardEvent):void {
			TSFrontController.instance.releaseFocus(this);
		}
		
		private function enterHandler(e:KeyboardEvent):void {
			if (model.stateModel.menus_prohibited) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			var container_view:PackContainerView = getFocusedPackContainerView();
			var pack_slot:PackSlot = getFocusedPackSlot();
			
			if (pack_slot.pis_view) {
				TSFrontController.instance.startInteractionWith(TSSprite(pack_slot.pis_view), false);
				SoundMaster.instance.playSound('CLICK_SUCCESS');
			} else {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
			
		}
		
		private function upHandler(e:KeyboardEvent):void {
			var container_view:PackContainerView = getFocusedPackContainerView();
			var pack_slot:PackSlot = container_view.getPackSlotForSlot(focused_slot);
			
			if (opened_container_tsid) { // there is an open container
				
				if (focused_container_tsid == opened_container_tsid) {
					// we're in the open container
					// DO NOTHING
					
				} else {
					// we're in the root					
					if (pack_slot.holds_container && opened_container_tsid != pack_slot.pis_view.tsid) {
						// open it
						openContainer(pack_slot.pis_view.tsid);
						SoundMaster.instance.playSound('CLICK_SUCCESS');
					}
					
					var max_slot_in_open_container:int = model.worldModel.getItemstackByTsid(getContainerViewForContainerTsid(opened_container_tsid).name).slots-1;
					
					//set it to the middle slot in the pack always
					setFocusedSlot(opened_container_tsid, Math.floor(max_slot_in_open_container/2));
				}
				
			} else { // there is no open container
				
				if (pack_slot.holds_container) {
					// open it
					openContainer(pack_slot.pis_view.tsid);
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					setFocusedSlot(opened_container_tsid, 0);
				}
				
			}
			/*
			
			this is the old way, where up key opens menus
			
			if (focused_container_tsid == opened_container_tsid && opened_container_tsid) {
			// we're in the open container
			
			enterHandler(e);
			
			} else {
			// we're in the root
			if (pack_slot.holds_container) {
			if (opened_container_tsid != pack_slot.pis_view.tsid) {
			openContainer(pack_slot.pis_view.tsid);
			}
			
			setFocusedSlot(pack_slot.pis_view.tsid, 0);
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			} else {
			
			enterHandler(e);
			
			}
			
			}*/
		}
		
		private function downHandler(e:KeyboardEvent):void {
			var container_view:PackContainerView = getFocusedPackContainerView();
			var pack_slot:PackSlot = container_view.getPackSlotForSlot(focused_slot);
			
			
			if (opened_container_tsid) { // there is an open container
				
				if (focused_container_tsid == opened_container_tsid) {
					// we're in the open container
					
					//find the container slot
					setFocusedSlot(root_container_view.name, root_container_view.getPackSlotByTsid(opened_container_tsid).slot);
					//closeContainer(opened_container_tsid); //uncomment if you want it to close when pressing down
					
				} else {
					// we're in the root
					if (pack_slot.holds_container && opened_container_tsid == pack_slot.pis_view.tsid) {
						closeContainer(pack_slot.pis_view.tsid);
						SoundMaster.instance.playSound('CLICK_SUCCESS');
					} else {
						//SoundMaster.instance.playSound('CLICK_FAILURE');
						
					}
				}
			}
			
			/*
			
			this is the old way, where up key opens menus
			
			if (focused_container_tsid == opened_container_tsid && opened_container_tsid) {
			// we're in the open container
			setFocusedSlot('', model.worldModel.getItemstackByTsid(getContainerViewForContainerTsid(focused_container_tsid).name).slot);
			closeContainer(opened_container_tsid);
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			} else {
			// we're in the root
			if (pack_slot.holds_container && opened_container_tsid == pack_slot.pis_view.tsid) {
			closeContainer(pack_slot.pis_view.tsid);
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			} else {
			SoundMaster.instance.playSound('CLICK_FAILURE');
			
			}
			
			}
			
			*/
		}
		
		private function rightHandler(e:KeyboardEvent):void {
			var max_slot:int = getFocusedPackContainerView().pack_slotsA.length-1;
			var new_slot:int = focused_slot+1;
			if (new_slot > max_slot) new_slot = 0;
			setFocusedSlot(focused_container_tsid, new_slot);
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function leftHandler(e:KeyboardEvent):void {
			var max_slot:int = getFocusedPackContainerView().pack_slotsA.length-1;
			var new_slot:int = focused_slot-1;
			if (new_slot < 0) new_slot = max_slot;
			setFocusedSlot(focused_container_tsid, new_slot);
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function getFocusedPackContainerView():PackContainerView {
			var container_view:PackContainerView;
			
			if (focused_container_tsid) container_view = getContainerViewForContainerTsid(focused_container_tsid);
			if (!container_view || !container_view.visible) {
				container_view = root_container_view;
				focused_container_tsid = '';
			}
			
			return container_view;
		}
		
		private function getFocusedPackSlot():PackSlot {
			var container_view:PackContainerView = getFocusedPackContainerView();
			var pack_slot:PackSlot = container_view.getPackSlotForSlot(focused_slot);
			
			if (!pack_slot) {
				focused_slot = 0;
				focused_container_tsid = '';
				pack_slot = root_container_view.getPackSlotForSlot(focused_slot);
			}
			
			return pack_slot;
		}
		
		public function setFocusedSlot(focused_container_tsid:String, focused_slot:int, force:Boolean = false):void {
			this.focused_container_tsid = focused_container_tsid;
			this.focused_slot = focused_slot;
			if (has_focus || force) highlightFocusedSlot();
		}
		
		private function highlightFocusedSlot():void {
			if (last_focused_pack_slot) {
				last_focused_pack_slot.is_focused = false;
			}
			
			if(_opened_container_tsid != focused_container_tsid){
				openContainer(focused_container_tsid);
			}
			
			var pack_slot:PackSlot = getFocusedPackSlot();
			pack_slot.is_focused = true;
			last_focused_pack_slot = pack_slot;
			CONFIG::god {
				TSFrontController.instance.setSingleInteractionSP(pack_slot.pis_view as TSSprite);
			}
			
			dimOtherSlots(pack_slot);
		}
		
		public function blurFocusedSlot():void {
			var pack_slot:PackSlot = getFocusedPackSlot();
			pack_slot.is_focused = false;
			dimOtherSlots(pack_slot);
		}
		
		private function dimOtherSlots(active_slot:PackSlot):void {
			//if we don't have an active_slot then bring all the slots back to full alpha
			const slot_alpha:Number = active_slot && active_slot.is_focused ? .5 : 1;
			
			var container_view:PackContainerView = _opened_container_tsid ? getContainerViewForContainerTsid(_opened_container_tsid) : root_container_view;
			
			//dim everything except the container and the slot
			var total:int = container_view.pack_slotsA.length;
			var i:int;
			var slot:PackSlot;
			
			for(i = 0; i < total; i++){
				slot = container_view.pack_slotsA[int(i)] as PackSlot;
				slot.alpha = slot_alpha;
			}
			
			//dim the root as well
			if(container_view != root_container_view){
				total = root_container_view.pack_slotsA.length;
				const itemstack:Itemstack = active_slot && active_slot.pis_view ? model.worldModel.getItemstackByTsid(active_slot.pis_view.tsid) : null;
				
				for(i = 0; i < total; i++){
					slot = root_container_view.pack_slotsA[int(i)] as PackSlot;
					//if it's not the open one and the container, set it to the alpha it needs to be
					if(slot.pis_view && (slot.pis_view.tsid != _opened_container_tsid || itemstack && slot.is_open && slot.pis_view.tsid != itemstack.container_tsid)) {
						slot.alpha = slot_alpha;
					}
					else {
						slot.alpha = 1;
					}
				}
			}
			
			if(active_slot) active_slot.alpha = 1;
		}
		
		// asumption: this only gets called when the value has changed
		private function onDecoratorModeChange(enabled:Boolean):void {
			if (enabled) {
				// always switch to furniture bag when going into deco mode
				if (!FurnitureBagUI.instance.visible) {
					was_furniture_bag_visible_when_starting_decorator_mode = false;
					showFurnitureBag();
				} else {
					was_furniture_bag_visible_when_starting_decorator_mode = true;
				}
				
				//make sure the swatches are set to the all category
				WallSwatchBagUI.instance.activatePane(BagUI.CATEGORY_ALL);
				FloorSwatchBagUI.instance.activatePane(BagUI.CATEGORY_ALL);
				CeilingSwatchBagUI.instance.activatePane(BagUI.CATEGORY_ALL);
			} else {
				// only toggle back to normal pack when leaving deco mode if it makes sense
				if (!was_furniture_bag_visible_when_starting_decorator_mode) {
					hideFurnitureBag();
				}
			}
		}
		
		public function showFurnitureBag():void {
			if (!FurnitureBagUI.instance.visible) {
				open_tab_name = PackTabberUI.TAB_FURNITURE;
				FurnitureBagUI.instance.show();
				handleBagVisibility();
				YouDisplayManager.instance.changePackTab(true);
			}
		}
		
		public function hideFurnitureBag():void {
			if(!normal_pack_holder.visible) {
				open_tab_name = PackTabberUI.TAB_PACK;
				handleBagVisibility();
				YouDisplayManager.instance.changePackTab(false);
			}
		}
		
		public function showWallSwatches():void {
			if(!WallSwatchBagUI.instance.visible){
				open_tab_name = PackTabberUI.TAB_WALL;
				WallSwatchBagUI.instance.show();
				handleBagVisibility();
			}
		}
		
		public function showFloorSwatches():void {
			if(!FloorSwatchBagUI.instance.visible){
				open_tab_name = PackTabberUI.TAB_FLOOR;
				FloorSwatchBagUI.instance.show();
				handleBagVisibility();
			}
		}
		
		public function showCeilingSwatches():void {
			if(!CeilingSwatchBagUI.instance.visible){
				open_tab_name = PackTabberUI.TAB_CEILING;
				CeilingSwatchBagUI.instance.show();
				handleBagVisibility();
			}
		}
		
		private function handleBagVisibility():void {
			//this just makes sure if something is visible, that the other guys are not
			normal_pack_holder.visible = open_tab_name == PackTabberUI.TAB_PACK;
			FurnitureBagUI.instance.visible = open_tab_name == PackTabberUI.TAB_FURNITURE;
			WallSwatchBagUI.instance.visible = open_tab_name == PackTabberUI.TAB_WALL;
			FloorSwatchBagUI.instance.visible = open_tab_name == PackTabberUI.TAB_FLOOR;
			CeilingSwatchBagUI.instance.visible = open_tab_name == PackTabberUI.TAB_CEILING;
		}
		
		public function getOpenTabName():String {
			//useful for knowing which tab we are showing
			return open_tab_name;
		}
		
		CONFIG::god private function editingChangeHandler(editing:Boolean):void {
			visible = !editing;
		}
		
		private function _findItemDragTargetSlot(dragged_itemstack:Itemstack):PackSlot {
			var container_view:PackContainerView;
			var container_tsid:String
			var pack_slot:PackSlot;
			var target_itemstack:Itemstack;
			var target_item_class:Item;
			var ob:Object;
			if (!dragged_itemstack) return null;
			
			for (var i:int=0;i<normal_pack_holder.numChildren;i++) {
				container_view = normal_pack_holder.getChildAt(i) as PackContainerView;
				if (!container_view.visible) continue;
				if (!container_view.hitTestObject(Cursor.instance.drag_DO)) continue;
				
				if (dragged_itemstack.slots && container_view != root_container_view) continue; // can't drag a bag to anything other than the root 
				
				for (var m:int=0;m<container_view.pack_slotsA.length;m++) {
					pack_slot = container_view.pack_slotsA[m] as PackSlot;
					
					target_itemstack = null;
					target_item_class = null;
					
					// if it already has a stack in it, check to see if the drag is ok and bail if not
					if (pack_slot.pis_view) {
						
						target_itemstack = model.worldModel.getItemstackByTsid(pack_slot.pis_view.tsid);
						target_item_class = model.worldModel.getItemByTsid(target_itemstack.class_tsid);
						
						// if it is a receptive_inventory_item/stack, return it right away 
						ob = dragVO.receptive_inventory_items[target_item_class.tsid]; // is it a target by virtue of class?
						if (!ob) ob = dragVO.receptive_inventory_itemstacks[target_itemstack.tsid]; // if not, is it a target by stack tsid?
						if (ob) {
							if (pack_slot.hitTestObject(Cursor.instance.drag_DO)) {
								dragVO.drag_tip = ob.tip;
								return pack_slot;
							}
						}
						
						if (dragged_itemstack.container_tsid == target_itemstack.tsid) continue; //can't drag onto the bag it is already in
						
						if (dragged_itemstack == target_itemstack) continue; // can't drop on self
						
						if (target_itemstack.slots) { // a drag to a bag, potentially ok
							
							// TODO: check here if the bag is full and continue? potentially a hard one, because
							// it might be full, but contain a stack of the dragged item with room to hold the dragged stack (or part of it)
							
							if (dragged_itemstack.slots) continue; // can't drag a bag onto another bag
							
						} else { // a drag to a non bag stack
							
							if (dragged_itemstack.class_tsid != target_itemstack.class_tsid) continue; // can't drag on different item class
							
							if (target_itemstack.count >= target_item_class.stackmax) continue; //target stack is full
							//if (dragged_itemstack.count >= target_item_class.stackmax) continue; //dragged stack is full (commented out because you can still put some of the dragged stack into the target stack)
						}
						
					}
					
					var drag_tip:String = default_drag_tip;
					if (target_itemstack && target_itemstack.slots) { // dragging onto an icon of a container
						container_tsid = target_itemstack.tsid;
						
						if (model.worldModel.location.itemstack_tsid_list[dragVO.dragged_itemstack.tsid]) { // dragging from the location
							drag_tip = 'Put in <b>'+target_itemstack.label+'</b>';
						} else { // dragging from the pack
							drag_tip = 'Move to <b>'+target_itemstack.label+'</b>';
						}
						
					} else { // dragging onto anything but an icon of a container
						// use pc.tsid as container_tsid if it is the root, because that will be the value in receptive_bag_tsidsA
						container_tsid = (container_view == root_container_view) ? model.worldModel.pc.tsid : container_view.name;
					}
					
					ob = dragVO.receptive_bags[container_tsid];
					if (!ob) continue;
					
					if (ob.disabled) {
						drag_tip = '<font color="#cc0000">'+ob.tip+'</font>';
					} else {
						drag_tip = ob.tip;
					}
					
					if (pack_slot.hitTestObject(Cursor.instance.drag_DO)) {
						dragVO.drag_tip = drag_tip;
						return pack_slot;
					}
				}
			}
			
			return null;
		}
		
		private function _packDragStartHandler(e:TSEvent):void {
			dragVO.setReceptiveInventoryItemstacksAndBags(_dragMoveHandler);
			default_drag_tip = 'Move here';
			StageBeacon.mouse_move_sig.add(_dragMoveHandler);
		}
		
		private function _hodDragStartHandler(e:TSEvent):void {
			dragVO.setReceptiveInventoryItemstacksAndBags(_dragMoveHandler);
			default_drag_tip = 'Pick up';
			dragVO.drag_tip = default_drag_tip;
			
			if (model.stateModel.can_decorate && !dragVO.proxy_item_class) {
				// WE DO NOT WANT TO DO THIS WHEN DRAGGING WITH HOD in this case!! instead, HOD will call onHODHasNoTarget and onHODHasATarget as needed
			} else {
				StageBeacon.mouse_move_sig.add(_dragMoveHandler);
			}
		}
		
		public function onHODHasNoTarget():void {
			if (dragVO) _dragMoveHandler();
		}
		
		public function onHODHasATarget():void {
			if (dragVO) {
				if (dragVO.target) dragVO.target.unhighlightOnDragOut();
				dragVO.target = null;
			}
			Cursor.instance.hideTip();
		}
		
		private function _cabinetDragStartHandler(e:TSEvent):void {
			CONFIG::debugging {
				trace(_cabinetDragStartHandler)
			}
			// I think we don't have to do this, because it gets done by cabinetDialog
			//setReceptiveInventoryItemstacksAndBags();
			default_drag_tip = 'Move Here';
			StageBeacon.mouse_move_sig.add(_dragMoveHandler);
		}
		
		private function isTargetOneOfMine(target:IDragTarget):Boolean {
			return (dragVO.target is PackSlot || dragVO.target is FurnitureBagUI);
		}
		
		private function _dragMoveHandler(e:MouseEvent=null):void {
			if (Cursor.instance.drag_DO && this.hitTestObject(Cursor.instance.drag_DO)) {
				var target:IDragTarget;// = _findItemDragTargetSlot(dragVO.dragged_itemstack) as IDragTarget;
				var item:Item = dragVO.dragged_itemstack.item;
				
				if (item.is_special_furniture || item.is_trophy || item.is_furniture) {
					// if this is a trophy or a special crazy furniture that is not furniture right now, the target should be the FBUI
					var ob:Object = dragVO.receptive_bags[model.worldModel.pc.furniture_bag_tsid];
					if (ob) {
						target = FurnitureBagUI.instance;
						
						if (ob.disabled) {
							dragVO.drag_tip = '<font color="#cc0000">'+ob.tip+'</font>';
						} else {
							dragVO.drag_tip = ob.tip;
						}
					}
				}
				
				target = target || _findItemDragTargetSlot(dragVO.dragged_itemstack) as IDragTarget;
				
				if (target is FurnitureBagUI) {
					showFurnitureBag();
				} else {
					hideFurnitureBag();
				}
				
				if (target) {
					if (target != dragVO.target) {
						if (dragVO.target) {
							dragVO.target.unhighlightOnDragOut();
						}
						
						Cursor.instance.showTip(dragVO.drag_tip, item.is_furniture || item.is_trophy);
						
						dragVO.target = target; // tuck a reference to the PackSlot in the dragVO
						dragVO.target.highlightOnDragOver();
					}
				} else {
					if (dragVO.target) {
						dragVO.target.unhighlightOnDragOut();
						dragVO.target = null;
						Cursor.instance.hideTip();
					}
				}
				
			} else if (dragVO.target && isTargetOneOfMine(target)) {
				dragVO.target.unhighlightOnDragOut();
				dragVO.target = null;
				Cursor.instance.hideTip();
			}
		}
		
		private function _hodDragCompleteHandler(e:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(_dragMoveHandler);
			
			if (dragVO && dragVO.target && isTargetOneOfMine(dragVO.target)) {
				var target_pack_slot:PackSlot = (dragVO.target is PackSlot) ? dragVO.target as PackSlot : null;
				var target_tsid:String = '';
				var target_itemstack:Itemstack;
				var target_item:Item;
				var target_slot:* = null;
				var ob:Object;
				
				// the item you dropped on, if there is one
				target_itemstack = (target_pack_slot && target_pack_slot.pis_view) ? model.worldModel.getItemstackByTsid(target_pack_slot.pis_view.tsid) : null;
				
				if (target_itemstack) {
					target_item = model.worldModel.getItemByTsid(target_itemstack.class_tsid);
					
					// see if there is a receptive_inventory_item/stack
					ob = dragVO.receptive_inventory_items[target_item.tsid];
					if (!ob || ob.disabled) ob = dragVO.receptive_inventory_itemstacks[target_itemstack.tsid];
				}
				
				if (ob) { // we have an ob which represents a receptive_inventory_item/stack, so use it
					
					if (ob && !ob.disabled) {
						TSFrontController.instance.sendItemstackVerb(
							new NetOutgoingItemstackVerbVO(
								target_itemstack.tsid,
								ob.verb,
								1,
								dragVO.dragged_itemstack.tsid,
								dragVO.dragged_itemstack.class_tsid,
								'',
								'',
								'',
								(ob.just_one) ? 1: dragVO.dragged_itemstack.count
							)
						);
					}
					
				} else { // must be a pick up!
					
					if (dragVO.target is FurnitureBagUI) {
						
						if (model.stateModel.decorator_mode || dragVO.dragged_itemstack.item.is_furniture || dragVO.dragged_itemstack.item.is_special_furniture) {
							//do nothing! handled in HOD
						} else {
							TSFrontController.instance.sendItemstackVerb(
								new NetOutgoingItemstackVerbVO(
									dragVO.dragged_itemstack.tsid,
									'pickup',
									dragVO.dragged_itemstack.count
								)
							);
						}
				
					} else {
						
						if (target_pack_slot.pis_view && target_itemstack.slots) { // dropped on a container icon, put it in the container
							
							target_tsid = target_itemstack.tsid;
							target_slot = null
							
						} else { //dropped on an empty slot, or an item that is not a bag; put it in the slot
							
							var target_container_view:PackContainerView = getContainerViewForChildPackSlot(target_pack_slot);
							target_itemstack = model.worldModel.getItemstackByTsid(target_container_view.name);
							target_tsid = (target_itemstack) ? target_itemstack.tsid : '';
							target_slot = target_pack_slot.slot;
						}
						
						TSFrontController.instance.sendItemstackVerb(
							new NetOutgoingItemstackVerbVO(
								dragVO.dragged_itemstack.tsid,
								'pickup',
								dragVO.dragged_itemstack.count,
								'',
								'',
								'',
								target_tsid,
								target_slot)
						);
						
					}
					
				}
				
				dragVO.target.unhighlightOnDragOut();
				Cursor.instance.hideTip();
			}
		}
		
		private function _cabinetDragCompleteHandler(e:TSEvent):void {
			// this seems to work fine, to let _packDragCompleteHandler handle it all
			_packDragCompleteHandler(e);
		}
		
		private function _packDragCompleteHandler(e:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(_dragMoveHandler);
			
			if (dragVO.target && dragVO.target is PackSlot) { // target is a packSlot
				var target_pack_slot:PackSlot = _findItemDragTargetSlot(dragVO.dragged_itemstack);
				var target_itemstack:Itemstack;
				var target_item:Item;
				var target_path:String;
				var target_slot:* = null;
				var ob:Object;
				
				// the item you dropped on, if there is one
				if (target_pack_slot && target_pack_slot.pis_view) {
					target_itemstack = model.worldModel.getItemstackByTsid(target_pack_slot.pis_view.tsid);
					
					if (target_itemstack) {
						target_item = model.worldModel.getItemByTsid(target_itemstack.class_tsid);
						
						// see if there is a receptive_inventory_item/stack
						ob = dragVO.receptive_inventory_items[target_item.tsid];
						if (!ob || ob.disabled) ob = dragVO.receptive_inventory_itemstacks[target_itemstack.tsid];
					}
				}
				
				if (ob) { // we have an ob which represents a receptive_inventory_item/stack, so use it
					if (ob && !ob.disabled) {
						TSFrontController.instance.sendItemstackVerb(
							new NetOutgoingItemstackVerbVO(
								target_itemstack.tsid,
								ob.verb,
								1,
								dragVO.dragged_itemstack.tsid,
								dragVO.dragged_itemstack.class_tsid,
								'',
								'',
								'',
								(ob.just_one) ? 1: dragVO.dragged_itemstack.count
							)
						);
					}
					
				} else if (target_pack_slot) { // must be an inventory move!
					
					if (target_pack_slot.pis_view && target_itemstack.slots) { // dropped on a container icon, put it in the container
						
						target_path = target_itemstack.path_tsid;
						target_slot = null;
						
					} else { //dropped on an empty slot, or an item that is not a bag; put it in the slot
						
						var target_container_view:PackContainerView = getContainerViewForChildPackSlot(target_pack_slot);
						target_itemstack = model.worldModel.getItemstackByTsid(target_container_view.name);
						target_path = (target_itemstack) ? target_itemstack.path_tsid : '';
						target_slot = target_pack_slot.slot;
						
					}
					
					//to_path_tsid and from_path_tsid are the same
					TSFrontController.instance.genericSend(
						new NetOutgoingInventoryMoveVO(
							dragVO.dragged_itemstack.tsid,
							dragVO.dragged_itemstack.container_tsid,
							target_path,
							target_slot
						)
					);
				} else {
					// WTF, dragVO.target is PackSlot but _findItemDragTargetSlot returned null.
					var error_details:String = '';
					error_details+= ' dragVO.target.slot:'+PackSlot(dragVO.target).slot;
					error_details+= ' dragVO.target.pis_view:'+PackSlot(dragVO.target).pis_view;
					if (PackSlot(dragVO.target).pis_view) {
						error_details+= ' dragVO.target.pis_view.tsid:'+PackSlot(dragVO.target).pis_view.tsid;
					}
					BootError.handleError(
						error_details,
						new Error("_findItemDragTargetSlot returned null, but dragVO.target is PackSlot"),
						['_packDragCompleteHandler_returned_null'],
						true
					);
				}
				
				dragVO.target.unhighlightOnDragOut();
				Cursor.instance.hideTip();
			}
		}
		
		public function get opened_container_tsid():String {
			return _opened_container_tsid;
		}
		
		public function translateSlotCenterToGlobal(slot:int, path_tsid:String):Point {
			var container_tsid:String;
			var A:Array = path_tsid.split('/');
			if (A.length>1) {
				container_tsid = A[A.length-2]
			}
			
			if (!container_tsid) {
				// it must be a slot in the root
				return root_container_view.translateSlotCenterToGlobal(slot);
			} else {
				// it must be a slot in a container
				var container_view:PackContainerView = getContainerViewForContainerTsid(container_tsid);
				if (container_view && container_view.visible) {
					// it is an open container, so use it to get the slot pt
					return container_view.translateSlotCenterToGlobal(slot);
				} else {
					// it is a closed container, so get the pt for the slot of its icon view instead
					var container_itemstack:Itemstack = model.worldModel.getItemstackByTsid(container_tsid);
					if (!container_itemstack) {
						//Console.reportError('translateSlotCenterToGlobal Bad container_tsid:'+container_tsid);
						return new Point(0,0);
					}
					return root_container_view.translateSlotCenterToGlobal(container_itemstack.slot);
				}
			}
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
			refresh();
		}
		
		public function toggleContainer(container_tsid:String):void {
			
			if (!model.worldModel.pc.itemstack_tsid_list[container_tsid]) return;
			
			if (container_tsid == _opened_container_tsid) {
				closeContainer(container_tsid);
			} else {
				openContainer(container_tsid);
			}
		}
		
		private function openContainer(container_tsid:String, and_render:Boolean = true):void {
			
			if (!model.worldModel.pc.itemstack_tsid_list[container_tsid]) return;
			
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(container_tsid);
			if (!itemstack) {
				CONFIG::debugging {
					Console.info('openContainer but no stack exists '+container_tsid);
				}
				return;
			}
			
			if (_opened_container_tsid == container_tsid) {
				closeContainer(_opened_container_tsid);
				CONFIG::debugging {
					Console.info('_opened_container_tsid == container_tsid, so closing and ending');
				}
				return;
			}
			
			if (_opened_container_tsid) {
				closeContainer(_opened_container_tsid);
			}
			
			_opened_container_tsid = container_tsid;
			LocalStorage.instance.setUserData(LocalStorage.OPEN_CONTAINER_TSID, _opened_container_tsid);
			
			root_container_view.markSlotOpenForTsid(container_tsid);
			
			var As:Object;
			if (and_render) As = ContainersUtil.getItemstackTsidAsGroupedByContainer(model.worldModel.pc.itemstack_tsid_list, model.worldModel.itemstacks);
			var container_view:PackContainerView = getContainerViewForContainerTsid(container_tsid);
			
			if (!container_view) {
				container_view = new PackContainerView(itemstack.slots, itemstack.label);
				container_view.name = container_tsid;
				normal_pack_holder.addChildAt(container_view, 0);
				container_view.init(true);
				if (and_render) container_view.addPISViews(As[container_tsid]);
			}
			
			//apply the mask to the container view
			container_view.mask = sub_container_mask;
			
			//place the sub-container smartly above the opened bag
			placeContainer(false);
			
			//animate the sub-container in place
			const final_y:int = margin_top;
			container_view.y = root_container_view.y;
			container_view.visible = true;
			TSTweener.addTween(container_view, 
				{
					y: final_y, 
					time: .3, 
					transition: 'easeInCubic', 
					onUpdate:onAnimateUpdate, 
					onUpdateParams:[container_view],
					onComplete:onAnimateUpdate, 
					onCompleteParams:[container_view]
				}
			);
			TSTweener.addTween(root_container_view, {y: _h, time: .3, transition: 'easeInCubic', onComplete:refresh});
			
			//this will make sure that all the slots are reset to alpha 1
			dimOtherSlots(null);
		}
		
		private function onAnimateUpdate(container_view:PackContainerView):void {
			//this will make sure the mask is always the right size
			var g:Graphics = sub_container_mask.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(-10, 0, 1300, root_container_view.y);
		}
		
		public function destroyContainerView(container_tsid:String):void {
			closeContainer(container_tsid);
			var container_view:PackContainerView = getContainerViewForContainerTsid(container_tsid);
			if (!container_view) return;
			if (container_view.parent) container_view.parent.removeChild(container_view);
			container_view.dispose();
		}
		
		public function closeContainer(container_tsid:String):void {
			var container_view:PackContainerView = getContainerViewForContainerTsid(container_tsid);
			if (!container_view) return;
			
			if (focused_container_tsid == container_tsid) {
				setFocusedSlot('', 0);
			}
			
			root_container_view.markSlotClosedForTsid(container_tsid);
			if (!container_view) return;
			container_view.visible = false;
			TSTweener.addTween(root_container_view, {y: margin_top, time: .3, transition: 'easeInCubic'});
			_opened_container_tsid = '';
			LocalStorage.instance.setUserData(LocalStorage.OPEN_CONTAINER_TSID, _opened_container_tsid);
		}
		
		private function placeContainer(animate:Boolean):void {
			if (!_opened_container_tsid) return;
			const container_view:PackContainerView = getContainerViewForContainerTsid(_opened_container_tsid);
			const slot_w:int = model.layoutModel.pack_slot_w;
			const pack_slot:PackSlot = root_container_view.getPackSlotByTsid(_opened_container_tsid);
			
			if(!container_view || !pack_slot) return;
			
			var final_x:int = pack_slot.x + slot_w/2 - container_view.width/2;
			
			//make sure we are not too far left or too far right
			final_x = Math.max(0, Math.min(final_x, root_container_view.width - container_view.width));
			if(!animate){
				container_view.x = final_x;
			}
			else {
				TSTweener.addTween(container_view, {x:final_x, time:.3, transition:'easeInCubic'});
			}
		}
		
		public function getItemstackViewByTsid(stack_tsid:String, container_tsid:String = ''):PackItemstackView {
			var container_view:PackContainerView;
			var pis_view:PackItemstackView;
			
			if (!container_tsid || container_tsid == 'root') {
				container_view = root_container_view;
			} else {
				container_view = getContainerViewForContainerTsid(container_tsid);
			}
			
			if (container_view) pis_view = container_view.getItemstackViewByTsid(stack_tsid);
			
			if (pis_view) return pis_view;
			
			// we either had a bad container_tsid or did not find the stack in the container, so let's look through them all
			for (var i:int=0;i<normal_pack_holder.numChildren;i++) {
				container_view = normal_pack_holder.getChildAt(i) as PackContainerView;
				pis_view = container_view.getItemstackViewByTsid(stack_tsid);
				if (pis_view) {
					return pis_view;
				}
			}
			
			return null;
		}
		
		public function onPcItemstackAdds(tsids:Array):void {
			if (debug_pack_updates) Benchmark.addCheck('onPcItemstackAdds '+tsids);
			if (model.flashVarModel.no_render_stacks) return;
			var As:Object = ContainersUtil.getItemstackTsidAsGroupedByContainer(tsids, model.worldModel.itemstacks);
			var i:int;
			var itemstack:Itemstack;
			var pis_view:PackItemstackView;
			var container_view:PackContainerView;
			var stack_tsid:String;
			var A:Array;
			
			for (var container_tsid:String in As) {
				A = As[container_tsid];
				if (container_tsid == 'root') {
					container_view = root_container_view;
				} else {
					container_view = getContainerViewForContainerTsid(container_tsid);
				}
				
				if (container_view) {
					//Console.warn('adding '+A);
					for (i=0;i<A.length;i++) {
						stack_tsid = A[int(i)];
						itemstack = model.worldModel.getItemstackByTsid(stack_tsid);
						
						if (!itemstack) {
							CONFIG::debugging {
								Console.warn('itemstack not exists');
							}
							continue;
						}
						
						if (!container_view.getPackSlotForSlot(itemstack.slot)) {
							
							BootError.handleError(
								'container:'+container_tsid+' slots:'+container_view.pack_slotsA.length+' itemstack:'+itemstack.tsid+' slot:'+itemstack.slot,
								new Error("Bad slot"), null, !CONFIG::god
							);
							
							continue;
							
						}
						
						pis_view = getItemstackViewByTsid(stack_tsid, container_tsid);
						
						if (pis_view) {
							pis_view.changeHandler();
							continue;
						}
						
						container_view.addItemstackSpriteByTsid(stack_tsid);
						
					}
					container_view.refresh();
				} else if (container_tsid == model.worldModel.pc.furniture_bag_tsid) {
					// this is ok! just ignore it
				} else if (container_tsid == model.worldModel.pc.auction_storage_tsid) {
					// this is ok! just ignore it
				} else if (container_tsid == model.worldModel.pc.escrow_tsid) {
					// this is ok! just ignore it
				} else if (model.worldModel.pc.itemstack_tsid_list[container_tsid]) {
					// this is ok! just ignore it
				} else {
					CONFIG::debugging {
						Console.warn('no container_view for container:'+container_tsid);
					}
				}
			}
			
			bruteForceUpdateContainerItemstackViews();
		}
		
		public function onPcItemstackDels(tsids:Array):void {
			if (debug_pack_updates) Benchmark.addCheck('onPcItemstackDels '+tsids);
			var stack_tsid:String;
			var i:int;
			var itemstack:Itemstack;
			var pis_view:PackItemstackView;
			var container_view:PackContainerView;
			
			//Console.warn('deling '+tsids);
			for (i=0;i<tsids.length;i++) {
				stack_tsid = tsids[int(i)];
				//Console.warn('deling '+stack_tsid);
				
				if (stack_tsid == _opened_container_tsid) {
					destroyContainerView(_opened_container_tsid);
				}
				
				itemstack = model.worldModel.getItemstackByTsid(stack_tsid);
				
				CONFIG::debugging {
					if (!itemstack) Console.warn('itemstack not exists');
				}
				
				pis_view = getItemstackViewByTsid(stack_tsid);
				
				if (!pis_view) {
					// this is ok; it could mean that the stack is in the storage compartment of a trophy
					//Console.warn('pis_view not exists '+stack_tsid);
					continue;
				}
				
				container_view = getContainerViewForChildItemstackView(pis_view);
				
				if (!container_view) {
					// this  missing is ok because pis_views may have been rmeoved from a slot by onPcItemstackAdds or onPcItemstackUpdates
					//Console.warn('container_view not exists for child stack '+stack_tsid);
					continue;
				}
				
				//Console.warn('removing '+stack_tsid+' from '+container_view.name);
				container_view.removeItemstackSpriteByTsid(stack_tsid);
				container_view.refresh();
				
			}
			bruteForceUpdateContainerItemstackViews();
		}
		
		public function onPcItemstackUpdates(tsids:Array):void {
			if (debug_pack_updates) Benchmark.addCheck('onPcItemstackUpdates '+tsids);
			if (model.flashVarModel.no_render_stacks) return;
			var As:Object = ContainersUtil.getItemstackTsidAsGroupedByContainer(tsids, model.worldModel.itemstacks);
			var i:int;
			var itemstack:Itemstack;
			var pis_view:PackItemstackView;
			var container_view:PackContainerView;
			var stack_tsid:String;
			var A:Array;
			var pc:PC;
			var container_tsid:String;
			var actual_container_view:PackContainerView;
			var affected_container_views:Object = {};
			var tsids_to_add:Array = [];
			
			for (container_tsid in As) {
				A = As[container_tsid];
				if (container_tsid == 'root') {
					container_view = root_container_view;
				} else {
					container_view = getContainerViewForContainerTsid(container_tsid);
				}
				
				//show some info in the console if we haven't created a container view yet
				/*CONFIG::debugging {
				if (!container_view) {
				Console.info('no container_view for: '+container_tsid);
				}
				}*/
				
				
				//Console.warn('updating '+A);
				for (i=0;i<A.length;i++) {
					stack_tsid = A[int(i)];
					itemstack = model.worldModel.getItemstackByTsid(stack_tsid);
					
					if (!itemstack) {
						CONFIG::debugging {
							Console.warn('itemstack not exists');
						}
						continue;
					}
					if (debug_pack_updates) Benchmark.addCheck(+i+' '+ stack_tsid);
					
					pis_view = getItemstackViewByTsid(stack_tsid, container_tsid);
					
					if (!pis_view) {
						/*CONFIG::debugging {
						Console.warn('THIS IS A CONTAINER BAG THAT HAS NOT BEEN OPENED OR WAS MAYBE MOVED FROM OR TO PRIVATE STORAGE: pis_view not exists '+stack_tsid);
						}*/
						tsids_to_add.push(stack_tsid)
						//onPcItemstackAdds([stack_tsid]); // This will ignore private storage adds, but do the right thing otherwise
						continue;
					}
					
					actual_container_view = getContainerViewForChildItemstackView(pis_view);
					
					if (!actual_container_view) {
						; //satisfy compiler
						CONFIG::debugging {
							Console.error('actual_container_view not exists '+stack_tsid);
						}
					} else {
						
						if (actual_container_view != container_view) { //it has moved containers
							if (debug_pack_updates) Benchmark.addCheck(stack_tsid+' has moved containers');
							actual_container_view.removeItemstackSpriteByTsid(stack_tsid);
							tsids_to_add.push(stack_tsid);
							//actual_container_view.refresh();
							//onPcItemstackAdds([stack_tsid]); // This will ignore private storage adds, but do the right thing otherwise (and call actual_container_view.refresh())
						} else {
							affected_container_views[actual_container_view.name] = actual_container_view;
							if (itemstack.slot != PackSlot(pis_view.parent.parent).slot) { // it has moved slots
								if (debug_pack_updates) Benchmark.addCheck(stack_tsid+' has moved slots');
								//container_view.removeItemstackSpriteByTsid(stack_tsid);
								//container_view.addItemstackSpriteByTsid(stack_tsid);
								container_view.moveItemstackSpriteByTsid(stack_tsid);
								if (container_view.open_container_tsid == stack_tsid) {
									container_view.markSlotOpenForTsid(stack_tsid);
								}
							} else {
								if (debug_pack_updates) Benchmark.addCheck(stack_tsid+' has NOT moved slots');
							}
							
							pis_view.changeHandler();
						}
					}
				}
			}
			// fresh all containers we have fiddled with
			for (var k:String in affected_container_views) {
				if (debug_pack_updates) Benchmark.addCheck('refreshing '+PackContainerView(affected_container_views[k]).name);
				PackContainerView(affected_container_views[k]).refresh();
			}
			
			if (tsids_to_add.length) onPcItemstackAdds(tsids_to_add);
			
			bruteForceUpdateContainerItemstackViews();
		}
		
		public function bruteForceUpdateContainerItemstackViews():void {
			var pack_slot:PackSlot;
			for (var i:int=0;i<root_container_view.pack_slotsA.length;i++) {
				pack_slot = root_container_view.pack_slotsA[int(i)] as PackSlot;
				if (pack_slot.pis_view) pack_slot.pis_view.changeHandler();
			}
			
			placeContainer(true);
			
			//let the subscribers know that things have changed
			//TODO: we might want to be able to listen to only certain bags instead of all of them
			notifySubscribers();
		}
		
		public function isChangeSubscriber(subscriber:IPackChange):Boolean {
			var index:int = change_subscribers.indexOf(subscriber);
			return (index > -1) ? true : false;
		}
		
		public function registerChangeSubscriber(subscriber:IPackChange):void {
			if(!isChangeSubscriber(subscriber)){
				change_subscribers.push(subscriber);
			}
		}
		
		public function unRegisterChangeSubscriber(subscriber:IPackChange):void {
			var index:int = change_subscribers.indexOf(subscriber);
			
			if(index > -1){
				change_subscribers.splice(index, 1);
			}
		}
		
		private function notifySubscribers():void {
			var i:int = 0;
			var total:uint = change_subscribers.length;
			
			for(i; i < total; i++){
				change_subscribers[int(i)].onPackChange();
			}
		}
		
		public function getContainerViewForChildPackSlot(pack_slot:PackSlot):PackContainerView {
			return pack_slot.parent.parent as PackContainerView;
		}
		
		public function getContainerViewForChildItemstackView(pis_view:PackItemstackView):PackContainerView {
			if (!pis_view || (pis_view && !pis_view.parent)) return null;
			return pis_view.parent.parent.parent.parent as PackContainerView;
		}
		
		public function getContainerViewForContainerTsid(container_tsid:String):PackContainerView {
			return normal_pack_holder.getChildByName(container_tsid) as PackContainerView;
		}
		
		public function refresh():void {
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					visible = false;
				}
			}
			
			_w = StageBeacon.stage.stageWidth;
			if (model.layoutModel.loc_vp_h) {
				y = model.layoutModel.header_h + model.layoutModel.loc_vp_h;
			}
			
			const offset:int = 5;
			const pack_width:int = model.layoutModel.pack_is_wide ? model.layoutModel.overall_w : model.layoutModel.loc_vp_w;
			
			x = model.layoutModel.gutter_w + offset;
			
			// do we have room for the label boxes for containers?
			if (showing_label_boxes) {
				showing_label_boxes = (pack_width < width) ? false : true;
			} else {
				showing_label_boxes = (pack_width < width+label_box_w) ? false : true;
			}
			
			// this will cause each container to display the label box or not, based on showing_label_boxes
			for (var i:int=0;i<normal_pack_holder.numChildren;i++) {
				PackContainerView(normal_pack_holder.getChildAt(i)).refresh();
			}
			
			// now we can see if we need to scale down
			normal_pack_holder.scaleX = normal_pack_holder.scaleY = 1;
			if (pack_width - offset < (root_container_view ? root_container_view.width : width)) {
				normal_pack_holder.scaleX = normal_pack_holder.scaleY = ((pack_width - offset)/(root_container_view ? root_container_view.width : width));
			}
			
			FurnitureBagUI.instance.refresh();
			WallSwatchBagUI.instance.refresh();
			FloorSwatchBagUI.instance.refresh();
			CeilingSwatchBagUI.instance.refresh();
			
			if(root_container_view){
				//this will make sure the mask is always the right size
				var g:Graphics = sub_container_mask.graphics;
				g.clear();
				g.beginFill(0,0);
				g.drawRect(-10, 0, 1300, root_container_view.y);
			}
		}
		
		public function isContainerTsidPrivate(container_tsid:String, ...more_container_tsid:Array):Boolean {
			var pc:PC = model.worldModel.pc;
			var i:int;
			var total:int = more_container_tsid ? more_container_tsid.length : 0;
			
			if(pc && pc.escrow_tsid){
				//check escrow and private trophy
				if(container_tsid.indexOf(pc.escrow_tsid) != -1) return true;
				
				//trying out other than 1 container/path?
				for(i = 0; i < total; i++){
					if(more_container_tsid[int(i)].indexOf(pc.escrow_tsid) != -1) return true;
				}
			}
			
			//check the private trophy storage
			if(TrophyCaseManager.instance.trophy_cases && TrophyCaseManager.instance.trophy_cases.length){
				//just snag the first case and get the private tsid since it's shared
				var trophy_case:TrophyCase = TrophyCaseManager.instance.trophy_cases[0];
				
				if(container_tsid.indexOf(trophy_case.private_tsid) != -1) return true;
				
				//trying out other than 1 container/path?
				for(i = 0; i < total; i++){
					if(more_container_tsid[int(i)].indexOf(trophy_case.private_tsid) != -1) return true;
				}				
			}
			
			if (container_tsid && Cabinet.getCabinetByTsid(container_tsid.split('/')[0])) {
				return true;
			}
			
			//no match
			return false;
		}
		
		public function isTsidOwnedByPlayer(container_tsid:String, log:Boolean=true, ...more_container_tsid:Array):Boolean {
			var pc:PC = model.worldModel.pc;
			var i:int;
			var j:int;
			var chunks:Array;
			
			//shove it in there so we can loop through it
			if(more_container_tsid) more_container_tsid.push(container_tsid);
			
			//look through the pc stuff first
			if(pc && pc.itemstack_tsid_list){			
				for(i = 0; i < more_container_tsid.length; i++){
					//split it up
					chunks = String(more_container_tsid[int(i)]).split('/');
					for(j = 0; j < chunks.length; j++){
						if(pc.itemstack_tsid_list[chunks[int(j)]]) return true;
					}
				}
			}
			
			//check private bags
			if(more_container_tsid) more_container_tsid.pop(); //remove the container_tsid
			if(isContainerTsidPrivate(container_tsid, more_container_tsid)) return true;
			
			//nada, bad scene
			CONFIG::debugging {
				if (log) Console.error('Container/Bag passed that is NOT owned by the player! Better tell Serguei.', container_tsid, more_container_tsid);
			}
			return false;
		}
		
		private var viz_lockers:Object = {};
		public function changeVisibility(viz:Boolean, locker_str:String):void {
			if (!locker_str) return;
			if (viz) {
				delete viz_lockers[locker_str];
				var c:int = 0;
				for (var k:String in viz_lockers) {
					c++;
				}
				if (c==0) {
					showHide(true);
				}
			} else {
				viz_lockers[locker_str] = true;
				showHide(false);
			}
		};
		
		public function reassesVisibility():void {
			showHide(model.worldModel.location.show_pack);
		}
		
		public function get is_viz():Boolean { return _is_viz; }
		private function showHide(viz:Boolean):void {
			if (!model.worldModel.location || !model.worldModel.location.show_pack) {
				viz = false;
			}
			
			//allows the pack contents to go away. Will also hide the currants
			if(viz == _is_viz) return;
			const ani_time:Number = .5;
			
			if(TSTweener.isTweening(this)) TSTweener.removeTweens(this);
			
			_is_viz = mouseEnabled = mouseChildren = viz;
			TSTweener.addTween(this, {_autoAlpha:(viz ? 1 : 0), time:ani_time, transition:'linear'});
			YouDisplayManager.instance.pack_tabber.changeVisibility();
		}
		
		public function animateEmptySlots(is_showing:Boolean):void {
			//if we are showing, let's set any empty slots in the pack to fade down from 100% after the tween
			if(root_container_view){
				const ani_time:Number = .5;
				const total:int = root_container_view.pack_slotsA.length;
				var pack_slot:PackSlot;
				var i:int;
				for(i; i < total; i++) {
					pack_slot = root_container_view.pack_slotsA[int(i)] as PackSlot;
					if(!pack_slot.is_full){
						//animate the empty slot
						pack_slot.animateEmptyBox(ani_time, is_showing);
					}
				}
			}
		}
		
		public override function get h():int {
			return _h;
		}
		
		public function get root_container_width():Number {
			return root_container_view ? root_container_view.width : 0;
		}
	}
}