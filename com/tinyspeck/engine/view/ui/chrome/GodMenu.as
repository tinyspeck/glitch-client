package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.engine.admin.AdminDialog;
	import com.tinyspeck.engine.admin.ButtonPreviewDialog;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.PrefsDialog;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	import com.tinyspeck.engine.view.renderer.commands.ChangeRenderModeCmd;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	import com.tinyspeck.engine.view.ui.TSDropdown;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	public class GodMenu extends TSDropdown implements IMoveListener
	{
		private var icon_bg:Sprite = new Sprite();
		
		private var _icon:DisplayObject;
		
		public function GodMenu(){}
		
		override protected function buildBase():void {
			_icon = new AssetManager.instance.assets.god_menu();
			addChild(_icon);
			
			_h = model.layoutModel.header_h - icon.height/2;
			_auto_width = true;
			_button_label_x = 4;
			_button_padding = 4;
			_border_color = model.layoutModel.bg_color;
			
			//draw a bg behind this
			var g:Graphics = icon_bg.graphics;
			g.beginFill(model.layoutModel.bg_color);
			g.drawRect(0, 0, _icon.width, _h);
			addChildAt(icon_bg, 0);
			
			//add this as a move listener
			TSFrontController.instance.registerMoveListener(this);
			
			//listen to things
			model.worldModel.registerCBProp(refreshMenu, "pc", "stats");
			model.moveModel.registerCBProp(refreshMenu, 'loading_img_url');
			
			//special mouse stuff because the default ones are called in toggleMenu, and that's what we want to call with the mouse!
			addEventListener(MouseEvent.ROLL_OVER, onMouseOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onMouseOut, false, 0, true);
			
			super.buildBase();
		}
		
		public function show():void {
			if(!is_built) buildBase();
			refreshMenu();
		}
		
		public function refreshMenu(anything:* = null):void {
			cleanArrays();
			
			const tsfc:TSFrontController = TSFrontController.instance;
			const state:StateModel = model.stateModel;
			const location:Location = model.worldModel.location;
			const locationReady:Boolean = (location && location.isFullyLoaded);
			
			//basic stuff
			addItem('Admin tools', AdminDialog.instance.start);
			addItem('Geo god page', tsfc.openGeoForLocation);
			addItem('Loc items page', tsfc.openItemsForLocation);
			addItem('Button previewer', ButtonPreviewDialog.instance.start);
			
			addItem(BREAK_STRING);
			if (model.flashVarModel.interact_with_all) {
				addItem('Disable interaction glow on all items', tsfc.toggleInteractWithAll);
			} else {
				addItem('Enable interaction glow on all items', tsfc.toggleInteractWithAll);
			}
			
			//renderer stuff
			if(!model.moveModel.rebuilding_location && locationReady && !CONFIG::locodeco){
				addItem(BREAK_STRING);
				addItem({label:'Vector renderer', disabled:state.render_mode == RenderMode.VECTOR}, onRendererChange, RenderMode.VECTOR);
				addItem({label:'Bitmap renderer', disabled:state.render_mode == RenderMode.BITMAP}, onRendererChange, RenderMode.BITMAP);
			}
			
			//snapping stuff
			if(!model.moveModel.moving 
				&& model.moveModel.loading_info 
				&& model.worldModel.location 
				&& model.worldModel.location.tsid == model.moveModel.loading_info.to_tsid) {
				
				addItem(BREAK_STRING);
				addItem(model.moveModel.loading_info.loading_img_url ? 'Re-snap' : 'Snap (no existing snap!)', tsfc.saveLocationLoadingImg);
				addItem('Save snap png ', tsfc.saveLocationImgFullSize);
				addItem('Save snap png with everything', tsfc.saveLocationImgFullSizeWithEverything);
				if (model.worldModel.pc.home_info.playerIsAtHome()) {
					addItem('Save home snap', tsfc.saveHomeImg);
				}
			}
			
			//performance
			addItem(BREAK_STRING);
			if (tsfc.getMainView().performanceGraphVisible) {
				addItem('Hide performance graph', tsfc.hidePerformanceGraph);
			} else {
				addItem('Show performance graph', tsfc.showPerformanceGraph);
			}
			
			//prefs
			addItem(BREAK_STRING);
			addItem('Player god page', onGodPage);
			
			//build it!
			buildMenu();
		}
		
		private function onRendererChange(mode:RenderMode):void {
			LocationCommands.changeRenderMode(mode);
			refreshMenu();
		}
		
		CONFIG::locodeco private function onLocationSave(is_save:Boolean):void {
			//we doing a save of a revert?
			if(is_save){
				TSFrontController.instance.saveLocoDecoChanges();
			}
			else {
				TSFrontController.instance.revertLocoDecoChanges();
			}
		}
		
		CONFIG::locodeco private function onLocodecoHelp():void {
			//show the help page for loco deco
			const url:String = "https://docs.google.com/leaf?id=175-y2qjNWHFxxWZApSF4Pw0mtwn0OpHQ9VIJe_hJeis";
			navigateToURL(new URLRequest(url), URLUtil.getTarget('ldhelp'));
		}
		
		private function onGodPage():void {
			//this opens god to the current logged in player's page
			const url:String = model.flashVarModel.root_url+'god/user_player.php?tsid='+model.worldModel.pc.tsid;
			navigateToURL(new URLRequest(url), URLUtil.getTarget('player_god'));
		}
		
		private function onMouseOver(event:MouseEvent=null):void {
			//delay a little bit, then open the sucker
			is_open = false;
			toggleMenu();
		}
		
		private function onMouseOut(event:MouseEvent=null):void {
			toggleMenu();
		}
		
		override protected function onClick(event:MouseEvent):void {
			//NOTHING!
		}
		
		///////////////////////////////////////////////////////////////////////////////
		//////// IMoveListener /////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function moveLocationHasChanged():void {}
		public function moveLocationAssetsAreReady():void {}
		
		public function moveMoveStarted():void {
			//refresh the menu
			refreshMenu();
		}
		
		public function moveMoveEnded():void {
			//refresh the menu
			refreshMenu();
		}
		
		public function get icon():DisplayObject { return _icon; }
	}
}