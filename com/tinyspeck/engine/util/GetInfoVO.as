package com.tinyspeck.engine.util {
	import com.tinyspeck.debug.Console;
	
	public class GetInfoVO {
		public static const TYPE_ITEM:String = 'item';
		public static const TYPE_SKILL:String = 'skill';
		
		public var type:String;
		public var skill_class:String;
		public var item_class:String;
		public var itemstack_tsid:String;
		
		public function GetInfoVO(type:String) {
			CONFIG::debugging {
				if (type != TYPE_ITEM && type != TYPE_SKILL) {
					Console.error('WTF '+type);
				}
			}
			this.type = type;
		}
		
	}
}