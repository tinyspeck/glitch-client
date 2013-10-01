package com.tinyspeck.engine.data.skill
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.SortTools;

	public class SkillDetails extends AbstractTSDataEntity
	{
		public var skill_id:int;
		public var class_tsid:String;
		public var name:String;
		public var url:String;
		public var description:String;
		public var seconds:int;
		public var unlearn_seconds:int;
		public var learning:Boolean;
		public var unlearning:Boolean;
		public var can_learn:Boolean;
		public var can_unlearn:Boolean;
		public var got:Boolean;
		public var paused:Boolean;
		public var reqs:Vector.<SkillRequirement> = new Vector.<SkillRequirement>();
		public var post_reqs:Vector.<SkillRequirement> = new Vector.<SkillRequirement>();
		public var giants:Vector.<SkillGiant> = new Vector.<SkillGiant>();
		public var icon_44:String;
		public var icon_100:String;
		public var icon_460:String;
		
		public function SkillDetails(hashName:String){
			class_tsid = hashName;
			super(hashName);
		}
		
		public static function parseMultiple(object:Object):Vector.<SkillDetails> {
			var V:Vector.<SkillDetails> = new Vector.<SkillDetails>();
			
			for(var j:String in object){
				V.push(fromAnonymous(object[j],j));
			}
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):SkillDetails {
			var skill_details:SkillDetails = new SkillDetails(hashName);
			var val:*;
			var j:String;
			var k:String;
			var count:int;
			var req:SkillRequirement;
			var giant:SkillGiant;
			
			for(j in object){
				val = object[j];
				if(j == 'reqs'){
					count = 0;
					while(val && val[count]){
						req = SkillRequirement.fromAnonymous(val[count], 'req'+count);
						skill_details.reqs.push(req);
						count++;
					}
					
					//sort them
					SortTools.vectorSortOn(skill_details.reqs, ['type', 'name'], [Array.CASEINSENSITIVE, Array.CASEINSENSITIVE]);
				}
				else if(j == 'post_reqs'){
					count = 0;
					while(val && val[count]){
						req = SkillRequirement.fromAnonymous(val[count], 'post_req'+count);
						skill_details.post_reqs.push(req);
						count++;
					}
					
					//sort them
					SortTools.vectorSortOn(skill_details.post_reqs, ['type', 'name'], [Array.CASEINSENSITIVE, Array.CASEINSENSITIVE]);
				}
				else if(j == 'giants'){
					count = 0;
					while(val && val[count]){
						giant = SkillGiant.fromAnonymous(val[count], 'giant'+count);
						skill_details.giants.push(giant);
						count++;
					}
				}
				//do some mapping from different API methods
				else if(j == 'total_time'){
					skill_details.seconds = val;
				}
				else if(j == 'unlearn_time'){
					skill_details.unlearn_seconds = val;
				}
				else if(j == 'required_level'){
					req = new SkillRequirement('level');
					req.type = SkillRequirement.TYPE_LEVEL;
					req.level = val;
				}
				else if(j == 'required_skills' || j == 'time_remaining' || j == 'time_start' || j == 'time_complete'){
					//don't do anything here
				}
				else if(j in skill_details){
					skill_details[j] = val;
				}
				else {
					resolveError(skill_details,object,j);
				}
			}
			
			//if the skill ID isn't set, let's set it
			if(!skill_details.skill_id && skill_details.url){
				var pattern:RegExp = new RegExp('[^0-9]', 'g');
				skill_details.skill_id = int(skill_details.url.replace(pattern, ''));
			}
			
			return skill_details;
		}
		
		public static function updateFromAnonymous(object:Object, skill_details:SkillDetails):SkillDetails {
			skill_details = fromAnonymous(object, skill_details.hashName);
			
			return skill_details;
		}
		
		public function getGiants(is_primary:Boolean):Vector.<SkillGiant> {
			var g:Vector.<SkillGiant> = new Vector.<SkillGiant>();
			var i:int;
			
			for(i; i < giants.length; i++){
				if(giants[int(i)].primary && is_primary){
					g.push(giants[int(i)]);
				}
				else if(!giants[int(i)].primary && !is_primary){
					g.push(giants[int(i)]);
				}
			}
			
			return g;
		}
	}
}