package com.tinyspeck.engine.data.pc
{
	public class PCXP extends AbstractPCEntity
	{
		public var base:Number;
		public var nxt:Number;
		public var total:Number;
		
		public function PCXP(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PCXP
		{
			var pcXP:PCXP = new PCXP(hashName);
			for(var j:String in object){
				if(j in pcXP){
					pcXP[j] = object[j];
				}else{
					resolveError(pcXP,object,j);
				}
			}
			return pcXP;
		}
	}
}