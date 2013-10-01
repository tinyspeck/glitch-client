package com.tinyspeck.engine.spritesheet {
	
	public class AnimationSequenceCommand {
		
		public var A:Array;
		public var loop:Boolean;
		public var loops_from:uint;
		public var name:String = '';
		
		public function AnimationSequenceCommand(A:Array=null, loop:Boolean=false, loops_from:uint=0) {
			this.A = A;
			this.loop = loop;
			this.loops_from = loops_from;
		}
	}
}