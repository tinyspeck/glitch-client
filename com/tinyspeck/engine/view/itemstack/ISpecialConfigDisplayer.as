package com.tinyspeck.engine.view.itemstack
{
	import flash.display.DisplayObject;

	public interface ISpecialConfigDisplayer
	{
		function removeSpecialConfigDO(specialConfigID:String):String;
		function addToSpecialBack(DO:DisplayObject):void;
		function addToSpecialFront(DO:DisplayObject):void;
	}
}