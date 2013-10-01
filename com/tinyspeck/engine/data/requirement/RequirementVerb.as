package com.tinyspeck.engine.data.requirement
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class RequirementVerb extends AbstractTSDataEntity
	{		
		public var name:String;
		public var past_tense:String;
		
		public function RequirementVerb(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):RequirementVerb {
			var verb:RequirementVerb = new RequirementVerb(hashName);
			var val:*;
			
			for(var i:String in object){
				val = object[i];
				if(i in verb){
					verb[i] = val;
				}
				else {
					resolveError(verb,object,i);
				}
			}
			
			return verb;
		}
		
		public static function updateFromAnonymous(object:Object, verb:RequirementVerb):RequirementVerb
		{
			verb = fromAnonymous(object, verb.hashName);
			
			return verb;
		}
	}
}