package com.tinyspeck.engine.data.rook
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class RookedStatus extends AbstractTSDataEntity
	{
		public static const PHASE_BUILD_UP:String = 'build_up';
		public static const PHASE_ANGRY:String = 'angry';
		public static const PHASE_STUNNED:String = 'stunned';
		
		public var loc_tsid:String;
		public var rooked:Boolean;
		public var start_time:int;
		public var strength:int;
		public var vulnerability:String;
		public var vulnerability_ms:int;
		public var vulnerability_start_ms:int;
		public var countdown:Object;
		public var preview_duration_secs:int = 6*60;
		public var messaging:Object = {
			top_txt: '',
			bottom_txt: ''
		};
		public var phase:String;
		public var epicentre:Boolean;  //false if not the epicentre of the attacks
		public var timer:int;  //how much time is left in seconds
		public var max_stun:int;
		public var stun:int;
		public var max_health:int;
		public var health:int;
		public var txt:String;
		public var angry_state:String;
		
		public function RookedStatus(hashName:String){
			super(hashName);
			loc_tsid = hashName;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):RookedStatus {
			var rs:RookedStatus = new RookedStatus(hashName);
			
			for(var j:String in object){
				if(j in rs){
					rs[j] = object[j];
				}
				else{
					resolveError(rs,object,j);
				}
			}
			
			return rs;
		}
	}
}