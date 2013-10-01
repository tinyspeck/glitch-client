package com.tinyspeck.engine.physics.avatar
{
	final public class PhysicsParameter
	{
		public static const TYPE_NUM:String = 'TYPE_NUM';
		public static const TYPE_INT:String = 'TYPE_INT';
		public static const TYPE_BOOL:String = 'TYPE_BOOL';
		
		public var name:String;
		public var label:String;
		public var type:String;
		public var min:Number;
		public var max:Number;
		
		public function PhysicsParameter(name:String, label:String, min:Number, max:Number, type:String)
		{
			this.name = name;
			this.label = label;
			this.min = min;
			this.max = max;
			this.type = type;
			
			if (this.type == TYPE_BOOL) {
				this.min = 0;
				this.max = 1;
			}
		}
	}
}