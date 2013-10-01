package com.tinyspeck.engine.data.reward
{
	import com.tinyspeck.engine.data.giant.Giants;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	
	public class Rewards
	{		
		/******************************************************************************
		 * Accepts a Rewards Hash formatted object
		 * http://svn.tinyspeck.com/wiki/RewardsHash
		 * 
		 * Returns a vector of "Reward" type of all the rewards
		 * NOTE: favor and item types are accessed via reward.favor and reward.items
		 ******************************************************************************/
		
		public static function fromAnonymous(object:Object):Vector.<Reward> {
			var rewards:Vector.<Reward> = new Vector.<Reward>();
			var reward:Reward;
			var k:String;
			var count:int;
			
			for(k in object){
				if(k == Reward.FAVOR || k == Reward.ITEMS || k == Reward.RECIPES || k == Reward.DROP_TABLE){
					if (object[k] is Number) continue; //legacy support
					
					count = 0;
					while(object[k] && object[k][count]){
						reward = Reward.fromAnonymous(object[k][count], k);
						rewards.push(reward);
						count++;
					}
				}
				else {
					if(!isNaN(object[k])){ //sometimes the server sends poop. make sure we don't parse poop.
						reward = Reward.fromAnonymous(object[k], k);
						rewards.push(reward);
					}
				}
			}
			
			//sort it
			rewards.sort(SortTools.rewardsSort);
			
			return rewards;
		}
		
		public static function updateFromAnonymous(object:Object, rewards:Vector.<Reward>):Vector.<Reward> {
			rewards = fromAnonymous(object);
			
			return rewards;
		}
		
		public static function convertToString(rewards:Vector.<Reward>):String {
			var i:int;
			var type:String;
			var rewards_txt:String = '';
			var total:int = rewards.length;
			
			for(i; i < rewards.length; i++){				
				type = rewards[int(i)].type;
				
				if(rewards[int(i)].amount != 0){
					if(type == Reward.FAVOR){
						if(rewards[int(i)].favor.giant == 'all'){
							type += ' with all of the giants';
						}
						else {
							type += ' with ' + Giants.getLabel(rewards[int(i)].favor.giant);
						}
					}
					else if(type == Reward.ITEMS){
						type = rewards[int(i)].item.label;
					}
					else if(type == Reward.DROP_TABLE){
						type = rewards[int(i)].drop_table.label;
					}
					else if(type == Reward.RECIPES){
						type = rewards[int(i)].recipe.label;
					}
					
					//drop_table only ever has 1 as the count says Mr. Myles.
					if(i < total-1){
						rewards_txt += (rewards[int(i)].type != Reward.DROP_TABLE ? StringUtil.formatNumberWithCommas(rewards[int(i)].amount) + ' ' : '') + 
									   type + (total > 2 ? ', ' : ' ');
					}
					else {
						rewards_txt += rewards.length > 1 ? 'and ' : '';
						rewards_txt += (rewards[int(i)].type != Reward.DROP_TABLE ? StringUtil.formatNumberWithCommas(rewards[int(i)].amount) + ' ' : '') + 
							 		   type + '.';
					}
				}
			}
			
			return rewards_txt;
		}
		
		public static function getRewardByType(rewards:Vector.<Reward>, type:String):Reward {
			var i:int;
			var total:int = rewards.length;
			var reward:Reward;
			
			for(i; i < total; i++){
				reward = rewards[int(i)];
				if(reward.type == type) return reward;
			}
			
			return null;
		}
	}
}