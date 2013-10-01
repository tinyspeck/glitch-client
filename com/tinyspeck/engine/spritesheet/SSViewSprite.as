package com.tinyspeck.engine.spritesheet
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	
	public class SSViewSprite extends Sprite implements ISpriteSheetView
	{
		public var smooth:Boolean = true;
		
		private var _sequenceA:Array = [];
		private var _sequence_index:int = 0;
		private var _ss:SSAbstractSheet;
		private var _is_playing:Boolean;
		private var _do_loop:Boolean = false;
		internal var _curr_frame_num:int;
		internal var _curr_frame:SSFrame;
		internal var _curr_frame_coll:SSFrameCollection;
		private var _frame_coll_names_usedA:Array = [];
		
		internal var displayShape:Shape;
		public var displayFilterSprite:Sprite;
		public var displayFilterShape:Shape;
		private var _interaction_target:DisplayObject;
		
		public function SSViewSprite(spriteSheet:SSAbstractSheet) {
			super();
			_ss = spriteSheet;
			init();
		}
		
		private function init():void {
			mouseChildren = false;
			/*
			For experimenting with a custom DO for glowing
			
			displayFilterSprite = new Sprite();
			displayFilterSprite.name = 'displayFilterSprite';
			displayFilterSprite.visible = false;
			addChild(displayFilterSprite);
			
			displayFilterShape = new Shape();
			displayFilterShape.name = 'displayFilterShape';
			displayFilterSprite.addChild(displayFilterShape);
			*/
			displayShape = new Shape();
			displayShape.name = 'displayShape';
			addChild(displayShape);
			_curr_frame_num = 0;
		}
		
		public function get ss():SSAbstractSheet {
			return _ss;
		}
		
		private var sequenceDoneCallback:Function;
		public function update():void {
			if(_is_playing && _curr_frame_coll && _curr_frame_coll.frames){
				var next_frame_num:int = _curr_frame_num+1;
				var length:int = _curr_frame_coll.frames.length;
				
				if (next_frame_num >= length) {
					if (_do_loop && !_sequenceA.length) { // if we're not in a sequence and we should loop
						//make sure this does not exceed length
						next_frame_num = Math.min(
							length-1, 
							_curr_frame_coll.loops_from+(next_frame_num%length)
						);
					} else {
						if (_sequenceA.length) { // we're in a sequence
							_sequence_index++;
							if (_sequence_index < _sequenceA.length) { // there is a next one
								gotoFrame(0, _sequenceA[_sequence_index]);
								return;
							} else if (_do_loop) { // there is no next one, but we should loop
								_sequence_index = 0;
								gotoFrame(0, _sequenceA[_sequence_index]);
								return;
							} else {
								// fall through to the stop() below, because the sequence is over
								// (not that _sequence_index ends up out of range in this case; should not be a problem though)
								if (sequenceDoneCallback != null) {
									sequenceDoneCallback(true);
									sequenceDoneCallback = null;
								}
							}
							
						} 
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
			if (!_curr_frame_coll) {
				//Console.warn('I have no _curr_frame_coll');
				return '';
			}
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
		
		public function gotoAndPlaySequence(sequenceA:Array, callBack:Function=null):void {
			if (sequenceDoneCallback != null) {
				sequenceDoneCallback(false);
			}
			
			sequenceDoneCallback = callBack;
			
			_sequenceA = sequenceA;
			
			for (var i:int=0;i<_sequenceA.length;i++) {
				if (_frame_coll_names_usedA.indexOf(_sequenceA[int(i)]) == -1) _frame_coll_names_usedA.push(_sequenceA[int(i)]);
			}
			
			_sequence_index = 0;
			gotoFrame(0, _sequenceA[_sequence_index]);
			play();
		}
		
		// it is unlcear what callBack should do here, so it does nothing
		public function gotoAndLoopSequence(sequenceA:Array, callBack:Function=null):void {
			if (sequenceDoneCallback != null) {
				sequenceDoneCallback(false);
			}
			
			_sequenceA = sequenceA;
			_sequence_index = 0;
			gotoFrame(0, _sequenceA[_sequence_index]);
			loop();
		}
		
		public function get interaction_target():DisplayObject {
			return _interaction_target;
		}
		
		public function glow(filtersA:Array):void {
			if (!_interaction_target){
				if (displayFilterSprite) {
					displayFilterSprite.filters = StaticFilters.tsSpriteKnockout_GlowA;
					displayFilterSprite.visible = true;
				} else {
					filters = filtersA;
				}
			} else {
				_interaction_target.visible = true;
				_interaction_target.filters = StaticFilters.tsSpriteKnockout_GlowA;
			}
		}
		
		public function unglow():void {
			if(!_interaction_target){
				if (displayFilterSprite) {
					displayFilterSprite.filters = null;
					displayFilterSprite.visible = false;
				} else {
					filters = null;
				}
			}else{
				_interaction_target.filters = null;
				_interaction_target.visible = false;
			}
		}
		
		public function gotoAndPlay(frame:Object, frame_coll_name:String = null):void {
			_sequenceA = [];
			gotoFrame(frame, frame_coll_name);
			play();
		}
		
		public function gotoAndLoop(frame:Object, frame_coll_name:String = null):void {
			_sequenceA = [];
			gotoFrame(frame, frame_coll_name);
			loop();
		}
		
		public function gotoAndStop(frame:Object, frame_coll_name:String = null):void {
			_sequenceA = [];
			gotoFrame(frame, frame_coll_name);
			stop();
		}
		
		private function gotoFrame(frame:Object, frame_coll_name:String = null):void {
			//Check out the frame_coll_name.
			if (frame_coll_name) {
				if (!_curr_frame_coll || _curr_frame_coll.name != frame_coll_name) {
					var new_frame_coll:SSFrameCollection = _ss.getFrameCollectionByName(frame_coll_name);
					
					if (new_frame_coll) {
						_curr_frame_coll = new_frame_coll;
					} else {
						
					}
				}
			}
			
			if (_curr_frame_coll == null) {
				_curr_frame_coll = _ss.getFirstFrameCollection();
			}
			
			if (_curr_frame_coll) {
				if (_frame_coll_names_usedA.indexOf(_curr_frame_coll.name) == -1) _frame_coll_names_usedA.push(_curr_frame_coll.name);
				
				var ssFrame:SSFrame;
				if (frame is int) {
					ssFrame = _curr_frame_coll.getFrameByNumber(int(frame));
				} else if (frame is String) {
					ssFrame = _curr_frame_coll.getFrameByName(String(frame));
				}
				
				if (!ssFrame) {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('no ssFrame?')
					}
				}
				
				if (ssFrame && ssFrame != _curr_frame) {
					_curr_frame_num = ssFrame._number;
					_curr_frame = ssFrame;
					_ss.updateViewSprite(this);
				}
				
				if(ssFrame && ssFrame.interaction_target){ 
					//remove one if there is one already
					if (_interaction_target && _interaction_target.parent) {
						_interaction_target.parent.removeChild(_interaction_target);
					}
					
					//place the interaction target on the spritesheet
					_interaction_target = new Bitmap(ss.intTargetBitmaps[ssFrame.int_target_bmd_index]);
					_interaction_target.x = ssFrame.interaction_target.x;
					_interaction_target.y = ssFrame.interaction_target.y;
					_interaction_target.visible = false;
					
					addChild(_interaction_target);
				} 
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('NO USED? frame_coll_name '+frame_coll_name)
				}
			}
		}
		
		public function dispose():void {
			if (parent) parent.removeChild(this);
			_curr_frame = null;
			_curr_frame_coll = null;
			_ss = null;
		}
	}
}