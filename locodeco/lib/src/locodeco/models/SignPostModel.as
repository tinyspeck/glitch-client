package locodeco.models
{
public class SignPostModel extends GeoModel
{
	public function SignPostModel(layer:LayerModel) {
		super(layer);
	}
	
	override public function updateModel(signpost:Object):void {
		originalWidth  = signpost.w;
		originalHeight = signpost.h;
		tsid = signpost.tsid;
		name = signpost.name;
		x = signpost.x;
		y = signpost.y;
		r = signpost.r;
	}
	
	override public function get type():String {
		return DecoModelTypes.SIGNPOST_TYPE;
	}
}
}