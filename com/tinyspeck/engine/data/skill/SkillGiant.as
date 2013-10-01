package com.tinyspeck.engine.data.skill
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.giant.Giants;

	public class SkillGiant extends AbstractTSDataEntity
	{
		public var name:String;
		public var primary:Boolean;
		
		public function SkillGiant(hashName:String)	{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):SkillGiant {
			var skill_giant:SkillGiant = new SkillGiant(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j in skill_giant){
					skill_giant[j] = val;
				}
				else if(j == 'id'){
					//map funky var from API
					skill_giant.name = val;
				}
				else if(j == 'is_primary'){
					//map funky var from API
					skill_giant.primary = val;
				}
				else{
					resolveError(skill_giant,object,j);
				}
			}
			
			if (skill_giant.name == 'ti') skill_giant.name = 'tii';
			
			return skill_giant;
		}
		
		public static function updateFromAnonymous(object:Object, skill_giant:SkillGiant):SkillGiant {
			skill_giant = fromAnonymous(object, skill_giant.hashName);
			
			return skill_giant;
		}
		
		public function get giant_name():String {
			return Giants.getLabel(name);
		}
	}
}