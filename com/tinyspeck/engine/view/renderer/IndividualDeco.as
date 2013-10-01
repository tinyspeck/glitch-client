package com.tinyspeck.engine.view.renderer
{
/** Helper class for DecoByteLoader */
internal final class IndividualDeco {
	public var class_name:String;
	public var complete_func:Function;
	
	public function IndividualDeco(class_name:String, complete_func:Function) {
		this.class_name = class_name;
		this.complete_func = complete_func;
	}
}
}