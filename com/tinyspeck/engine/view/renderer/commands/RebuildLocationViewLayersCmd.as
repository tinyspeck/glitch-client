package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.LocationViewBuilder;
	
	public class RebuildLocationViewLayersCmd implements ICommand {
		private var layers:Vector.<Layer>;
		private var locationRenderer:LocationRenderer;
		private var mainView:TSMainView;
		
		public function RebuildLocationViewLayersCmd(layers:Vector.<Layer>, locationRenderer:LocationRenderer) {
			this.layers = layers;
			this.locationRenderer = locationRenderer;
			mainView = TSFrontController.instance.getMainView();
		}
		
		public function execute():void {
			new LocationViewBuilder(locationRenderer, mainView, null).rebuildLayers(layers);
		}
	}
}