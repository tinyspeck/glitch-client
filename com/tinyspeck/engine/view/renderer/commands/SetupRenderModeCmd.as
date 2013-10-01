package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	
	public class SetupRenderModeCmd implements ICommand {
		private var flashVarModel:FlashVarModel
		private var stateModel:StateModel;
		private var mainView:TSMainView;
		
		public function SetupRenderModeCmd() {
			flashVarModel = TSModelLocator.instance.flashVarModel;
			stateModel = TSModelLocator.instance.stateModel;
			mainView = TSFrontController.instance.getMainView();
		}
		
		public function execute():void {
			// only check the fVM bitmap_renderer for the *initial* render mode
			// everyone else should use model.stateModel.render_mode.usesBitmaps
			if (flashVarModel.vector_renderer) {
				stateModel.render_mode = RenderMode.VECTOR;
			} else {
				stateModel.render_mode = RenderMode.BITMAP;
			}			
		}
	}
}