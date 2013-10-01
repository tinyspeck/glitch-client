package com.tinyspeck.engine.data.itemstack {
	
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.ObjectUtil;
	

	public class ItemstackStatus extends AbstractTSDataEntity {
		public var verb_states:Object;
		public var msg:String;
		public var is_tend_verbs:Boolean;
		public var is_rook_verbs:Boolean;
		private var sig:String;
		public var is_dirty:Boolean;
		
		public function ItemstackStatus(hashName:String) {
			super(hashName);
		}
		
		public function reset():void {
			verb_states = null;
			msg = null;
			is_tend_verbs = false;
			is_rook_verbs = false;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):ItemstackStatus {
			var istatus:ItemstackStatus = new ItemstackStatus(hashName);
			
			return ItemstackStatus.updateFromAnonymous(object, istatus);
		}
		
		public static function updateFromAnonymous(object:Object, istatus:ItemstackStatus):ItemstackStatus {
			for(var j:String in object){
				if(j in istatus){
					istatus[j] = object[j];
				}else{
					resolveError(istatus,object,j);
				}
			}
			var sig:String = ObjectUtil.makeSignatureForHash(object);
			if (sig != istatus.sig) {
				//Console.warn('istatus.sig:'+istatus.sig)
				//Console.warn('sig:'+sig)
				istatus.is_dirty = true;
			}
			istatus.sig = sig;
			return istatus;
		}
		
		public static function resetAndUpdateFromAnonymous(object:Object, istatus:ItemstackStatus):ItemstackStatus {
			istatus.reset();
			
			return updateFromAnonymous(object, istatus);
		}
	}
}