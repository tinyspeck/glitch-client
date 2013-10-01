package com.tinyspeck.engine.net {
	public class NetOutgoingRecipeRequestVO extends NetOutgoingMessageVO {
		
		public var class_tsids:Array;
		
		public function NetOutgoingRecipeRequestVO(class_tsids:Array) {
			super(MessageTypes.RECIPE_REQUEST);
			this.class_tsids = class_tsids;
		}
	}
}