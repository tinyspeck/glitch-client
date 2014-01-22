package locodeco.models
{
public class BoxModel extends GeoModel
{
	public function BoxModel(layer:LayerModel) {
		super(layer);
	}
	
	override public function updateModel(box:Object):void {
		originalWidth  = box.w;
		originalHeight = box.h;
		tsid = box.tsid;
		name = box.name;
		x = box.x;
		y = box.y;
	}
	
	override public function set r(value:int):void {
		// nope, not yet
	}
	
	override public function get type():String {
		return DecoModelTypes.BOX_TYPE;
	}
}
}