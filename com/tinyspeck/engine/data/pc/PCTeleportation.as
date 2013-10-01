package com.tinyspeck.engine.data.pc
{
	public class PCTeleportation extends AbstractPCEntity
	{
		public var has_teleportation_skill:Boolean;
		public var can_set_target:Boolean;
		public var can_teleport:Boolean;
		public var energy_cost:int;
		public var targets:Vector.<PCTeleportationTarget> = new Vector.<PCTeleportationTarget>();
		public var tokens_remaining:int;
		public var map_tokens_used:int;
		public var map_tokens_max:int; //how many they can use in a game day
		public var map_free_used:int;
		public var map_free_max:int; //how many they can use in a game day
		public var skill_level:int;
		
		public function PCTeleportation(hashName:String) {
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PCTeleportation
		{
			var teleportation:PCTeleportation = new PCTeleportation(hashName);
			var j:String;
			var val:*;
			var count:int;
			
			for(j in object){
				val = object[j];
				if(j == 'targets'){
					count = 1;
					while(val && val[count]){
						teleportation.targets.push(PCTeleportationTarget.fromAnonymous(val[count], 'target'+count));
						count++;
					}
				}
				else if(j in teleportation){
					teleportation[j] = val;
				}
				else{
					resolveError(teleportation,object,j);
				}
			}
			return teleportation;
		}
	}
}