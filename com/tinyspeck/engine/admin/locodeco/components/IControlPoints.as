package com.tinyspeck.engine.admin.locodeco.components
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	
	public interface IControlPoints
	{
		function set stage(s:Stage):void;
		
		function redraw():void;
		
		/** Since there's no IDisplayObject interface to use */
		function get displayObject():DisplayObject;
	}
}