package com.tinyspeck.engine.data.pc {
	import flash.utils.getTimer;
	
	public class PCSkill extends AbstractPCEntity {
		
		public var tsid:String;
		public var name:String;
		public var desc:String;
		public var total_time:int;
		public var time_remaining:int;
		public var local_time_start:int;
		public var is_accelerated:Boolean;
		
		public function PCSkill(hashName:String) {
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PCSkill {
			var pcSkill:PCSkill = new PCSkill(hashName);
			pcSkill.local_time_start = getTimer();
			for(var j:String in object){
				var val:* = object[j];
				if(j in pcSkill){
					pcSkill[j] = val;
				}else{
					resolveError(pcSkill,object,j);
				}
			}
			return pcSkill;
		}
		
	}
}