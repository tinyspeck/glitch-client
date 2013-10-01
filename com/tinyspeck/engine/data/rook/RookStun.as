package com.tinyspeck.engine.data.rook
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class RookStun extends AbstractTSDataEntity
	{
		public var successful:Boolean;
		public var damage:int;
		public var txt:String;
		public var stunned:Boolean;
		public var attacking:Boolean;
		
		public function RookStun(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):RookStun {
			var stun:RookStun = new RookStun('rook_stun');
			var j:String;
			
			for(j in object){
				if(j in stun){
					stun[j] = object[j];
				}
				else{
					resolveError(stun,object,j);
				}
			}
			
			return stun;
		}
	}
}