package com.tinyspeck.engine.data.craftybot
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class CraftyStatus extends AbstractTSDataEntity
	{
		public var is_complete:Boolean;
		public var is_active:Boolean;
		public var is_missing:Boolean;
		public var is_paused:Boolean;
		public var is_locked:Boolean;
		public var is_halted:Boolean;
		public var txt:String;
		
		public function CraftyStatus(){
			super('CraftyStatus');
		}
		
		public static function fromAnonymous(object:Object):CraftyStatus {
			const status:CraftyStatus = new CraftyStatus();
			var k:String;
			
			for(k in object){
				if(k in status){
					status[k] = object[k];
				}
				else {
					resolveError(status, object, k);
				}
			}
			
			return status;
		}
	}
}