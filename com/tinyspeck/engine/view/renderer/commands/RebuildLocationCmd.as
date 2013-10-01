package com.tinyspeck.engine.view.renderer.commands {
	
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.IRenderListener;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.LoadingLocationView;
	import com.tinyspeck.engine.view.gameoverlay.LocationCanvasView;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	
	CONFIG::god { import com.tinyspeck.engine.view.gameoverlay.ViewportScaleSliderView; }
	
	/** Rebuilds the location, including loading newly needed assets */ 
	public class RebuildLocationCmd implements ICommand, IRenderListener {
		private var model:TSModelLocator;
		private var mainView:TSMainView;
		private var frontController:TSFrontController;
		private var wasMoving:Boolean;
		
		public function RebuildLocationCmd() {
			model = TSModelLocator.instance;
			mainView = TSFrontController.instance.getMainView();
			frontController = TSFrontController.instance;
		}
		
		public function execute():void {
			if (model.moveModel.rebuilding_location) return;
			model.moveModel.rebuilding_location = true;
			
			Benchmark.addCheck("REBUILDING LOCATION");

			// are we rebuilding during a move? we'll need to know whether
			// TSMainView will be handling things or whether we need to 
			// help revealing the location and placing UI
			wasMoving = model.moveModel.moving;
			frontController.registerRenderListener(this);

			//TODO it'd be great if we could outsource the rest of this function
			//     to TSMainView, since parts of this are likely to go stale...
			
			// avoid visual artifacts while the LoadingLocationView fades in
			mainView.gameRenderer.pause();
			
			// show the loading screen now!
			LoadingLocationView.instance.fadeIn();
			LocationCanvasView.instance.hide();
			MiniMapView.instance.hide();
			CONFIG::god {
				ViewportScaleSliderView.instance.hide();
			}
			
			// this will load the location SWF if necessary
			// and kick off the re-render when it's done
			DecoAssetManager.reloadLocationSWFs();
		}
		
		public function renderHasStarted():void {
			//
		}
		
		public function renderHasEnded():void {
			// we're done with out work
			frontController.removeRenderListener(this);
			model.moveModel.rebuilding_location = false;
			
			// when not moving, we have to pretend that a move just ended
			// so the UI will be set up correctly by TSMainView
			if (!wasMoving) {
				mainView.moveMoveEnded();
			}
		}
	}
}
