package com.tinyspeck.engine.spritesheet
{
	import flash.display.Bitmap;
	

	public class SSViewBitmap extends Bitmap implements ISpriteSheetView
	{
		private var _ss:SSAbstractSheet;
		private var _is_playing:Boolean;
		private var _do_loop:Boolean = false;
		private var _curr_frame_num:int;
		internal var _curr_frame:SSFrame;
		internal var _curr_frame_coll:SSFrameCollection;
		private var _frame_coll_names_usedA:Array = [];
		
		public function SSViewBitmap(sheet:SSAbstractSheet)
		{
			super();
			smoothing = true;
			_ss = sheet;
			init();
		}
		
		private function init():void	
		{
			_curr_frame_num = 0;
		}
		
		public function get ss():SSAbstractSheet {
			return _ss;
		}
		
		public function update():void
		{
			if(_is_playing){
				var next_frame_num:int = _curr_frame_num+1;
				var length:int = _curr_frame_coll.frames.length;
				
				if (next_frame_num >= length) {
					if (_do_loop) {
						//make sure this does not exceed length
						next_frame_num = Math.min(
							length-1, 
							_curr_frame_coll.loops_from+(next_frame_num%length)
						);
					} else {
						stop();
						return;
					}
				}
				
				gotoFrame(next_frame_num);
			}
		}
		
		public function get is_playing():Boolean {
			return _is_playing;
		}
		
		public function get frame_coll_name():String {
			return _curr_frame_coll.name;
		}
		
		public function get frame_coll_names_usedA():Array {
			return _frame_coll_names_usedA;
		}
		
		public function get will_loop():Boolean {
			return _do_loop;
		}
		
		public function play():void {
			_do_loop = false;
			_is_playing = true;
		}
		
		public function loop():void {
			_do_loop = true;
			_is_playing = true;
		}
		
		public function stop():void {
			_is_playing = false;
		}
		
		public function gotoAndPlay(frame:Object, frame_coll_name:String = null):void {
			gotoFrame(frame, frame_coll_name);
			play();
		}
		
		public function gotoAndLoop(frame:Object, frame_coll_name:String = null):void {
			gotoFrame(frame, frame_coll_name);
			loop();
		}
		
		public function gotoAndStop(frame:Object, frame_coll_name:String = null):void {
			gotoFrame(frame, frame_coll_name);
			stop();
		}
		
		private function gotoFrame(frame:Object, frameCollection:String = null):void
		{
			//Check out the frameCollection.
			if(frameCollection != null && frameCollection != ""){
				if(_curr_frame_coll){
					if(_curr_frame_coll.name != frameCollection){
						_curr_frame_coll = _ss.getFrameCollectionByName(frameCollection);
					}
				}else{
					_curr_frame_coll = _ss.getFrameCollectionByName(frameCollection);
				}
			}else if(_curr_frame_coll == null){
				_curr_frame_coll = _ss.getFirstFrameCollection();
			}
			if(_curr_frame_coll){
				if (_frame_coll_names_usedA.indexOf(_curr_frame_coll.name) == -1) _frame_coll_names_usedA.push(_curr_frame_coll.name);
				var ssFrame:SSFrame;
				if(frame is int){
					ssFrame = _curr_frame_coll.getFrameByNumber(int(frame));
				}else if(frame is String){
					ssFrame = _curr_frame_coll.getFrameByName(String(frame));
				}
				if(ssFrame != _curr_frame){
					_curr_frame_num = ssFrame._number;
					_curr_frame = ssFrame;
					_ss.updateViewBitmapData(this);
				}
			}
		}
		
		public function dispose():void
		{
			if(parent){
				parent.removeChild(this);
			}
			_curr_frame = null;
			_curr_frame_coll = null;
			_ss = null;
		}
	}
}