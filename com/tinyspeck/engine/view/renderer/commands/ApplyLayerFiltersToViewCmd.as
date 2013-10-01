package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.geo.SurfaceView;
	
	import flash.display.DisplayObject;
	
	CONFIG::locodeco { import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer; }
	CONFIG::locodeco { import com.tinyspeck.engine.view.util.StaticFilters; }
	
	/** Applies filters defined in the specified Layer to the Specified view Displayobject */
	public class ApplyLayerFiltersToViewCmd implements ICommand {
		private var layer:Layer;
		private var view:DisplayObject;
		private var disableHighlighting:Boolean;
		
		public function ApplyLayerFiltersToViewCmd(layer:Layer, view:DisplayObject, disableHighlighting:Boolean = false) {
			this.layer = layer;
			this.view = view;
			this.disableHighlighting = disableHighlighting;
		}
		
		public function execute():void {
			// Don't apply filters if flashvar is set
			if (TSModelLocator.instance.flashVarModel.no_layer_filters) return;
			
			var layerFilters:Array = layer.filtersA;
			
			CONFIG::locodeco {
				// for LocoDeco, replace the selection glow filter
				if (!disableHighlighting && (view is IAbstractDecoRenderer) && IAbstractDecoRenderer(view).highlight) {
					if (layerFilters) {
						// don't modify Layer's master copy of the filters
						layerFilters = layerFilters.concat(StaticFilters.ldSelection_Glow);
					} else {
						layerFilters = StaticFilters.ldSelection_GlowA;
					}
				}
			}

			// ewwwww, special cases
			if (view is SignpostView) {
				SignpostView(view).deco_holder.filters = layerFilters;
				SignpostView(view).holder.filters = layerFilters;
			} else if (view is DoorView) {
				DoorView(view).deco_holder.filters = layerFilters;
			} else if (view is SurfaceView) {
				SurfaceView(view).tiling.filters = layerFilters;
			} else {
				view.filters = layerFilters;
			}
		}
	}
}