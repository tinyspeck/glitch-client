package locodeco.models
{
public class WallModel extends GeoModel
{
	[Bindable] public var item_perm:*; // must be able to be an int or null
	[Bindable] public var pc_perm:*; // must be able to be an int or null
	
	public function WallModel(layer:LayerModel) {
		super(layer);
	}
	
	override public function updateModel(wall:Object):void {
		originalWidth  = wall.w;
		originalHeight = wall.h;
		tsid = wall.tsid;
		name = wall.name;
		x = wall.x;
		y = wall.y;
		pc_perm = wall.pc_perm;
		item_perm = wall.item_perm;
	}
	
	override public function set r(value:int):void {
		// nope
	}
	
	override public function get type():String {
		return DecoModelTypes.WALL_TYPE;
	}
	
	override public function getState():Object {
		const ob:Object = super.getState();
		ob.pc_perm = pc_perm;
		ob.item_perm = item_perm;
		return ob;
	}
}
}