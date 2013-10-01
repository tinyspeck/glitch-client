package com.tinyspeck.engine.view.renderer
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Box;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.location.Target;
	import com.tinyspeck.engine.data.location.Wall;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.physics.data.PhysicsQuery;
	import com.tinyspeck.engine.port.StoreEmbed;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.geo.BoxView;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.LadderView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.geo.TargetView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	CONFIG::god { import com.tinyspeck.engine.view.geo.PlatformLineView; }
	CONFIG::god { import com.tinyspeck.engine.view.geo.WallView; }
	CONFIG::locodeco { import locodeco.LocoDecoGlobals; }

	CONFIG const notgod:Boolean = !(CONFIG::god);
	
	/** 
	 * Manages ordering of DisplayObjects based on their types.  
	 * The type of display object is determined by the corrsponding 
	 * add<Type>() function that is called.
	 */
	public class MiddleGroundRenderer extends LayerRenderer {
		// Shapes representing end indices
		private const CHASSIS:Shape = new Shape();
		private const GEO:Shape = new Shape();
		private const UNDERLAY_ABOVE_DECOS:Shape = new Shape();
		private const WALL_FURN:Shape = new Shape();
		private const RUG_FURN:Shape = new Shape();
		private const BOOKSHELF_FURN:Shape = new Shape();
		private const CHAIR_FURN:Shape = new Shape();
		private const BG_ITEM:Shape = new Shape();
		private const NRM_ITEM:Shape = new Shape();
		private const FG_ITEM:Shape = new Shape();
		private const OTHER_AV:Shape = new Shape();
		private const OV_BELOW_YOUR_PLAYER:Shape = new Shape();
		private const YOUR_AVATAR:Shape = new Shape();
		private const FOREMOST_ITEMS:Shape = new Shape();
		private const FG_FURN:Shape = new Shape();
		
		private const glowingRenderers:Dictionary = new Dictionary();
		private var _pc:PC;
		private var _avatarView:AvatarView;
		private var worldModel:WorldModel;
		
		private const hiddenNonItemStacks:Vector.<DisplayObject> = new Vector.<DisplayObject>();
		
		/**
		 * These are [Model -> Renderer] mappings
		 * NOTE: These are all WEAK and do not need to be cleaned out.
		 * */
		/** Note: does not contain itemstacks in containers */			
		private const ladderToRenderer:Dictionary         = new Dictionary(true);
		private const doorToRenderer:Dictionary           = new Dictionary(true);
		private const signPostToRenderer:Dictionary       = new Dictionary(true);
		private const pcToRenderer:Dictionary             = new Dictionary(true);
		private const itemstackTSIDToRenderer:Dictionary  = new Dictionary(false);
		
		//These 3 are now only used for removal again. For that, Disposable Sprite had the functionality. Should be ported to that.
		private const _ladder_spV:Vector.<LadderView>            = new Vector.<LadderView>();
		private const _signpost_spV:Vector.<SignpostView>       = new Vector.<SignpostView>();
		private const _door_spV:Vector.<DoorView>                = new Vector.<DoorView>();
		private const _pc_viewV:Vector.<PCView>                 = new Vector.<PCView>();
		private const _lis_viewV:Vector.<LocationItemstackView> = new Vector.<LocationItemstackView>();
		CONFIG::god private const box_spV:Vector.<BoxView>       = new Vector.<BoxView>();
		CONFIG::god private const target_spV:Vector.<TargetView> = new Vector.<TargetView>();
		CONFIG::god private const _platformline_spV:Vector.<PlatformLineView> = new Vector.<PlatformLineView>();
		CONFIG::god private const _wall_spV:Vector.<WallView>                 = new Vector.<WallView>();
		
		CONFIG::god private var _wallModelDirty:Boolean;
		CONFIG::god private var _platformLineModelDirty:Boolean;
		private var _doorModelDirty:Boolean;
		CONFIG::locodeco private var _boxModelDirty:Boolean;
		CONFIG::locodeco private var _ladderModelDirty:Boolean;
		CONFIG::locodeco private var _targetModelDirty:Boolean;
		CONFIG::locodeco private var _signpostModelDirty:Boolean;
		
		public function MiddleGroundRenderer(layerData:Layer, useLargeBitmap:Boolean) {
			super(layerData, useLargeBitmap);
			worldModel = TSModelLocator.instance.worldModel;
		}
		
		override protected function setupEndShapes():void {
			super.setupEndShapes();
			
			addChild(CHASSIS);
			CHASSIS.visible = false;
			CHASSIS.name = 'CHASSIS';
			
			addChild(GEO);
			GEO.visible = false;
			GEO.name = 'GEO';
			
			addChild(UNDERLAY_ABOVE_DECOS);
			UNDERLAY_ABOVE_DECOS.visible = false;
			UNDERLAY_ABOVE_DECOS.name = 'UNDERLAY_ABOVE_DECOS';
			
			addChild(WALL_FURN);
			WALL_FURN.visible = false;
			WALL_FURN.name = 'WALL_FURN';
			
			addChild(RUG_FURN);
			RUG_FURN.visible = false;
			RUG_FURN.name = 'RUG_FURN';
			
			addChild(BOOKSHELF_FURN);
			BOOKSHELF_FURN.visible = false;
			BOOKSHELF_FURN.name = 'BOOKSHELF_FURN';
			
			addChild(CHAIR_FURN);
			CHAIR_FURN.visible = false;
			CHAIR_FURN.name = 'CHAIR_FURN';
			
			addChild(BG_ITEM);
			BG_ITEM.visible = false;
			BG_ITEM.name = 'BG_ITEM';
			
			addChild(NRM_ITEM);
			NRM_ITEM.visible = false;
			NRM_ITEM.name = 'NRM_ITEM';
			
			addChild(FG_ITEM);
			FG_ITEM.visible = false;
			FG_ITEM.name = 'FG_ITEM';
			
			addChild(OTHER_AV);
			OTHER_AV.visible = false;
			OTHER_AV.name = 'OTHER_AV';
			
			addChild(OV_BELOW_YOUR_PLAYER);
			OV_BELOW_YOUR_PLAYER.visible = false;
			OV_BELOW_YOUR_PLAYER.name = 'OV_BELOW_YOUR_PLAYER';
			
			addChild(YOUR_AVATAR);
			YOUR_AVATAR.visible = false;
			YOUR_AVATAR.name = 'YOUR_AVATAR';
			
			addChild(FOREMOST_ITEMS);
			FOREMOST_ITEMS.visible = false;
			FOREMOST_ITEMS.name = 'FOREMOST_ITEMS';
			
			addChild(FG_FURN);
			FG_FURN.visible = false;
			FG_FURN.name = 'FG_FURN';
		}
		
		/** This function only clears LargeBitmap decos */
		override protected function createLargeBitmap():void {
			CONFIG::god {
				if (!model.stateModel.render_mode.usesBitmaps) throw new Error();
			}
			
			var lbIndex:int = 0;
			if (_largeBitmap) {
				lbIndex = getChildIndex(_largeBitmap);
				removeChildAt(lbIndex);
				_largeBitmap.dispose();
				_largeBitmap = null;
			}
			
			// MG needs an offset since top left isn't (0,0)
			_largeBitmap = new LargeBitmap(layerData.w, layerData.h,
				model.stateModel.render_mode.bitmapSegmentDimension,
				model.worldModel.location.l, model.worldModel.location.t);
			
			// decos don't be needin' mousin'
			_largeBitmap.mouseEnabled = false;
			_largeBitmap.mouseChildren = false;
			
			addChildAt(_largeBitmap, lbIndex);
		}
		
		CONFIG::locodeco public function getDecoRenderer(deco:Deco):DecoRenderer {
			return decoToRenderer[deco] as DecoRenderer;
		}
		
		public function addGeo(geo:DisplayObject):void {
			addUnder(geo, GEO);
		}
		
		public function placeOverlayAboveDecos(DO:DisplayObject):void {
			addUnder(DO as DisplayObject, UNDERLAY_ABOVE_DECOS);
		}
		
		/** Embeded stores will be removed.  For now add it at the BG_ITEM index */
		public function addStoreEmbed(storeEmbed:StoreEmbed):void {
			addUnder(storeEmbed, BG_ITEM);
		}
		
		public function addWallFurnitureItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), WALL_FURN);
		}
		
		public function addChassisItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), CHASSIS);
		}
		
		public function addRugFurnitureItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), RUG_FURN);
		}
		
		public function addBookshelfFurnitureItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), BOOKSHELF_FURN);
		}
		
		public function addChairFurnitureItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), CHAIR_FURN);
		}
		
		public function addForegroundFurnitureItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), FG_FURN);
		}
		
		public function addBackgroundItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), BG_ITEM);
		}
		
		public function addNormalItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), NRM_ITEM);
		}
		
		public function addForegroundItem(iiv:LocationItemstackView):void {
			addUnder(LocationItemstackView(iiv), FG_ITEM);
		}
		
		public function placeOverlayBelowAnItemstack(overlay:DisplayObject, itemstack_tsid:String):void {
			var lis_view:LocationItemstackView = getLocationItemStackView(itemstack_tsid);
			if (lis_view) {
				addUnder(overlay as DisplayObject, LocationItemstackView(lis_view));
			} else {
				placeOverlayBelowYourPlayer(overlay);
			}
		}
		
		public function placeOverlayAboveAnItemstack(overlay:DisplayObject, itemstack_tsid:String):void {
			var lis_view:LocationItemstackView = getLocationItemStackView(itemstack_tsid);
			if (lis_view) {
				addAbove(overlay as DisplayObject, LocationItemstackView(lis_view));
			} else {
				placeOverlayBelowYourPlayer(overlay);
			}
		}
		
		public function placeOverlayBelowOtherAvatar(overlay:DisplayObject, pcView:PCView):void {
			if (pcView.parent == this) {
				addUnder(overlay, pcView);
			}
		}
		
		public function addOtherAvatar(pc:PC):void {
			var pcView:PCView = createPcView(pc) as PCView;
			addUnder(pcView, OTHER_AV);
		}
		
		public function removeOtherAvatar(pc:PC):void {
			destroyPCView(pc);
		}
		
		public function getOtherAvatar(pc:PC):PCView {
			return pcToRenderer[pc] as PCView;
		}
		
		public function placeOverlayBelowYourPlayer(overlayBelSerg:DisplayObject):void {
			addUnder(overlayBelSerg, OV_BELOW_YOUR_PLAYER);
		}
		
		public function addYourAvatar(yourAvatar:AvatarView):void {
			addUnder(DisplayObject(yourAvatar), YOUR_AVATAR);
		}
		
		public function addForemostGroundItem(fmgItem:LocationItemstackView):void {
			addUnder(LocationItemstackView(fmgItem), FOREMOST_ITEMS);
		}
		
		public function addItemJustAboveOtherItem(lis:LocationItemstackView, other_lis:LocationItemstackView):void {
			addAbove(LocationItemstackView(lis), LocationItemstackView(other_lis));
		}
		
		public function placeOverlay(overlay:DisplayObject):void {
			addChild(overlay as DisplayObject);
		}
		
		public function addLadderView(ladderView:LadderView, ladder:Ladder):void {
			addGeo(ladderView as LadderView);
			_ladder_spV.push(ladderView);
			ladderToRenderer[ladder] = ladderView;
		}
		
		public function addDoorView(doorView:DoorView, door:Door):void {
			addGeo(doorView as DisplayObject);
			_door_spV.push(doorView);
			doorToRenderer[door] = doorView;
		}
		
		public function addSignPostView(signpostView:SignpostView, signpost:SignPost):void {
			addGeo(SignpostView(signpostView));
			
			_signpost_spV.push(signpostView);
			signPostToRenderer[signpost] = signpostView;
		}
		
		CONFIG::god public function addWallView(wallView:WallView):void {
			_wall_spV.push(wallView);
			addGeo(wallView);
		}
		
		CONFIG::god public function addPlatformLineView(platformLineView:PlatformLineView):void {
			_platformline_spV.push(platformLineView);
			var pl:PlatformLine = model.worldModel.location.mg.getPlatformLineById(platformLineView.tsid);
			if (pl && pl.source) {
				addUnder(platformLineView, OV_BELOW_YOUR_PLAYER);
			} else {
				addGeo(platformLineView);
			}
		}
		
		public function getLocationItemStackView(tsid:String):LocationItemstackView {
			return itemstackTSIDToRenderer[tsid] as LocationItemstackView;
		}
		
		CONFIG::god public function addBoxView(boxView:BoxView):void {
			box_spV.push(boxView);
			addGeo(boxView);
		}
		
		CONFIG::god public function addTargetView(targetView:TargetView):void {
			target_spV.push(targetView);
			addGeo(targetView);
		}
				
		/** Show platform lines/walls/ladders */
		CONFIG::god public function showPlatformLinesEtc():void {
			model.stateModel.hide_platforms = false;
			for each (var plv:PlatformLineView in _platformline_spV) plv.visible = true;
			for each (var wv:WallView in _wall_spV) wv.visible = true;
			for each (var lv:LadderView in _ladder_spV) lv.syncRendererWithModel();
		}
		
		/** Show platform lines/walls/ladders without forcing them to stay on */
		CONFIG::god public function showPlatformLinesEtcTemporarily():void {
			//model.stateModel.hide_platforms = false;
			for each (var plv:PlatformLineView in _platformline_spV) plv.visible = true;
			for each (var wv:WallView in _wall_spV) wv.visible = true;
			for each (var lv:LadderView in _ladder_spV) lv.syncRendererWithModel();
		}
		
		/** Show platform lines/walls/ladders if they should be shown */
		CONFIG::god public function maybeShowPlatformLinesEtc():void {
			CONFIG::locodeco {
				if(model.stateModel.editing) {
					if (LocoDecoGlobals.instance.overlayPlatforms) {
						// the overlay shouldn't 'permanently' turn on geo
						// it's just temporal while LD is visible
						showPlatformLinesEtcTemporarily();
					}
					return;
				}
			}
			
			if (!model.stateModel.hide_platforms) showPlatformLinesEtc();
		}
		
		/** Call this instead of hidePlatformLinesEtc() if you want maybeShowPlatformLinesEtc() to restore them */
		CONFIG::god public function hidePlatformLinesEtcTemporarily():void {
			// LadderView expects model.stateModel.hide_platforms to be false or it won't hide it
			const oldHidePlatforms:Boolean = model.stateModel.hide_platforms;
			model.stateModel.hide_platforms = true;
			for each (var plv:PlatformLineView in _platformline_spV) plv.visible = false;
			for each (var wv:WallView in _wall_spV) wv.visible = false;
			for each (var lv:LadderView in _ladder_spV) lv.syncRendererWithModel();
			model.stateModel.hide_platforms = oldHidePlatforms;
		}
		
		/** Hide platform lines/walls/ladders */
		CONFIG::god public function hidePlatformLinesEtc():void {
			model.stateModel.hide_platforms = true;
			for each (var plv:PlatformLineView in _platformline_spV) plv.visible = false;
			for each (var wv:WallView in _wall_spV) wv.visible = false;
			for each (var lv:LadderView in _ladder_spV) lv.syncRendererWithModel();
		}
		
		CONFIG::god public function showBoxes():void {
			model.stateModel.hide_boxes = false;
			for each (var bv:BoxView in box_spV) bv.visible = true;
		}
		
		/** Show platform lines if they should be shown */
		CONFIG::god public function maybeShowBoxes():void {
			if(!model.stateModel.hide_boxes) showBoxes();
		}
		
		/** Call this instead of hideBoxes() if you want maybeShowBoxes() to restore them */
		CONFIG::god public function hideBoxesTemporarily():void {
			//model.stateModel.hide_boxes = true;
			for each (var bv:BoxView in box_spV) bv.visible = false;
		}
		
		CONFIG::god public function hideBoxes():void {
			model.stateModel.hide_boxes = true;
			for each (var bv:BoxView in box_spV) bv.visible = false;
		}
		
		CONFIG::god public function showTargets():void {
			model.stateModel.hide_targets = false;
			for each (var target:TargetView in target_spV) target.visible = true;
		}
		
		/** Show targets if they should be shown */
		CONFIG::god public function maybeShowTargets():void {
			if(!model.stateModel.hide_targets) showTargets();
		}
		
		/** Call this instead of hideTargets() if you want maybeShowTargets() to restore them */
		CONFIG::god public function hideTargetsTemporarily():void {
			//model.stateModel.hide_targets = true;
			for each (var target:TargetView in target_spV) target.visible = false;
		}
		
		CONFIG::god public function hideTargets():void {
			model.stateModel.hide_targets = true;
			for each (var target:TargetView in target_spV) target.visible = false;
		}
		
		public function showPCs():void {
			model.stateModel.hide_pcs = false;
			TSFrontController.instance.changeAvatarVisibility();
			toggleVisibility(_pc_viewV);
		}
		
		/** Show PCs if they should be shown */
		public function maybeShowPCs():void {
			// this is the whole point of this function:
			if (model.stateModel.hide_pcs) return;
			
			if (CONFIG::locodeco) {
				; // satisfy compiler
				CONFIG::locodeco {
					if (model.stateModel.editing && LocoDecoGlobals.instance.overlayPCs) {
						showPCs();
					}
				}
			} else {
				showPCs();
			}
		}
		
		/** Call this instead of hidePCs() if you want maybeShowPCs() to restore them */
		public function hidePCsTemporarily():void {
			// the point of this function is that we do not do this:
			//model.stateModel.hide_pcs = true;
			// which means that we can call maybeShowPCs() after calling this
			// and the pcs will be shown (useful when you only want to hidePCs during a function,
			// like when taking a loc snapshot)
			
			TSFrontController.instance.changeAvatarVisibility();
			toggleVisibility(_pc_viewV);
		}
		
		public function rescalePCs():void {
			for each (var thing:Object in _pc_viewV) PCView(thing).rescale();
		}
		
		public function hidePCs():void {
			model.stateModel.hide_pcs = true;
			TSFrontController.instance.changeAvatarVisibility();
			toggleVisibility(_pc_viewV);
		}
		
		CONFIG::god public function showCTBoxes():void {
			model.stateModel.hide_CTBoxes = false;
			for each (var lis_view:LocationItemstackView in _lis_viewV) lis_view.showCTBox();
		}
		
		/** Show CTBoxes if they should be shown */
		CONFIG::god public function maybeShowCTBoxes():void {
			if(model.stateModel.hide_CTBoxes) {
				hideCTBoxes();
			} else {
				showCTBoxes();
			}
		}
		
		/** Call this instead of hideCTBoxes() if you want maybeShowCTBoxes() to restore them */
		CONFIG::god public function hideCTBoxesTemporarily():void {
			//model.stateModel.hide_CTBoxes = true;
			for each (var lis_view:LocationItemstackView in _lis_viewV) lis_view.hideCTBox();
		}
		
		/** Call this instead of hideCTBoxes() if you want maybeShowCTBoxes() to restore them */
		CONFIG::god public function showCTBoxesTemporarily():void {
			//model.stateModel.hide_CTBoxes = false;
			for each (var lis_view:LocationItemstackView in _lis_viewV) lis_view.showCTBox();
		}
		
		CONFIG::god public function hideCTBoxes():void {
			model.stateModel.hide_CTBoxes = true;
			for each (var lis_view:LocationItemstackView in _lis_viewV) lis_view.hideCTBox();
		}
		
		public function showItemstacks():void {
			model.stateModel.hide_loc_itemstacks = false;
			toggleVisibility(_lis_viewV);
		}
		
		/** Show Itemstacks if they should be shown */
		public function maybeShowItemstacks():void {
			if (CONFIG::locodeco) {
				; // satisfy compiler
				CONFIG::locodeco {
					if(!model.stateModel.hide_loc_itemstacks || model.stateModel.editing && LocoDecoGlobals.instance.overlayItemstacks) {
						showItemstacks();
					}
				}
			} else {
				showItemstacks();
			}
		}
		
		/** Call this instead of hideItemstacks() if you want hideItemstacks() to restore them */
		public function hideItemstacksTemporarily():void {
			//model.stateModel.hide_loc_itemstacks = true;
			toggleVisibility(_lis_viewV);
		}
		
		public function hideItemstacks():void {
			model.stateModel.hide_loc_itemstacks = true;
			toggleVisibility(_lis_viewV);
		}
		
		/** Hide all children beyond GEO index that are not itemstacks */
		public function hideVisibleNonItemstacks():void {
			const etcIndex:uint =  getChildIndex(GEO)+ 1;
			var displayObject:DisplayObject;
			for (var i:uint = etcIndex; i < numChildren; i++) {
				displayObject = getChildAt(i);
				if (displayObject.visible && !(displayObject is LocationItemstackView)) {
					hiddenNonItemStacks.push(displayObject);
					displayObject.visible = false;
				}						
			}			
		}
		
		/** Show all previously visibel non-itemstacks that were hidden via call to hideVisibleNonitemstacks */
		public function showVisibleNonItemStacks():void {
			var numElements:uint = hiddenNonItemStacks.length;
			for (var i:uint = 0; i < numElements; i++) {
				hiddenNonItemStacks.pop().visible = true;
			}
		}
		
		public function toggleVisibility(list:Object):void {
			for each (var thing:Object in list) thing.showHide();
		}
		
		public function updateGeos():void {
			if (_doorModelDirty) {
				updateDoorsForMG();
			}
			
			CONFIG::god {
				CONFIG::locodeco {
					if (_targetModelDirty) {
						updateTargetsForMG();
					}
					if (_signpostModelDirty) {
						updateSignpostsForMG();
					}
					if (_boxModelDirty) {
						updateBoxesForMG();
					}
					if (_ladderModelDirty) {
						updateLaddersForMG();
					}
				}
				if (_platformLineModelDirty) {
					updatePlatformLinesForMG();
				}
				if (_wallModelDirty) {
					updateWallsForMG();
				}
			}
		}
		
		CONFIG::god private function updatePlatformLinesForMG():void {
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			
			// remove and store existing renderers in a tsid -> renderer map
			var map:Object = {};
			var platlineRenderer:PlatformLineView;
			while (_platformline_spV.length) {
				platlineRenderer = _platformline_spV.pop();
				map[platlineRenderer.name] = platlineRenderer;
				// clean up existing references
				removeChild(platlineRenderer);
			}
			
			// remove unused renderers
			// re-add renderers that are still in use and new ones
			var platline:PlatformLine;
			const platlines:Vector.<PlatformLine> = mg.platform_lines;
			const dl:int = platlines.length;
			for(var i:int=0; i<dl; i++) {
				platline = platlines[int(i)];
				platlineRenderer = map[platline.tsid];
				
				// create new renderers if needed
				if (!platlineRenderer) {
					platlineRenderer = new PlatformLineView(platline);
					// this visible logic differs from createPlatformLinesForMG
					// because the other will get called when LD is not yet loaded
					// so should only be based on draw_plats; new plats will only
					// be created dynamically when LD is loaded and they are visible
					//platlineRenderer.visible = true;
					
					platlineRenderer.visible = !model.stateModel.hide_platforms || CONFIG::locodeco;
				}
				
				// put it back
				_platformline_spV.push(platlineRenderer);
				addGeo(platlineRenderer);
			}
			_platformLineModelDirty = false;
		}
		
		CONFIG::god private function updateWallsForMG(disableHighlighting:Boolean = false):void {
			const loc_tsid:String = model.worldModel.location.tsid;
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			
			// remove and store existing renderers in a tsid -> renderer map
			var map:Object = {};
			var wallRenderer:WallView;
			while (_wall_spV.length) {
				wallRenderer = _wall_spV.pop();
				map[wallRenderer.name] = wallRenderer;
				// clean up existing references
				removeChild(wallRenderer);
			}
			
			// remove unused renderers
			// re-add renderers that are still in use and new ones
			var wall:Wall;
			const walls:Vector.<Wall> = mg.walls;
			const dl:int = walls.length;
			for(var i:int=0; i<dl; i++) {
				wall = walls[int(i)];
				wallRenderer = map[wall.tsid];
				
				// create new renderers if needed
				if (!wallRenderer) {
					wallRenderer = new WallView(wall, loc_tsid);
					LocationCommands.applyFiltersToView(mg, wallRenderer, disableHighlighting);
					// this visible logic differs from createWallsForMG
					// because the other will get called when LD is not yet loaded
					// so should only be based on draw_plats; new walls will only
					// be created dynamically when LD is loaded and they are visible
					//wallRenderer.visible = true;
				}
				
				// put it back
				_wall_spV.push(wallRenderer);
				addGeo(wallRenderer);
			}
			
			_wallModelDirty = false;
		}
		
		CONFIG::locodeco private function updateBoxesForMG():void {
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			
			// remove and store existing renderers in a tsid -> renderer map
			var map:Object = {};
			var boxRenderer:BoxView;
			while (box_spV.length) {
				boxRenderer = box_spV.pop();
				map[boxRenderer.name] = boxRenderer;
				// clean up existing references
				removeChild(boxRenderer);
			}
			
			// remove unused renderers
			// re-add renderers that are still in use and new ones
			var box:Box;
			const boxes:Vector.<Box> = mg.boxes;
			const dl:int = boxes.length;
			for(var i:int=0; i<dl; i++) {
				box = boxes[int(i)];
				boxRenderer = map[box.tsid];
				
				// create new renderers if needed
				if (!boxRenderer) {
					boxRenderer = new BoxView(box);
					// this visible logic differs from createBoxesForMG
					// because the other will get called when LD is not yet loaded
					// so should only be based on draw_boxes; new boxes will only
					// be created dynamically when LD is loaded and they are visible
					//boxRenderer.visible = true;
				}
				
				// put it back
				box_spV.push(boxRenderer);
				addGeo(boxRenderer);
			}
			
			_boxModelDirty = false;
		}
		
		CONFIG::locodeco private function updateLaddersForMG(disableHighlighting:Boolean = false):void {
			const loc_tsid:String = model.worldModel.location.tsid;
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			
			// remove and store existing renderers in a tsid -> renderer map
			var map:Object = {};
			var ladderRenderer:LadderView;
			while (_ladder_spV.length) {
				ladderRenderer = _ladder_spV.pop();
				map[ladderRenderer.name] = ladderRenderer;
				// clean up existing references
				removeChild(ladderRenderer);
				delete ladderToRenderer[ladderRenderer];
			}
			
			// remove unused renderers
			// re-add renderers that are still in use and new ones
			var ladder:Ladder;
			const ladders:Vector.<Ladder> = mg.ladders;
			const dl:int = ladders.length;
			for(var i:int=0; i<dl; i++) {
				ladder = ladders[int(i)];
				ladderRenderer = map[ladder.tsid];
				
				// create new renderers if needed
				if (!ladderRenderer) {
					ladderRenderer = new LadderView(ladder, loc_tsid);
					LocationCommands.applyFiltersToView(mg, ladderRenderer, disableHighlighting);
				}
				
				// put it back
				ladderToRenderer[ladder] = ladderRenderer;
				_ladder_spV.push(ladderRenderer);
				addGeo(ladderRenderer);
			}
			
			_ladderModelDirty = false;
		}
		
		CONFIG::locodeco private function updateTargetsForMG():void {
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			
			// remove and store existing renderers in a tsid -> renderer map
			var map:Object = {};
			var targetRenderer:TargetView;
			while (target_spV.length) {
				targetRenderer = target_spV.pop();
				map[targetRenderer.name] = targetRenderer;
				// clean up existing references
				removeChild(targetRenderer);
			}
			
			// remove unused renderers
			// re-add renderers that are still in use and new ones
			var target:Target;
			const targets:Vector.<Target> = mg.targets;
			const dl:int = targets.length;
			for(var i:int=0; i<dl; i++) {
				target = targets[int(i)];
				targetRenderer = map[target.tsid];
				
				// create new renderers if needed
				if (!targetRenderer) {
					targetRenderer = new TargetView(target);
					// this visible logic differs from createTargetsForMG
					// because the other will get called when LD is not yet loaded
					// so should only be based on draw_boxes; new boxes will only
					// be created dynamically when LD is loaded and they are visible
					//targetRenderer.visible = true;
				}
				
				// put it back
				addGeo(targetRenderer);
				target_spV.push(targetRenderer);
			}
			
			_targetModelDirty = false;
		}
		
		CONFIG::locodeco private function updateSignpostsForMG(disableHighlighting:Boolean = false):void {
			const loc_tsid:String = model.worldModel.location.tsid;
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			
			// remove and store existing renderers in a tsid -> renderer map
			var map:Object = {};
			var signpostRenderer:SignpostView;
			while (_signpost_spV.length) {
				signpostRenderer = _signpost_spV.pop();
				map[signpostRenderer.name] = signpostRenderer;
				// clean up existing references
				removeChild(signpostRenderer);
				delete signPostToRenderer[signpostRenderer];
			}
			
			// remove unused renderers
			// re-add renderers that are still in use and new ones
			var signpost:SignPost;
			const signposts:Vector.<SignPost> = mg.signposts;
			const dl:int = signposts.length;
			for(var i:int=0; i<dl; i++) {
				signpost = signposts[int(i)];
				signpostRenderer = map[signpost.tsid];
				
				// create new renderers if needed
				if (!signpostRenderer) {
					signpostRenderer = new SignpostView(signpost, loc_tsid);
					LocationCommands.applyFiltersToView(mg, signpostRenderer, disableHighlighting);
				}
				
				// put it back
				addGeo(signpostRenderer);
				_signpost_spV.push(signpostRenderer);
				signPostToRenderer[signpost] = signpostRenderer;
			}
			
			_signpostModelDirty = false;
		}
		
		private function updateDoorsForMG(disableHighlighting:Boolean = false):void {
			const loc_tsid:String = model.worldModel.location.tsid;
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			
			// remove and store existing renderers in a tsid -> renderer map
			var map:Object = {};
			var doorRenderer:DoorView;
			while (_door_spV.length) {
				doorRenderer = _door_spV.pop();
				map[doorRenderer.name] = doorRenderer;
				// clean up existing references
				removeChild(doorRenderer);
				delete doorToRenderer[doorRenderer];
			}
			
			// remove unused renderers
			// re-add renderers that are still in use and new ones
			var door:Door;
			const doors:Vector.<Door> = mg.doors;
			const dl:int = doors.length;
			for(var i:int=0; i<dl; i++) {
				door = doors[int(i)];
				doorRenderer = map[door.tsid];
				
				// create new renderers if needed
				if (!doorRenderer) {
					doorRenderer = new DoorView(door, loc_tsid);
					LocationCommands.applyFiltersToView(mg, doorRenderer, disableHighlighting);
				}
				
				// put it back
				addGeo(doorRenderer);
				_door_spV.push(doorRenderer);
				doorToRenderer[door] = doorRenderer;
			}
			
			_doorModelDirty = false;
		}
		
		/** Refreshes the filters on every object of every layer */
		CONFIG::locodeco public override function updateFilters(disableHighlighting:Boolean):void {
			if (!_filtersDirty) return;
			var renderer:Sprite;
			var layer:Layer;
			var alr:LayerRenderer;
			// re-apply filters over every visible object that we track
			const dictionaries:Array = [decoToRenderer, ladderToRenderer, doorToRenderer, 
				signPostToRenderer, _platformline_spV, target_spV, box_spV, _wall_spV];
			for each (var dict:Object in dictionaries) {
				for each (renderer in dict) {
					// sketchy!
					alr = (renderer.parent as LayerRenderer);
					// some renderers in the dictionaries may not be on the DisplayList anymore
					if (alr && alr.filtersDirty) {
						layer = alr.layerData;
						if ((renderer is PlatformLineView) || (renderer is TargetView) || (renderer is BoxView) || (renderer is WallView)) {
							// plats, walls, targets, and boxes should apply highlights
							// but none of the other layer filters
							renderer.filters = null;
							if (!disableHighlighting && (renderer is IAbstractDecoRenderer) && IAbstractDecoRenderer(renderer).highlight) {
								renderer.filters = StaticFilters.ldSelection_GlowA;
							}
						} else {
							LocationCommands.applyFiltersToView(layer, renderer, disableHighlighting);
						}
					}
				}
			}
			
			// these Arrays are renderers on the middleground
			layer = layerData;
			for each (var vector:Object in [_lis_viewV, _pc_viewV]) {
				for each (renderer in vector) {
					LocationCommands.applyFiltersToView(layer, renderer, disableHighlighting);
				}
			}
			
			// special case for the avatarView
			LocationCommands.applyFiltersToView(worldModel.location.mg, DisplayObject(_avatarView), disableHighlighting);
			
			_filtersDirty = false;
		}
		
		override public function dispose():void {
			const itemstacks:Dictionary = model.worldModel.itemstacks;
			const pcs:Dictionary = model.worldModel.pcs;
			
			var pc_view:PCView;
			while (_pc_viewV.length) {
				pc_view = _pc_viewV.pop();
				destroyPCView(pcs[pc_view.tsid] as PC);
			}
			
			var lis_view:LocationItemstackView;
			while (_lis_viewV.length) {
				lis_view = _lis_viewV.pop();
				destroyLocationItemstackView(itemstacks[lis_view.tsid] as Itemstack);
			}
			
			CONFIG::god {
				var platformline_view:PlatformLineView;
				while (_platformline_spV.length) {
					platformline_view = _platformline_spV.pop();
					super.removeChild(platformline_view);
					platformline_view.dispose();
				}
				
				var wall_view:WallView;
				while (_wall_spV.length) {
					wall_view = _wall_spV.pop();
					super.removeChild(wall_view);
					wall_view.dispose();
				}
				
				var box_view:BoxView;
				while (box_spV.length) {
					box_view = box_spV.pop();
					super.removeChild(box_view);
					box_view.dispose();
				}
				
				var target_view:TargetView;
				while (target_spV.length) {
					target_view = target_spV.pop();
					super.removeChild(target_view);
					target_view.dispose();
				}
			}
			
			var door_sp:DoorView;
			while (_door_spV.length) {
				door_sp = _door_spV.pop();
				super.removeChild(door_sp as DisplayObject);
				door_sp.dispose();
			}
			
			var signpost_sp:SignpostView;
			while (_signpost_spV.length) {
				signpost_sp = _signpost_spV.pop();
				//TipDisplayManager.instance.unRegisterTipTrigger(signpost_sp);
				super.removeChild(signpost_sp);
				signpost_sp.dispose();
			}
			
			var ladder_sp:LadderView;
			while (_ladder_spV.length) {
				ladder_sp = _ladder_spV.pop() as LadderView;
				super.removeChild(ladder_sp);
				ladder_sp.dispose();
			}
			
			if (_avatarView && _avatarView.parent){
				var avatarViewDO:DisplayObject = DisplayObject(_avatarView);
				avatarViewDO.parent.removeChild(avatarViewDO);
			}
			
			// do this AFTER above, since it will remove all children
			super.dispose();
		}
		
		private function createPcView(pc:PC):PCView {
			var renderer:PCView = new PCView(pc.tsid);
			renderer.x = pc.x;
			renderer.y = pc.y;
			
			_pc_viewV.push(renderer);
			pcToRenderer[pc] = renderer;
			
			if (model.stateModel.hide_pcs) renderer.visible = false;
			
			LocationCommands.applyFiltersToView(model.worldModel.location.mg, DisplayObject(renderer));
			return renderer;
		}
		
		private function destroyPCView(pc:PC):void {
			const pc_view:PCView = (pcToRenderer[pc] as PCView);
			
			if (pc.tsid == model.stateModel.camera_center_pc_tsid) {
				TSFrontController.instance.resetCameraCenter();
			}
			
			if (pc_view) {
				if(pc_view.parent) removeChild(pc_view);
				pc_view.dispose();
				
				// clear references
				const index:int = _pc_viewV.indexOf(pc_view);
				// we might have popped it before destroying
				if (index > -1) _pc_viewV.splice(index, 1);
				
				pcToRenderer[pc] = null;
				delete pcToRenderer[pc];
			}
		}

		public function createLocationItemstackView(itemstack:Itemstack):LocationItemstackView {
			var renderer:LocationItemstackView = new LocationItemstackView(itemstack.tsid);
			renderer.x = itemstack.x;
			renderer.y = itemstack.y;
			
			_lis_viewV.push(renderer);
			itemstackTSIDToRenderer[itemstack.tsid] = renderer;
			
			// I am removing this from here, because the LIVs handle this themselves
			//TipDisplayManager.instance.registerTipTrigger(LocationItemstackView(renderer));
			
			LocationCommands.applyFiltersToView(model.worldModel.location.mg, DisplayObject(renderer));
			return renderer;
		}		
		
		public function destroyLocationItemstackView(itemstack:Itemstack):void {
			if (itemstack.tsid == model.stateModel.camera_center_itemstack_tsid) {
				TSFrontController.instance.resetCameraCenter();
			}
			
			const lis_view:LocationItemstackView = (itemstackTSIDToRenderer[itemstack.tsid] as LocationItemstackView);
			if (lis_view) {
				TipDisplayManager.instance.unRegisterTipTrigger(lis_view);
				if(lis_view.parent) removeChild(lis_view);
				lis_view.dispose();
				
				// clear references
				const index:int = _lis_viewV.indexOf(lis_view);
				// we might have popped it before destroying
				if (index > -1) _lis_viewV.splice(index, 1);
				
				itemstackTSIDToRenderer[itemstack.tsid] = null;
				delete itemstackTSIDToRenderer[itemstack.tsid];
			}
		}
		
		//		 _       _                      _   _             
		//		(_)     | |                    | | (_)            
		//		 _ _ __ | |_ ___ _ __ __ _  ___| |_ _  ___  _ __  
		//		| | '_ \| __/ _ \ '__/ _` |/ __| __| |/ _ \| '_ \ 
		//		| | | | | ||  __/ | | (_| | (__| |_| | (_) | | | |
		//		|_|_| |_|\__\___|_|  \__,_|\___|\__|_|\___/|_| |_|
		
		public function _findInteractionSprites(apo:AvatarPhysicsObject):void {
			//apo._nav_interaction_spV.length = 0;
			apo._interaction_spV.length = 0;
			
			if (model.stateModel.location_interactions_disabled) return;
			if (apo.onLadder) return;
			
			// mark existing glowing renderers as unused
			// if they get glowed later, they'll be marked as used
			// then we'll sweep and unglow
			var object:Object;
			for (object in glowingRenderers) {
				glowingRenderers[object] = false;
			}
			
			const lq:PhysicsQuery = model.physicsModel.lastAvatarQuery;
			
			glowItemstacks(lq.resultItemstacks);
			
			// test here while _interaction_spV only has itemstacks in it
			if (apo._interaction_spV.length == 1) {
				TSFrontController.instance.setSingleInteractionSP(apo._interaction_spV[0]);
			} else {
				TSFrontController.instance.clearSingleInteractionSP();
			}
			
			// hit test against ladders, doors, and signposts
			glowSignPosts(lq.resultSignPosts);
			glowDoors(lq.resultDoors);
			glowLadders(lq.resultLadders);
			
			glowPCs(lq.resultPCs);
			
			// sweep: unglow unused renderers
			for (object in glowingRenderers) {
				if (glowingRenderers[object] == false) {
					(object as TSSprite).unglow();
					delete glowingRenderers[object];
				}
			}
		}
		
		public function unglowAllInteractionSprites():void {
			TSFrontController.instance.clearSingleInteractionSP();
			
			if (!_pc.apo) {
				CONFIG::debugging {
					Console.warn('no pc.apo')
				}
				return;
			} 
			if (!_pc.apo._interaction_spV) {
				CONFIG::debugging {
					Console.warn('no pc.apo._interaction_spV')
				}
				return;
			}
			
			const interaction_spV:Vector.<TSSprite> = _pc.apo._interaction_spV;
			for (var i:int=interaction_spV.length-1; i>=0; --i) {
				interaction_spV[int(i)].unglow(true);
				delete glowingRenderers[interaction_spV[int(i)]];
			}
		}		
		
		private function glowRenderer(renderer:TSSprite):void {
			if(renderer){
				CONFIG::notgod {
					if (!(renderer.visible && renderer.interaction_target.visible)) return;
				}
				if (_avatarView && _avatarView.hit_target.hitTestObject(renderer.hit_target)){
					renderer.glow();
					glowingRenderers[renderer] = true;
					_pc.apo._interaction_spV.push(renderer);
				}
			}
		}
		
		private function glowSignPosts(signPosts:Vector.<SignPost>):void {
			for(var i:int=signPosts.length-1; i>=0; --i){
				var signpost:SignPost = signPosts[int(i)];
				// don't glow it if it has no connects, unless it is in the pc's exteriror location
				if (!CONFIG::god && model.worldModel.location.tsid != model.worldModel.pc.home_info.exterior_tsid) {
					if (signpost.getVisibleConnects().length == 0) continue;
				}
				glowRenderer(signPostToRenderer[signpost]);
			}
		}
		
		private function glowDoors(doors:Vector.<Door>):void {
			for(var i:int=doors.length-1; i>=0; --i){
				glowRenderer(doorToRenderer[doors[int(i)]]);
			}
		}
		
		private function glowLadders(ladders:Vector.<Ladder>):void {
			for(var i:int=ladders.length-1; i>=0; --i){
				glowRenderer(ladderToRenderer[ladders[int(i)]]);
			}
		}
		
		private function glowItemstacks(itemstacks:Vector.<Itemstack>):void {
			for each (var itemstack:Itemstack in itemstacks) {
				// bail if it is an item that cannot be selected
				// (leave it selectable for DEV client, for edit props)
				if (!CONFIG::god) {
					if (!itemstack.is_selectable) continue;
				} else {
					; // satisfy compiler
					CONFIG::god {
						if (!model.flashVarModel.interact_with_all) {
							if (!itemstack.is_selectable) continue;
						}
					}
				}
				
				// if it is an itemstack waiting on a verb response,
				// unglow and keep it from the _interaction_spV
				if (itemstack.waiting_on_verb) {
					itemstackTSIDToRenderer[itemstack.tsid].unglow();
					delete glowingRenderers[itemstackTSIDToRenderer[itemstack.tsid]];
					continue;
				}
				
				glowRenderer(itemstackTSIDToRenderer[itemstack.tsid]);
			}
		}
		
		private function glowPCs(pcs:Vector.<PC>):void {
			const ghost:String = worldModel.pc.tsid;
			for each (var pc:PC in pcs) {
				// bail if it is your ghost
				if (pc.tsid != ghost && !pc.fake) {
					glowRenderer(pcToRenderer[pc]);
				}
			}
		}		
		
		public function get pc():PC { return _pc; }
		public function set pc(value:PC):void { _pc = value; }
		
		public function get avatarView():AvatarView { return _avatarView; }
		public function set avatarView(value:AvatarView):void { _avatarView = value; }
		
		public function get signpostViews():Vector.<SignpostView> { return _signpost_spV; }
		public function get doorViews():Vector.<DoorView> { return _door_spV; }
		public function get pcViews():Vector.<PCView> { return _pc_viewV; }
		public function get locationItemStackViews():Vector.<LocationItemstackView> { return _lis_viewV; }
		public function get ladderViews():Vector.<LadderView> { return _ladder_spV; }
		CONFIG::god public function get platformLineViews():Vector.<PlatformLineView> { return _platformline_spV; }
		CONFIG::god public function get wallViews():Vector.<WallView> { return _wall_spV; }

		CONFIG::locodeco public function get boxModelDirty():Boolean { return _boxModelDirty; }
		CONFIG::locodeco public function set boxModelDirty(value:Boolean):void { _boxModelDirty = value; }

		public function get doorModelDirty():Boolean { return _doorModelDirty; }
		public function set doorModelDirty(value:Boolean):void { _doorModelDirty = value; }

		CONFIG::locodeco public function get ladderModelDirty():Boolean { return _ladderModelDirty; }
		CONFIG::locodeco public function set ladderModelDirty(value:Boolean):void { _ladderModelDirty = value; }

		CONFIG::locodeco public function get targetModelDirty():Boolean { return _targetModelDirty; }
		CONFIG::locodeco public function set targetModelDirty(value:Boolean):void { _targetModelDirty = value; }

		CONFIG::locodeco public function get signpostModelDirty():Boolean { return _signpostModelDirty; }
		CONFIG::locodeco public function set signpostModelDirty(value:Boolean):void { _signpostModelDirty = value; }

		CONFIG::god public function get wallModelDirty():Boolean { return _wallModelDirty; }
		CONFIG::god public function set wallModelDirty(value:Boolean):void { _wallModelDirty = value; }
		
		CONFIG::god public function get platformLineModelDirty():Boolean { return _platformLineModelDirty; }
		CONFIG::god public function set platformLineModelDirty(value:Boolean):void { _platformLineModelDirty = value; }
		
		// TODO: Find alternative to returning a shape.
		public function get sergOverlay():Shape { return getChildByName('serg_overlay') as Shape };
		public function set sergOverlay(value:Shape):void  {addChild(value);}
	}
}