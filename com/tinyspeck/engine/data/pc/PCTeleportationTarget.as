package com.tinyspeck.engine.data.pc
{
	public class PCTeleportationTarget extends AbstractPCEntity
	{
		
		public var tsid:String;
		public var x:int;
		public var y:int;
		public var label:String;
		
		public function PCTeleportationTarget(hashName:String) {
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PCTeleportationTarget
		{
			var teleportation_target:PCTeleportationTarget = new PCTeleportationTarget(hashName);
			for(var j:String in object){
				if(j in teleportation_target){
					teleportation_target[j] = object[j];
				}
				else{
					resolveError(teleportation_target,object,j);
				}
			}
			return teleportation_target;
		}
	}
}