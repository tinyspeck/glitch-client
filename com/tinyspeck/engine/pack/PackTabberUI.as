package com.tinyspeck.engine.pack {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.InventorySearchManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.gameoverlay.UICalloutView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.inventory.InventorySearch;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	
	public class PackTabberUI extends TSSpriteWithModel implements IMoveListener {
		
		public static const HEIGHT:uint = 17;
		public static const TAB_PACK:String = 'pack';
		public static const TAB_FURNITURE:String = 'furniture';
		public static const TAB_WALL:String = 'wall';
		public static const TAB_FLOOR:String = 'floor';
		public static const TAB_CEILING:String = 'ceiling';
		
		private static const CURVE_W:uint = 18;
		private static const SEARCH_RADIUS:Number = 14.5;
		
		private var pack_bt:Button;
		private var furniture_bt:Button;
		private var wall_bt:Button;
		private var floor_bt:Button;
		private var ceiling_bt:Button;
		private var search_ui:InventorySearch;
		
		private var tabs:Vector.<Sprite> = new Vector.<Sprite>(); //keeps order
		private var tab_holder:Sprite = new Sprite();
		private var pack_holder:Sprite = new Sprite();
		private var furniture_holder:Sprite = new Sprite();
		private var wall_holder:Sprite = new Sprite();
		private var floor_holder:Sprite = new Sprite();
		private var ceiling_holder:Sprite = new Sprite();
		private var search_holder:Sprite = new Sprite();
		private var mag_glass:DisplayObject;
		
		private var active_color:uint = 0xe6ecee;
		private var inactive_color:uint = 0x78898a;
		private var next_x:int;
		
		private var active_filters:Array;
		private var inactive_filters:Array;
		
		private var bottom_shadow:DropShadowFilter = new DropShadowFilter();
		private var side_shadow_left:DropShadowFilter = new DropShadowFilter();
		private var side_shadow_right:DropShadowFilter = new DropShadowFilter();

		public function PackTabberUI(tsid:String=null) {
			super(tsid);
			build();
		}
		
		private function build():void {
			//set the colors
			active_color = CSSManager.instance.getUintColorValueFromStyle('button_pack_tab_label', 'backgroundColor', active_color);
			inactive_color = CSSManager.instance.getUintColorValueFromStyle('button_pack_tab_label', 'backgroundColorDisabled', inactive_color);
			
			//build the tabs
			tab_holder.blendMode = BlendMode.LAYER;
			addChild(tab_holder);
			pack_bt = buildTab('Inventory', pack_holder, onPackButtonClick);
			furniture_bt = buildTab('Furniture', furniture_holder, onFurnitureButtonClick);
			
			wall_bt = buildTab('Walls', wall_holder, onWallButtonClick);
			floor_bt = buildTab('Floors', floor_holder, onFloorButtonClick);
			ceiling_bt = buildTab('Ceilings', ceiling_holder, onCeilingButtonClick);
			
			//hide by default
			wall_holder.visible = false;
			floor_holder.visible = false;
			ceiling_holder.visible = false;
			
			//filters
			side_shadow_left.distance = side_shadow_right.distance = 3;
			side_shadow_left.blurX = side_shadow_right.blurX = 3;
			side_shadow_left.blurY = side_shadow_right.blurY = 0;
			side_shadow_left.alpha = side_shadow_right.alpha = .2;
			side_shadow_left.angle = 180;
			side_shadow_right.angle = 0;
			
			active_filters = [side_shadow_left, side_shadow_right];
			
			bottom_shadow.angle = -90;
			bottom_shadow.inner = true;
			bottom_shadow.distance = 2;
			bottom_shadow.blurX = 0;
			bottom_shadow.blurY = 4;
			bottom_shadow.alpha = .2;
			inactive_filters = [bottom_shadow].concat(active_filters);
			
			//inventory searcher
			const draw_h:int = 17;
			const draw_y:int = 8;
			const matrix:Matrix = new Matrix();
			matrix.createGradientBox(1, draw_h*2, Math.PI/2);
			
			mag_glass = new AssetManager.instance.assets.mag_glass_inventory();
			mag_glass.x = int(SEARCH_RADIUS/2);
			mag_glass.y = int(SEARCH_RADIUS/2);
			mag_glass.filters = StaticFilters.white1px90Degrees_DropShadowA;
			search_holder.addChild(mag_glass);
			
			var g:Graphics = search_holder.graphics;
			g.beginFill(model.layoutModel.bg_color);
			g.drawCircle(SEARCH_RADIUS, SEARCH_RADIUS, SEARCH_RADIUS);
			g.endFill();
			g.beginFill(model.layoutModel.bg_color);
			g.drawRect(SEARCH_RADIUS*2 - 4, draw_y, 14, draw_h);//bridge from circle to tab
			g.beginGradientFill(GradientType.LINEAR, [0xf4f7f8, 0xf4f7f8], [1, 0], [120, 180], matrix);
			g.drawRect(SEARCH_RADIUS*2 + 1, draw_y, 1, draw_h); //whiteish vertical line
			g.beginGradientFill(GradientType.LINEAR, [0xbfc9cb, 0xbfc9cb], [1, 0], [120, 180], matrix);
			g.drawRect(SEARCH_RADIUS*2 + 2, draw_y, 1, draw_h); //blueish vertical line
			
			search_holder.x = int(-SEARCH_RADIUS - 7);
			search_holder.y = int(-SEARCH_RADIUS + 6);
			search_holder.useHandCursor = search_holder.buttonMode = true;
			search_holder.addEventListener(MouseEvent.CLICK, search_toggle, false, 0, true);
			addChild(search_holder);
			
			search_ui = InventorySearchManager.instance.search_ui;
			search_ui.addEventListener(TSEvent.CLOSE, onSearchClose, false, 0, true);
			
			TSFrontController.instance.registerMoveListener(this);
			
			packShowing();
			changeVisibility();
			
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_COMPLETE, _furnitureBagDragCompleteHandler);
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_STARTED, _furnitureBagDragStartHandler);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, _packDragCompleteHandler);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, _packDragStartHandler);
			HandOfDecorator.instance.addEventListener(TSEvent.DRAG_COMPLETE, _hodDragCompleteHandler);
			HandOfDecorator.instance.addEventListener(TSEvent.DRAG_STARTED, _hodDragStartHandler);
			
			//listen for decoration changes
			model.stateModel.registerCBProp(onDecoratorModeChange, 'decorator_mode');
			onDecoratorModeChange(false);
		}
		
		private function buildTab(label:String, holder:Sprite, click_function:Function):Button {
			const bt:Button = new Button({
				name: label,
				label: label,
				size: Button.SIZE_PACK_TAB,
				type: Button.TYPE_PACK_TAB
			});
			bt.x = CURVE_W;
			holder.addChild(bt);
			
			holder.useHandCursor = holder.buttonMode = true;
			holder.mouseChildren = false;
			tab_holder.addChildAt(holder, 0);
			
			holder.x = next_x;
			next_x += holder.width + CURVE_W/2 + 7;
			
			holder.addEventListener(MouseEvent.CLICK, click_function, false, 0, true);
			tabs.push(holder);
			
			return bt;
		}
		
		private function setActiveTab(holder:Sprite):void {
			//this will draw the little curvy things
			const bt:Button = holder.getChildAt(0) as Button;
			const total:int = tabs.length;
			var i:int;
			var other_holder:Sprite;
			var other_bt:Button;
			
			for(i; i < total; i++){
				other_holder = tabs[int(i)];
				other_bt = other_holder.getChildAt(0) as Button;
				other_bt.disabled = other_bt != bt;
				
				//draw it
				drawButtonCurves(other_bt, other_holder);
				
				//set the index of the holder
				tab_holder.setChildIndex(other_holder, 0);
				
				//set the look
				other_holder.filters = other_bt.disabled ? inactive_filters : active_filters;
			}
			
			//make the active holder the highest
			tab_holder.setChildIndex(holder, tab_holder.numChildren-1);
			
			//handle the search holder
			search_holder.visible = false;
			if(holder == pack_holder){
				setChildIndex(search_holder, numChildren-1);
				search_holder.visible = true;
				
				//if this was set from the location flag, let's handle that
				if(model && model.worldModel && model.worldModel.location && model.worldModel.location.no_inventory_search){
					search_holder.visible = false;
				}
			}
			
			//handle the callout if it's there
			const callout:UICalloutView = UICalloutView.instance;
			if(callout.parent && callout.current_section == UICalloutView.SWATCH_OPEN && (holder == wall_holder || holder == floor_holder || holder == ceiling_holder)){
				//show the callout to drag a swatch
				UICalloutView.instance.show({
					section: UICalloutView.SWATCH_DRAG,
					display_time: 3000
				});
			}
		}
		
		private function drawButtonCurves(bt:Button, sp:Sprite):void {
			//make our fancy curves
			const g:Graphics = sp.graphics;
			var start_x:int;
			
			g.clear();
			g.beginFill(bt.disabled ? inactive_color : active_color);
			g.moveTo(0, HEIGHT);
			
			g.curveTo(6,HEIGHT, 8,HEIGHT-6);
			g.curveTo(11,0, CURVE_W,0);
			
			start_x = bt.width+CURVE_W-3; //buttons have a little fat on the right, this makes it tighter
			g.lineTo(start_x, 0);
			
			start_x += CURVE_W;
			g.curveTo(start_x-11,0, start_x-8,HEIGHT-6);
			g.curveTo(start_x-6,HEIGHT, start_x,HEIGHT);
			
			//draw a rect around the button so you don't get the lame look on alpha fade (cuts it out of the drawing)
			g.drawRect(bt.x + 1, bt.y + 1, int(bt.width - 6), int(bt.height - 4));
			
			g.endFill();
		}
		
		private function _hodDragStartHandler(e:TSEvent):void {
			changeVisibility();
		}
		
		private function _hodDragCompleteHandler(e:TSEvent):void {
			StageBeacon.waitForNextFrame(changeVisibility);
		}
		
		private function _packDragStartHandler(e:TSEvent):void {
			changeVisibility();
		}
		
		private function _packDragCompleteHandler(e:TSEvent):void {
			StageBeacon.waitForNextFrame(changeVisibility);
		}
		
		private function _furnitureBagDragStartHandler(e:TSEvent):void {
			changeVisibility();
		}
		
		private function _furnitureBagDragCompleteHandler(e:TSEvent):void {
			StageBeacon.waitForNextFrame(changeVisibility);
		}
		
		public function getTabByName(tab_name:String):Sprite {
			//try and return a valid tab
			try {
				return this[tab_name+'_holder'] as Sprite;
			}
			catch(error:Error){
				return null;
			}
			
			return null;
		}
		
		public var showing:Boolean = true;
		public function changeVisibility():void {
			var show:Boolean = true;
			if (Cursor.instance.is_dragging) show = false;
			if (model.moveModel.moving) show = false;
			if (!PackDisplayManager.instance.is_viz) show = false;
			
			//can we show the furniture tab?
			furniture_holder.visible = model.worldModel.location && !model.worldModel.location.no_furniture_bag;
			
			if (show) {
				if (!showing) {
					TSTweener.removeTweens(this);
					TSTweener.addTween(this, {alpha:1, time:.5});
					showing = true;
					mouseChildren = mouseEnabled = true;
					
					//handle the inventory holder
					TSTweener.removeTweens(search_holder);
					TSTweener.addTween(search_holder, {alpha:1, time:.3});
				}
			} else {
				if (showing) {
					TSTweener.removeTweens(this);
					TSTweener.addTween(this, {alpha:0, time:.5});
					showing = false;
					mouseChildren = mouseEnabled = false;
					
					TSTweener.removeTweens(search_holder);
					TSTweener.addTween(search_holder, {alpha:0, time:.1});
				}
			}
		}	
		
		private function onPackButtonClick(event:MouseEvent):void {
			if(UICalloutView.instance.parent && UICalloutView.instance.current_section == UICalloutView.FURNITURE){
				//rare edge case that they might select the regular pack after being told to drag furniture
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			packShowing();
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		private function onFurnitureButtonClick(event:MouseEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			furnitureShowing();
			StageBeacon.stage.focus = StageBeacon.stage;
			
			//if we are showing the UICallout for this, make sure it shows the furniture dragging
			if(UICalloutView.instance.parent && UICalloutView.instance.current_section == UICalloutView.FURNITURE_TAB){
				UICalloutView.instance.show({section:UICalloutView.FURNITURE, display_time:0});
			}
		}
		
		private function onWallButtonClick(event:MouseEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			setActiveTab(wall_holder);
			PackDisplayManager.instance.showWallSwatches();
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		private function onFloorButtonClick(event:MouseEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			setActiveTab(floor_holder);
			PackDisplayManager.instance.showFloorSwatches();
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		private function onCeilingButtonClick(event:MouseEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			setActiveTab(ceiling_holder);
			PackDisplayManager.instance.showCeilingSwatches();
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		public function packShowing():void {
			setActiveTab(pack_holder);
			PackDisplayManager.instance.hideFurnitureBag();
		}
		
		public function furnitureShowing():void {
			setActiveTab(furniture_holder);
			PackDisplayManager.instance.showFurnitureBag();
		}
		
		private function search_toggle(event:Event = null):void {
			if(!search_ui.visible){
				search_ui.show(true);
				StageBeacon.mouse_down_sig.add(onStageMouseDown);
			}
			else {
				search_ui.hide();
				PackDisplayManager.instance.blurFocusedSlot();
				StageBeacon.mouse_down_sig.remove(onStageMouseDown);
			}
			
			//apply the filter to the mag glass
			if(mag_glass) mag_glass.filters = search_ui.visible ? StaticFilters.blue2px40Alpha_GlowA : StaticFilters.white1px90Degrees_DropShadowA;
		}
		
		private function onStageMouseDown(event:MouseEvent):void {
			//if we've clicked the stage and it's not on search, hide it
			if(event.target != search_holder && !search_ui.hitTestPoint(event.stageX, event.stageY)){
				hideSearch();
			}
		}
		
		private function onDecoratorModeChange(enabled:Boolean):void {
			//toggle the swatch tabs visibility
			//if we ever do other types of tabs, we'll need a reflow function
			const start_alpha:Number = enabled ? 0 : 1;
			const end_alpha:Number = enabled ? 1 : 0;
			
			//check to make sure that we go back to inventory if furniture isn't selected
			if(!enabled && PackDisplayManager.instance.getOpenTabName() != TAB_FURNITURE){
				packShowing();
			}
			
			if(wall_holder.alpha == end_alpha) return;
			TSTweener.removeTweens([wall_holder, floor_holder, ceiling_holder]);
			if(end_alpha == 1){
				wall_holder.visible = true;
				floor_holder.visible = true;
				ceiling_holder.visible = true;
			}
			TSTweener.addTween([wall_holder, floor_holder, ceiling_holder], {alpha:end_alpha, time:.3, transition:'linear',
				onComplete:function():void {
					//if we are fading out, make them invisible
					if(end_alpha == 0){
						wall_holder.visible = false;
						floor_holder.visible = false;
						ceiling_holder.visible = false;
					}
				}
			});
		}
		
		public function showInventorySearch():void {
			//open the inventory search and focus it to the tf
			if(!(StageBeacon.stage.focus is TextField)){
				search_ui.show(true);
				if(mag_glass) mag_glass.filters = StaticFilters.blue2px40Alpha_GlowA;
				StageBeacon.mouse_down_sig.add(onStageMouseDown);
			}
		}
		
		private function onSearchClose(event:TSEvent):void {
			if(mag_glass) mag_glass.filters = StaticFilters.white1px90Degrees_DropShadowA;
		}
		
		private function hideSearch():void {
			if(search_ui.visible){
				search_toggle();
			}
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
			changeVisibility();
			PackDisplayManager.instance.hideFurnitureBag();
		}
		
		public function moveMoveEnded():void {
			StageBeacon.setTimeout(changeVisibility, 1000);
		}
		
		//height is the same no matter what!
		override public function get height():Number { return HEIGHT; }
	}
}