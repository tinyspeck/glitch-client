package com.tinyspeck.engine.data.skill
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;

	public class SkillRequirement extends AbstractTSDataEntity
	{
		public static const TYPE_SKILL:String = 'skill';
		public static const TYPE_LEVEL:String = 'level';
		public static const TYPE_ACHIEVEMENT:String = 'achievement';
		public static const TYPE_QUEST:String = 'quest';
		public static const TYPE_UPGRADE:String = 'upgrade';
		
		public var type:String;
		public var class_tsid:String;
		public var name:String;
		public var url:String;
		public var event:String;
		public var got:Boolean;
		public var level:int;
		public var ok:Boolean; //indicates whether or not a skill is ok to learn.
		
		public function SkillRequirement(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):SkillRequirement {
			var skill_req:SkillRequirement = new SkillRequirement(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j in skill_req){
					skill_req[j] = val;
				}
				else if(j == 'skill' || j == 'quest' || j == 'upgrade' || 'achievement'){
					//convert this into something more smart
					skill_req.class_tsid = val;
				}
				else if (j != 'need'){
					resolveError(skill_req,object,j);
				}
			}
			
			//calculate "got" if this is a level
			if(skill_req.type == TYPE_LEVEL && 'need' in object){
				const pc:PC = TSModelLocator.instance.worldModel.pc;
				skill_req.got = pc && pc.level >= object.need;
			}
			
			return skill_req;
		}
		
		public static function updateFromAnonymous(object:Object, skill_req:SkillRequirement):SkillRequirement {
			skill_req = fromAnonymous(object, skill_req.hashName);
			
			return skill_req;
		}
	}
}