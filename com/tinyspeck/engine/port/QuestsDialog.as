package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.net.NetOutgoingQuestDialogClosedVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Toast;
	import com.tinyspeck.engine.view.ui.quest.QuestConversationUI;
	import com.tinyspeck.engine.view.ui.quest.QuestElementUI;
	import com.tinyspeck.engine.view.ui.quest.QuestListUI;
	import com.tinyspeck.engine.view.ui.quest.QuestToast;
	
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;

	public class QuestsDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:QuestsDialog = new QuestsDialog();
		
		private const PAD_LEFT:int = 20;
		private const CLOSED_SCALE:Number = .02;
		
		private var error_toast:Toast;
		private var quest_toast:QuestToast;
		private var quest_list:QuestListUI;
		private var quest_convo_ui:QuestConversationUI;
		
		private var spinner:MovieClip;
		
		private var emergency_timer:Timer = new Timer(1000);
		
		private var quest_id_to_highlight:String;
		
		private var is_built:Boolean;
		
		public function QuestsDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 615;
			_body_min_h = 400;
			_head_min_h = 59;
			_draggable = true;
			_scrolltrack_always = false;
			_title_padd_left = PAD_LEFT;
			_construct();
		}
		
		private function buildBase():void {
			_setTitle('<span class="quest_dialog_header">Quest Log</span>');
			
			//build the error toast
			error_toast = new Toast(_w - _base_padd*4);
			error_toast.x = _base_padd + 2;
			_body_sp.addChild(error_toast);
			
			//the quest list
			quest_list = new QuestListUI(_w, _body_min_h);
			_scroller.body.addChild(quest_list);
			
			//build the quest count toast
			quest_toast = new QuestToast(_w);
			quest_toast.addEventListener(TSEvent.CHANGED, onToastChange, false, 0, true);
			quest_toast.addEventListener(TSEvent.STARTED, onToastStarted, false, 0, true);
			_scroller.body.addChild(quest_toast);
			
			quest_convo_ui = new QuestConversationUI();
			quest_convo_ui.addEventListener(TSEvent.CLOSE, onConvoClose, false, 0, true);
			
			//listen to the emergency timer
			emergency_timer.addEventListener(TimerEvent.TIMER, onEmergencyTick, false, 0, true);
			
			//load up the spinner
			spinner = new AssetManager.instance.assets.spinner();
			spinner.scaleX = spinner.scaleY = .8;
			spinner.mouseEnabled = spinner.mouseChildren = false;
			spinner.y = int(_head_min_h/2 - spinner.height/2 + 7);
			
			is_built = true;
		}
		
		override public function start():void {
			if (parent) return;
			if (!canStart(false)) return;
			if (!is_built) buildBase();
			
			//make sure the convo is hidden
			quest_convo_ui.hide();
			
			//update the counts/button
			updateCountToast();
			if(quest_toast) quest_toast.show_bt.disabled = false;
			
			//make the scroller look like it should
			_scroller.scrolltrack_always = model.worldModel.quests.length > 0;
			_scroller.refreshAfterBodySizeChange();
			
			//listen to stuff
			QuestManager.instance.addEventListener(TSEvent.QUEST_OFFERED, refreshQuests, false, 0, true);
			QuestManager.instance.addEventListener(TSEvent.QUEST_UPDATED, onQuestUpdated, false, 0, true);
			
			//call start before the end so it can be built and invalidate
			super.start();
			
			//animate it open
			tweenOpenClose(true);
			
			//set the toast postion
			error_toast.y = _body_h;
		}
		
		override public function end(release:Boolean):void {
			if(!parent) return;
			
			//animate it close (onComplete fires the super call to end())
			tweenOpenClose(false);
		}
		
		override public function refresh():void {
			if(!is_built) return;
			if(!parent && quest_convo_ui.parent){
				//we are showing an emergency quest offer, center up the quest convo
				const lm:LayoutModel = model.layoutModel;
				quest_convo_ui.x = int(lm.gutter_w + (lm.loc_vp_w/2 - quest_convo_ui.width/2));
				quest_convo_ui.y = int(lm.header_h + 80);
			}
			else {
				super.refresh();
			}
		}
		
		public function acceptQuest(success:Boolean):void {
			//hide the convo
			quest_convo_ui.hide();
			
			//throw up an error if there was one
			if(!success){
				error_toast.show('There was an error accepting that quest. Try it again.');
			}
		}
		
		private function tweenOpenClose(is_open:Boolean):void {
			const start_pt:Point = YouDisplayManager.instance.getMoodGaugeCenterPt();
			const final_scale:Number = is_open ? 1 : CLOSED_SCALE;
			const final_pt:Point = is_open ? new Point(dest_x, dest_y) : start_pt;
			const transition:String = is_open ? 'easeInCubic' : 'easeOutCubic';
			
			//set the starting stuff
			if(is_open) {
				scaleX = scaleY = CLOSED_SCALE;
				x = start_pt.x;
				y = start_pt.y;
			}
			else if(model.worldModel.location.no_imagination){
				//tell the server we closed this
				TSFrontController.instance.genericSend(new NetOutgoingQuestDialogClosedVO());
			}
			
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {
				x:final_pt.x, 
				y:final_pt.y, 
				scaleX:final_scale, 
				scaleY:final_scale, 
				time:.3, 
				transition:transition, 
				onComplete:onTweenComplete, 
				onCompleteParams:[is_open]
			});
			
			//play the sound
			SoundMaster.instance.playSound(is_open ? 'QUEST_DIALOGUE_BOX' : 'QUEST_DIALOGUE_BOX_CLOSE');
		}
		
		private function onTweenComplete(is_open:Boolean):void {
			if(is_open){
				//show the quest list
				quest_list.show();
				highlightQuest(quest_id_to_highlight);
				_scroller.refreshAfterBodySizeChange();
				
				_place();
			}
			else {
				super.end(true);
				scaleX = scaleY = 1;
				
				//stop listening to stuff
				QuestManager.instance.removeEventListener(TSEvent.QUEST_OFFERED, refreshQuests);
				QuestManager.instance.removeEventListener(TSEvent.QUEST_UPDATED, onQuestUpdated);
				
				//hide the offer convo
				quest_convo_ui.hide();
			}
		}
		
		private function onConvoClose(event:TSEvent):void {
			//we closed the conversation
			const quest:Quest = event.data as Quest;
			if(quest) QuestManager.instance.setQuestConversationActive(quest.hashName, false);
			
			//allow them to close the dialog since the conversation is over (used with is_emergency)
			_close_bt.disabled = false;
		}
		
		private function onToastChange(event:TSEvent):void {
			//toast is moving, make sure the quests move too
			quest_list.y = int(quest_toast.h*2 - quest_toast.height);
		}
		
		private function onToastStarted(event:TSEvent):void {
			//fetch the first un accepted quest
			const quests:Vector.<Quest> = QuestManager.instance.getUnacceptedQuests();
			if(quests.length){				
				//have to get the last one since it's ordered by OFFER TIME and not ACCEPTED TIME
				const quest:Quest = quests[quests.length-1];
				
				//place the convo
				quest_convo_ui.show(quest);
				quest_convo_ui.x = 10;
				quest_convo_ui.y = int(_head_min_h + quest_list.y + 10);
				addChild(quest_convo_ui);
				
				//place the dimmed version in the list
				quest_list.show();
			}
		}
		
		private function updateCountToast():void {
			//any more left?
			const quests:Vector.<Quest> = QuestManager.instance.getUnacceptedQuests();
			if(quests.length){
				quest_toast.show('You have <span class="quest_dialog_count">'+quests.length+'</span> new '+
					(quests.length != 1 ? 'quests' : 'quest')
				);
				quest_toast.show_bt.label = quests.length > 1 ? 'Show me one' : 'Show me';
			}
			else {
				quest_toast.hide(0);
			}
			
			_scroller.refreshAfterBodySizeChange();
		}
		
		public function startAndHighlightQuest(quest_id:String):void {
			quest_id_to_highlight = quest_id;
			start();
		}
		
		public function startEmergencyQuest():void {
			//this will show the rock without the dialog, and then open the dialog once the convo is accepted
			if(!is_built) buildBase();
			
			//go and try to show it
			onEmergencyTick();
		}
		
		public function highlightQuest(quest_id:String, from_retry:Boolean = false):void {
			if(!quest_id) return;
			
			//make sure the list has loaded first
			if(quest_list.loaded){
				//highlight and move the scroller
				const element:QuestElementUI = quest_list.getElementByQuestId(quest_id);
				if(element) {
					//delay the highlight if this isn't from a retry (300ms is the time of the opening animation)
					StageBeacon.setTimeout(element.highlight, !from_retry ? 200 : 0);
					_scroller.scrollYToTop(element.y);
				}
				
				quest_id_to_highlight = null;
				
				if(spinner && spinner.parent){
					//don't need the spinner anymore
					spinner.parent.removeChild(spinner);
				}
			}
			else {
				//try again
				StageBeacon.setTimeout(highlightQuest, 100, quest_id, true);
				if(spinner && !spinner.parent) {
					//show the spinner
					spinner.x = int(_title_tf.x + _title_tf.width + 3);
					addChild(spinner);
				}
			}
		}
		
		public function refreshQuests(event:TSEvent = null):void {
			if(!parent) return;
			
			//rebuild the list after we add/remove a quest
			quest_list.show();
			updateCountToast();
		}
		
		public function showError(msg:String):void {
			error_toast.show(msg, 5);
		}
		
		private function onQuestUpdated(event:TSEvent):void {
			const quest:Quest = event.data as Quest;
			
			//see if we can re-enable the show button on the toast
			if(quest_toast) quest_toast.show_bt.disabled = quest.offer_conversation_active;
			
			const element:QuestElementUI = quest_list.getElementByQuestId(quest.hashName);
			if(element){
				if(!quest.accepted && !quest.offer_conversation_active){
					//we didn't want this quest, hide it (removes from list)
					element.hide();
				}
				
				quest_list.update(quest.hashName);
			}
			else if(quest.accepted && !quest.offer_conversation_active){
				//accepted this and the convo is over (will bring the alpha to 100%)
				quest_list.show();
			}
			
			updateCountToast();
		}
		
		private function onEmergencyTick(event:TimerEvent = null):void {
			//check to see if we show the emergency convo yet
			if(!model.moveModel.moving && !quest_convo_ui.parent){
				//cool we aren't moving, go ahead and show the quest
				const emergency_quests:Vector.<Quest> = QuestManager.instance.getUnacceptedQuests(true);
				
				if(emergency_quests.length){
					quest_convo_ui.show(emergency_quests[0]);
					
					if(!parent){
						TSFrontController.instance.getMainView().addView(quest_convo_ui);
						
						//add it to the refresh list
						TSFrontController.instance.registerRefreshListener(this);
						refresh();
					}
					else {
						_close_bt.disabled = true;
						
						//add it to the dialog like it normally would
						quest_convo_ui.x = 10;
						quest_convo_ui.y = int(_head_min_h + quest_list.y + 10);
						quest_convo_ui.hide_rays = true;
						addChild(quest_convo_ui);
						
						//place the dimmed version in the list
						quest_list.show();
					}
				}
				
				//stop the timer if there is only 1 quest to go
				if(emergency_quests.length <= 1){
					emergency_timer.stop();
				}
				else if(!emergency_timer.running){
					//more then 1, start the timer
					emergency_timer.reset();
					emergency_timer.start();
				}
			}
			else if(!emergency_timer.running) {
				emergency_timer.reset();
				emergency_timer.start();
			}
		}
		
		override public function escKeyHandler(e:KeyboardEvent):void {
			//if the quest convo is open, close that, otherwise close the whole thang
			//this should NEVER happen since quest_convo has focus and only drops it when hide() is called
			if(quest_convo_ui.parent){
				quest_convo_ui.hide();
				quest_list.update();
				return;
			}
			
			super.escKeyHandler(e);
		}
	}
}