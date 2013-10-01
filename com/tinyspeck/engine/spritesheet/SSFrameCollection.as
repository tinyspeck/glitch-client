package com.tinyspeck.engine.spritesheet
{	
	import com.tinyspeck.debug.Console;
	
	import flash.display.BitmapData;

	public class SSFrameCollection 
	{
		public static const GOTOANDPLAY:String = 'gotoAndPlay';
		public static const GOTOANDLOOP:String = 'gotoAndLoop';
		public static const GOTOANDSTOP:String = 'gotoAndStop';
		
		private var _name:String;
		internal var _ss:SSAbstractSheet;
		private var _default_action:String = SSFrameCollection.GOTOANDSTOP;
		private var _loops_from:int = 0;
		public var using_avatar_placeholder:Boolean;
		
		internal var frames:Vector.<SSFrame>;
		
		public function SSFrameCollection(spriteSheet:SSAbstractSheet,name:String)
		{
			_name = name;
			_ss = spriteSheet;
			init();
		}
		
		private function init():void
		{
			frames = new Vector.<SSFrame>();
		}
		
		public function set default_action(s:String):void {
			if (s == SSFrameCollection.GOTOANDLOOP || s == SSFrameCollection.GOTOANDPLAY) {
				_default_action = s;
			} else {
				_default_action = SSFrameCollection.GOTOANDSTOP;
			}
		}
		
		public function get default_action():String {
			if (_default_action == SSFrameCollection.GOTOANDLOOP || _default_action == SSFrameCollection.GOTOANDPLAY) {
				return _default_action;
			} else {
				return SSFrameCollection.GOTOANDSTOP;
			}
		}
		
		public function set loops_from(i:int):void {
			_loops_from = i;
		}
		
		public function get loops_from():int {
			return _loops_from;
		}
		
		public function get name():String {
			return _name;
		}
		
		public function getbmds():Vector.<BitmapData> {
			if (!(_ss is SSMultiBitmapSheet)) return null;
			
			var V:Vector.<BitmapData> = new Vector.<BitmapData>;
			for (var i:int=0;i<frames.length;i++) {
				V.push((_ss as SSMultiBitmapSheet).bmds[frames[i]._bmd_index]);
			}
			return V;
		}
		
		internal function getFrameByNumber(frame:int):SSFrame
		{
			if(frames){
				if (frames.length == 0) {
					; // satisfy compiler
					CONFIG::debugging {
						Console.log(111, "no frames "+_name+' f:'+frame+' l:'+frames.length);
					}
				} else if(frame < frames.length && frame >= 0){
					return frames[int(frame)];
				}else{
					return frames[frames.length-1];
					//throw new Error("frame out of range "+_name+' f:'+frame+' l:'+frames.length);
					/*if (loop) {
						//loop:
						frame = frame%frames.length;
						return frames[int(frame)];
					} else {
						// advance not past the end:
						return frames[frames.length-1];
					}*/
				}
			}
			return null;
		}
		
		internal function getFrameByName(name:String):SSFrame
		{
			var frame:SSFrame;
			var fl:int = frames.length;
			for(var i:int = 0; i<fl; i++){
				frame = frames[int(i)];
				if(frame._name == name){
					return frame;
				}
			}
			return null;
		}
		
		internal function addFrame(frame:SSFrame):void
		{
			frame._number = frames.push(frame)-1;
		}
		
		internal function dispose():void
		{
			var frame:SSFrame;
			while(frames.length){
				frame = frames.pop();
				frame.dispose();
			}
		}
		
	}
}