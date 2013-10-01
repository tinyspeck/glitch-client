package com.tinyspeck.engine.view.ui.quest
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.giant.Giants;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingQuestBeginVO;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.QuestsDialog;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class QuestElementUI extends Sprite
	{
		private static const REQ_GAP_WIDTH:int = 5;
		private static const REWARDS_BUFFER:uint = 40; //how many px allowing for overlap before going to a new line
		private static const PADD:uint = 20;
		private static const TRY_W:uint = 70;
		private static const ACTIVE_ALPHA:Number = .3;
		
		//flash text sucks so much hog that we need to specifiy quests that require special widths. This may change down the road
		//with a redesign, but for now this sucks ass so we gotta do it
		private static const SPECIAL_WIDTHS:Array = ['saucery_make_level2_recipes'];
		
		private var req_elements:Vector.<QuestRequirementUI> = new Vector.<QuestRequirementUI>();
		private var try_bt:Button;
		private var offer_bt:Button;
		private var current_quest:Quest;
		
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var rewards_tf:TextField = new TextField();
		
		private var req_holder:Sprite = new Sprite();
		private var highlight_holder:Sprite = new Sprite();
		
		private var highlight_color:uint = 0xf6f270;
		private var highlight_alpha:Number = 1;
		private var next_x:int;
		private var next_y:int;
		private var _w:int;
		
		private var is_built:Boolean;
		
		public function QuestElementUI(w:int){
			_w = w - PADD*3;
		}
		
		private function buildBase():void {
			//highlighter
			highlight_color = CSSManager.instance.getUintColorValueFromStyle('quest_element_highlight', 'backgroundColor', highlight_color);
			highlight_alpha = CSSManager.instance.getNumberValueFromStyle('quest_element_highlight', 'backgroundAlpha', highlight_alpha);
			addChild(highlight_holder);
			
			//body
			TFUtil.prepTF(body_tf);
			body_tf.selectable = true;
			body_tf.x = PADD;
			body_tf.y = PADD - 7;
			body_tf.thickness = 100;
			addChild(body_tf);
			
			//buttons
			try_bt = new Button({
				name: 'try',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				h: QuestRequirementUI.ICON_SIZE + QuestRequirementUI.ICON_PADDING*2
			});
			try_bt.addEventListener(TSEvent.CHANGED, onTryClick, false, 0, true);
			req_holder.addChild(try_bt);
			
			offer_bt = new Button({
				name: 'offer',
				label: 'Tell me more',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				h: QuestRequirementUI.ICON_SIZE + QuestRequirementUI.ICON_PADDING*2
			});
			offer_bt.x = PADD;
			offer_bt.addEventListener(TSEvent.CHANGED, onOfferClick, false, 0, true);
			addChild(offer_bt);
			
			//reqs
			req_holder.x = PADD;
			addChild(req_holder);
			
			//rewards
			TFUtil.prepTF(rewards_tf);
			req_holder.addChild(rewards_tf);
			
			is_built = true;
		}
		
		public function show(quest:Quest):void {
			if(!is_built) buildBase();
			
			current_quest = quest;
			name = quest.hashName;
			
			//build out the body text
			buildBody(quest);
			
			//build out the reqs
			buildReqs(quest.reqs);
			
			//set the try button
			setTryButton();
			
			//set the rewards
			setRewards();
			
			//are we showing the offer button?
			offer_bt.visible = !quest.accepted && !quest.finished;
			offer_bt.disabled = quest.offer_conversation_active;
			offer_bt.y = req_holder.y;
			req_holder.visible = !offer_bt.visible && !quest.finished;
			
			alpha = !quest.offer_conversation_active ? 1 : ACTIVE_ALPHA;
			offer_bt.visible = false;
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		public function update():void {
			current_quest = TSModelLocator.instance.worldModel.getQuestById(current_quest.hashName);
			if(current_quest) show(current_quest);
		}
		
		public function highlight():void {
			const g:Graphics = highlight_holder.graphics;
			g.clear();
			g.beginFill(highlight_color, highlight_alpha);
			g.drawRect(0, 0, _w + PADD*3, height);
			
			highlight_holder.alpha = 0;
			TSTweener.removeTweens(highlight_holder);
			TSTweener.addTween(highlight_holder, {alpha:1, time:.3, transition:'linear'});
			TSTweener.addTween(highlight_holder, {alpha:0, time:1, delay:1, transition:'linear'});
		}
		
		private function buildBody(quest:Quest):void {
			var title:String = '<span class="quest_dialog_title_active">'+quest.title+'</span>';
			var body:String = '<span class="quest_dialog_text_'+(quest.finished ? 'complete' : 'active')+'">'+quest.desc+'</span>';
			var body_height:Number;
			
			//inject the link class for items
			body = StringUtil.injectClass(body, 'a', 'quest_dialog_link');
			body = StringUtil.replaceHTMLTag(body, 'b', 'span', 'quest_dialog_bold_replace');
			
			//if it's finished, style it differently
			if(quest.finished){
				title = '<span class="quest_dialog_title_complete">COMPLETED - '+quest.title+'</span>';
				body = '<span class="quest_dialog_text_complete">'+body+'</span>';
			}
			
			//slap it all in the TF
			body_tf.autoSize = TextFieldAutoSize.LEFT;
			body_tf.width = _w - (SPECIAL_WIDTHS.indexOf(quest.hashName) == -1 ? 0 : 5);
			body_tf.htmlText = '<p class="quest_dialog_text">'+title+'&nbsp;&nbsp;&nbsp;'+body+'</p>';
			body_height = body_tf.height;
			body_tf.autoSize = TextFieldAutoSize.NONE;
			body_tf.height = body_height + 6;
		}
		
		private function buildReqs(reqs:Vector.<Requirement>):void {
			var i:int;
			var total:int = req_elements.length;
			var req_ui:QuestRequirementUI;
			
			next_x = 0;
			next_y = 0;
			
			//reset the reqs
			for(i = 0; i < total; i++){
				req_ui = req_elements[int(i)];
				req_ui.x = req_ui.y = 0;
				req_ui.hide();
			}
			
			total = reqs.length;
			for(i = 0; i < total; i++){
				if(req_elements.length > i){
					//use an old one
					req_ui = req_elements[int(i)];
				}
				else {
					req_ui = new QuestRequirementUI();
					req_elements.push(req_ui);
				}
				
				req_ui.show(reqs[int(i)]);
				if(next_x + req_ui.width > _w){
					//if it's going to go too far, then wrap it down and start again
					next_x = 0;
					next_y += req_ui.height + REQ_GAP_WIDTH;
				}
				req_ui.x = next_x;
				req_ui.y = next_y;
				req_holder.addChild(req_ui);
				
				next_x += req_ui.width + REQ_GAP_WIDTH;
			}
			
			req_holder.y = int(body_tf.y + body_tf.height + 5);
		}
		
		private function setTryButton():void {
			//handle the try button
			try_bt.visible = current_quest.startable && !current_quest.finished;
			
			if(try_bt.visible){
				//set the state and label
				try_bt.disabled = current_quest.started || TSModelLocator.instance.worldModel.location.no_starting_quests;
				try_bt.label = current_quest.failed ? 'Try again' : 'Try it';
				try_bt.w = TRY_W;
				
				//place it where it needs to go
				if(next_x + try_bt.width > _w){
					next_x = 0;
					next_y += try_bt.height + REQ_GAP_WIDTH;
				}
				try_bt.x = next_x;
				try_bt.y = next_y;
				
				next_x += try_bt.width + REQ_GAP_WIDTH;
				
				//set the tooltip
				if(try_bt.disabled) {
					if(current_quest.started){
						try_bt.tip = {
							txt: 'You\'re already doing this quest!',
							offset_y: -7,
							pointer: WindowBorder.POINTER_BOTTOM_CENTER
						};
					}
					else {
						try_bt.tip = {
							txt: 'Starting new quests is not allowed right now!',
							offset_y: -7,
							pointer: WindowBorder.POINTER_BOTTOM_CENTER
						};
					}
				} 
				else {
					//nothing wrong
					try_bt.tip = null;
				}
			}
			else {
				//reset it
				try_bt.x = try_bt.y = 0;
				try_bt.label = '';
			}
		}
		
		private function setRewards():void {
			//if the quest is done, don't even bother showing rewards
			rewards_tf.visible = !current_quest.finished;
			if(current_quest.finished) return;
			
			const total:int = current_quest.rewards.length;
			const rewards:Vector.<Reward> = current_quest.rewards;
			var recipe_count:int;
			var reward_descsA:Array = [];
			var reward_txt:String = '';
			var i:int;
			var reward_str:String;
			
			for(i; i < total; i++){
				if(rewards[int(i)].type != Reward.RECIPES){
					reward_str = rewards[int(i)].amount != 0 ? rewards[int(i)].amount + '&nbsp;' : '';
					
					if(rewards[int(i)].type == Reward.ITEMS){
						reward_str += rewards[int(i)].item.label;
					}
					else if(rewards[int(i)].type == Reward.FAVOR){
						reward_str += 'favor&nbsp;with&nbsp;' + Giants.getLabel(rewards[int(i)].favor.giant);
					}
					else {
						reward_str += rewards[int(i)].type;
					}
					
					reward_descsA.push(reward_str);
				}
				else {
					recipe_count++;
				}
			}
			
			//set the Reward: part
			reward_str = '<span class="quest_dialog_rewards_title">Reward: </span>';
			
			//count up the recipes and add them to the end of the array
			if(recipe_count > 0){
				reward_descsA.push('+'+recipe_count+'&nbsp;new&nbsp;'+(recipe_count != 1 ? 'recipes' : 'recipe'));
			}
			
			//a quest with unknown rewards
			if(rewards.length == 0){
				reward_descsA.push('???');
			}
			
			//set it to single line in order to get the proper width
			rewards_tf.multiline = rewards_tf.wordWrap = false;
			rewards_tf.htmlText = '<p class="quest_dialog_rewards">'+reward_str+reward_descsA.join(', ')+'</p>';
			
			//are the rewards too fat to a) fit on the same line or b) fit on the same line while squished
			if(rewards_tf.width + REQ_GAP_WIDTH > _w){
				//this is a huge sucker, let's size it up
				rewards_tf.multiline = rewards_tf.wordWrap = true;
				rewards_tf.width = _w - next_x - REWARDS_BUFFER;
			}
			
			const rewards_w:uint = rewards_tf.width + REQ_GAP_WIDTH;
			const rewards_gap:int = _w - next_x - rewards_w;
			if(rewards_w > _w - next_x && rewards_gap < -REWARDS_BUFFER){
				//needs it's own line
				next_y += try_bt.height + REQ_GAP_WIDTH;
			}
			else if(rewards_gap < 0 && rewards_gap > -REWARDS_BUFFER){
				//size the textfield up
				rewards_tf.multiline = rewards_tf.wordWrap = true;
				rewards_tf.width = rewards_w/2 + REWARDS_BUFFER;
			}
			
			rewards_tf.x = int(_w - rewards_tf.width);
			rewards_tf.y = int(next_y + (try_bt.height/2 - rewards_tf.height/2));
		}
		
		private function onOfferClick(event:TSEvent):void {
			if(offer_bt.disabled || TSModelLocator.instance.stateModel.fam_dialog_conv_is_active) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			offer_bt.disabled = true;
			
			if(current_quest.offer_conversation) {
				if(TSFrontController.instance.startFamiliarConversationWithPayload(current_quest.offer_conversation, true)) {
					//end the dialog
					QuestsDialog.instance.end(true);
					SoundMaster.instance.playSound('CLICK_SUCCESS');
				}
			} 
			else {
				CONFIG::debugging {
					Console.error('wtf, no offer_conversation')
				}
			}
			
			//down here means we failed
			SoundMaster.instance.playSound('CLICK_FAILURE');
		}
		
		private function onTryClick(event:TSEvent):void {
			if(try_bt.disabled || TSModelLocator.instance.stateModel.fam_dialog_conv_is_active) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			try_bt.disabled = true;
			
			//tell the server to try
			TSFrontController.instance.genericSend(new NetOutgoingQuestBeginVO(current_quest.hashName));
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		override public function get height():Number {
			return req_holder.y + (req_holder.visible ? req_holder.height : offer_bt.height) + PADD - 5; //-5 for visual tweaking
		}
	}
}