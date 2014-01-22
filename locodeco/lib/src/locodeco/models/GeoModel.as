package locodeco.models
{
import locodeco.LocoDecoGlobals;

public class GeoModel extends DecoModel
{
	public function GeoModel(layer:LayerModel) {
		super(layer);
	}
	
	override public function get type():String {
		return DecoModelTypes.GEO_TYPE;
	}
	
	override public function removeFromLayer():void {
		LocoDecoGlobals.instance.location.geometryModels.removeItem(this);
	}
	
	override public function toString():String {
		return "GeoModel{name:" + name + ", tsid:" + tsid
			+ ", x:" + x + ", y:" + y + ", width:" + w + ", height:" + h
			+ ", r:" + r + ", hflip:" + h_flip + ", visible:" + visible
			+ "}";
	}
}
}