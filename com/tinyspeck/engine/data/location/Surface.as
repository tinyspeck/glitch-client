package com.tinyspeck.engine.data.location
{
public class Surface extends AbstractPositionableLocationEntity
{
	public var w:Number = 0;
	public var h:Number = 0;
	public var tiling:Tiling;
	
	public function Surface(hashName:String) {
		super(hashName);
	}
	
	override public function AMF():Object {
		const ob:Object = super.AMF();
		ob.w = w;
		ob.h = h;
		if (tiling) ob.tiling = tiling.AMF();
		return ob;
	}
}
}