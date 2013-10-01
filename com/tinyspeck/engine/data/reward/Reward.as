package com.tinyspeck.engine.data.reward
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.model.TSModelLocator;

	public class Reward extends AbstractTSDataEntity
	{				
		public static const XP:String = 'xp';
		public static const MOOD:String = 'mood';
		public static const ENERGY:String = 'energy';
		public static const CURRANTS:String = 'currants';
		public static const FAVOR:String = 'favor';
		public static const ITEMS:String = 'items';
		public static const RECIPES:String = 'recipes';
		public static const DROP_TABLE:String = 'drop_table';
		public static const IMAGINATION:String = 'imagination';
		
		private static const REWARD_TYPES:Array = new Array(XP, MOOD, ENERGY, CURRANTS, FAVOR, ITEMS, RECIPES, DROP_TABLE, IMAGINATION);
		
		public var type:String;
		public var favor:RewardFavor;
		public var item:RewardItem;
		public var recipe:RewardRecipe;
		public var drop_table:RewardDropTable;
		public var amount:int;
		
		public function Reward(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, reward_type:String):Reward {
			var reward:Reward = new Reward(reward_type);
			
			if(REWARD_TYPES.indexOf(reward_type) >= 0){
				//convert to iMG
				if(reward_type == XP) reward_type = IMAGINATION;
				
				//set the type
				reward.type = reward_type;
				
				//check if we are already passing the value in a number
				if(!isNaN(Number(object))){
					reward.amount = int(object);
				}
				else {
					if(reward_type == FAVOR){
						reward.favor = RewardFavor.fromAnonymous(object, reward_type);
						reward.amount = reward.favor.points;
					}
					else if(reward_type == ITEMS){						
						reward.item = RewardItem.fromAnonymous(object, reward_type);
						reward.amount = reward.item.count;
					}
					else if(reward_type == RECIPES){						
						reward.recipe = RewardRecipe.fromAnonymous(object, reward_type);
						reward.amount = 1;
					}
					else if(reward_type == DROP_TABLE){						
						reward.drop_table = RewardDropTable.fromAnonymous(object, reward_type);
						reward.amount = reward.drop_table.count;
					}
				}
			}
			else {
				//this reward type isn't known!
				resolveError(reward,object,reward_type);
				CONFIG::debugging {
					Console.warn('unknown reward type '+reward_type);
				}
			}
			
			return reward;
		}
		
		public static function updateFromAnonymous(object:Object, questReward:Reward):Reward 
		{
			questReward = fromAnonymous(object, questReward.type);
			
			return questReward;
		}
	}
}