package com.tinyspeck.engine.control {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.bridge.CartesianMouseEvent;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.admin.locodeco.LocoDecoConstants;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.decorate.Swatch;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.data.house.HouseExpand;
	import com.tinyspeck.engine.data.house.HouseExpandCosts;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.ContiguousPlatformLineSet;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingFurnitureDropVO;
	import com.tinyspeck.engine.net.NetOutgoingFurnitureMoveVO;
	import com.tinyspeck.engine.net.NetOutgoingFurniturePickupVO;
	import com.tinyspeck.engine.net.NetOutgoingFurnitureSetZedsVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesCeilingBuyVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesCeilingChoicesVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesCeilingPreviewVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesCeilingSetVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesExpandCostsVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesFloorBuyVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesFloorChoicesVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesFloorPreviewVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesFloorSetVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesWallBuyVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesWallChoicesVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesWallPreviewVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesWallSetVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackModifyVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbMenuVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.net.NetOutgoingLocationMoveVO;
	import com.tinyspeck.engine.net.NetOutgoingResnapMiniMapVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.pack.CeilingSwatchBagUI;
	import com.tinyspeck.engine.pack.FloorSwatchBagUI;
	import com.tinyspeck.engine.pack.FurnitureBagUI;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.pack.SwatchBagUI;
	import com.tinyspeck.engine.pack.WallSwatchBagUI;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.DecoratorDisclaimerDialog;
	import com.tinyspeck.engine.port.FurnUpgradeDialog;
	import com.tinyspeck.engine.port.HouseExpandDialog;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.UICalloutView;
	import com.tinyspeck.engine.view.geo.ContiguousPlatformLineSetView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackDragView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackGhostView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.renderer.LocationInputHandler;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.ui.decorate.SwatchTarget;
	import com.tinyspeck.engine.view.ui.decorate.ToastDecorate;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	public final class HandOfDecorator extends EventDispatcher implements IFocusableComponent, ILocItemstackAddDelConsumer, ILocItemstackUpdateConsumer, IMoveListener, IRefreshListener
	{
		public static const instance:HandOfDecorator = new HandOfDecorator();
		
		private static const KEY_REPEAT_DELAY:int = 250; // ms
		
		private const plat_under_allowance:int = 10; // pixels over cursor to look for a target plat when dragging an item around
		private const second_storey_y:int = -530;
		private var storey_yA:Array = [];
		private var storey_h:int = 486; // technically it is 475 in homes (486 in towers) but this works while we only have 3 floors in houses
		
		
		private var initialized:Boolean;
		private var has_focus:Boolean;
		private var model:TSModelLocator;
		private var wm:WorldModel;
		private var lm:LayoutModel;
		private var sm:StateModel;
		private var dm:DecorateModel;
		private var gameRenderer:LocationRenderer;
		
		private var selected_lis_view:LocationItemstackView;
		private var highlighted_lis_view:LocationItemstackView;
		private var ghost_liv:LocationItemstackView;
		
		/** While the mouse is down, this specifies whether it originated over the viewport */
		private var mouseDownOriginatedInViewport:Boolean;
		
		// keyboard
		private var kb:KeyBeacon;
		
		private var current_item_class:String;
		private var current_item:Item;
		private var pack_stack_tsid:String;
		private var loc_stack_tsid:String;
		
		private var pl_to_cpls_map:Dictionary;
		private var cpls_to_cplsv_map:Dictionary;
		private const drag_offset_pt:Point = new Point();
		private var other_dragged_lis_viewsV:Vector.<LocationItemstackView>;
		
		private var debug_str:String = 'yes';
		public function get inhibits_scroll():String {
			//if (CONFIG::debugging) {
				debug_str = '';
				if (StageBeacon.mouseIsDown && Cursor.instance.is_dragging)
					debug_str+= ' StageBeacon.mouseIsDown:'+StageBeacon.mouseIsDown+' && Cursor.instance.is_dragging:'+Cursor.instance.is_dragging;
				if (_dragging_furniture_from_bag)
					debug_str+= ' _dragging_furniture_from_bag:'+_dragging_furniture_from_bag;
				if (_dragging_from_pack)
					debug_str+= ' _dragging_from_pack:'+_dragging_from_pack;
				if (_dragging_from_loc)
					debug_str+= ' _dragging_from_loc:'+_dragging_from_loc;
				if (_dragging_proxy_from_loc)
					debug_str+= ' _dragging_proxy_from_loc:'+_dragging_proxy_from_loc;
				if (_stamping)
					debug_str+= ' _stamping:'+_stamping;
				CONFIG::debugging {
					Console.trackValue(' HOD.inhibits_scroll', debug_str);
				}
			//}
			return ((StageBeacon.mouseIsDown && Cursor.instance.is_dragging) || _dragging_furniture_from_bag || _dragging_from_pack || _dragging_from_loc || _dragging_proxy_from_loc || _stamping) ? debug_str : null;
		}
		
		private var _dragging_furniture_from_bag:Boolean;
		private var _dragging_from_pack:Boolean;
		private var _dragging_proxy_from_loc:Boolean;
		private var _dragging_from_loc:Boolean;
		private var _stamping:Boolean;
		
		private var stamping_swatch:Swatch;
		private var stamping_under_cursor_deco:Deco;
		private var stamping_in_center:Boolean;
		private var last_cplsv:ContiguousPlatformLineSetView;
		
		private var _last_cpls:ContiguousPlatformLineSet;
		public function get last_cpls():ContiguousPlatformLineSet {
			return _last_cpls;
		}
		public function set last_cpls(value:ContiguousPlatformLineSet):void {
			_last_cpls = value;
			CONFIG::debugging {
				Console.trackValue(' HOD cpls ', _last_cpls);
			}
		}

		private var last_valid_mouse_pt:Point;
		private var last_closest_pl_pt:Point = new Point();
		private var start_closest_pl_pt:Point = new Point();
		private var last_time_over_vp:int;
		private var temp_lis_view:LocationItemstackView;
		
		private var measuring_mouse_move:Boolean;
		
		private var wall_decosV:Vector.<Deco>;
		private var floor_decosV:Vector.<Deco>;
		private var ceiling_decosV:Vector.<Deco>;
		private var deco_target_map:Dictionary;
		private var target_holders:Dictionary;
		
		private var toast:ToastDecorate = new ToastDecorate();
		
		private var stamping_preview_deco:Deco;
		private var stamping_preview_in_center:Boolean;
		private var stamping_preview_type:String;
		private var stamp_holder:Sprite = new Sprite();
		private var stamp_holder_mask:Sprite = new Sprite();
		public var stamping_preview_key:String;
		public var stamping_preview_undo_layers:Object;
		public var waiting_on_purchase:Boolean;
		
		private var listening_for_ctrl_evts:Boolean;
		private var dragVO:DragVO = DragVO.vo;
		private var and_stop_deco_mode_after_purchase:Boolean;
		private var reusableLIVV:Vector.<LocationItemstackView> = new Vector.<LocationItemstackView>();
		private var door_plat_id:String = ''; // used to know where a door can be placed
		
		public function HandOfDecorator():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			init();
		}
		
		public function refresh():void {
			if (!toast) return;
			if (!model) return;
			//make sure the toast is in the center
			toast.x = model.layoutModel.gutter_w + (model.layoutModel.loc_vp_w/2 - toast.w/2);
			toast.y = model.layoutModel.loc_vp_h + toast.h - 20;
		}
		
		private function init():void {
			if (initialized) return;
			initialized = true;
			
			for (var i:int=0;i<10;i++) {
				storey_yA.unshift(second_storey_y-(i*storey_h));
			}
			
			model = TSModelLocator.instance;
			wm = model.worldModel;
			lm = model.layoutModel;
			sm = model.stateModel;
			dm = model.decorateModel;
			gameRenderer = TSFrontController.instance.getMainView().gameRenderer;
			kb = KeyBeacon.instance;
			
			sm.registerCBProp(onDecoratorModeChange, 'decorator_mode');
			TSFrontController.instance.registerMoveListener(this);
			
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_COMPLETE, furnitureBagDragCompleteHandler);
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_STARTED, furnitureBagDragStartHandler);
			
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, packDragCompleteHandler);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, packDragStartHandler);
			
			LocationInputHandler.instance.addEventListener(TSEvent.DRAG_COMPLETE, locDragCompleteHandler);
			LocationInputHandler.instance.addEventListener(TSEvent.DRAG_STARTED, locDragStartHandler, false, 1);
			
			registerSelfAsFocusableComponent();
			
			//draw the mask for the dragger
			stamp_holder.mask = stamp_holder_mask;
			stamp_holder.addChild(stamp_holder_mask);
		}
		
		public function onToastCancelClick():void {
			stopPreviewingSwatch(true);
		}
		
		public function onToastBuyClick(and_stop_deco_mode:Boolean):void {
			switch(stamping_preview_type){
				case Swatch.TYPE_WALLPAPER:
					TSFrontController.instance.genericSend(new NetOutgoingHousesWallBuyVO(toast.swatch.tsid), onBuySuccess, onBuyFailure);
					break;
				case Swatch.TYPE_FLOOR:
					TSFrontController.instance.genericSend(new NetOutgoingHousesFloorBuyVO(toast.swatch.tsid), onBuySuccess, onBuyFailure);
					break;
				case Swatch.TYPE_CEILING:
					TSFrontController.instance.genericSend(new NetOutgoingHousesCeilingBuyVO(toast.swatch.tsid), onBuySuccess, onBuyFailure);
					break;
				default:
					CONFIG::debugging {
						Console.error('stamping_preview_type:'+stamping_preview_type+'???');
					}
					return;
			}
			
			startWaitingForPurchase(and_stop_deco_mode);
			
			toast.hide(0);
		}
		
		private function startWaitingForPurchase(and_stop_deco_mode:Boolean):void {
			waiting_on_purchase = true;
			and_stop_deco_mode_after_purchase = and_stop_deco_mode;
		}
		
		private function stopWaitingForPurchase():void {
			waiting_on_purchase = false;
			and_stop_deco_mode_after_purchase = false;
		}
		
		// NetController calls this when a swatch has been removed from your account
		public function swatchRemoved(type:String, swatch_tsid:String):void {
			var sw:Swatch = dm.getSwatchByTypeAndTsid(swatch_tsid, type);
			if (!sw) {
				CONFIG::debugging {
					Console.error('WTF type:'+type+' has NO swatch_tsid:'+swatch_tsid);
				}
				return;
			}
			
			CONFIG::debugging {
				Console.info(type+' '+swatch_tsid+' removed');
			}
			
			if (!sw.is_owned) return;
			
			sw.is_owned = false;
			
			const swatch_bag:SwatchBagUI = getSwatchBag(type);
			if(swatch_bag) swatch_bag.rebuildSwatches();
		}
		
		// NetController calls this from some messages which get sent after a houses_*_buy is sent, when the purchase is complste
		// it also happens if you get granted a swatch or buy one out of client, so we must accoutn for that possibility
		public function purchaseCallBack(type:String, swatch_tsid:String, error:Object):void {
			if (error) {
				
				CONFIG::debugging {
					Console.error(error);
				}
				
				reportPurchaseFailure('Cause: '+error);
				
			} else {
				
				var sw:Swatch = dm.getSwatchByTypeAndTsid(swatch_tsid, type);
				if (!sw) {
					CONFIG::debugging {
						Console.error('WTF type:'+type+' has NO swatch_tsid:'+swatch_tsid);
					}
					return;
				}
				
				CONFIG::debugging {
					Console.info(type+' '+swatch_tsid+' bought');
				}
				
				sw.is_owned = true;
				sw.date_purchased = TSFrontController.instance.getCurrentGameTimeInUnixTimestamp();
				
				const swatch_bag:SwatchBagUI = getSwatchBag(type);
				if(swatch_bag && !waiting_on_purchase){
					//rebuild now
					swatch_bag.rebuildSwatches();
					return;
				}
				else if(swatch_bag){
					// delay this a second, so hopefully the reload of the paper decos happens first and more quickly
					StageBeacon.setTimeout(swatch_bag.rebuildSwatches, 1000);
				}
				
				if (sw != toast.swatch) {
					CONFIG::debugging {
						Console.error('WTF sw:'+sw+' != toast.swatch:'+toast.swatch);
					}
					return;
				} else if (type != stamping_preview_type) {
					CONFIG::debugging {
						Console.error('WTF type:'+type+' != stamping_preview_type:'+stamping_preview_type);
					}
					return;
				}
				
				switch(stamping_preview_type){
					case Swatch.TYPE_WALLPAPER:
						setWall(stamping_preview_in_center, stamping_preview_deco, toast.swatch);
						break;
					case Swatch.TYPE_FLOOR:
						setFloor(stamping_preview_deco, toast.swatch);
						break;
					case Swatch.TYPE_CEILING:
						setCeiling(stamping_preview_deco, toast.swatch);
						break;
					default:
						CONFIG::debugging {
							Console.error('stamping_preview_type:'+stamping_preview_type+'???');
						}
						return;
				}
				
				// only do a confirm if it was not free
				if (sw.cost_credits) {
					var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
					cdVO.title = 'Purchase Successful!';
					cdVO.txt = 'You now totally own that thing.';
					cdVO.choices = [
						{value: true, label: 'OK'}
					];
					cdVO.escape_value = false;
					TSFrontController.instance.confirm(cdVO);
				}
				
				stopPreviewingSwatch(false);
				if (and_stop_deco_mode_after_purchase) {
					TSFrontController.instance.stopDecoratorMode();
				}
				stopWaitingForPurchase();
			}
		}
		
		private function getSwatchBag(type:String):SwatchBagUI {
			var swatch_bag:SwatchBagUI;
			
			switch(type){
				case Swatch.TYPE_WALLPAPER:
					swatch_bag = WallSwatchBagUI.instance;
					break;
				case Swatch.TYPE_FLOOR:
					swatch_bag = FloorSwatchBagUI.instance;
					break;
				case Swatch.TYPE_CEILING:
					swatch_bag = CeilingSwatchBagUI.instance;
					break;
			}
			
			return swatch_bag;
		}
		
		// gets a rsp from a buy message
		private function onBuySuccess(rm:NetResponseMessageVO):void {
			// still waiting_on_purchase
		}
		
		// gets a rsp from a buy message
		private function onBuyFailure(rm:NetResponseMessageVO):void {
			if (rm.payload.error && rm.payload.error.msg) {
				reportPurchaseFailure('Cause: '+rm.payload.error.msg);
			} else {
				reportPurchaseFailure('But the specifics are unknown.');
			}
		}
		
		private function reportPurchaseFailure(msg:String):void {
			stopPreviewingSwatch(true); // this undoes!
			stopWaitingForPurchase();
			
			var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.title = 'There was a problem!';
			cdVO.txt = msg;
			cdVO.choices = [
				{value: true, label: 'OK'}
			];
			cdVO.escape_value = false;
			TSFrontController.instance.confirm(cdVO);
		}
		
		public function startFurnitureUpgrade(payload:Object):Boolean {
			if (!payload.itemstack_tsid) return false;
			if (!payload.upgrades) return false;
			
			if (dm.upgrade_itemstack && dm.upgrade_itemstack.tsid == payload.itemstack_tsid) {
				return false;
			}
			
			dm.upgrade_itemstack = wm.getItemstackByTsid(payload.itemstack_tsid);
			
			if (!dm.upgrade_itemstack) return false;
			
			// update the model's upgradesV
			FurnUpgrade.parseMultiple(payload.upgrades, dm.upgradesV);
			if (dm.upgradesV.length) {
				; // barf
				CONFIG::debugging {
					Console.info(dm.upgradesV.length+' possible upgrades');
				}
			} else {
				; // barf
				CONFIG::debugging {
					Console.warn('NO possible upgrades');
				}
			}
			
			SortTools.vectorSortOn(dm.upgradesV, ['is_owned', 'credits', 'id'], [Array.DESCENDING, Array.NUMERIC, Array.NUMERIC]); // sorted by cost, with id:0 (base) on top
			
			// pop the one in use to the top;
			var upgrade:FurnUpgrade;
			var have_the_upgrade:Boolean;
			for (var i:int; i<dm.upgradesV.length;i++) {
				upgrade = dm.upgradesV[i];
				if (upgrade.id == dm.upgrade_itemstack.furn_upgrade_id) {
					have_the_upgrade = true;
					CONFIG::debugging {
						Console.warn('have_the_upgrade:true '+dm.upgrade_itemstack.furn_upgrade_id)
					}
					dm.upgradesV.splice(i, 1);
					dm.upgradesV.unshift(upgrade);
					upgrade.is_owned = true; //if it's being used, then they probably own it
					break;
				}
			}
			
			if (!have_the_upgrade) {
				// WE SHOULD LOG THIS TO CLIENT ERRORS
				CONFIG::debugging {
					Console.warn('invalid upgrade: '+dm.upgrade_itemstack.furn_upgrade_id)
				}
				dm.upgrade_itemstack.itemstack_state.furn_config.upgrade_id = '0';
			}
			
			if (dm.upgrade_itemstack.class_tsid == 'furniture_chassis' || dm.upgrade_itemstack.class_tsid == 'furniture_tower_chassis') {
				TSFrontController.instance.startChassisMode();
			} else {
				FurnUpgradeDialog.instance.start();
			}
			return true;
		}
		
		private function furnitureBagDragStartHandler(e:TSEvent):void {
			if (sm.can_decorate) {
				if (startWithFurnitureFromBag(dragVO.dragged_itemstack.tsid)) {
					_dragging_furniture_from_bag = true;
					StageBeacon.enter_frame_sig.add(onEnterFrameWhileDraggingButNotFocussed);
					
					//if we have a callout still showing, make sure we hide it
					if(UICalloutView.instance.parent && UICalloutView.instance.current_section == UICalloutView.FURNITURE){
						UICalloutView.instance.hide();
					}
				} else if (startWithItemFromPack(dragVO.dragged_itemstack.tsid)) {
					_dragging_from_pack = true;
					StageBeacon.enter_frame_sig.add(onEnterFrameWhileDraggingButNotFocussed);
				}
			}
		}
		
		private function furnitureBagDragCompleteHandler(e:TSEvent):void {
			deselect();
		}
		
		private function packDragStartHandler(e:TSEvent):void {
			if (sm.can_decorate) {
				if (startWithItemFromPack(dragVO.dragged_itemstack.tsid)) {
					_dragging_from_pack = true;
					StageBeacon.enter_frame_sig.add(onEnterFrameWhileDraggingButNotFocussed);
				}
			}
		}
		
		private function packDragCompleteHandler(e:TSEvent):void {
			deselect();
		}
		
		private function locDragStartHandler(e:TSEvent):void {
			if (startWithItemFromLocationWhileNOTinDecorateMode(dragVO.dragged_itemstack.tsid)) {
				// this makes it so we can drop precisely in your own home!
				if (sm.can_decorate) {
					StageBeacon.enter_frame_sig.add(onEnterFrame);
				}
			}
		}
		
		private function locDragCompleteHandler(e:TSEvent):void {
			if (_dragging_proxy_from_loc) {
				dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE));
				deselect()
			} else {
				endWithItemFromLocation();
			}
		}
		
		private function getWallChoices():void {
			TSFrontController.instance.genericSend(
				new NetOutgoingHousesWallChoicesVO(),
				function(rm:NetResponseMessageVO):void {
					Swatch.parseMultiple(rm.payload.choices, Swatch.TYPE_WALLPAPER);
					const swatch_bag:SwatchBagUI = getSwatchBag(Swatch.TYPE_WALLPAPER);
					if(swatch_bag) swatch_bag.rebuildSwatches();
				}
			)
		}
		
		private function getCeilingChoices():void {
			TSFrontController.instance.genericSend(
				new NetOutgoingHousesCeilingChoicesVO(),
				function(rm:NetResponseMessageVO):void {
					Swatch.parseMultiple(rm.payload.choices, Swatch.TYPE_CEILING);
					const swatch_bag:SwatchBagUI = getSwatchBag(Swatch.TYPE_CEILING);
					if(swatch_bag) swatch_bag.rebuildSwatches();
				}
			)
		}
		
		private function getFloorChoices():void {
			TSFrontController.instance.genericSend(
				new NetOutgoingHousesFloorChoicesVO(),
				function(rm:NetResponseMessageVO):void {
					Swatch.parseMultiple(rm.payload.choices, Swatch.TYPE_FLOOR);
					const swatch_bag:SwatchBagUI = getSwatchBag(Swatch.TYPE_FLOOR);
					if(swatch_bag) swatch_bag.rebuildSwatches();
				}
			)
		}
		
		private function startStamping(sw:Swatch):void {
			if (_stamping) {
				stopStamping();
			}
			
			if (stamping_preview_key) {
				stopPreviewingSwatch(true);
			}
			
			_stamping = true;
			stamping_swatch = sw;
			
			SpriteUtil.clean(stamp_holder, true, 1); //don't clean out the mask!
			Cursor.instance.startDragWith(stamp_holder, true);
			DecoAssetManager.loadIndividualDeco(sw.swatch, function(mc:MovieClip, class_name:String, swfWidth:Number, swfHeight:Number):void {
				stamp_holder.addChild(mc);
				mc.x = -Math.round(swfWidth/2);
				mc.y = -Math.round(swfHeight/2);
				
				//draw the mask
				var g:Graphics = stamp_holder_mask.graphics;
				g.beginFill(0);
				g.drawRoundRect(mc.x, mc.y, swfWidth, swfHeight, 10);
			});
			
			removeAllTargets();
			deco_target_map = new Dictionary(true);
			target_holders = new Dictionary(true);
		}
		
		private function removeAllTargets():void {
			if (!deco_target_map) return;
			var swatch_target:SwatchTarget;
			var target_holder:Sprite;
			
			for each (swatch_target in deco_target_map) {
				if (swatch_target.parent) swatch_target.parent.removeChild(swatch_target);
			}
			
			for each (target_holder in target_holders) {
				if (target_holder.parent) target_holder.parent.removeChild(target_holder);
			}
			
			deco_target_map = null;
			target_holders = null;
		}
		
		public function startStampingCeiling(sw:Swatch, by_click:Boolean):void {
			if (waiting_on_purchase) {
				return;
			}
			
			startStamping(sw);
			ceiling_decosV = TSModelLocator.instance.worldModel.location.getCeilingDecos();
			
			var deco:Deco;
			var swatch_target:SwatchTarget;
			var target_holder:Sprite;
			for each (deco in ceiling_decosV) {
				if (deco.ceiling_key) {
					target_holder = target_holders[deco.ceiling_key];
					
					// create a parent for the targets for each ceiling_key
					if (!target_holder) {
						target_holder = target_holders[deco.ceiling_key] = new Sprite();
						target_holder.name = deco.ceiling_key+' target holder';
						TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCHTop(target_holder, 'HOD.startStampingCeiling');
					}
					
					swatch_target = deco_target_map[deco] = new SwatchTarget(deco, 0);
					target_holder.addChild(swatch_target);
				}
			}
			
			if (by_click) {
				Cursor.instance.addEventListener(MouseEvent.CLICK, onCursorClickCeiling);
			} else {
				StageBeacon.mouse_up_sig.add(onCursorClickCeiling);
			}
		}
		
		public function startStampingFloor(sw:Swatch, by_click:Boolean):void {
			if (waiting_on_purchase) {
				return;
			}
			
			startStamping(sw);
			floor_decosV = TSModelLocator.instance.worldModel.location.getFloorDecos();
			
			var deco:Deco;
			var swatch_target:SwatchTarget;
			var target_holder:Sprite;
			for each (deco in floor_decosV) {
				if (deco.floor_key) {
					target_holder = target_holders[deco.floor_key];
					
					// create a parent for the targets for each floor_key
					if (!target_holder) {
						target_holder = target_holders[deco.floor_key] = new Sprite();
						target_holder.name = deco.floor_key+' target holder';
						TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCHTop(target_holder, 'HOD.startStampingFloor');
					}
					
					swatch_target = deco_target_map[deco] = new SwatchTarget(deco, 0);
					target_holder.addChild(swatch_target);
				}
			}
			
			if (by_click) {
				Cursor.instance.addEventListener(MouseEvent.CLICK, onCursorClickFloor);
			} else {
				StageBeacon.mouse_up_sig.add(onCursorClickFloor);
			}
		}
		
		public function startStampingWall(sw:Swatch, by_click:Boolean):void {
			if (waiting_on_purchase) {
				return;
			}
			
			startStamping(sw);
			wall_decosV = TSModelLocator.instance.worldModel.location.getWallPaperDecos();
			
			var deco:Deco;
			var swatch_target:SwatchTarget;
			var target_holder:Sprite;
			for each (deco in wall_decosV) {
				if (deco.room) {
					target_holder = target_holders[deco.room];
					
					// create a parent for the targets for each room
					if (!target_holder) {
						target_holder = target_holders[deco.room] = new Sprite();
						target_holder.name = deco.room+' target holder';
						TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCHTop(target_holder, 'HOD.startStampingWall');
					}
					
					swatch_target = deco_target_map[deco] = new SwatchTarget(deco, 45);
					target_holder.addChild(swatch_target);
				}
			}
			if (by_click) {
				Cursor.instance.addEventListener(MouseEvent.CLICK, onCursorClickWall);
			} else {
				StageBeacon.mouse_up_sig.add(onCursorClickWall);
			}
		}
		
		private function onCursorClickWall(e:MouseEvent):void {
			Cursor.instance.removeEventListener(MouseEvent.CLICK, onCursorClickWall);
			StageBeacon.mouse_up_sig.remove(onCursorClickWall);
			setWall(stamping_in_center, stamping_under_cursor_deco, stamping_swatch);
		}
		
		private function setWall(in_center:Boolean, deco:Deco, sw:Swatch):void {
			if (deco) {
				if (in_center) {
					applyWallPaperToSection(deco.wp_key, sw);
				} else {
					applyWallPaperToRoom(deco.room, sw);
				}
			}
			
			stopStamping();
		}
		
		private function applyWallPaperToSection(wp_key:String, sw:Swatch):void {
			if (sw && wp_key) {
				applyWallPaperWorker(wp_key, sw);
			}
		}
		
		private function applyWallPaperToRoom(room:String, sw:Swatch):void {
			// get all the wp_keys for this decos room
			var wp_keysA:Array = [];
			if (room) {
				for each (var deco:Deco in wall_decosV) {
					if (deco.room == room) wp_keysA.push(deco.wp_key);
				}
			}
			
			if (sw && wp_keysA.length) {
				applyWallPaperWorker(wp_keysA.join(','), sw);
			}
		}
		
		private function applyWallPaperWorker(wp_key:String, sw:Swatch):void {
			if (!sw) return;
			
			if (sw.is_owned) {
				TSFrontController.instance.genericSend(new NetOutgoingHousesWallSetVO(wp_key, sw.tsid), onHomeDecoChangeMsgSuccess);
			} else {
				startPreviewingSwatch(Swatch.TYPE_WALLPAPER);
				TSFrontController.instance.genericSend(new NetOutgoingHousesWallPreviewVO(wp_key, sw.tsid, stamping_preview_key));
			}
		}
		
		private function onCursorClickCeiling(e:MouseEvent):void {
			Cursor.instance.removeEventListener(MouseEvent.CLICK, onCursorClickCeiling);
			StageBeacon.mouse_up_sig.remove(onCursorClickCeiling);
			setCeiling(stamping_under_cursor_deco, stamping_swatch);
		}
		
		private function setCeiling(deco:Deco, sw:Swatch):void {
			if (sw && deco && deco.ceiling_key) {
				if (sw.is_owned) {
					TSFrontController.instance.genericSend(new NetOutgoingHousesCeilingSetVO(deco.ceiling_key, sw.tsid), onHomeDecoChangeMsgSuccess);
				} else {
					startPreviewingSwatch(Swatch.TYPE_CEILING);
					TSFrontController.instance.genericSend(new NetOutgoingHousesCeilingPreviewVO(deco.ceiling_key, sw.tsid, stamping_preview_key));
				}
			}
			
			stopStamping();
		}
		
		private function onCursorClickFloor(e:MouseEvent):void {
			Cursor.instance.removeEventListener(MouseEvent.CLICK, onCursorClickFloor);
			StageBeacon.mouse_up_sig.remove(onCursorClickFloor);
			setFloor(stamping_under_cursor_deco, stamping_swatch);
		}
		
		private function setFloor(deco:Deco, sw:Swatch):void {
			if (sw && deco && deco.floor_key) {
				if (sw.is_owned) {
					TSFrontController.instance.genericSend(new NetOutgoingHousesFloorSetVO(deco.floor_key, sw.tsid), onHomeDecoChangeMsgSuccess);
				} else {
					startPreviewingSwatch(Swatch.TYPE_FLOOR);
					TSFrontController.instance.genericSend(new NetOutgoingHousesFloorPreviewVO(deco.floor_key, sw.tsid, stamping_preview_key));
				}
			}
			
			stopStamping();
		}
		
		private function startPreviewingSwatch(type:String):void {
			stamping_preview_type = type;
			stamping_preview_key = new Date().getTime().toString();
			
			stamping_preview_deco = stamping_under_cursor_deco;
			stamping_preview_in_center = stamping_in_center;
			
			toast.hide(0);
			toast.swatch = stamping_swatch;
			toast.show();
		}
		
		private function stopPreviewingSwatch(undo:Boolean):void {
			if (undo) {
				if (stamping_preview_undo_layers) TSFrontController.instance.updateDeco(stamping_preview_undo_layers);
			}
			toast.hide(0);
			stamping_preview_type = null;
			stamping_preview_key = null;
			stamping_preview_undo_layers = null;
			stamping_preview_deco = null;
		}
		
		private function stopStamping():void {
			_stamping = false;
			stamping_swatch = null;
			stamping_under_cursor_deco = null;
			stamping_in_center = false;
			removeAllTargets();
			Cursor.instance.endDrag();
		}
		
		public function promptForSaveIfPreviewingSwatch(and_stop_deco_mode:Boolean):Boolean {
			/*
			if (stamping_preview_key && toast.parent && toast.promptForSave(and_stop_deco_mode)) {
				stopStamping();
				return true;
			}
			*/
			
			//stop deco mode if we need to
			if (and_stop_deco_mode) {
				TSFrontController.instance.stopDecoratorMode();
			}
			
			return false;
		}
		
		public function onHomeDecoChangeMsgSuccess(rm:NetResponseMessageVO=null):void {
			maybeResnapMiniMap();
		}
		
		public function start():Boolean {
			if (!sm.can_decorate) {
				return false;
			}
			
			// sometimes HOD has some stuff to do and can't just be quit outright
			if (sm.hand_of_god) {
				return false;
			}
			
			if (!TSFrontController.instance.requestFocus(this)) {
				return false;
			}
			
			// place the toast
			TSFrontController.instance.getMainView().addView(toast, true);
			
			gameRenderer.locationView.middleGroundRenderer.hidePCs();
			refresh();
			TSFrontController.instance.registerRefreshListener(this);
			
			setFurnitureZeds();
			
			return true;
		}
		
		private function maybeResnapMiniMap():void {
			if (model.moveModel.moving) return;
			if (!wm.pc.home_info.playerIsAtHome()) return;
			if (selected_lis_view) return; // because we're dragging

			CONFIG::debugging var start_ms:int = getTimer();
			
			if (highlighted_lis_view) highlighted_lis_view.unglow();
			TSFrontController.instance.resnapMiniMap();
			
			if (highlighted_lis_view) highlighted_lis_view.glow();
			
			CONFIG::debugging {
				Console.info('resnapMiniMap took '+(getTimer()-start_ms)+'ms');
			}
			TSFrontController.instance.genericSend(new NetOutgoingResnapMiniMapVO());
		}
		
		public function end():void {		
			deselect();
			TSFrontController.instance.releaseFocus(this);
			gameRenderer.locationView.middleGroundRenderer.showPCs();
			HouseExpandDialog.instance.end(true);
			
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			wall_decosV = null;
			ceiling_decosV = null;
			floor_decosV = null;
			
			//remove the toast
			stopPreviewingSwatch(true);
			if (toast.parent) {
				toast.parent.removeChild(toast);
			}
			
			maybeResnapMiniMap();
			TSFrontController.instance.saveHomeImg();
		}

		private var pl_cache:Dictionary = new Dictionary(true);
		private function getPlatsForCurrentNonFurnitureItem():Vector.<PlatformLine> {
			if (!current_item) return null;
			
			if (!pl_cache[current_item]) {
				if (current_item.hasTags('no_shelf')) {
					pl_cache[current_item] = PlatformLine.getNOTFurnPlatsSolidFromTopForItems(wm.location.mg.platform_lines);
				} else if (current_item.is_special_furniture && model.flashVarModel.furniture_placed_normally_on_pl_plats) {
					pl_cache[current_item] = PlatformLine.getPlatsSolidFromTopForSpecialFurniture(wm.location.mg.platform_lines, current_item.tsid);
				} else {
					pl_cache[current_item] = PlatformLine.getPlatsSolidFromTopForItems(wm.location.mg.platform_lines);
				}
			}
			
			return pl_cache[current_item];
		}
		
		public function calculateTargetPlatformLineForRegStackFromPt(pt:Point):Boolean {
			if (model.flashVarModel.debug_decorator_mode) {
				if (last_cplsv) {
					last_cplsv.hideDot();
				}
			}
			hideGhost();
			
			if (!current_item || current_item.is_furniture) { // not special furniture, mind you!
				return false;
			}
			
			var find_x:int = pt.x;
			var find_y:int = pt.y;
			
			var good:Boolean;
			var cplsv:ContiguousPlatformLineSetView;
			
			var item_plats:Vector.<PlatformLine> = getPlatsForCurrentNonFurnitureItem();
			
			
			// we'll need to rework this when we have house on bottom
			var storey_y:int;
			for (var i:int=0;i<storey_yA.length;i++) {
				storey_y = storey_yA[i];
				if (gameRenderer.getMouseYinMiddleground() < storey_y) {
					item_plats = PlatformLine.getPlatsAboveY(item_plats, storey_y);
					break;
				}
			}
			
			const placement_plats:Vector.<PlatformLine> = PlatformLine.getPlatsBelowY(item_plats, find_y-plat_under_allowance);
			var closest:Object = PlatformLine.getClosestToXYObject(placement_plats, find_x, find_y, true, 0, false);
			var item_ps:Boolean;
			if (!closest) {
				item_ps = true;
				closest = PlatformLine.getClosestToXYObject(item_plats, find_x, find_y, true, 0, true);
			}
			
			if (closest && closest.pl) {
				var pl:PlatformLine = closest.pl;
				
				
				CONFIG::debugging {
					Console.trackPhysicsValue('  reg closest pl 1', pl.tsid+' '+item_ps);
					Console.trackPhysicsValue('  reg closest pl 2', pl.start.x+','+pl.start.y+' '+pl.end.x+','+pl.end.y);
					Console.trackPhysicsValue('  reg closest pl 3', closest.x+' '+closest.y);
				}
				var cpls:ContiguousPlatformLineSet = pl_to_cpls_map[pl];
				if (cpls) good = true;
			}
			
			if (good) {
				last_closest_pl_pt.x = closest.x;
				last_closest_pl_pt.y = cpls.yIntersection(last_closest_pl_pt.x);
				
				showGhost();
				if (model.flashVarModel.debug_decorator_mode) {
					cplsv = cpls_to_cplsv_map[cpls];
					if (cplsv) {
						cplsv.showDot(last_closest_pl_pt.x, last_closest_pl_pt.y);
					}
				}
				
				CONFIG::debugging {
					Console.trackPhysicsValue(' HOD pt', last_closest_pl_pt);
				}
				
				last_valid_mouse_pt = pt;
				last_cplsv = cplsv;
				last_cpls = cpls;
			} else {
				hideGhost();
				last_cplsv = null;
				last_cpls = null;
			}
			
			return last_cpls != null;
		}
		
		public function LIPisHandlingTheDragNow():void {
			if (model.flashVarModel.debug_decorator_mode) {
				if (last_cplsv) {
					last_cplsv.hideDot();
				}
			}
			hideGhost();
			last_cplsv = null;
			last_cpls = null;
		}
		
		public function calculateTargetPlatformLineForFurnitureFromPt(pt:Point):Boolean {
			
			if (model.flashVarModel.debug_decorator_mode) {
				if (last_cplsv) {
					last_cplsv.hideDot();
				}
			}
			hideGhost();
			
			if (!current_item || !current_item.is_furniture) { // special furniture is not ok!
				return false;
			}
			
			var find_x:int = pt.x;
			var find_y:int = pt.y;
			
			var good:Boolean;
			var door_limited:Boolean;
			var cplsv:ContiguousPlatformLineSetView;
			var door_plats:Vector.<PlatformLine>;
			var item_plats:Vector.<PlatformLine>;
			var storey_plats:Vector.<PlatformLine>
			
			CONFIG::debugging {
				Console.trackValue(' HOD current_item', current_item.tsid);
			}
			
			if (current_item.tsid == 'furniture_door') {
				door_limited = true;
				// let's limit the possible drag targets for this door!
				if (door_plat_id) {
					var door_pl:PlatformLine = wm.location.mg.getPlatformLineById(door_plat_id);
					if (door_pl) {
						// the specified line for the door exists! create door_plats to be used for item_plats
						door_plats = new <PlatformLine>[door_pl];
						door_limited = false;
					}
				}
			}
			
			if (!door_limited) {
				if (door_plats) {
					item_plats = door_plats;
				} else {
					// we'll need to rework this when we have house on bottom
					storey_plats = wm.location.mg.platform_lines;
					var storey_y:int;
					for (var i:int=0;i<storey_yA.length;i++) {
						storey_y = storey_yA[i];
						if (gameRenderer.getMouseYinMiddleground() < storey_y) {
							storey_plats = PlatformLine.getPlatsAboveY(wm.location.mg.platform_lines, storey_y);
							break;
						}
					}
					
					item_plats = PlatformLine.getPlacementPlatsForItemClass(storey_plats, current_item_class);
				}
				
				const placement_plats:Vector.<PlatformLine> = PlatformLine.getPlatsBelowY(item_plats, find_y-plat_under_allowance);
				var closest:Object = PlatformLine.getClosestToXYObject(placement_plats, find_x, find_y, true, 0, false);
				var item_ps:Boolean;
				if (!closest) {
					item_ps = true;
					closest = PlatformLine.getClosestToXYObject(item_plats, find_x, find_y, true, 0, false);
				}
				
				if (closest && closest.pl) {
					var pl:PlatformLine = closest.pl;
					CONFIG::debugging {
						Console.trackPhysicsValue(' furn closest pl', 'item_ps:'+item_ps+' '+pl.tsid);
					}
					var cpls:ContiguousPlatformLineSet = pl_to_cpls_map[pl];
					if (cpls) good = true;
				} 
			}
			
			if (good) {
				
				// TODO: compute these only once per drag when drag starts, and redo it here only if width_it_takes == 0
				var width_it_takes:int; // = item.placement_w; (we were using item.placement_w for the width, but that is dumb. so do the below...)
				var height_it_takes:int; // TODO calculate this on the getRect of the view_holder, not just "height"
				
				// this depends on us calling Cursor.instance.startDragWith(); with a lis_view as argument in FurnitureBagUI
				var lis_to_measure:DisplayObject = (Cursor.instance.drag_DO is LocationItemstackView) ? Cursor.instance.drag_DO : temp_lis_view;
				if (lis_to_measure) {
					width_it_takes = lis_to_measure.width;
					height_it_takes = -lis_to_measure.getBounds(lis_to_measure).y;
				}
				
				// correct for the width the furniture blocks out on the platform
				var half_width_it_takes:int = (width_it_takes) ? Math.ceil(width_it_takes/2) : 0;
				last_closest_pl_pt.x = MathUtil.clamp(
					cpls.start.x+half_width_it_takes,
					cpls.end.x-half_width_it_takes,
					closest.x
				);
				
				// get the Y for the corrected last_closest_pl_pt.x
				last_closest_pl_pt.y = cpls.yIntersection(last_closest_pl_pt.x);
				
				// if needed, correct for the height the furniture blocks out in the plane
				if (pl.placement_plane_height && height_it_takes < pl.placement_plane_height) {
					// get the Y for the corrected last_closest_pl_pt.x
					last_closest_pl_pt.y = MathUtil.clamp(
						(last_closest_pl_pt.y - pl.placement_plane_height) + height_it_takes,
						last_closest_pl_pt.y,
						find_y
					)
				}
				
				showGhost();
				if (model.flashVarModel.debug_decorator_mode) {
					cplsv = cpls_to_cplsv_map[cpls];
					if (cplsv) {
						cplsv.showDot(last_closest_pl_pt.x, last_closest_pl_pt.y);
					}
				}
				
				last_valid_mouse_pt = pt;
				last_cplsv = cplsv;
				last_cpls = cpls;
			} else {
				hideGhost();
				last_cplsv = null;
				last_cpls = null;
			}
			
			return last_cpls != null;
		}
		
		private function removeCPLSVs():void {
			// remove all cplsvs
			if (cpls_to_cplsv_map) {
				var cplsv:ContiguousPlatformLineSetView;
				for (var k:Object in cpls_to_cplsv_map) {
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
		
		private function makeMeATempLisViewForDragging(itemstack_tsid:String, x:int, y:int, lis_to_hide:LocationItemstackView=null):LocationItemstackView {
			var lis:LocationItemstackView = new LocationItemstackDragView(itemstack_tsid);
			lis.worth_rendering = true;
			lis.disableGSMoveUpdates();
			lis.x = x;
			lis.y = y;
			
			return lis;
		}
		
		/*----------------------------------------------------
		When you start/end dragging from the location, we use these funcs. We might already have focus in this case, but might not
		----------------------------------------------------*/
		private function startWithItemFromLocationWhileNOTinDecorateMode(itemstack_tsid:String):Boolean {
			
			last_cplsv = null;
			last_cpls = null;
			
			if (has_focus) {
				CONFIG::debugging {
					Console.error('WTF this should not fire when we have focus');
				}
				return false;
			}
			
			var lis_view:LocationItemstackView = gameRenderer.getItemstackViewByTsid(itemstack_tsid);
			
			if (!lis_view || !setLISview(lis_view)) {
				return false;
			}
			
			_dragging_from_loc = true;
			if (startWithItemFromLocation(itemstack_tsid)) {
				return true;
			}
			_dragging_from_loc = false;
			
			return false;
		}
		
		private function startWithItemFromLocation(itemstack_tsid:String):Boolean {
			
			last_cplsv = null;
			last_cpls = null;
			
			if (!selected_lis_view) return false;
			
			// make sure we can act on this thing
			var itemstack:Itemstack = selected_lis_view.itemstack;
			if (!itemstack.item.is_furniture && !itemstack.item.is_special_furniture && !itemstack.item.is_trophy && !itemstack.item.pickupable) {
				return false;
			}
			
			setItemClass(wm.getItemstackByTsid(itemstack_tsid).class_tsid);
			
			if (!current_item) {
				return false;
			}
			
			if (current_item.tsid == 'furniture_door') {
				//make it so that the only plat it can go on is the current plat it is on.
				var pl:PlatformLine = wm.location.getPlatformForStack(itemstack, false);
				door_plat_id = (pl) ? pl.tsid : null;
			}
			
			setLocItemstack(itemstack_tsid);
			
			selected_lis_view.unglow();
			
			// calculate some stuff, so we know how to place things
			start_closest_pl_pt.x = selected_lis_view.x;
			start_closest_pl_pt.y = selected_lis_view.y;
			var pt:Point = gameRenderer.translateLocationCoordsToGlobal(selected_lis_view.x, selected_lis_view.y);
			
			// this will be used for calculateTargetPlatformLineForFurnitureFromPt()
			drag_offset_pt.x = (pt.x-StageBeacon.stage_mouse_pt.x);
			drag_offset_pt.y = (pt.y-StageBeacon.stage_mouse_pt.y);
			
			// now make the thing to drag, offset so we can simply use the gameRenderer.translateLocationCoordsToGlobal pt to place the lis in the dragged holder_sp
			var holder_sp:Sprite = new Sprite();
			holder_sp.x = -StageBeacon.stage_mouse_pt.x;
			holder_sp.y = -StageBeacon.stage_mouse_pt.y;
			
			
			// now make the temp stack and place it correctly
			// this will hide the stack in location. We will unhide it when drag is over
			temp_lis_view = makeMeATempLisViewForDragging(selected_lis_view.tsid, pt.x, pt.y, selected_lis_view);
			holder_sp.addChild(temp_lis_view);
			
			if (current_item.is_furniture) {
				// now how about the stacks sitting on any platforms this furniture has
				other_dragged_lis_viewsV = wm.location.getItemstackViewsOnThisFurniture(selected_lis_view);
			} else {
				other_dragged_lis_viewsV = null
			}
			
			if (other_dragged_lis_viewsV && other_dragged_lis_viewsV.length) {
				for each (var other_lis_view:LocationItemstackView in other_dragged_lis_viewsV) {
					other_lis_view.disableGSMoveUpdates();
				}
			} else {
				other_dragged_lis_viewsV = null;
			}
			
			// now go!
			Cursor.instance.startDragWith(holder_sp);
			
			dragVO.clear();
			dragVO.dragged_itemstack = wm.getItemstackByTsid(itemstack_tsid);
			dispatchEvent(new TSEvent(TSEvent.DRAG_STARTED, dragVO));
			dragVO.setReceptiveLocationItemstacksForDrag();
			
			return true;
		}
		
		private function endWithItemFromLocation():void {
			var ob:Object;
			if (selected_lis_view) {
				if (dragVO.target is LocationItemstackView) {
					var target_lis_view:LocationItemstackView = dragVO.target as LocationItemstackView;
					var target_itemstack:Itemstack = target_lis_view.itemstack;
					
					//let's check if this is a cabinet first
					
					var good_cab_target:Boolean
					
					ob = dragVO.receptive_cabinets[target_itemstack.tsid];
					if (ob && !ob.disabled) good_cab_target = true;
					
					if(good_cab_target){
						TSFrontController.instance.genericSend(
							new NetOutgoingLocationMoveVO(
								dragVO.dragged_itemstack.tsid,
								dragVO.dragged_itemstack.container_tsid,
								target_itemstack.tsid
							)
						);
						
						dragVO.target.unhighlightOnDragOut();
						//Cursor.instance.hideTip();
						//return;
					} else {
						ob = dragVO.receptive_location_items[target_itemstack.tsid];
						if (!ob || ob.disabled) ob = dragVO.receptive_location_itemstacks[target_itemstack.tsid];
						if (ob && !ob.disabled) {
							var verb_tsid:String = ob.verb;
							var verb:Verb = target_itemstack.item.getVerbByTsid(verb_tsid); // we /might/ have it.
							
							TSFrontController.instance.genericSend(
								new NetOutgoingItemstackVerbMenuVO(target_itemstack.tsid, false, ((dragVO.dragged_itemstack) ? dragVO.dragged_itemstack.tsid : '')),
								function(rm:NetResponseMessageVO):void {
									var verb:Verb = target_itemstack.item.verbs[verb_tsid]; // conditional_verbs got updated in netcontroller by this msg rsp
									if (rm.success && verb && verb.enabled) { // we have the the Verb now
										TSFrontController.instance.startItemstackMenuWithVerbAndTargetItem(
											target_itemstack, verb, dragVO.dragged_itemstack.item, dragVO.dragged_itemstack, true
										);
									}
								},
								null
							);
						}
					}
					
				} else if (last_cpls) {
					dropFromLocationOnTargetPlatform();
				} else if (loc_stack_tsid && FurnitureBagUI.instance.hitTestObject(Cursor.instance.drag_DO)) {
					if (current_item.is_furniture || current_item.is_special_furniture) {
						/*
						if (dragVO.receptive_bag_tsidsA.indexOf(model.worldModel.pc.furniture_bag_tsid) > -1) {
							dropFurnitureFromLocationInFurnitureBag();
						}
						*/
						ob = dragVO.receptive_bags[model.worldModel.pc.furniture_bag_tsid];
						if (ob && !ob.disabled) {
							dropFurnitureFromLocationInFurnitureBag();
						}
					} else if (current_item.is_trophy)  {
						// if we're not in deco mode, then let PDM handle this
						if (sm.decorator_mode) {
							ob = dragVO.receptive_bags[model.worldModel.pc.furniture_bag_tsid];
							if (ob && !ob.disabled) {
								dropTrophyFromLocationInFurnitureBag();
							}
						}
					}
				}
			}
			deselect();
			
			if (!has_focus) {
				// we must have added this listener when we started dragging a locstack
				// while not in deco mode, in locDragStartHandler() 
				StageBeacon.enter_frame_sig.remove(onEnterFrame);
			}
		}
		
		private function dropTrophyFromLocationInFurnitureBag():void {
			var itemstack:Itemstack = wm.getItemstackByTsid(loc_stack_tsid);
			TSFrontController.instance.sendItemstackVerb(
				new NetOutgoingItemstackVerbVO(
					itemstack.tsid,
					'pickup',
					itemstack.count
				)
			);
		}
		
		private function dropFurnitureFromLocationInFurnitureBag():void {
			var itemstack:Itemstack = wm.getItemstackByTsid(loc_stack_tsid);
			
			// remember some stuff
			var was_x:int = itemstack.x;
			var was_selected_lis_view:LocationItemstackView = selected_lis_view;
			
			// let's make sure the thing is moved so it cannot be seen while we wait for the GS to move it
			selected_lis_view.visible = false;
			itemstack.x = selected_lis_view.x = -8000;
			
			if (other_dragged_lis_viewsV && other_dragged_lis_viewsV.length) {
				for each (var other_lis_view:LocationItemstackView in other_dragged_lis_viewsV) {
					other_lis_view.x = other_lis_view.itemstack.x;
					other_lis_view.y = other_lis_view.itemstack.y;
				}
			}
			TSFrontController.instance.genericSend(
				new NetOutgoingFurniturePickupVO(loc_stack_tsid),
				onHomeDecoChangeMsgSuccess, 
				function(rm:NetResponseMessageVO):void {
					// this pick up failed, put the stack back where it should be!
					was_selected_lis_view.x = itemstack.x = was_x;
					was_selected_lis_view.changeHandler(true);
				}
			);
		}
		
		private function dropFromLocationOnTargetPlatform():void {
			door_plat_id = null;
			if (selected_lis_view && last_cpls && last_valid_mouse_pt) {
				var itemstack:Itemstack;
				
				if (!current_item) {
					return;
				}
				
				itemstack = wm.getItemstackByTsid(loc_stack_tsid);
				
				if (!itemstack) {
					return;
				}
				
				var fake_msg:Object;
				var changed:Boolean = (last_closest_pl_pt.x != itemstack.x || last_closest_pl_pt.y != itemstack.y);
				
				// remember some stuff
				var was_x:int = itemstack.x;
				var was_y:int = itemstack.y;
				var was_selected_lis_view:LocationItemstackView = selected_lis_view;
				var was_other_pts:Dictionary;
				
				// how much it will be moved in the end, when it settles on a platform
				var diff_moved_x:int = last_closest_pl_pt.x - itemstack.x;
				var diff_moved_y:int = last_closest_pl_pt.y - itemstack.y;
				
				// how much it was moved visually by dragging
				var diff_dragged_x:int = last_valid_mouse_pt.x - start_closest_pl_pt.x;
				var diff_dragged_y:int = last_valid_mouse_pt.y - start_closest_pl_pt.y;
				
				//---------------------------------------------------------------------
				// place it where you dragged to
				//---------------------------------------------------------------------
				selected_lis_view.x = last_valid_mouse_pt.x;
				selected_lis_view.y = last_valid_mouse_pt.y;
				selected_lis_view.visible = true;
				
				// we must update the model here so that bringToFront can find the proper platform the furn is on
				itemstack.x = last_closest_pl_pt.x;
				itemstack.y = last_closest_pl_pt.y;
				
				selected_lis_view.bringToFront();
				
				if (changed) {
					itemstack.x = selected_lis_view.x;
					itemstack.y = selected_lis_view.y;
					
					// move any plats that came with this furniture
					var plV:Vector.<PlatformLine> = wm.location.mg.getPlatformLinesBySource(itemstack.tsid);
					if (plV && plV.length) {
						var fake_obj:Object = {
							platform_lines: {}
						};
						for each (var pl:PlatformLine in plV) {
							fake_obj.platform_lines[pl.tsid] = {
								start: {
									x:pl.start.x+diff_moved_x,
									y:pl.start.y+diff_moved_y
								},
								end: {
									x:pl.end.x+diff_moved_x,
									y:pl.end.y+diff_moved_y
								}
							}
						}
						
						TSFrontController.instance.updateGeo(fake_obj);
					}
				}
				
				// get a list of stacks that are getting moved along with this furniture, and move them as needed
				var also_tsids:Array = [];
				if (other_dragged_lis_viewsV && other_dragged_lis_viewsV.length) {
					for each (var other_lis_view:LocationItemstackView in other_dragged_lis_viewsV) {
						other_lis_view.bringToFront();
						
						if (changed) {
							if (!was_other_pts) { // lazy!
								was_other_pts = new Dictionary(true);
							}
							also_tsids.push(other_lis_view.tsid);
							was_other_pts[other_lis_view] = new Point(other_lis_view.itemstack.x, other_lis_view.itemstack.y);
							other_lis_view.itemstack.x = other_lis_view.x;
							other_lis_view.itemstack.y = other_lis_view.y;
						} else {
							selected_lis_view.changeHandler(true);
						}
						
					}
				}
				
				if (changed) {
					
					var undoFunc:Function = function(rm:NetResponseMessageVO):void {
						// this move failed, put the stacks back where they were!
						was_selected_lis_view.x = itemstack.x = was_x;
						was_selected_lis_view.y = itemstack.y = was_y;
						was_selected_lis_view.changeHandler(true);
						if (was_other_pts) {
							var other_lis_view:LocationItemstackView;
							for (var ob:Object in was_other_pts) {
								other_lis_view = LocationItemstackView(ob);
								if (other_lis_view.itemstack && was_other_pts[other_lis_view]) {
									other_lis_view.itemstack.x = other_lis_view.x = was_other_pts[other_lis_view].x;
									other_lis_view.itemstack.y = other_lis_view.y = was_other_pts[other_lis_view].y;
									other_lis_view.changeHandler(true);
								}
							}
						}
						// move back any plats that came with this furniture
						if (plV && plV.length) {
							for each (var pl:PlatformLine in plV) {
								fake_obj.platform_lines[pl.tsid] = {
									start: {
										x:pl.start.x-diff_moved_x,
											y:pl.start.y-diff_moved_y
									},
									end: {
										x:pl.end.x-diff_moved_x,
											y:pl.end.y-diff_moved_y
									}
								}
							}
							
							TSFrontController.instance.updateGeo(fake_obj);
						}
					}
					
					//---------------------------------------------------------------------
					// ask the GS to place it in location at the valid spot on the platform!
					// This will result in it being animated from the place it is dropped to the platform
					// Undo the above if it is a fail response!!
					//---------------------------------------------------------------------
					// TODO: Also, maybe set a timer and undo if we get no changes for this stack
					
					if (current_item.is_furniture || (current_item.is_special_furniture && model.flashVarModel.furniture_placed_normally_on_pl_plats)) {
						
						TSFrontController.instance.genericSend(
							new NetOutgoingFurnitureMoveVO(
								itemstack.tsid,
								last_closest_pl_pt.x,
								last_closest_pl_pt.y,
								diff_moved_x,
								diff_moved_y,
								also_tsids
							),
							onHomeDecoChangeMsgSuccess, 
							undoFunc
						);
						
					} else {
						if (checkXIsInBounds(last_closest_pl_pt.x)) {
							TSFrontController.instance.genericSend(
								new NetOutgoingItemstackModifyVO(
									itemstack.tsid,
									last_closest_pl_pt.x,
									last_closest_pl_pt.y,
									null,
									null,
									!shouldMerge(current_item_class)
								),
								null, 
								undoFunc
							);
						}
					}
				} else {
					// we don't need to do anything over the wire in this case, so just animate it back to the original location.
					// technically the below not needed, because it will get called in selected_lis_view.enableGSMoveUpdates() in deselect()
					// but I am leaving it in so it is clearer what is animating the stack back to original location
					selected_lis_view.changeHandler(true);
				}
			}
		}
		
		private function checkXIsInBounds(x:int):Boolean {
			if (x >= wm.location.l && x <= wm.location.r) return true;
			CONFIG::debugging {
				Console.error('x:'+x+' is out of bounds! l:'+wm.location.l+' r:'+wm.location.r);
			}
			return false;

		}
		
		/*----------------------------------------------------
		END dragging from location stuff
		----------------------------------------------------*/
		
		/*----------------------------------------------------
		When you start/end dragging a non furniture item from the pack, we use these funcs. We do not take focus in this case
		----------------------------------------------------*/
		
		private function startWithItemFromPack(itemstack_tsid:String):Boolean {
			
			last_cplsv = null;
			last_cpls = null;
			
			var item:Item = wm.getItemByItemstackId(itemstack_tsid);
			if (!item || item.is_furniture) {
				return false;
			}
			
			setItemClass(wm.getItemstackByTsid(itemstack_tsid).class_tsid);
			
			setPackItemstack(itemstack_tsid);
			
			return true;
		}
		
		private function shouldMerge(item_class:String):Boolean {
			// if we're dropping directly on stack, then merge. Otherwise, no
			var lisV:Vector.<LocationItemstackView> = wm.location.getItemstackViewsOnThisCPLS(last_cpls);
			var no_merge:Boolean = true;
			var tolerance:int = 10;
			if (lisV && lisV.length) { 
				for each (var lis:LocationItemstackView in lisV) {
					if (lis.item.tsid != item_class) continue;
					if (Math.abs(last_closest_pl_pt.x-lis.x) > tolerance) continue;
					
					return true;
				}
			}
			
			return false;
		}
		
		public function dropItemFromPackOnTargetPlatform():void {
			if (!last_cpls) return;
			if (checkXIsInBounds(last_closest_pl_pt.x)) {
				var itemstack:Itemstack = wm.getItemstackByTsid(pack_stack_tsid);
				TSFrontController.instance.sendItemstackVerb(
					new NetOutgoingItemstackVerbVO(
						itemstack.tsid,
						'drop',
						itemstack.count,
						null,
						null,
						null,
						null,
						null,
						null,
						last_closest_pl_pt.x,
						last_closest_pl_pt.y,
						!shouldMerge(current_item_class)
					)
				);
			}
		}
		
		/*----------------------------------------------------
		END dragging non furniture item from the pack
		----------------------------------------------------*/
		
		/*----------------------------------------------------
		When you start/end dragging from the furniture bag, we use these funcs. We do not take focus in this case
		----------------------------------------------------*/
		
		private function startWithFurnitureFromBag(itemstack_tsid:String):Boolean {
			
			last_cplsv = null;
			last_cpls = null;
			
			var item:Item = wm.getItemByItemstackId(itemstack_tsid);
			if (!item || !item.is_furniture) {
				return false;
			}
			
			// let's see if we can add a door, and where (but only in home interior, not in towers)
			if (item.tsid == 'furniture_door' && model.worldModel.location.tsid == model.worldModel.pc.home_info.interior_tsid) {
				TSFrontController.instance.genericSend(new NetOutgoingHousesExpandCostsVO(), onNetOutgoingHousesExpandCosts, onNetOutgoingHousesExpandCosts);
			}
			
			setItemClass(wm.getItemstackByTsid(itemstack_tsid).class_tsid);
			
			setPackItemstack(itemstack_tsid);
			
			return true;
		}

		private function onNetOutgoingHousesExpandCosts(nrm:NetResponseMessageVO):void {
			door_plat_id = null;
			if(nrm.success){
				var house_expand:HouseExpand = HouseExpand.fromAnonymous(nrm.payload);
				const cost:HouseExpandCosts = house_expand.getCostsByType(HouseExpandCosts.TYPE_FLOOR);
				if (cost.door_placement && cost.door_placement.plat_id) {
					if (cost.locked) {
						;//
						CONFIG::debugging {
							Console.info('I think there is a job already going');
						}
					} else {
						door_plat_id = cost.door_placement.plat_id;
						
						// NOW update the visuals on the dragged stack and the ghost!
						var door_config_state:String = 'door_'+cost.door_placement.direction+'_job';
						CONFIG::debugging {
							Console.info(door_config_state);
						} 
						
						if (!dragVO) return;
						if (!dragVO.dragged_itemstack) return;
						if (!dragVO.dragged_itemstack.itemstack_state.furn_config) return;
						if (!(Cursor.instance.drag_DO is LocationItemstackView)) return;
						if (dragVO.dragged_itemstack.tsid != pack_stack_tsid) return;
						if (dragVO.dragged_itemstack.item.tsid != 'furniture_door') return;
						
						
						dragVO.dragged_itemstack.itemstack_state.furn_config.config.door = door_config_state;
						dragVO.dragged_itemstack.itemstack_state.furn_config.is_dirty = true;
						dragVO.dragged_itemstack.itemstack_state.is_config_dirty = true;
						LocationItemstackView(Cursor.instance.drag_DO).changeHandler();
						
						if (ghost_liv) {
							dragVO.dragged_itemstack.itemstack_state.furn_config.is_dirty = true;
							dragVO.dragged_itemstack.itemstack_state.is_config_dirty = true;
							ghost_liv.changeHandler();
						}
					}
				} else {
					if (!dragVO.receptive_location_itemstacks) {
						// show dialog explaining why you can't add a door
						HouseExpandDialog.instance.startWithType(HouseExpandCosts.TYPE_FLOOR);
					} else {
						for (var k:String in dragVO.receptive_location_itemstacks) {
							// there is one, so let's get out of here and not show the HouseExpandDialog
							return;
						}
						// show dialog explaining why you can't add a door
						HouseExpandDialog.instance.startWithType(HouseExpandCosts.TYPE_FLOOR);
						
					}
				}
			}
			else if(nrm.payload.error){
				;// stupid
				CONFIG::debugging {
					Console.warn('request for the data failed!');
				}
			}
		}
		
		public function dropFurnitureFromBagOnTargetPlatform():void {
			door_plat_id = null;
			if (last_cpls && last_valid_mouse_pt) {
				var itemstack:Itemstack = wm.getItemstackByTsid(pack_stack_tsid);
				
				if (!itemstack) {
					return;
				}
				
				// remember some stuff
				var was_x:int = itemstack.x;
				var was_y:int = itemstack.y;
				var was_path:String = itemstack.path_tsid;
				
				//---------------------------------------------------------------------
				// move it from furniture bag to location, at the spot it was dragged to
				//---------------------------------------------------------------------
				
				// we must place it in location on the plat, so that it gets placed at correct depth
				TSFrontController.instance.fakeMovingAStackFromPlayerToLocation(itemstack, last_closest_pl_pt.x, last_closest_pl_pt.y);
				
				// now let's move it up to where it was dropped, so the below will cause it to animate to the platform
				var lis_view:LocationItemstackView = gameRenderer.getItemstackViewByTsid(itemstack.tsid);
				if (lis_view) {
					itemstack.x = lis_view.x = last_valid_mouse_pt.x;
					itemstack.y = lis_view.y = last_valid_mouse_pt.y;
					lis_view.changeHandler(true);
				}
				
				lis_view.parent.getChildIndex(lis_view);
				
				//---------------------------------------------------------------------
				// ask the GS to place it in location at the valid spot on the platform!
				// This will result in it being animated from the place it is dropped to the platform
				// Undo the above if it is a fail response!! 
				//---------------------------------------------------------------------
				// TODO: Also, set a timer and undo if we get no changes for this stack
				TSFrontController.instance.genericSend(
					new NetOutgoingFurnitureDropVO(
						itemstack.tsid,
						last_closest_pl_pt.x,
						last_closest_pl_pt.y,
						lis_view.parent.getChildIndex(lis_view)
					),
					onHomeDecoChangeMsgSuccess, 
					function(rm:NetResponseMessageVO):void {
						// this drop failed, put the stack back where it should be!
						TSFrontController.instance.fakeMovingAStackFromLocationToPlayer(itemstack, was_path, was_x, was_y);
					}
				);
				
				TSFrontController.instance.startDecoratorMode();
			}
		}
		
		/*----------------------------------------------------
		END dragging from furn bag stuff
		----------------------------------------------------*/
		
		private function makeGhost(tsid:String):void {
			removeGhost()// just in case
			
			ghost_liv = new LocationItemstackGhostView(tsid);
			ghost_liv.worth_rendering = true;
			ghost_liv.disableGSMoveUpdates();
			ghost_liv.visible = false;
			ghost_liv.alpha = .7;
			gameRenderer.placeOverlayInSCH(ghost_liv, 'HOD.makeGhost');
		}
		
		private function removeGhost():void {
			if (ghost_liv) {
				var this_ghost_liv:LocationItemstackView = ghost_liv;
				TSTweener.addTween(ghost_liv, {alpha:0, time:.5, onComplete:function():void {
					this_ghost_liv.dispose();
					if (this_ghost_liv.parent) this_ghost_liv.parent.removeChild(this_ghost_liv);
				}})
			}
			
			ghost_liv = null;
		}
		
		private function showGhost():void {
			if (ghost_liv) {
				ghost_liv.visible = true;
				ghost_liv.x = last_closest_pl_pt.x;
				ghost_liv.y = last_closest_pl_pt.y;
			}
		}
		
		private function hideGhost():void {
			if (ghost_liv) {
				ghost_liv.visible = false;
			}
		}
		
		private function setLocItemstack(tsid:String):void {
			loc_stack_tsid = tsid;
			pack_stack_tsid = null;
			makeGhost(tsid);
		}
		
		private function setPackItemstack(tsid:String):void {
			pack_stack_tsid = tsid;
			loc_stack_tsid = null;
			makeGhost(tsid);
		}
		
		private function setItemClass(item_class:String):void {
			current_item_class = item_class;
			current_item = wm.getItemByTsid(current_item_class);
			
			// create a new map each time we set the item class, since the mapping are only relevant per item_class
			if (current_item.is_furniture) {
				pl_to_cpls_map = ContiguousPlatformLineSet.getPLtoCPLSDictionary(wm.location.mg.platform_lines, current_item_class);
			} else {
				pl_to_cpls_map = ContiguousPlatformLineSet.getPLtoCPLSDictionary(getPlatsForCurrentNonFurnitureItem());
			}
			
			// if we're debugging, create and show the cplsvs
			if (model.flashVarModel.debug_decorator_mode) {
				createCPLSVs();
			}
		}
		
		private function createCPLSVs():void {
			// make sure we have removed all the previous CPLVs!
			removeCPLSVs();
			
			cpls_to_cplsv_map = new Dictionary(true);
			
			// go over each key (which are pls) and make them all visible
			var pl:PlatformLine;
			var cpls:ContiguousPlatformLineSet;
			var cplsv:ContiguousPlatformLineSetView;
			for (var k:Object in pl_to_cpls_map) {
				pl = (k as PlatformLine);
				cpls = pl_to_cpls_map[pl];
				
				// if we dont already have a renderer for this cpls, make it!
				if (!cpls_to_cplsv_map[cpls]) {
					cplsv = cpls_to_cplsv_map[cpls] = new ContiguousPlatformLineSetView(cpls);
					cplsv.draw(/*item.placement_w/2*/);
					gameRenderer.placeOverlayInSCH(cplsv, 'HOD.createCPLSVs');
				}
			}
		}
		
		private function setFurnitureZedsIfThereIsFurn(tsids:Array):void {
			if (!sm.can_decorate) return;
			
			var i:int;
			var tsid:String;
			var itemstack:Itemstack;
			
			for (i=0;i<tsids.length;i++) {
				itemstack = wm.getItemstackByTsid(tsids[i]);
				if (!itemstack) continue;
				if (itemstack.item.is_furniture) {
					setFurnitureZeds();
					return;
				}
			}
		}
		
		private var zed_tim:int;
		private function setFurnitureZeds():void {
			if (!gameRenderer.lis_viewV.length) return;
			StageBeacon.clearTimeout(zed_tim);
			zed_tim = StageBeacon.setTimeout(setFurnitureZedsDo, 500);
		}
		
		private function setFurnitureZedsDo():void {
			if (!gameRenderer.lis_viewV.length) return;
			var start:int = getTimer();
			
			CONFIG::god {
				var changedA:Array = []; // this is just for logging purposes
			}
			var changedHash:Object = {};
			var lis_view:LocationItemstackView;
			var itemstack:Itemstack;
			var i:int = 0;
			var furn_itemstackA1:Array = [];
			var furn_itemstackA2:Array;
			var same_order:Boolean = true;
			var some_changed:Boolean = false;
			
			// build arrays and set display_z on the stacks, so we can sort on it
			for (i=0;i<gameRenderer.lis_viewV.length;i++) {
				lis_view = gameRenderer.lis_viewV[i]
				if (!lis_view.parent) continue;
				if (!lis_view.item.is_furniture) continue;
				
				furn_itemstackA1.push(lis_view.itemstack);
				lis_view.itemstack.display_z = lis_view.parent.getChildIndex(lis_view);
			}
			
			furn_itemstackA2 = furn_itemstackA1.concat();
			furn_itemstackA2.sortOn(['z'], [Array.NUMERIC]);
			furn_itemstackA1.sortOn(['display_z'], [Array.NUMERIC]);
			
			// go over the arrays, one ordered by z, the other  by display_z, and see if there is a discrepancy
			for (i=0;i<furn_itemstackA1.length;i++) {
				if (furn_itemstackA1[i].z == uint.MAX_VALUE) {
					// this tells us we have not yet set the value on the GS itemstack yet, so we need to send a message
					same_order = false;
					break;
				}
				if (furn_itemstackA1[i] != furn_itemstackA2[i]) {
					same_order = false;
					break;
				}
			}
			
			// we can bail, nothing has changed
			if (same_order) {
				CONFIG::debugging {
					Console.priinfo(488, (getTimer()-start)+'ms same_order:'+same_order);
				}
				return;
			}
			
			// build the data to send to the server
			for (i=0;i<furn_itemstackA1.length;i++) {
				itemstack = furn_itemstackA1[i];
				
				if (itemstack.display_z == itemstack.z) continue;
				
				some_changed = true;
				
				changedHash[itemstack.tsid] = itemstack.display_z;
				
				// for logging
				CONFIG::god {
					changedA.push({
						tsid:itemstack.tsid,
						z: itemstack.display_z,
						was_z: itemstack.z
					});
				}
				
				// go ahead and set it now locally, and do not wait for the changes to come in!
				itemstack.z = itemstack.display_z;
			}
			
			// no changes, bail
			if (!some_changed) {
				CONFIG::debugging {
					Console.priinfo(488, (getTimer()-start)+'ms some_changed:'+some_changed);
				}
				return;
			}
			
			CONFIG::debugging {
				Console.priinfo(488, (getTimer()-start)+'ms sending FURNITURE_SET_ZEDS');
				CONFIG::god {
					Console.pridir(488, changedA);
				}
			}
			
			TSFrontController.instance.genericSend(
				new NetOutgoingFurnitureSetZedsVO(changedHash)
			);
		}
		
		
		////////////////////////////////////////////////////////////////////////////////
		//////// Handlers //////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		private function startListeningForControlEvts():void {
			if (listening_for_ctrl_evts) return;
			StageBeacon.enter_frame_sig.add(onEnterFrame);
			
			// track the mouse for deco selection
			StageBeacon.mouse_down_sig.add(onMouseDown);
			StageBeacon.mouse_move_sig.add(onMouseMove);
			StageBeacon.stage.addEventListener(CartesianMouseEvent.CARTESIAN_MOUSE_WHEEL, onMouseWheel);
			kb.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey);
			
			TSFrontController.instance.startListeningToZoomKeys(zoomKeyHandler);
			listening_for_ctrl_evts = true;
		}
		
		private function stopListeningForControlEvts():void {
			StageBeacon.enter_frame_sig.remove(onEnterFrame);
			
			// stop tracking mouse
			StageBeacon.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			StageBeacon.mouse_down_sig.remove(onMouseDown);
			StageBeacon.mouse_move_sig.remove(onMouseMove);
			StageBeacon.stage.removeEventListener(CartesianMouseEvent.CARTESIAN_MOUSE_WHEEL, onMouseWheel);
			kb.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey);
			
			TSFrontController.instance.stopListeningToZoomKeys(zoomKeyHandler);
			listening_for_ctrl_evts = false;
		}
		
		private function zoomKeyHandler(e:KeyboardEvent):void {
			// it's important that we don't add shared listeners directly to TSFC
			// because where one class has started listening, another might
			// remove the same listener by accident, so the first class fails
			TSFrontController.instance.zoomKeyHandler(e);
		}
		
		private function onEscapeKey(event:Event):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (_stamping) {
				stopStamping();
			} else if (stamping_preview_key) {
				/*
				if (promptForSaveIfPreviewingSwatch(false)) {
					//
				} else {
					stopPreviewingSwatch(true);
				}
				*/
				stopPreviewingSwatch(true);
			} else if (HouseExpandDialog.instance.parent){
				HouseExpandDialog.instance.end(true);
			} else {
				TSFrontController.instance.stopDecoratorMode();
			}
		}
		
		private function onDecoratorModeChange(enabled:Boolean):void {
			if (!enabled) deselect();
		}
		
		private function onEnterFrame(time:int):void {
			maybeScrollVPByDragging();
			maybeScrollVPByKeys();
			
			if (_stamping) {
				stamping_under_cursor_deco = null;
				stamping_in_center = false;
				
				var target_holder:Sprite;
				var swatch_target:SwatchTarget;
				var deco_key:Object;
				var deco:Deco;
				
				for (deco_key in deco_target_map) {
					deco = deco_key as Deco;
					swatch_target = deco_target_map[deco];
					if (swatch_target.hitTestPoint(StageBeacon.stage_mouse_pt.x, StageBeacon.stage_mouse_pt.y)) {
						stamping_under_cursor_deco = deco as Deco;
						target_holder = swatch_target.parent as Sprite;
						
						if (!target_holder) {
							CONFIG::debugging {
								Console.warn('WTF no target_holder');
							}
							break;
						}
						
						// for those with a center area (wall segment targets) we need to behave differently if over the center
						if (swatch_target.center && swatch_target.center.hitTestPoint(StageBeacon.stage_mouse_pt.x, StageBeacon.stage_mouse_pt.y)) {
							stamping_in_center = true;
							target_holder.filters = null;
							swatch_target.filters = StaticFilters.decoTarget_GlowA;
						} else {
							target_holder.filters = StaticFilters.decoTarget_GlowA;
							swatch_target.filters = null;
						}
						
						break;
					}
				}
				
				for (deco_key in deco_target_map) {
					deco = deco_key as Deco;
					swatch_target = deco_target_map[deco];
					if (swatch_target.parent == target_holder && stamping_under_cursor_deco && (!stamping_in_center || deco == stamping_under_cursor_deco)) {
						swatch_target.visible = true;
					} else {
						swatch_target.visible = false;
						swatch_target.filters = null;
					}
				}
				
			} else if (selected_lis_view && current_item && !measuring_mouse_move) {
				// here check for valid drops
				var pt:Point = gameRenderer.getMouseXYinMiddleground().add(drag_offset_pt);
				var good:Boolean;
				var over_vp_at_all:Boolean = Cursor.instance.drag_DO && gameRenderer.hitTestObject(Cursor.instance.drag_DO);
				
				if (over_vp_at_all) {
					
					var target:IDragTarget = dragVO.findDragTargetForStack();
					if (target != dragVO.target) {
						if (dragVO.target) dragVO.target.unhighlightOnDragOut();
						dragVO.target = target; // tuck a reference to the target in the dragVO
						if (dragVO.target) dragVO.target.highlightOnDragOver();
					}
					
					dragVO.target = target || gameRenderer;
					
					if (dragVO.target is LocationItemstackView) {
						HandOfDecorator.instance.LIPisHandlingTheDragNow();
						var target_itemstack:Itemstack;
						var target_item:Item;
						var target_lis_view:LocationItemstackView;
						target_lis_view = dragVO.target as LocationItemstackView;
						target_itemstack = target_lis_view.itemstack;
						target_item = target_itemstack.item;
						
						var ob:Object = dragVO.receptive_location_items[target_item.tsid];
						if (!ob) ob = dragVO.receptive_location_itemstacks[target_itemstack.tsid];
						
						//handle cabinets
						if (!ob) {
							ob = dragVO.receptive_cabinets[target_itemstack.tsid];
						}
						
						if (ob) {
							if (ob.disabled) {
								Cursor.instance.showTip('<font color="#cc0000">'+ob.tip+'</font>');
							} else {
								Cursor.instance.showTip(ob.tip);
							}
						} else {
							//Cursor.instance.showTip('huh?');
							Cursor.instance.hideTip();
						}	
					} else {
						Cursor.instance.hideTip();
						
						if (current_item.is_furniture) {
							good = calculateTargetPlatformLineForFurnitureFromPt(pt);
							
							if (good && FurnitureBagUI.instance.hitTestObject(Cursor.instance.drag_DO)) {
								good = false;
							}
						} else {
							good = calculateTargetPlatformLineForRegStackFromPt(pt);
							
							if (good && FurnitureBagUI.instance.hitTestObject(Cursor.instance.drag_DO)) {
								good = false;
							}
						}
					}
				}
				
				if (good) {
					PackDisplayManager.instance.onHODHasATarget();
				} else {
					PackDisplayManager.instance.onHODHasNoTarget();
					if (model.flashVarModel.debug_decorator_mode) {
						if (last_cplsv) {
							last_cplsv.hideDot();
						}
					}
					hideGhost();
					last_cplsv = null;
					last_cpls = null;
				}
				
				if (Cursor.instance.drag_DO) {
					Cursor.instance.drag_DO.visible = !good;
				}
				if (other_dragged_lis_viewsV && other_dragged_lis_viewsV.length) {
					for each (var other_lis_view:LocationItemstackView in other_dragged_lis_viewsV) {
						other_lis_view.x+= (pt.x-selected_lis_view.x);
						other_lis_view.y+= (pt.y-selected_lis_view.y);
						
						// only show them if we have not made the drag_DO visible (which happens
						// when we drag over the pack at bottom)
						other_lis_view.visible = !Cursor.instance.drag_DO.visible;
					}
				}
				selected_lis_view.x = pt.x;
				selected_lis_view.y = pt.y;
			}
		}
		
		private function onEnterFrameWhileDraggingButNotFocussed(ms_elapsed:int):void {
			maybeScrollVPByDragging();
		}
		
		private function maybeScrollVPByDragging():void {
			const inc:int = getIncrement();
			
			var new_x:int;
			var new_y:int;
			
			// if the mouse is dragging across the edges of the VP, scroll it
			if (
				!_stamping && 
				!(
					StageBeacon.mouseIsDown &&
					(
						(mouseDownOriginatedInViewport && selected_lis_view) ||
						(_dragging_furniture_from_bag || _dragging_from_pack || _dragging_from_loc)
					)
				)
			) {
				return;
			}
			
			if (!Cursor.instance.drag_DO) {
				/*CONFIG::debugging {
				Console.error('how can there not be a Cursor.instance.drag_DO?????');
				}*/
				return;
			}
			
			if (!StageBeacon.flash_has_focus) return;
			
			var can_trigger_scroll:Boolean;
			var over_vp_at_all:Boolean = gameRenderer.hitTestObject(Cursor.instance.drag_DO);
			
			// pan the world
			new_x = model.layoutModel.loc_cur_x;
			new_y = model.layoutModel.loc_cur_y;
			
			if (StageBeacon.stage_mouse_pt.y < lm.header_h+lm.loc_vp_h || over_vp_at_all) { // only if the cursor is not down there under the viewport
				if (StageBeacon.stage_mouse_pt.x >= (lm.gutter_w + lm.loc_vp_w)) {
					// pan right
					new_x += inc;
					can_trigger_scroll = true;
				} else if (StageBeacon.stage_mouse_pt.x < lm.gutter_w) {
					// pan left
					new_x -= inc;
					can_trigger_scroll = true;
				}
			}
			
			// allow diagonal movement by separating the IF blocks
			if (StageBeacon.stage_mouse_pt.y < lm.header_h) {
				// pan up
				new_y -= inc;
				can_trigger_scroll = true;
			} else if (StageBeacon.stage_mouse_pt.y >= (lm.header_h + lm.loc_vp_h)) {
				if (over_vp_at_all) {
					// pan down only if there is a little of the dragged thing over the viewport, so you can drag down to furn bag and not have it scrolling the vp!
					new_y += inc;
					can_trigger_scroll = true;
				}
			}
			
			if (can_trigger_scroll) {
				// wait until mouse has triggered scrolling 500ms before scrolling
				if (getTimer()-last_time_over_vp > 500) {
					// pan the renderer
					sm.camera_control_pt.x = new_x;
					sm.camera_control_pt.y = new_y;
					CameraMan.instance.resetCameraCenterAverages();
					gameRenderer.moveTo(new_x, new_y);
				}
			} else {
				last_time_over_vp = getTimer();
			}
		}
		
		private function maybeScrollVPByKeys():void {
			if (!has_focus) return;
			if (StageBeacon.mouseIsDown) return;
			if (sm.focus_is_in_input) return;
			const inc:int = 3*getIncrement();
			
			if (kb.pressed(Keyboard.RIGHT) || kb.pressed(Keyboard.D)) {
				sm.camera_control_pt.x+= inc;
			} else if (kb.pressed(Keyboard.LEFT) || kb.pressed(Keyboard.A)) {
				sm.camera_control_pt.x-= inc;
			}
			
			if (kb.pressed(Keyboard.DOWN) || kb.pressed(Keyboard.S)) {
				sm.camera_control_pt.y+= inc;
			} else if (kb.pressed(Keyboard.UP) || kb.pressed(Keyboard.W)) {
				sm.camera_control_pt.y-= inc;
			}
			
			CameraMan.instance.boundCameraCameraControlPt();
		}
		
		/** Pans the viewport using a 2D mousewheel */
		private function onMouseWheel(e:CartesianMouseEvent):void {
			if (!gameRenderer.contains(e.target as DisplayObject)) {
				// however bug [2060]: you may be trying to draw geometry over
				// a location with no gradient, so detect that before giving up
				if ((e.target != TSFrontController.instance.getMainView()) || !gameRenderer.hitTestPoint(e.stageX, e.stageY)) {
					return;
				}
			}
			
			// Webkit may give you TWO non-zero values as it allows simultaneous scrolling
			const new_x:int = model.layoutModel.loc_cur_x-int(e.xDelta*10);
			const new_y:int = model.layoutModel.loc_cur_y-int(e.yDelta*10);
			sm.camera_control_pt.x = new_x;
			sm.camera_control_pt.y = new_y;
			CameraMan.instance.resetCameraCenterAverages();
			gameRenderer.moveTo(new_x, new_y);
		}

		private function setLISview(likely_lis_view:LocationItemstackView=null):Boolean {
			mouseDownOriginatedInViewport = true;
			
			if (likely_lis_view) {
				reusableLIVV.length = 0; // just to be safe
				reusableLIVV[0] = likely_lis_view;
				likely_lis_view = gameRenderer.getMostLikelyItemstackFromList(reusableLIVV, StageBeacon.last_mouse_down_pt);
			} else {
				likely_lis_view = gameRenderer.getMostLikelyItemstackUnderCursor();
			}
			
			if (!likely_lis_view) return false;
			
			updateSelectedLISView(likely_lis_view);
			
			return true;
		}
		
		private function updateSelectedLISView(lisView:LocationItemstackView):void {
			selected_lis_view = lisView;
			selected_lis_view.disableGSMoveUpdates();
			
			selected_lis_view.bringToFront();
			if (selected_lis_view.item.is_furniture) {
				setFurnitureZeds();
			}			
		}
		
		private function onMouseDown(e:MouseEvent):void {
			// only allow clicking on the renderer, skip dialogs above it
			if (!gameRenderer.contains(e.target as DisplayObject)) {
				if ((e.target != TSFrontController.instance.getMainView()) || !gameRenderer.hitTestPoint(e.stageX, e.stageY)) {
					mouseDownOriginatedInViewport = false;
					return;
				}
			}
			
			// the priority was added in http://svn.tinyspeck.com/wsvn/main?op=revision&rev=83716
			StageBeacon.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 1);
			
			if (setLISview()) {
				measuring_mouse_move = true;
				// onMouseMove will now chekc how far the mouse has moved, and when it has moved enough, will 
				// call startWithItemFromLocation to start actually dragging the thing
			}
		}
		
		private function onMouseMove(e:MouseEvent):void {
			if (measuring_mouse_move) {
				var distance:Number = Math.abs(Point.distance(StageBeacon.last_mouse_down_pt, StageBeacon.stage_mouse_pt));
				if (distance >= StateModel.DRAG_DIST_REQUIRED) {
					measuring_mouse_move = false;
					startWithItemFromLocation(selected_lis_view.tsid);
				}
				return;
			}
			
			// this is to detect when we are dragging from the inventory
			if (sm.focused_component is Cursor) {
				return;
			}
			
			// this is to detect when we are dragging from location
			if (Cursor.instance.drag_DO) {
				return;
			}
			
			// if we're hovering over the map or other UI,
			// remove existing highlights and don't highlight anything new
			if (!gameRenderer.contains(e.target as DisplayObject)) {
				if (highlighted_lis_view && (highlighted_lis_view != selected_lis_view)) {
					highlighted_lis_view.unglow();
					highlighted_lis_view = null;
					gameRenderer.buttonMode = false;
					gameRenderer.useHandCursor = false;
				}
				return;
			}
			
			// find the object that you are most likely selecting
			const lis_view_to_highlight:LocationItemstackView = gameRenderer.getMostLikelyItemstackUnderCursor();
			
			updateHighlightedLISView(lis_view_to_highlight);
		}
		
		private function updateHighlightedLISView(lis_view_to_highlight:LocationItemstackView):void {
			// if the new highlight is already highlighted, we're done
			if (lis_view_to_highlight == highlighted_lis_view) return;
			
			// if there is a new highlight and it's our selection, we're done
			if (lis_view_to_highlight && (lis_view_to_highlight == selected_lis_view)) return;
			
			// at this point we can be sure that there is a new highlight
			// and it is not over the existing highlight or selection
			if (highlighted_lis_view && (highlighted_lis_view != selected_lis_view)) {
				highlighted_lis_view.unglow();
				highlighted_lis_view = null;
			}
			
			// draw the new highlight
			highlighted_lis_view = lis_view_to_highlight;
			if (lis_view_to_highlight) {
				lis_view_to_highlight.glow();
				
				// make it apparent that you can click the itemstack
				gameRenderer.buttonMode = true;
				gameRenderer.useHandCursor = true;
			} else {
				gameRenderer.buttonMode = false;
				gameRenderer.useHandCursor = false;
			}
		}
		
		private function onMouseUp(e:MouseEvent):void {
			StageBeacon.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			if (measuring_mouse_move) {
				// if measuring_mouse_move==true, then we did not move 5 pixels since mouse down,
				// so treat this like a click and open the menu if we can 
				if (selected_lis_view) {
					TSFrontController.instance.startInteractionWith(selected_lis_view, true);
				}
				deselect();
			} else {
				// we were dragging, so do the stuff after a drag
				endWithItemFromLocation();
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// SELECTION /////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		private function deselect():void {
			if (selected_lis_view) {
				selected_lis_view.enableGSMoveUpdates();
				selected_lis_view.unglow();
				selected_lis_view = null;
				
				if (other_dragged_lis_viewsV && other_dragged_lis_viewsV.length) {
					for each (var other_lis_view:LocationItemstackView in other_dragged_lis_viewsV) {
						other_lis_view.enableGSMoveUpdates();
					}
				}
				
				if (Cursor.instance.drag_DO) {
					SpriteUtil.clean(Cursor.instance.drag_DO as Sprite, true);
				}
				Cursor.instance.hideTip();
				Cursor.instance.endDrag();
				
				dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE));
			}
			
			if (dragVO && dragVO.target) dragVO.target.unhighlightOnDragOut();
			
			if (highlighted_lis_view) {
				highlighted_lis_view.unglow();
				highlighted_lis_view = null;
				gameRenderer.buttonMode = false;
				gameRenderer.useHandCursor = false;
			}
			
			temp_lis_view = null;
			
			pack_stack_tsid = null;
			loc_stack_tsid = null;
			current_item_class = null;
			if (current_item) {
				delete pl_cache[current_item];
			}
			current_item = null;
			measuring_mouse_move = false;
			removeGhost();
			removeCPLSVs();
			
			if (_dragging_furniture_from_bag || _dragging_from_pack || _dragging_from_loc || _dragging_proxy_from_loc) {
				_dragging_furniture_from_bag = false;
				_dragging_from_pack = false;
				_dragging_from_loc = false;
				_dragging_proxy_from_loc = false;
				StageBeacon.enter_frame_sig.remove(onEnterFrameWhileDraggingButNotFocussed);
			}
			
			if (_stamping) {
				stopStamping();
			}
		}
		
		/** Returns the increment/decrement for rotation and positioning */
		private function getIncrement():int {
			var xcrement:int = LocoDecoConstants.DEFAULT_INCREMENT;
			if (kb.pressed(Keyboard.SHIFT)) {
				xcrement = LocoDecoConstants.SHIFT_INCREMENT;
			} else if (kb.pressed(Keyboard.Z)) {
				xcrement = 1;
			}
			return xcrement;
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// FOCUS /////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
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
			if (!(sm.about_to_be_focused_component is Cursor)) {
				stopListeningForControlEvts();
			}
		}
		
		public function registerSelfAsFocusableComponent():void {
			sm.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			sm.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			has_focus = true;
			
			sm.camera_control_pt.x = lm.loc_cur_x;
			sm.camera_control_pt.y = lm.loc_cur_y;
			CameraMan.instance.setCameraCenterLimits(false, 0);
			CameraMan.instance.boundCameraCameraControlPt();
			
			startListeningForControlEvts();
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// ILocItemstackAddDelConsumer ///////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function onLocItemstackAdds(tsids:Array):void {
			if (!sm.can_decorate) return;
			setFurnitureZedsIfThereIsFurn(tsids);
		}
		
		public function onLocItemstackDels(tsids:Array):void {
			// if our current selection was deleted
			if (selected_lis_view && (tsids.indexOf(selected_lis_view.tsid) != -1)) {
				deselect();
			}
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// ILocItemstackUpdateConsumer ///////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function onLocItemstackUpdates(tsids:Array):void {
			if (!sm.can_decorate) return;
			setFurnitureZedsIfThereIsFurn(tsids);
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
			TSFrontController.instance.stopDecoratorMode();
		}
		
		public function moveMoveEnded():void {
			// any home location
			if (wm.location.is_home) {
				// your interiror
				if (sm.can_decorate) {
					HouseExpandDialog.instance.prime();
					getWallChoices();
					getCeilingChoices();
					getFloorChoices();
					
					if (!model.flashVarModel.no_deco_disclaimer) {
						// we can uncomment out this bit if we want to make users see it only once
						if (!sm.seen_deco_disclaimer_dialog_this_session/* && !LocalStorage.instance.getUserData('seen_deco_test_discalimer')*/) {
							DecoratorDisclaimerDialog.instance.start();
						}
					}
					
				}
			}
		}
	}
}
