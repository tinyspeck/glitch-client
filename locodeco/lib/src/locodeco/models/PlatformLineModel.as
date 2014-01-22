package locodeco.models
{
public class PlatformLineModel extends GeoModel
{
	// left coordinate
	[Bindable] public var x1:Number;
	[Bindable] public var y1:Number;
	
	// right coordinate
	[Bindable] public var x2:Number;
	[Bindable] public var y2:Number;

	[Bindable] public var platform_item_perm:*; // must be able to be an int or null
	[Bindable] public var platform_pc_perm:*; // must be able to be an int or null
	
	[Bindable] public var placement_invoking_set:String;
	[Bindable] public var placement_userdeco_set:String;
 	private var _is_for_placement:Boolean;
 	private var _placement_plane_height:Number;
	
	public function PlatformLineModel(layer:LayerModel) {
		super(layer);
	}
	
	[Bindable]
	public function get placement_plane_height():Number {
		return _placement_plane_height;
	}

	public function set placement_plane_height(value:Number):void {
		_placement_plane_height = value;
		if (_placement_plane_height && (y1 != y2)) {
			// meet halfway
			y1 = y2 = y1 + int((y2-y1)/2);
		}
	}

	[Bindable]
	public function get is_for_placement():Boolean {
		return _is_for_placement;
	}

	public function set is_for_placement(value:Boolean):void {
		_is_for_placement = value;
		if (value) {
			// trigger the setter
			placement_plane_height = placement_plane_height;
		} else {
			placement_plane_height = 0;
		}
	}

	override public function set r(value:int):void {
		// nope
	}
	
	/** Returns the start of the line */
	override public function get x():Number {
		return x1;
	}
	
	/** Sets the start of the line */
	override public function set x(_x:Number):void {
		const delta:Number = (_x - x1);
		x1 += delta;
		x2 += delta;
	}
	
	/** Returns the start of the line */
	override public function get y():Number {
		return y1;
	}
	
	/** Sets the start of the line */
	override public function set y(_y:Number):void {
		const delta:Number = (_y - y1);
		y1 += delta;
		y2 += delta;
	}
	
	override public function get type():String {
		return DecoModelTypes.PLATFORM_LINE_TYPE;
	}
	
	override public function getState():Object {
		// nope, don't want super.getState()
		const ob:Object = {};
		ob.x1 = x1;
		ob.y1 = y1;
		ob.x2 = x2;
		ob.y2 = y2;
		ob.platform_pc_perm = platform_pc_perm;
		ob.platform_item_perm = platform_item_perm;
		ob.is_for_placement = is_for_placement;
		ob.placement_invoking_set = placement_invoking_set;
		ob.placement_userdeco_set = placement_userdeco_set;
		ob.placement_plane_height = placement_plane_height;
		return ob;
	}
	
	override public function updateModel(platform_line:Object):void {
		tsid = platform_line.tsid;
		name = platform_line.name;
		x1 = platform_line.start.x;
		y1 = platform_line.start.y;
		x2 = platform_line.end.x;
		y2 = platform_line.end.y;
		platform_pc_perm = platform_line.platform_pc_perm;
		platform_item_perm = platform_line.platform_item_perm;
		is_for_placement = platform_line.is_for_placement;
		placement_invoking_set = platform_line.placement_invoking_set;
		placement_userdeco_set = platform_line.placement_userdeco_set;
		placement_plane_height = platform_line.placement_plane_height;
	}
}
}