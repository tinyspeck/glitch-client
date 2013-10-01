package com.tinyspeck.engine.view
{
	import flash.display.DisplayObject;
	
	public interface ITipProvider {
		
		function getTip(tip_target:DisplayObject = null):Object;
	} 
}