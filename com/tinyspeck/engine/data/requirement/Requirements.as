package com.tinyspeck.engine.data.requirement
{
	import com.tinyspeck.engine.util.SortTools;

	public class Requirements
	{		
		/*******************************************************************
		 * Accepts a Requirements Hash formatted object
		 * http://svn.tinyspeck.com/wiki/RequirementsHash
		 * 
		 * Returns a vector of "Requirement" type of all the requirements
		 *******************************************************************/
		
		public static function fromAnonymous(object:Object):Vector.<Requirement> {
			var reqs:Vector.<Requirement> = new Vector.<Requirement>();
			var req:Requirement;
			var k:String;
			
			for(k in object){
				req = Requirement.fromAnonymous(object[k], k);
				reqs.push(req);
			}
			
			//sort it
			reqs.sort(SortTools.requirementsSort);
			
			return reqs;
		}
		
		public static function updateFromAnonymous(object:Object, reqs:Vector.<Requirement>):Vector.<Requirement> {
			reqs = fromAnonymous(object);
			
			return reqs;
		}
	}
}