package com.tinyspeck.engine.data.pc
{
	public class PCStats extends AbstractPCEntity
	{
		public var p_limit:PCStatValue;
		public var b:PCStatValue;
		public var b_limit:PCStatValue;
		public var w_limit:PCStatValue;
		public var f_minor:PCStatValue;
		public var p:PCStatValue;
		public var b_minor:PCStatValue;
		public var w:PCStatValue;
		public var energy:PCStatValue;
		public var g_minor:PCStatValue;
		public var mood:PCStatValue;
		public var g:PCStatValue;
		public var g_limit:PCStatValue;
		public var f:PCStatValue;
		public var p_minor:PCStatValue;
		public var f_limit:PCStatValue;
		public var w_minor:PCStatValue;
		public var currants:int;
		public var level:int;
		public var xp:PCXP;
		public var skill_points:int;
		public var favor_points:PCFavorPoints;
		public var quoins_today:PCStatValue;
		public var meditation_today:PCStatValue;
		public var energy_spent_today:int;
		public var xp_gained_today:int;
		public var imagination:int;
		public var imagination_gained_today:int;
		public var imagination_shuffle_cost:int;
		public var imagination_shuffled_today:Boolean;
		public var credits:int;
		public var is_subscriber:Boolean;
		public var imagination_hand:Vector.<ImaginationCard>;
		
		public function PCStats(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PCStats
		{
			var pcStats:PCStats = new PCStats(hashName);
			for(var j:String in object){
				if (j == 'skill_training' || j == 'skill_unlearning') {
					// not sure why this is here, but I am shutting up the warns about it
					continue;
				}
				var stringArray:Array = j.split("-");
				var modName:String = stringArray.join("_");
				if(modName == 'favor_points_new'){
					pcStats.favor_points = PCFavorPoints.fromAnonymous(object[j]);
				}else if(modName in pcStats){
					if(modName == "xp"){
						pcStats.xp = PCXP.fromAnonymous(object[j], j);
					}else if(modName == "favor_points"){
						//do nothing, cause we use favor_points_new
					}else if(modName == "level"){
						pcStats.level = object[j];
					}else if(modName == "currants"){
						pcStats.currants = object[j];
					}else if(modName == "skill_points"){
						pcStats.skill_points = object[j];
					}else if(modName == "energy_spent_today"){
						pcStats.energy_spent_today = object[j];
					}else if(modName == "xp_gained_today"){
						pcStats.xp_gained_today = object[j];
					}else if(modName == "imagination"){
						pcStats.imagination = object[j];
					}else if(modName == "imagination_gained_today"){
						pcStats.imagination_gained_today = object[j];
					}else if(modName == "imagination_shuffle_cost"){
						pcStats.imagination_shuffle_cost = object[j];
					}else if(modName == "imagination_shuffled_today"){
						pcStats.imagination_shuffled_today = object[j];
					}else if(modName == "credits"){
						pcStats.credits = object[j];
					}else if(modName == "is_subscriber"){
						pcStats.is_subscriber = object[j] === true;
					}else if(modName == "imagination_hand"){
						pcStats.imagination_hand = ImaginationCard.parseMultiple(object[j]);
					}else if (modName) {
						pcStats[modName] = PCStatValue.fromAnonymous(object[j],j);
					}else{
						pcStats[modName] = PCStatValue.fromAnonymous(object[j],j);
					}
				}else{
					resolveError(pcStats,object,j);
				}
			}
			return pcStats;
		}
	}
}