package locodeco.models
{
public class LadderModel extends GeoModel
{
	public function LadderModel(layer:LayerModel) {
		super(layer);
	}
	
	override public function updateModel(ladder:Object):void {
		originalWidth  = ladder.w;
		originalHeight = ladder.h;
		tsid = ladder.tsid;
		name = ladder.name;
		x = ladder.x;
		y = ladder.y;
	}
	
	override public function set r(value:int):void {
		// nope, not yet
	}
	
	override public function get type():String {
		return DecoModelTypes.LADDER_TYPE;
	}
}
}