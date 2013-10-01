package com.tinyspeck.engine.data.requirement
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class Requirement extends AbstractTSDataEntity
	{		
		public var id:String;
		public var is_count:Boolean;
		public var is_work:Boolean;
		public var completed:Boolean;
		public var disabled:Boolean;
		
		public var item_class:String;
		public var item_classes:Array;
		public var desc:String;
		public var disabled_reason:String;
		public var verb:RequirementVerb;
		
		public var need_num:int;
		public var got_num:int;
		public var base_cost:int;
		public var energy:int; //how many energy units this requirement takes
		
		public function Requirement(hashName:String){
			super(hashName);
			id = hashName;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Requirement {
			var req:Requirement = new Requirement(hashName);
			var val:*;
			var count:int;
			
			for(var i:String in object){
				val = object[i];
				if(i in req){
					if(i == 'verb'){
						req.verb = RequirementVerb.fromAnonymous(val, i);
					}
					else if(i == 'item_classes' && val){
						req.item_classes = [];
						count = 0;
						while(val[count]){
							req.item_classes.push(val[count]);
							count++;
						}
					}
					else {
						req[i] = val;
					}
				}
				else{
					resolveError(req,object,i);
				}
			}
			
			return req;
		}
		
		public static function updateFromAnonymous(object:Object, req:Requirement):Requirement 
		{
			req = fromAnonymous(object, req.hashName);
			
			return req;
		}
	}
}