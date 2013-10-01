package com.tinyspeck.engine.view.ui.quest
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.chat.ChatElement;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;

	public class QuestQueue extends Sprite implements IRefreshListener
	{
		protected var SHOW_TIME:Number = .2; //animate showing
		protected var HIDE_TIME:Number = .6; //animate hiding
		protected var MAX_STAY_TIME:Number = 4; //how many secs to stay on screen
		protected var MAX_TITLE_CHARS:uint = 40;
		
		protected var all_holder:Sprite = new Sprite();
		
		protected var book_icon:Bitmap;
		
		protected var update_queue:Array = [];
		
		protected var tf:TSLinkedTextField = new TSLinkedTextField();
		
		protected var is_built:Boolean;
		
		public function QuestQueue(){}
		
		protected function buildBase():void {
			//the all holder 
			addChild(all_holder);
			
			//book
			book_icon = new AssetManager.instance.assets.quest_book();
			book_icon.smoothing = true;
			book_icon.scaleX = book_icon.scaleY = .5;
			book_icon.y = 6;
			all_holder.addChild(book_icon);
			
			//tf
			tf = new TSLinkedTextField();
			TFUtil.prepTF(tf);
			tf.wordWrap = false;
			tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			
			visible = false;
			
			is_built = true;
		}
		
		public function show(anything_you_want:*, no_delay:Boolean = false):void {
			if(!is_built) buildBase();
			
			//shove it in the queue and show it maybe, 1 at a time
			update_queue.push(anything_you_want);
			if(update_queue.length == 1 && !visible || no_delay){
				showNextMessage();
			}
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			visible = false;
			
			//stop listening
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			//bring back iMG
			YouDisplayManager.instance.hideImaginationAmount(false);
			
			//bring back the current location
			YouDisplayManager.instance.showHideCurrentLocation();
			
			//bring back the cult/deco buttons
			YouDisplayManager.instance.showHideCultDecoButtons();
			
			//we have any more?
			showNextMessage();
		}
		
		public function refresh():void {
			if(!TSModelLocator.instance) return;
			
			//place this where it should be
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const ydm:YouDisplayManager = YouDisplayManager.instance;
			
			const min_x:int = YouDisplayManager.instance.getImaginationButtonBasePt().x + 40;
			const max_x:int = lm.gutter_w + int(lm.loc_vp_w/2 - all_holder.width/2);
			
			all_holder.x = Math.max(min_x, max_x);
			all_holder.y = int(lm.header_h/2 - all_holder.height/2);
			
			const all_position:Number = all_holder.x + all_holder.width;
			
			//see if we need to hide the imagination amount
			ydm.hideImaginationAmount(all_holder.x < ydm.getImaginationCenterPt().x + 5);
			
			//see if we need to hide the deco buttons
			ydm.showHideCultDecoButtons();
			if(ydm.dec_cult_bt_holder.visible && all_position > ydm.dec_cult_bt_holder.x + lm.gutter_w - 15){
				ydm.dec_cult_bt_holder.visible = false;
			}
			
			//see if we need to hide the current location
			ydm.showHideCurrentLocation(all_position > ydm.current_location_x + lm.gutter_w - 15);
		}
		
		protected function showNextMessage():void {			
			//nothing? bail out
			if(!update_queue.length) return;
			
			//get the next thing and see what we need to do with it
			visible = true;
			handleNextThingInQueue();
			
			//place it where it should go (if we are not in capture mode)
			if(!TSModelLocator.instance.stateModel.in_capture_mode){
				TSFrontController.instance.getMainView().addView(this);
			}
			
			//listen to stuff
			TSFrontController.instance.registerRefreshListener(this);
		}
		
		protected function handleNextThingInQueue():void {
			//this will get the next element in the queue and figure out how we need to display it
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const next_thing:Object = update_queue.shift();
			var txt:String = next_thing.toString();
			
			//built the string
			const req:Requirement = next_thing as Requirement;
			const quest:Quest = TSModelLocator.instance.worldModel.getQuestByReqId(req.id);
			
			//setup the title
			const title_txt:String = quest ? StringUtil.truncate(quest.title, MAX_TITLE_CHARS) : 'Quest Update';
			
			//setup the description
			var desc_txt:String = req.desc;
			if(req.need_num > 1) desc_txt += ' ('+req.got_num+'/'+req.need_num+')';
			txt = title_txt+'<br><span class="quest_queue_req">'+desc_txt+'</span>';
			
			//play a sound
			SoundMaster.instance.playSound('COMPLETE_QUEST_REQUIREMENT');
			
			tf.htmlText = '<p class="quest_queue">'+txt+'</p>';
			
			//build a message out for local activity
			var quest_txt:String = '<p class="chat_element_quest">';
			quest_txt += '<a href="event:'+TSLinkedTextField.LINK_QUEST_HIGHLIGHT+'|'+quest.hashName+'" class="chat_element_quest_title">';
			quest_txt += 'Quest Progress: '+quest.title+'</a><br>';
			quest_txt += desc_txt;
			quest_txt += '</p>';
			RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, WorldModel.NO_ONE, quest_txt, ChatElement.TYPE_QUEST);
			
			//animate the text
			TSTweener.removeTweens(all_holder);
			all_holder.alpha = 0;
			tf.x = book_icon.width + 5;
			all_holder.addChild(tf);
			
			TSTweener.addTween(all_holder, {alpha:1, time:SHOW_TIME, transition:'linear'});
			TSTweener.addTween(all_holder, {alpha:0, time:HIDE_TIME, delay:MAX_STAY_TIME, transition:'linear', onComplete:hide});
			
			refresh();
		}
	}
}