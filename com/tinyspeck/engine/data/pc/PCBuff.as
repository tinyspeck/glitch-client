package com.tinyspeck.engine.data.pc
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.engine.ns.client;

	public class PCBuff extends AbstractPCEntity
	{
		public var tsid:String;
		public var name:String;
		public var desc:String;
		public var duration:int;
		public var ticks:int;
		public var ticks_elapsed:int;
		public var is_timer:Boolean = false;
		public var is_debuff:Boolean;
		public var remaining_duration:int;
		public var timer_id:Number;
		public var start_time:Number;
		public var item_class:String;// = 'apple';
		public var swf_url:String; // if the swf is any old swf, not an item swf, specify with swf_url
		client var removed:Boolean = false;
		
		public function PCBuff(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PCBuff
		{
			var buff:PCBuff = new PCBuff(hashName);
			buff.tsid = hashName;
			return PCBuff.updateFromAnonymous(object, buff);
		}
		
		public static function updateFromAnonymous(object:Object, buff:PCBuff):PCBuff {
			for(var j:String in object){
				var val:* = object[j];
				if(j == 'duration'){
					//the server sends this in flots, round them down
					buff.duration = Math.floor(val as Number);
				}else if(j in buff){
					buff[j] = val;
				}else{
					resolveError(buff,object,j);
				}
			}
			
			//if this buff is a timer, but it doesn't have any ticks... let's set it to 1
			if(buff.is_timer && !buff.ticks){
				buff.ticks = 1;
			}
			
			var client_set:Boolean;
			
			if (buff.ticks && !('remaining_duration' in object)) { 
				//no remaining duration set, let the client calculate it based on ticks
				buff.remaining_duration = Math.floor(buff.duration - (buff.ticks_elapsed * (buff.duration / buff.ticks)));
				client_set = true;
				BootError.handleError('Client setting buff remaining_duration (it was not there): ' +
					'\n  tsid-'+buff.tsid+
					'\n  duration-'+buff.duration+
					'\n  ticks-'+buff.ticks+
					'\n  ticks_elapsed-'+buff.ticks_elapsed+
					'\n  client set remaining_duration-'+buff.remaining_duration,
					new Error('Client setting remaining_duration'), ['buff'], true);
			}
			
			//if somehow the remaining is larger than the duration, that's fucked up and we gotta log that
			if(buff.remaining_duration > buff.duration){
				BootError.handleError('buff remaining_duration > duration (client setting remaining to == duration): ' +
					'\n  tsid-'+buff.tsid+
					'\n  duration-'+buff.duration+
					'\n  ticks-'+buff.ticks+
					'\n  ticks_elapsed-'+buff.ticks_elapsed+
					'\n  remaining_duration-'+buff.remaining_duration+
					'\n  client set-'+client_set,
					new Error('remaining_duration > duration'), ['buff'], true);
				
				buff.remaining_duration = buff.duration;
			}
			
			return buff;
		}
	}
}



// http://svn.tinyspeck.com/wiki/SpecBuffs
