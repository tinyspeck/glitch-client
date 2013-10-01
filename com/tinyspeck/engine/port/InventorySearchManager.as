package com.tinyspeck.engine.port {
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.pack.PackTabberUI;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.BaseScreenView;
	import com.tinyspeck.engine.view.gameoverlay.BaseSplashScreenView;
	import com.tinyspeck.engine.view.ui.inventory.InventorySearch;
	
	CONFIG::perf { import com.tinyspeck.engine.perf.PerfTestController; }

	public class InventorySearchManager implements IRefreshListener {
		/* singleton boilerplate */
		public static const instance:InventorySearchManager = new InventorySearchManager();
		
		private var model:TSModelLocator;
		private var ui:InventorySearch = new InventorySearch();
		
		// these classes, when in focus, keep you from using inventory search
		private var badClassesV:Vector.<Class> = new <Class>[
			BaseSplashScreenView,
			BaseScreenView,
			AnnouncementController,
			FurnUpgradeDialog,
			ChassisManager
		];
		
		public function InventorySearchManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			CONFIG::perf {
				badClassesV.push(PerfTestController);
			}
		}
		
		public function init():void {
			if (model) return;
			
			model = TSModelLocator.instance;
			
			//listen to refreshing
			TSFrontController.instance.registerRefreshListener(this);
		}
		
		public function refresh():void {
			if (!model) return;
			
			//place the inventory search
			ui.x = int(model.layoutModel.gutter_w + 23);
			ui.y = int(model.layoutModel.header_h + model.layoutModel.loc_vp_h - InventorySearch.HEIGHT - 35);
		}
		
		// TSMainView calls this
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			if (!canStart()) {
				goAway();
			}
		}
		
		public function canStart():Boolean {
			if (!model) return false;
			if (model.stateModel.menus_prohibited) return false;
			if (!PackDisplayManager.instance.is_viz) return false;
			if (PackDisplayManager.instance.getOpenTabName() != PackTabberUI.TAB_PACK) return false;
			if (model.worldModel.location.no_inventory_search) return false;
			return canShowWhileThisIsFocussed(model.stateModel.focused_component);
		}
		
		private function goAway():void {
			if(ui.visible){
				ui.hide();
			}
		}
		
		private function canShowWhileThisIsFocussed(focused_comp:IFocusableComponent):Boolean {
			for (var i:int;i<badClassesV.length;i++) {
				if (focused_comp is badClassesV[i]) return false;
			}
			return true;
		}
		
		public function get search_ui():InventorySearch { return ui; }
	}
}