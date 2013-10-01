package com.tinyspeck.engine.data.pc
{

	public class PCStatValue extends AbstractPCEntity
	{
		public var value:Number;
		public var max:Number;
		
		public function PCStatValue(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PCStatValue
		{
			var pcStatValue:PCStatValue = new PCStatValue(hashName);
			for(var j:String in object){
				if(j in pcStatValue){
					pcStatValue[j] = object[j];
				}else{
					resolveError(pcStatValue,object,j);
				}
			}
			return pcStatValue;
		}
	}
}