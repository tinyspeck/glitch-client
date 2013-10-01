package com.tinyspeck.engine.data.quest {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.data.requirement.Requirements;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.ConversationManager;
	import com.tinyspeck.engine.util.StringUtil;
	
	public class Quest extends AbstractQuestEntity {
		
		public static const MAX_TITLE_CONV_LENGTH:uint = 39;
		
		public var desc:String;
		public var title:String;
		public var finished:Boolean;
		public var startable:Boolean;
		public var started:Boolean;
		public var accepted:Boolean;
		public var offer_immediately:Boolean;
		public var offer_conversation:Object;
		public var offer_conversation_active:Boolean;
		public var failed:Boolean;
		public var reqs:Vector.<Requirement>;
		public var rewards:Vector.<Reward>;
		public var offered_time:int;
		public var new_this_session:Boolean;
		public var tried_to_offer_this_session:Boolean;
		public var is_emergency:Boolean;
		
		public function Quest(hashName:String) {
			super(hashName);
		}
		
		public static function parseMultiple(object:Object):Vector.<Quest> {
			var V:Vector.<Quest> = new Vector.<Quest>();
			var quest:Quest;
			
			for(var j:String in object){
				if (!object[j]) {
					CONFIG::debugging {
						Console.warn('WTF null object for quest:'+j);
					}
					continue;
				} 
				V.push(fromAnonymous(object[j],j));
			}
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Quest {
			var quest:Quest = new Quest(hashName);
			var req:Requirement;
			var reward:Reward;
			var val:*;
			var k:String;
			
			//if (!object.quest_id && object.class_id) object.quest_id = object.class_id;
			
			for(var j:String in object){
				val = object[j];
				if(j == 'complete'){
					// ignore this
				} else if(j == 'ts_done'){
					// ignore this, I think the JS is leaking it
				} else if(j == 'reqs'){
					quest.reqs = Requirements.fromAnonymous(val);
				}else if(j == 'rewards'){
					quest.rewards = Rewards.fromAnonymous(val);
				}else if(j in quest){
					quest[j] = val;
				}else{
					resolveError(quest,object,j);
				}
			}
			
			if (quest.offer_conversation) {
				
				// add a little context header
				quest.offer_conversation.title = '<span class="choices_quest_title">New quest</span>';
				quest.offer_conversation.graphic = new AssetManager.instance.assets.familiar_dialog_quests_small();
				quest.offer_conversation.txt = '<span class="choices_quest_start_finish">'+quest.title+'</span><br>'+
											   StringUtil.injectClass(quest.offer_conversation.txt, 'a', 'familiar_conversation_link');
					
				// these are IMPORTANT! maybe we should just add them to the object the GS sends us
				quest.offer_conversation.quest_id = quest.hashName;
				quest.offer_conversation.conv_type = ConversationManager.TYPE_QUEST_OFFER;
				quest.offer_conversation.itemstack_tsid = TSModelLocator.instance.worldModel.pc.familiar.tsid;
			}
			
			if (quest.hashName == 'leave_gentle_island' && !quest.finished) {
				TSModelLocator.instance.flashVarModel.needs_todo_leave_gentle_island = true;
				NewxpLogger.log('has_quest_leave_gentle_island');					
			}
			
			return quest;
		}
		
		public static function updateFromAnonymous(object:Object, quest:Quest):Quest {
			quest = fromAnonymous(object, quest.hashName);
			
			return quest;
		}
		
		public static function getRewardByType(reward_type:String, quest:Quest):Reward {
			var questReward:Reward;
			var i:int = 0;
			var total:int = quest.rewards.length;
			
			for(i; i < total; i++){
				questReward = quest.rewards[int(i)];
				if(questReward.type == reward_type) return questReward;
			}
			
			return null;
		}
		
		public static function getRequestByID(request_id:String, quest:Quest):Requirement {
			var questReq:Requirement;
			var i:int = 0;
			var total:int = quest.reqs.length;
			
			for(i; i < total; i++){
				questReq = quest.reqs[int(i)];
				if(questReq.hashName == request_id){
					return questReq;
					break;
				}
			}
			
			return null;
		}
	}
}