package com.tinyspeck.engine.control.engine {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.spritesheet.AnimationSequenceCommand;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class AnimationSequenceController {
		
		private var mc:MovieClip;
		private var asc:AnimationSequenceCommand;
		private var asc_for_after_label:AnimationSequenceCommand;
		private var asc_for_after_seq:AnimationSequenceCommand;
		private var current_label:String;
		private var startingCallback:Function;
		private var _labelStartingCallback:Function;
		private var _labelCompleteCallback:Function;
		private var _sequenceCompleteCallback:Function;
		
		public function set labelStartingCallback(value:Function):void { _labelStartingCallback = value; }
		public function set labelCompleteCallback(value:Function):void { _labelCompleteCallback = value; }
		public function set sequenceCompleteCallback(value:Function):void { _sequenceCompleteCallback = value; }
		
		public function AnimationSequenceController(asc:AnimationSequenceCommand) {
			this.asc = asc;
		}
		
		public function setMC(mc:MovieClip):void {
			this.mc = mc;
			if (mc.trackFrames) {
				mc.console = Console;
				mc.trackFrames();
				mc.addEventListener('ANIMATION_STARTING', labelStartingHandler);
				mc.addEventListener('ANIMATION_COMPLETE', labelCompleteHandler);
				mc.addEventListener('SEQUENCE_COMPLETE', sequenceCompleteHandler);
				playImmediately(asc_for_after_label || asc_for_after_seq || asc);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('this item swf does not have a trackFrames method. probably need to recompile the swf with the latest timeline_animation.as');
				}
			}
		}
		
		// get called when a sequence ends, even if it is looping
		private function sequenceCompleteHandler(e:Event):void {
			//Console.warn(mc.animatee.currentFrameLabel);
			if (asc_for_after_seq) {
				playSequence(asc_for_after_seq);
				asc_for_after_seq = null;
			}
			if (_sequenceCompleteCallback != null) _sequenceCompleteCallback(this, asc);
		}
		
		private function labelStartingHandler(e:Event):void {
			current_label = mc.animatee.currentFrameLabel;
			
			if (_labelStartingCallback != null) _labelStartingCallback(this, asc);
			//Console.warn(mc.animatee.currentFrameLabel);
		}
		
		private function labelCompleteHandler(e:Event):void {
			//Console.warn(mc.animatee.currentFrameLabel);
			
			if (asc_for_after_label) {
				playSequence(asc_for_after_label);
				asc_for_after_label = null;
			}
			
			if (_labelCompleteCallback != null) _labelCompleteCallback(this, asc);
		}
		
		// will start playing the passed sequence as soon as the current frame label is finished, no matter
		// where it is in the current sequence.
		// TODO If the mc has stopped, it will play the passed sequence immediately.
		public function playAfterCurrentLabel(asc:AnimationSequenceCommand):void {
			/*var is_stopped:Boolean;
			if (is_stopped) {
				playImmediately(asc);
				return;
			}*/
			
			asc_for_after_label = asc;
			asc_for_after_seq = null;
		}
		
		// will start playing the passed sequence as soon as the current sequence is finished.
		// TODO If the mc has stopped, it will play the passed sequence immediately.
		public function playAfterCurrentSequence(asc:AnimationSequenceCommand):void {
			var is_stopped:Boolean;
			if (is_stopped) {
				playImmediately(asc);
				return;
			}
			
			asc_for_after_label = null;
			asc_for_after_seq = asc;
		}
		
		public function playImmediately(asc:AnimationSequenceCommand):void {
			asc_for_after_label = null;
			asc_for_after_seq = null;
			playSequence(asc);
		}
		
		private var play_tim:int;
		private function playSequence(asc:AnimationSequenceCommand):void {
			//this.asc = asc;
			var self:AnimationSequenceController = this;
			//Console.warn(asc.A+' '+asc.loop);
			if (play_tim) StageBeacon.clearTimeout(play_tim);
			if (mc) {
				// This needs to be in a timeout, because this can be triggered by an event dispatch from mc.onEnterFrame,
				// which we need to let complete before we issue another playAnimationSeq() call, else shits stomps on itself 
				play_tim = StageBeacon.setTimeout(function():void {
					try {
						self.asc = asc;
						mc.playAnimationSeq(asc.A.concat(), asc.loop, null, asc.loops_from);
					} catch (err:Error) {
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('this item swf seems to not accept 4 args to playAnimationSeq(). probably need to recompile the swf with the latest timeline_animation.as');
						}
					}
				}, 0);
			}
		}
	}
}