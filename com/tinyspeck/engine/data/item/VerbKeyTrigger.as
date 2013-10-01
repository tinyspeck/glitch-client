package com.tinyspeck.engine.data.item {		
	
	public class VerbKeyTrigger extends AbstractItemEntity {
		public var key_code:uint;
		public var key_str:String;
		public var verb_tsid:String;
		
		public function VerbKeyTrigger(hashName:String) {
			super(hashName);
			key_code = parseInt(hashName);
		}
	}
}