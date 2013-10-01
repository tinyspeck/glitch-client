package com.tinyspeck.engine.view.renderer
{
	import com.flexamphetamine.InterruptableWorker;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.memory.ClientOnlyPools;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.GrowlView;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.system.System;
	import flash.utils.getTimer;

	/**
	 * Builds a location view by creating a LayerRenderer for each layer defined in the
	 * specified Location's 'layers' property.
	 * 
	 * Excessive constructor parameters will be removed with the introduction of
	 * a LocationView class.
	 */
	public class LocationViewBuilder extends InterruptableWorker implements IMoveListener {
		
		private var locationRenderer:LocationRenderer;
		private var mainView:TSMainView;
		private var control_points_holder:Sprite = new Sprite();
		
		// stuff related to asynchronous location loading
		// these are states returned from dispatch():
		private static const BUILD_LAYERS:int    = FINISHED      + 1;
		private static const BUILD_DECOS:int     = BUILD_LAYERS  + 1;
		private static const RELOAD_ASSETS:int   = BUILD_DECOS   + 1;
		private static const WAIT_FOR_ASSETS:int = RELOAD_ASSETS + 1;
		
		/** True while we're building a location, which is asynchronous */
		private var building_location:Boolean = false;
		private var waiting_for_location_assets:Boolean = false;
		
		private var location_building_time_start:int;
		
		private var stateModel:StateModel;
		private var flashVarModel:FlashVarModel;

		private var currentLocationView:LocationView;
		
		public function LocationViewBuilder(locationRenderer:LocationRenderer, mainView:TSMainView, control_points_holder:Sprite) {
			super(TSModelLocator.instance.flashVarModel.async_timeslice_ms);
			
			this.locationRenderer = locationRenderer;
			this.mainView = mainView;
			this.control_points_holder = control_points_holder;
			
			flashVarModel = TSModelLocator.instance.flashVarModel;
			stateModel = TSModelLocator.instance.stateModel;
		}
		
		// TODO: Rather than passing a LocationView, dispatch one using Signals
		public function buildLocationView(location:Location, avatarView:AvatarView, pc:PC):void {
			if (building_location) return;
			building_location = true;
			
			currentLocationView = new LocationView();
			
			location_building_time_start = getTimer();
			
			const layers:Vector.<Layer> = location.layers;
			layers.sort(SortTools.layerZSort);
			
			var layer:Layer;
			var layerRenderer:LayerRenderer;
			for (var i:int=0; i<layers.length; i++) {
				layer = layers[int(i)];
				layer.decos.sort(SortTools.decoZSort);
				
				if (layer is MiddleGroundLayer) {
					layerRenderer = new MiddleGroundRenderer(layer, stateModel.render_mode.usesBitmaps);
					currentLocationView.middleGroundRenderer = MiddleGroundRenderer(layerRenderer);
					currentLocationView.middleGroundRenderer.avatarView = avatarView;
					currentLocationView.middleGroundRenderer.pc = pc;
				} else {
					layerRenderer = new LayerRenderer(layer, stateModel.render_mode.usesBitmaps);
					// hide the layer if it's supposed to be hidden
					// (this is really only relevant to the DEV and LOCODECO clients
					//  as the regular client will just splice hidden layers from
					//  Location.layers in Location.fromAnonymous to avoid rendering them)
					layerRenderer.visible = !layerRenderer.layerData.is_hidden;
				}
				
				currentLocationView.layerRenderers.push(layerRenderer);
				
				locationRenderer.addChild(DisplayObject(layerRenderer));
			}
			
			// set this only once we have created the layer renderers!
			locationRenderer.locationView = currentLocationView;
			
			// TODO: let LocationRenderer handle this once LocationView has been dispatched.
			// keep these on top
			locationRenderer.addChild(locationRenderer.scrolling_overlay_holder);
			CONFIG::god {
				locationRenderer.addChild(control_points_holder);
			}

			// stuff we'll keep track of during loading/rendering
			const data:LoadingData = new LoadingData(layers);
			data.lastBuiltLayerIndex = -1;
			start(BUILD_LAYERS, data);
			
			//TODO bottom or top of this function?
			TSFrontController.instance.renderHasStarted();
		}
		
		public function rebuildLayers(layers:Vector.<Layer>):void {
			if (building_location) return;
			building_location = true;
			
			Benchmark.addCheck('LVB.rebuildLayers');

			currentLocationView = locationRenderer.locationView;
			
			location_building_time_start = getTimer();
			
			var layer:Layer;
			var layerRenderer:LayerRenderer;
			for (var i:int=0; i<layers.length; i++) {
				layer = layers[int(i)];
				layer.decos.sort(SortTools.decoZSort);

				Benchmark.addCheck('LVB.rebuildLayers rebuilding: ' + layer.tsid)
				
				layerRenderer = currentLocationView.getLayerRendererByTsid(layer.tsid);
				layerRenderer.visible = !layerRenderer.layerData.is_hidden;
				layerRenderer.clearDecos();
			}
			
			// stuff we'll keep track of during loading/rendering
			const data:LoadingData = new LoadingData(layers);
			data.lastBuiltLayerIndex = -1;
			
			// reload assets first
			start(RELOAD_ASSETS, data);
		}
		
		private function reloadLocationAssets(data:LoadingData):int {
			// we don't want TSMainView to think we are moving locations
			// so temporarily remove it as a listener.
			TSFrontController.instance.removeMoveListener(mainView);
			TSFrontController.instance.registerMoveListener(this);
			
			// this will load the location SWF if necessary
			// and kick off the re-render when it's done
			// (moveLocationAssetsAreReady() will get called)
			waiting_for_location_assets = true;
			DecoAssetManager.reloadLocationSWFs();
			return WAIT_FOR_ASSETS;
		}
		
		private function waitForLocationAssets(data:LoadingData):int {
			return (waiting_for_location_assets ? WAIT_FOR_ASSETS : BUILD_LAYERS);
		}
		
		public function moveLocationAssetsAreReady():void {
			// re-add TSMainView as a move listener and remove this command.
			TSFrontController.instance.removeMoveListener(this);
			TSFrontController.instance.registerMoveListener(mainView);
			TSFrontController.instance.renderHasStarted();
			
			// this will kick off layer rebuilding the next time waitForLocationAssets is dispatched
			waiting_for_location_assets = false;
		}
		
		// Other functions for IMoveListener
		public function moveLocationHasChanged():void{}
		public function moveMoveStarted():void{}
		public function moveMoveEnded():void {}
		
		override protected function workerTimedOut():Boolean {
			return (flashVarModel.async_rendering && super.workerTimedOut());
		}
		
		override protected function stopped(lastState:int, data:Object):void {
			// update load percentage
			TSFrontController.instance.updateLoadingLocationProgress(data.completedDecos / data.totalDecos);
		}
		
		override protected function terminated(lastState:int, data:Object):void {
			switch (lastState) {
				case FAILED: {
					Benchmark.addCheck("LVB.terminated: last state: " + lastState);
					building_location = false;
					currentLocationView = null;
					
					// apologize, profusely
					GrowlView.instance.addGodNotification("I had trouble imagining-up this location for you; I'm going to try something different...");
					
					// update load percentage
					TSFrontController.instance.updateLoadingLocationProgress(0);
					
					// fall back to the next render on the next frame
					StageBeacon.waitForNextFrame(LocationCommands.fallBackRenderMode);
					break;
				}
				case FINISHED: {
					// update load percentage
					TSFrontController.instance.updateLoadingLocationProgress(1);
				}
			}
		}
		
		override protected function dispatch(state:int, data:Object):int {
			switch(state) {
				case BUILD_LAYERS:
					return renderNextLayer(LoadingData(data));
				case BUILD_DECOS:
					return renderLayerDecos(LoadingData(data));
				case WAIT_FOR_ASSETS:
					return waitForLocationAssets(LoadingData(data));
				case RELOAD_ASSETS:
					return reloadLocationAssets(LoadingData(data));
			}
			// should not be possible to get here:
			Benchmark.addCheck("LVB.dispatch: failed: " + state);
			return FAILED;
		}
		
		/** Builds the next unbuilt layer, returns what state is next */
		private function renderNextLayer(data:LoadingData):int {
			// lastBuiltLayerIndex starts from -1 and increments to layer length
			data.lastBuiltLayerIndex++;
			
			if (data.lastBuiltLayerIndex < data.layers.length) {
				Benchmark.addCheck('LVB.renderNextLayer start');
				
				const layer:Layer = data.layers[int(data.lastBuiltLayerIndex)];
				const layerRenderer:LayerRenderer = currentLocationView.getLayerRendererByTsid(layer.tsid);
				
				// clear any existing sky
				layerRenderer.graphics.clear();
				
				LocationCommands.prepareLayerRenderer(layerRenderer);
				
				// start building decos for this layer
				data.lastBuiltDecoIndex = -1;
				return renderLayerDecos(data);
			} else {
				// no more layers to render
				
				// draw sky
				currentLocationView.fastUpdateGradient();
				
				// location loading complete
				building_location = false;
				
				Benchmark.addCheck('LVB.renderNextLayer total '+(getTimer()-location_building_time_start)+'ms');
	
				System.gc();
				locationBuilt();
				return FINISHED;
			}
		}
		
		private function renderLayerDecos(data:LoadingData):int {
			const layer:Layer = data.layers[int(data.lastBuiltLayerIndex)];
			const decos:Vector.<Deco> = layer.decos;
			
			// is there nothing to do
			if (!decos || flashVarModel.no_render_decos) return BUILD_LAYERS;
			
			try {
				// lastBuiltLayerIndex starts from -1 and increments to layer length
				data.lastBuiltDecoIndex++;
				
				const layerRenderer:LayerRenderer = currentLocationView.getLayerRendererByTsid(layer.tsid);
				
				if (data.lastBuiltDecoIndex == 0) {
					if (layerRenderer.largeBitmap) {
						layerRenderer.lockBitmaps();
					}
				}
				
				if (data.lastBuiltDecoIndex < decos.length) {
					renderNextDecoForLayer(decos[data.lastBuiltDecoIndex], layerRenderer, layer);
					data.completedDecos++;
					//trace('progress: ' + completedDecos / totalDecos);
				}
				
				if (data.lastBuiltDecoIndex == decos.length) {
					// no more decos for this layer
					if (layerRenderer.largeBitmap) {
						layerRenderer.unlockBitmaps();
						layerRenderer.finalize();
					}
				}
				/*
				if (stateModel.render_mode == RenderMode.BITMAP) {
					throw new Error('hi!');
				}
				*/
			} catch(error:Error) {
				Benchmark.addCheck("LVB.renderLayerDecos: Error: " + error.getStackTrace());
				
				// report this
				BootError.handleError("LocationRenderer failed to build '" + layer.tsid +
					"' (" + error.toString() + ")", error, ['renderer'], true);
				
				return FAILED;
			}
			
			// are we done?
			return ((data.lastBuiltDecoIndex == decos.length) ? BUILD_LAYERS : BUILD_DECOS);
		}
		
		private function renderNextDecoForLayer(deco:Deco, layerRenderer:LayerRenderer, layer:Layer):void {
			var decoAsset:MovieClip;
			if (layerRenderer.largeBitmap) {
				// grab a template copy of the vectors for drawing
				decoAsset = DecoAssetManager.getTemplate(deco.sprite_class);
				if (decoAsset) {
					decoAsset.filters = null;
				}
			} else {
				// grab a unique copy of the vectors for this particular deco
				decoAsset = DecoAssetManager.getInstance(deco);
			}
			
			CONFIG::debugging {
				if (decoAsset){
					var swf_dims:Object = DecoAssetManager.getDimensions(deco.sprite_class);
					// make sure the deco FLA was not saved with a stage size smaller than its contents
					if (decoAsset.width>swf_dims.width+1 || decoAsset.height > swf_dims.height+1) {
						//Console.warn('decoAsset bigger than swf stage! '+deco.sprite_class+' decoAsset.width/height:'+decoAsset.width+'x'+decoAsset.height+' swf_dims.width/Height:'+swf_dims.width+'x'+swf_dims.height);
					}
				} else if (!DecoAssetManager.isAssetAvailable(deco.sprite_class)) {
					// make sure we have that in the swf
					Console.warn('no decoAsset for deco.sprite_class:'+deco.sprite_class);
				}
			}

			// render only if we have the asset, or render a red box when we don't have it but we're in locodeco
			if (decoAsset || CONFIG::locodeco) {
				if (layerRenderer.largeBitmap) {
					// get from pool
					var borrowedDecoRenderer:DecoRenderer = ClientOnlyPools.DecoRendererPool.borrowObject();
					try {
						if (deco.should_be_rendered_standalone) {
							// we must instantiate a new DecoRenderer since
							// 'decoRenderer' above is reused
							var standaloneDecos:DecoRenderer = new DecoRenderer();
							// do not init with the template decoAsset;
							// the renderer will load an instance copy on its own
							standaloneDecos.init(deco, null);
							LocationCommands.applyFiltersToView(layer, standaloneDecos);
							layerRenderer.addDeco(standaloneDecos);
						} else {
							// reset the renderer
							borrowedDecoRenderer.dispose();
							// decoAsset is guaranteed to be non-null here,
							// except when in locodeco (this is crtical when
							// reusing DecoRenderers in the GPU renderer;
							// locodeco disallows GPU, so null is okay)
							borrowedDecoRenderer.init(deco, decoAsset);
							LocationCommands.applyFiltersToView(layer, borrowedDecoRenderer);
							layerRenderer.addDeco(borrowedDecoRenderer);
						}
					} catch(e:Error) {
						// LayerRenderer.addDeco may throw: ArgumentError: Error #2015: Invalid BitmapData;
						Benchmark.addCheck("FAILED TO ADD DECO " + deco.sprite_class + " TO LAYER " + layerRenderer.layerData.name );
						throw e;
					} finally {
						// return to pool
						borrowedDecoRenderer.dispose();
						ClientOnlyPools.DecoRendererPool.returnObject(borrowedDecoRenderer);
						borrowedDecoRenderer = null;
					}
				} else {
					try {
						var instanceDecoRenderer:DecoRenderer = new DecoRenderer();
						instanceDecoRenderer.init(deco, decoAsset);
						LocationCommands.applyFiltersToView(layer, instanceDecoRenderer);
						layerRenderer.addDeco(instanceDecoRenderer);
					} catch(e:Error) {
						// LayerRenderer.addDeco may throw: ArgumentError: Error #2015: Invalid BitmapData;
						Benchmark.addCheck("FAILED TO ADD DECO " + deco.sprite_class + " TO LAYER " + layerRenderer.layerData.name );
						throw e;
					}
				}
			}
		}
		
		private function locationBuilt():void {
			// update performance tool with renderer name
			mainView.updatePerformanceRendererInfo(stateModel.render_mode.name);
			
			DecoAssetManager.reportLocationBuilt();
			mainView.locationBuilt();
			// call renderHasEnded asynchronously so that RenderTestController gets an accurate time from FPSTracker.
			StageBeacon.waitForNextFrame(TSFrontController.instance.renderHasEnded);
			currentLocationView = null;
			TSFrontController.instance.resnapMiniMap();
		}
	}
}

import com.tinyspeck.engine.data.location.Layer;

/** Tracks stuff that needs tracking during location loading */
class LoadingData {
	public var layers:Vector.<Layer>;
	
	public var lastBuiltLayerIndex:int;
	public var lastBuiltDecoIndex:int;
	
	public var completedDecos:int = 0;
	public var totalDecos:int = 0;
	
	public function LoadingData(layers:Vector.<Layer>) {
		this.layers = layers;
		for each (var layer:Layer in layers) {
			this.totalDecos += layer.decos.length;
		}
	}
}