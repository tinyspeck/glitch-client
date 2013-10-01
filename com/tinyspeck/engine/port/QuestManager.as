/*
"0":[object Object]
	"type":quest_start
	"info":[object Object]
		"complete":false
	"reqs":[object Object]
		"r82":[object Object]
			"got_num":0
			"desc":Drink Beers
			"is_count":true
			"completed":false
			"need_num":12
	"title":The Great Guzzler Challenge 
	"desc":Drink a dozen beers. Shotgunning is optional. <br><br><font color='#000000'>Drink Beers : 0/12</font>
"quest_id":beer_guzzle
"title":* The Great Guzzler Challenge 
"desc":* Drink a dozen beers. Shotgunning is optional. <br><br><font color='#000000'>Drink Beers : 0/12</font>

"quests": {
"taskmaster_orange": {
"title": "Oranges!",
"desc": "I'm feeling peckish - could you bring me an orange?"
},
"taskmaster_quest_1":{
"title":"The first quest",
"desc":"First quest description"
}
}

Quest started

{
"type":"quest_start",
"quest_id":"taskmaster_apple",
"title":"Apples!",
"desc":"I'm feeling peckish - could you bring me an apple?"
}

Quest completed

{
"type":"quest_complete",
"quest_id":"taskmaster_quest_1"
}
*/
package com.tinyspeck.engine.port {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetIncomingMessageVO;
	import com.tinyspeck.engine.net.NetOutgoingQuestBeginVO;
	import com.tinyspeck.engine.net.NetOutgoingQuestConversationChoiceVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.ui.quest.QuestQueue;
	
	import flash.events.EventDispatcher;
	
	public class QuestManager extends EventDispatcher {
		
		/* singleton boilerplate */
		public static const instance:QuestManager = new QuestManager();
		
		private static const MAX_NEED_TO_SHOW:uint = 20; //how many "need" things to allow for the quest update requirement to show up
		
		private var model:TSModelLocator;
		private var quest_queue:QuestQueue = new QuestQueue();
		
		/* constructor */
		public function QuestManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		CONFIG::debugging public function logQuests():void {
			for (var i:int;i<quests.length;i++) {
				Console.warn(quests[int(i)].hashName)
			}
		}
		
		public function questAcceptedHandler(im:NetIncomingMessageVO):void {
			questOfferedHandler(im);
		}
		
		public function questOfferedHandler(im:NetIncomingMessageVO):void {
			if (im.payload.quest_id) {
				var quest:Quest = model.worldModel.getQuestById(im.payload.quest_id);
				var anonQuest:Quest = Quest.fromAnonymous(im.payload.info, im.payload.quest_id);
				
				//update, so let's update!
				if(quest != null){
					var index:int = quests.indexOf(quest);
					quests.splice(index, 1);
					//let's see if the finished status has changed
					if(quest.finished != anonQuest.finished){
						if(quest.finished){
							//if it WAS finished, but now isn't, put it to the top
							quests.unshift(anonQuest);
						}else{
							//now finished, so throw it on the bottom
							quests.push(anonQuest);
						}
						
					}else{
						//quests[index] = anonQuest; // NO! this stomps over another quest. do this instead:
						quests.splice(index, 0, anonQuest);
					}
					
					sortQuests();
					
					//don't need to update if this is emergency since the number won't change
					if(!anonQuest.is_emergency) YouDisplayManager.instance.updateNewQuestCount();
					dispatchEvent(new TSEvent(TSEvent.QUEST_UPDATED, anonQuest));
				}else{
					//if it's null, then it's new!
					if(im.payload.info.finished){
						// why a quest is finished when you get it is odd, but it can happen
						// EC: it happens when you get a quest with no requirements, like de_embiggenify (BUT IT SHOULD NOT HAPPEN ANYMORE)
						quests.push(anonQuest);
					}else{
						quests.unshift(anonQuest);
					}
					
					sortQuests();
					
					anonQuest.new_this_session = true;
					
					//don't need to update if this is emergency since the number won't change
					if(!anonQuest.is_emergency) YouDisplayManager.instance.updateNewQuestCount();
					dispatchEvent(new TSEvent(TSEvent.QUEST_OFFERED, anonQuest));
				}
				
				//if this quest was an emergency
				if(anonQuest.is_emergency && anonQuest.offer_conversation && ('txt' in anonQuest.offer_conversation)){
					QuestsDialog.instance.startEmergencyQuest();
				}
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('_questStartHandler lacking info');
				}
			}
		}
		
		public function questRequirementHandler(payload:Object):void {
			/*CONFIG::debugging {
				Console.warn('_questRequirementHandler');
			}*/

			//we've completed some quest requirement. Let's update it!
			var quest:Quest = model.worldModel.getQuestById(payload.quest_id);
			
			//if we get the requirements BEFORE the quest...
			if(!quest){
				CONFIG::debugging {
					Console.error('Quest: '+payload.quest_id+' has not been received yet');
				}
				return;
			}
			
			/* ignoring mission_accomplished for now
			//set the quest status
			if(quest.finished != im.payload.mission_accomplished){
				quests.splice(quests.indexOf(quest), 1);
				//if it WAS finished, but now isn't, put it to the top
				if(quest.finished){
					quests.unshift(quest);
				}else{
					//now finished, so throw it on the bottom
					quests.push(quest);
				}
			}
			
			quest.finished = im.payload.mission_accomplished;
			*/
			
			//update the requirement
			var quest_req:Requirement = Quest.getRequestByID(payload.req_id, quest);
			if(!quest_req){
				CONFIG::debugging {
					Console.error('Quest: '+payload.quest_id+' does not have the request ID of '+payload.req_id);
				}
				return;
			}
			
			var quest_req_index:int = quest.reqs.indexOf(quest_req);
			
			quest.reqs[quest_req_index] = Requirement.updateFromAnonymous(payload.status, quest_req);
			
			sortQuests();
			
			YouDisplayManager.instance.updateNewQuestCount();
			dispatchEvent(new TSEvent(TSEvent.QUEST_UPDATED, quest));
			
			//show an update that a certain requirement was complete
			const req:Requirement = quest.reqs[quest_req_index];
			
			//make sure the req is worthy of showing
			if((!req.is_count && !req.completed) || (req.is_count && !req.got_num)){
				//reseting a req, aka a failed attempt, show nothing
				return;
			}
			
			//show the req
			if(quest.hashName != 'numismatic_hustle') quest_queue.show(req, 'no_delay' in payload && payload.no_delay === true);
		}
		
		public function setQuestConversationActive(quest_id:String, a:Boolean):void {
			var quest:Quest = model.worldModel.getQuestById(quest_id);
			if (quest) {
				quest.offer_conversation_active = a;
				if (a) {
					quest.tried_to_offer_this_session = true;
				} 
				dispatchEvent(new TSEvent(TSEvent.QUEST_UPDATED, quest));
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('no quest? ' + quest_id);
				}
			}
		}
		
		public function questFinishedHandler(im:NetIncomingMessageVO):void {
			/*
			CONFIG::debugging {
				Console.warn('questFinishedHandler');
			}*/
			
			if (im.payload.quest_id){
				var quest:Quest = model.worldModel.getQuestById(im.payload.quest_id);
				
				//if we get here BEFORE the quest...
				if(!quest){
					CONFIG::debugging {
						Console.error('Quest: '+im.payload.quest_id+' has not been received yet');
					}
					return;
				}
				
				quest.finished = true;
				quest.failed = false;
				
				if (quest.hashName == 'leave_gentle_island') {
					NewxpLogger.log('finished_quest_leave_gentle_island');		
					model.flashVarModel.needs_todo_leave_gentle_island = false;			
				}
				
				/////quests.splice(quests.indexOf(quest), 1);
				/////quests.push(quest);
				
				sortQuests();
				
				YouDisplayManager.instance.updateNewQuestCount();
				dispatchEvent(new TSEvent(TSEvent.QUEST_UPDATED, quest));
				dispatchEvent(new TSEvent(TSEvent.QUEST_COMPLETE, quest));
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('questFinishedHandler lacking info');
				}
			}
		}
		
		public function questFailedHandler(im:NetIncomingMessageVO):void {
			if (im.payload.quest_id){
				var quest:Quest = model.worldModel.getQuestById(im.payload.quest_id);
				
				//if we get here BEFORE the quest...
				if(!quest){
					CONFIG::debugging {
						Console.error('Quest: '+im.payload.quest_id+' has not been received yet');
					}
					return;
				}
				
				quest.failed = true;
				quest.started = false;
				quest.finished = false;
				
				sortQuests();
				
				YouDisplayManager.instance.updateNewQuestCount();
				dispatchEvent(new TSEvent(TSEvent.QUEST_UPDATED, quest));
				
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('questFailedHandler missing quest_id');
				}
			}
		}
		
		public function questBeginHandler(rm:NetResponseMessageVO):void {
			if (rm.success) {
				var qbVO:NetOutgoingQuestBeginVO = NetOutgoingQuestBeginVO(rm.request);
				var quest:Quest = model.worldModel.getQuestById(qbVO.quest_id);
				if (quest) {
					quest.started = true;
					
					//close the QuestsDialog, if open
					//because clicking "try it" may not always succeed
					if (QuestsDialog.instance.parent) {
						QuestsDialog.instance.end(true);
					}
					
					sortQuests();
					
					YouDisplayManager.instance.updateNewQuestCount();
					dispatchEvent(new TSEvent(TSEvent.QUEST_UPDATED, quest));
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('no quest? ' + qbVO.quest_id);
					}
				}
			}
			else {
				//you did not do something right in order to start the quest
				if(rm.payload.error){
					QuestsDialog.instance.showError('Error starting quest: '+rm.payload.error.msg);
				}
			}
		}
		
		public function questConversationCompleteHandler(rm:NetResponseMessageVO):void {
			if (rm.success) {
				var qccVO:NetOutgoingQuestConversationChoiceVO = NetOutgoingQuestConversationChoiceVO(rm.request);
				var quest:Quest = model.worldModel.getQuestById(qccVO.quest_id);
				if (quest) {
					quest.accepted = true;
					
					// if you're starting, mark it as started, and close the QuestsDialog, if open
					if (qccVO.choice == 'accept_and_start') {
						quest.started = true;
						QuestsDialog.instance.end(true);
						
					} else { // just accepting, open the QuestsDialog if not open
						
						// THIS SORT OF SUCKS IN MANY CASES (like the you're dead quest)
						if (!QuestsDialog.instance.parent) {
							QuestsDialog.instance.startAndHighlightQuest(quest.hashName);
						} else {
							QuestsDialog.instance.highlightQuest(quest.hashName);
						}
					}
					
					sortQuests();
										
					YouDisplayManager.instance.updateNewQuestCount();
					dispatchEvent(new TSEvent(TSEvent.QUEST_UPDATED, quest));
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('no quest? ' + qccVO.quest_id);
					}
				}
			}
			else {
				//after acepting the quest, you did not meet a requirement to start it
				if(rm.payload.error){
					//open the dialog and show the error with a small delay
					QuestsDialog.instance.start();
					StageBeacon.setTimeout(QuestsDialog.instance.showError, 500, rm.payload.error.msg);
				}
			}
		}
		
		public function questRemoveHandler(payload:Object):void {
			//server says that we need to axe a quest
			if('tsid' in payload){
				//remove the quest from the world
				const quest:Quest = model.worldModel.getQuestById(payload.tsid);
				const index:int = quest ? model.worldModel.quests.indexOf(quest) : -1;
				if(quest && index != -1){
					model.worldModel.quests.splice(index, 1);
				}
				
				//refresh the dialog
				QuestsDialog.instance.refreshQuests();
				
				//update the count in the header
				YouDisplayManager.instance.updateNewQuestCount();
			}
			else {
				CONFIG::debugging {
					Console.warn('Quest remove without a TSID');
				}
			}
		}
		
		public function init():void {
			model = TSModelLocator.instance;
			model.worldModel.registerCBProp(onQuestChange, "quests");
		}
		
		private function sortQuests():void {
			SortTools.vectorSortOn(
				quests,
				['finished', 'accepted', 'offered_time', 'title'],
				[Array.NUMERIC, Array.NUMERIC, Array.NUMERIC | Array.DESCENDING, Array.CASEINSENSITIVE]
			);
			/*
			var i:int;
			for (i=0;i<quests.length;i++) {
				Console.warn('f:'+quests[int(i)].finished+' a:'+quests[int(i)].accepted+' ot:'+quests[int(i)].offered_time+' t:'+quests[int(i)].title)
			}
			*/
		}
		
		private function onQuestChange(quests:Vector.<Quest>):void {
			sortQuests();
			YouDisplayManager.instance.updateNewQuestCount();
			
			//do we have any emergency quests that need handling?
			const emergency_quests:Vector.<Quest> = getUnacceptedQuests(true);
			if(emergency_quests.length){
				QuestsDialog.instance.startEmergencyQuest();
			}
		}

		private function get quests():Vector.<Quest> {
			//another way to call the worldModel's quests
			return model.worldModel.quests;
		}
		
		public function getUnacceptedQuests(is_emergency:Boolean = false):Vector.<Quest> {
			var V:Vector.<Quest> = new Vector.<Quest>;
			var q:Quest;
			var i:int;
			
			for (i=0;i<quests.length;i++){
				q = quests[int(i)];
				if (q.accepted) continue;
				if (is_emergency && q.is_emergency){
					V.push(q);
				}
				else if(!is_emergency){
					V.push(q);
				}
			}
			
			return V;
		}
		
		public function acceptQuest(quest_id:String, value:String):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingQuestConversationChoiceVO(quest_id, value), onAcceptQuest, onAcceptQuest
			);
		}
		
		private function onAcceptQuest(nrm:NetResponseMessageVO):void {
			//update the dialog
			QuestsDialog.instance.acceptQuest(nrm.success);
		}
	}
}