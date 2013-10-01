package com.tinyspeck.engine.spritesheet
{
import de.polygonal.core.IPoolableObject;

internal class SSCallback implements IPoolableObject {
	public var callback:Function;
	public var sheet:SSAbstractSheet;
	public var url:String;
	
	public function run():void {
		callback(sheet, url);
	}

	public function reset():void {
		callback = null;
		sheet = null;
		url = null;
	}
}
}