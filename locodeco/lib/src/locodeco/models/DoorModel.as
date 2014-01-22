package locodeco.models
{
public class DoorModel extends GeoModel
{
	public function DoorModel(layer:LayerModel) {
		super(layer);
	}
	
	override public function updateModel(door:Object):void {
		originalWidth  = door.w;
		originalHeight = door.h;
		tsid = door.tsid;
		name = door.name;
		x = door.x;
		y = door.y;
		r = door.r;
		h_flip = door.h_flip;
	}
	
	override public function get type():String {
		return DecoModelTypes.DOOR_TYPE;
	}
}
}