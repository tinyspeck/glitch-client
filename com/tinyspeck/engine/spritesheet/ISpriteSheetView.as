package com.tinyspeck.engine.spritesheet
{
	public interface ISpriteSheetView extends ISpriteSheetUpdateable
	{
		function dispose():void;
		function get ss():SSAbstractSheet;
		
		function get is_playing():Boolean;
		
		function get frame_coll_names_usedA():Array;
		
		function get frame_coll_name():String;
		
		function get will_loop():Boolean;
		
		function play():void;
		
		function loop():void;
		
		function stop():void;

		function gotoAndPlay(frame:Object, frame_coll_name:String = null):void;
		
		function gotoAndLoop(frame:Object, frame_coll_name:String = null):void;
		
		function gotoAndStop(frame:Object, frame_coll_name:String = null):void;
	}
}