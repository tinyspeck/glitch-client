package com.tinyspeck.engine.port
{
	import flash.display.Sprite;
	import flash.geom.Point;

	public interface IChatBubble
	{
		function get showing():Boolean;
		function show(msg:String, pt:Point=null, extra_sp:Sprite=null, force_tf_width:int=0, reverse_pointer:Boolean=false):void;
		function hide(callback_when_done:Function=null):void;
		function set scaleX(value:Number):void;
		
	}
}