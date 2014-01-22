package locodeco.models
{
public class TargetModel extends GeoModel
{
	public function TargetModel(layer:LayerModel) {
		super(layer);
	}
	
	override public function updateModel(target:Object):void {
		tsid = target.tsid;
		name = target.name;
		x = target.x;
		y = target.y;
	}
	
	override public function set r(value:int):void {
		// nope, not yet
	}
	
	override public function get type():String {
		return DecoModelTypes.TARGET_TYPE;
	}
}
}