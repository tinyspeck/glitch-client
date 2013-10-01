package com.tinyspeck.engine.data.pc {
	public class PCFamiliar extends AbstractPCEntity {
		
		public var tsid:String;
		public var accelerated:Boolean;
		public var messages:uint;
		
		public function PCFamiliar(){
			super('familiar');
		}
		
		public static function fromAnonymous(object:Object):PCFamiliar {
			var pc_fam:PCFamiliar = new PCFamiliar();
			var j:String;
			
			for(j in object){
				if(j in pc_fam){
					pc_fam[j] = object[j];
				}else{
					resolveError(pc_fam,object,j);
				}
			}
			
			return pc_fam;
		}
	}
}