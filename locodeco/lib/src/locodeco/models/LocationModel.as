package locodeco.models
{
import flash.events.EventDispatcher;

import mx.collections.ArrayList;

public class LocationModel extends EventDispatcher
{
	/**
	 * Data-binding-aware ArrayList which controls the SWF Layers panel
	 * and receives change events from UI interaction in the SWF.
	 * 
	 * These are all consts in practice, but [Bindable] doesn't allow
	 * them to BE const instead of var.
	 */
	[Bindable] public var layerModels:ArrayList = new ArrayList();
	
	/** Doors, signposts, platforms, walls, etc */
	[Bindable] public var geometryModels:ArrayList = new ArrayList();
	
	/** Sky gradient */
	[Bindable] public var topGradientColor:ColorModel = new ColorModel();
	[Bindable] public var bottomGradientColor:ColorModel = new ColorModel();
	
	/** Ground Y */
	[Bindable] public var groundY:int;
	[Bindable] public var groundYMin:int;
	[Bindable] public var groundYMax:int;
	
	public function addLayer(tsid:String, position:int=0, wPx:Number=NaN, hPx:Number=NaN, wPct:Number=NaN, hPct:Number=NaN):void {
		const newLM:LayerModel = new LayerModel();
		newLM.name = newLM.tsid = tsid
		if (!isNaN(wPx)) newLM.width = wPx;
		if (!isNaN(hPx)) newLM.height = hPx;
		if (!isNaN(wPct)) newLM.displayWidth = wPct;
		if (!isNaN(hPct)) newLM.displayHeight = hPct;
		layerModels.addItemAt(newLM, position);
	}
	
	public function getLayerModel(tsid:String):LayerModel {
		for each (var layer:LayerModel in layerModels.source) {
			if (layer.tsid == tsid) return layer;
		}
		return null;
	}
	
	public function getDecoModel(decoTSID:String, layerTSID:String):DecoModel {
		var deco:DecoModel;
		const layer:LayerModel = getLayerModel(layerTSID);
		if (layer) {
			for each (deco in layer.decos.source) {
				if (deco.tsid == decoTSID) return deco;
			}
		}
		if (layerTSID == 'middleground') {
			for each (deco in geometryModels.source) {
				if (deco.tsid == decoTSID) return deco;
			}
		}
		return null;
	}
}
}