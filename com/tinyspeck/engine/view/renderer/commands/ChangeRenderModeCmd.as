package com.tinyspeck.engine.view.renderer.commands {
	
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.GrowlView;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	
	/**
	 * Changes location rendering mode and rebuilds location to 
	 * use the newly specified mode.
	 */ 
	public class ChangeRenderModeCmd implements ICommand  {
		private var newRenderMode:RenderMode;
		
		private var model:TSModelLocator;
		private var mainView:TSMainView;
		private var frontController:TSFrontController;
		
		public function ChangeRenderModeCmd(newRenderMode:RenderMode) {
			this.newRenderMode = newRenderMode;
			
			model = TSModelLocator.instance;
			mainView = TSFrontController.instance.getMainView();
			frontController = TSFrontController.instance;
		}
		
		public function execute():void {
			Benchmark.addCheck("CHANGING RENDER MODE FROM " + model.stateModel.render_mode.name + ' to ' + newRenderMode.name);
			
			if (newRenderMode == model.stateModel.render_mode) {
				return;
			}
			
			mainView.gameRenderer.setAvatarView(null);
			model.stateModel.render_mode = newRenderMode;
			model.stateModel.triggerCBProp(true, false, "render_mode");

			CONFIG::god {
				GrowlView.instance.addNormalNotification("CHANGING RENDER MODE: " + newRenderMode.name);
			}
			
			LocationCommands.rebuildLocation();
		}
	}
}
