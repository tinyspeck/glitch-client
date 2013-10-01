package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.job.JobInfo;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.JobDialog;
	import com.tinyspeck.engine.port.JobManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;

	public class JobIntroUI extends TSSpriteWithModel
	{
		private static const TEXT_WIDTH:uint = 370;
		private static const BUTTON_WIDTH:uint = 63;
		private static const BUTTON_ICON_WH:uint = 36;
		private static const MAX_CUSTOM_NAME_CHARS:uint = 20;
		private static const CUSTOM_NAME_WIDTH:uint = 200;
		private static const CLAIM_TEXT:String = 'Claim this project!';
		private static const CLOSE_TEXT:String = "Let's see what I can do...";
		private static const GROUP_VIEW_TEXT:String = 'Get some group info';
		
		public var map_bg:DisplayObject;
		public var choice_arrows:DisplayObject;
		
		private var close_bt:Button;
		private var claim_bt:Button;
		private var accept_bt:Button;
		private var phase_ui:JobPhaseUI;
		private var req_bts:Vector.<Button> = new Vector.<Button>();
		private var group_selector:JobGroupSelectorUI = new JobGroupSelectorUI();
		
		private var bg:Sprite = new Sprite();
		private var claim_holder:Sprite = new Sprite();
		private var custom_name_holder:Sprite = new Sprite();
				
		private var intro_tf:TextField = new TextField();
		private var rewards_title:TextField = new TextField();
		private var rewards_body:TextField = new TextField();
		private var timeout_tf:TextField = new TextField();
		private var claimed_tf:TSLinkedTextField = new TSLinkedTextField();
		private var claim_reqs_tf:TextField = new TextField();
		private var custom_name_tf:TextField = new TextField();
		
		private var currants_snapshot:int; //just record the currant count so that on stat updates we only refresh when currants change
		private var _padd:int;
		
		private var _can_claim:Boolean;
		
		public function JobIntroUI(w:int, h:int, padd:int){
			_w = w;
			_h = h;
			_padd = padd;
			
			buildBase();
		}
		
		private function buildBase():void {
			addChild(bg);
			
			choice_arrows = new AssetManager.instance.assets.job_either_arrows();
			choice_arrows.visible = false;
			addChild(choice_arrows);
			
			close_bt = new Button({
				name: 'close_intro',
				label: CLOSE_TEXT,
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			addChild(close_bt);
			
			claim_bt = new Button({
				name: 'claim',
				label: CLAIM_TEXT,
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			claim_bt.addEventListener(TSEvent.CHANGED, onClaimClick, false, 0, true);
			addChild(claim_bt);
			claim_bt.visible = false;
			
			TFUtil.prepTF(intro_tf);
			addChild(intro_tf);
			
			TFUtil.prepTF(rewards_title, false);
			addChild(rewards_title);
			
			TFUtil.prepTF(rewards_body);
			addChild(rewards_body);
			
			TFUtil.prepTF(claimed_tf, false);
			claimed_tf.htmlText = '<p class="job_claimed">Placeholderp</p>';
			claimed_tf.x = _padd;
			addChild(claimed_tf);
			
			TFUtil.prepTF(timeout_tf);
			timeout_tf.width = _w - TEXT_WIDTH;
			timeout_tf.x = _padd;
			addChild(timeout_tf);
			
			//phase UI
			phase_ui = new JobPhaseUI(_w - _padd*2 - 150);
			addChild(phase_ui);
			
			//listen to the timer
			JobDialog.instance.addEventListener(TSEvent.TIMER_TICK, onTimerTick, false, 0, true);
			
			//for the claim reqs
			TFUtil.prepTF(claim_reqs_tf);
			claim_reqs_tf.htmlText = '<p class="job_intro_claim">Placeholderp</p>';
			claim_reqs_tf.width = int(_w/2 - _padd*2);
			addChild(claim_reqs_tf);
			addChild(claim_holder);
			
			//custom naming things
			var g:Graphics = custom_name_holder.graphics;
			g.lineStyle(1, 0xd6d6b1);
			g.beginFill(0xe4e4bf);
			g.drawRoundRectComplex(0, 0, CUSTOM_NAME_WIDTH, 33, 4, 0, 4, 0);
			g.lineStyle(0,0,0);
			g.beginFill(0xf5f5ce);
			g.drawRoundRectComplex(1, 3, CUSTOM_NAME_WIDTH-1, 30, 4, 0, 4, 0);
			addChild(custom_name_holder);
			
			TFUtil.prepTF(custom_name_tf);
			TFUtil.setTextFormatFromStyle(custom_name_tf, 'rename_bubble_input');
			custom_name_tf.selectable = true;
			custom_name_tf.autoSize = TextFieldAutoSize.NONE;
			custom_name_tf.text = ' ';
			custom_name_tf.width = custom_name_holder.width - 16;
			custom_name_tf.height = custom_name_tf.textHeight + 4;
			custom_name_tf.x = 8;
			custom_name_tf.y = int(custom_name_holder.height/2 - custom_name_tf.height/2);
			custom_name_tf.type = TextFieldType.INPUT;
			custom_name_tf.maxChars = MAX_CUSTOM_NAME_CHARS;
			custom_name_holder.addChild(custom_name_tf);
			
			//accept bt
			accept_bt = new Button({
				name: 'accept',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_INPUT_ACCEPT,
				w: 37,
				x: custom_name_holder.width - 2,
				y: -1,
				graphic: new AssetManager.instance.assets.input_check(),
				graphic_hover: new AssetManager.instance.assets.input_check_hover(),
				graphic_disabled: new AssetManager.instance.assets.input_check_disabled()
			});
			accept_bt.addEventListener(TSEvent.CHANGED, onAcceptClick, false, 0, true);
			accept_bt.h = 35;
			custom_name_holder.addChild(accept_bt);
			
			//group list
			group_selector.w = 200;
			group_selector.h = 82;
			addChild(group_selector);
			
			//listen for any group changes
			RightSideManager.instance.addEventListener(TSEvent.GROUPS_CHANGED, onGroupsChanged, false, 0, true);
			
			//listen for currants changes
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			
			jigger();
		}
		
		public function show():void {
			//single phase jobs are layed out differently than multiphase, so you should do that!
			var job_info:JobInfo = JobManager.instance.job_info;
			var phase_count:int = job_info.phases.length;
			var group:Group = job_info.group_tsid ? model.worldModel.getGroupByTsid(job_info.group_tsid) : null;
			
			visible = true;
			custom_name_holder.visible =  false;
			
			/** DEBUG
			job_info.owner_tsid = 'P123456';
			job_info.owner_label = 'Scott';
			job_info.type = JobInfo.TYPE_GROUP_HALL;
			job_info.timeout = TSFrontController.instance.getCurrentGameTimeInUnixTimestamp() + 60;
			//**/
			
			//get a snapshot of the currants
			if(model.worldModel.pc && model.worldModel.pc.stats) currants_snapshot = model.worldModel.pc.stats.currants;
			
			// set the description
			intro_tf.htmlText = '<p class="job_intro">' + job_info.desc + '</p>';
			
			//setup the map
			if(map_bg && map_bg.parent){
				map_bg.parent.removeChild(map_bg);
				map_bg = null;
			}
			map_bg = new AssetManager.instance.assets['job_'+(job_info.type == JobInfo.TYPE_REGULAR ? 'map' : job_info.type)+'_bg']();
			map_bg.visible = (job_info.options.length <= 1 && phase_count == 1);
			addChildAt(map_bg, getChildIndex(choice_arrows));
			
			//set the phase
			if(phase_count > 1){
				phase_ui.w = !job_info.owner_label && job_info.claim_reqs && job_info.claim_reqs.length ? _w/2 - _padd*2 : _w - _padd*2 - 150;
				phase_ui.show(true);
			}
			else {
				phase_ui.hide();
			}
			
			rewards_title.htmlText = '<p class="job_rewards_title">Rewards'+(phase_count > 1 ? ' for Phase '+(job_info.getCurrentPhaseIndex()+1) : '')+'</p>';
			
			rewards_title.visible = job_info.claim_reqs && job_info.claim_reqs.length == 0 && ((job_info.rewards && job_info.rewards.length) || (job_info.performance_rewards && job_info.performance_rewards.length));
			rewards_body.visible = rewards_title.visible;
			
			//make sure the button is enter-ready
			claim_bt.visible = job_info.type == JobInfo.TYPE_GROUP_HALL && !job_info.owner_tsid;
			close_bt.visible = !claim_bt.visible;
			
			if(close_bt.visible) close_bt.focus();
			if(claim_bt.visible) claim_bt.focus();
			
			//if we have a duration, make sure we populate it
			claimed_tf.visible = job_info.owner_label ? true : false;
			timeout_tf.visible = claimed_tf.visible;
			
			setClaimText();
			
			//any claim requirements?
			_can_claim = true;
			claim_holder.visible = !job_info.owner_label && job_info.claim_reqs && job_info.claim_reqs.length > 0;
			claim_reqs_tf.visible = claim_holder.visible;
			if(claim_holder.visible){
				showClaimReqs();
				claim_reqs_tf.htmlText = '<p class="job_intro_claim">You\'ll need the following '+
										 (job_info.claim_reqs.length != 1 ? 'things' : 'thing')+
										 ':</p>';
				group_selector.show();
			}
			else {
				group_selector.hide();
			}
			
			//if there is group data in this job, and you're not a member, swap the label
			close_bt.label = (!group || (group && !group.is_member)) && job_info.group_tsid ? GROUP_VIEW_TEXT : CLOSE_TEXT;
			close_bt.value = (!group || (group && !group.is_member)) && job_info.group_tsid ? job_info.group_tsid : null;
			
			//if you're the owner of the job, but haven't given it a name yet, make sure that happens!
			/*
			if(job_info.type == JobInfo.TYPE_GROUP_HALL && job_info.owner_tsid && job_info.owner_tsid == model.worldModel.pc.tsid && !job_info.custom_name){
				showCustomName();
				return;
			}
			*/

			//move things around that need moving around
			jigger();
		}
		
		public function showCustomName():void {
			close_bt.visible = false;
			claim_bt.visible = false;
			claim_holder.visible = false;
			custom_name_holder.visible =  true;
			accept_bt.disabled = false;
			
			claimed_tf.visible = true;
			timeout_tf.visible = true;
			
			claim_reqs_tf.visible = true;
			claim_reqs_tf.htmlText = '<p class="job_intro_claim">What would you like to name your Organization?</p>';
			
			custom_name_tf.text = '';
			
			//set focus to the input
			StageBeacon.stage.focus = custom_name_tf;
			
			jigger();
		}
		
		public function hide():void {
			visible = false;
		}
		
		public function setRewardText(str:String):void {
			if(JobManager.instance.job_info && JobManager.instance.job_info.type != JobInfo.TYPE_GROUP_HALL){
				rewards_body.htmlText = '<p class="job_rewards_body">' + str + '</p>';
				jigger();
			}
		}
		
		private function setClaimText():void {
			if(!JobManager.instance.job_info) return;
			
			/** TODO SY, MAKE THIS NOT SET HTML EACH SECOND **/
			const job_info:JobInfo = JobManager.instance.job_info;
			const group:Group = job_info.group_tsid ? model.worldModel.getGroupByTsid(job_info.group_tsid) : null;
			
			if(job_info.owner_label){				
				//claimed by you?
				if(!group && job_info.owner_tsid == model.worldModel.pc.tsid){
					claimed_tf.htmlText = '<p class="job_claimed">Claimed by <b>you!</b></p>';
				}
				else {
					//claimed by a group or another player
					var claim_tsid:String = group ? group.tsid : job_info.owner_tsid;
					var claim_label:String = group ? StringUtil.truncate(group.label, 25) : job_info.owner_label;
					
					claimed_tf.htmlText = '<p class="job_claimed">Claimed by ' +
						'<a href="event:'+(group ? TSLinkedTextField.LINK_GROUP : TSLinkedTextField.LINK_PC)+'|'+claim_tsid+'">'+claim_label+'</a>' +
						'</p>';
				}
			}
		}
		
		private function showClaimReqs():void {
			_can_claim = true;
			
			var reqs:Vector.<Requirement> = JobManager.instance.job_info.claim_reqs;
			if(!reqs) return;
			
			var i:int;
			var total:int = reqs.length;
			var req:Requirement;
			var bt:Button;
			var next_x:int;
			
			//reset the current ones
			for(i = 0; i < req_bts.length; i++){
				bt = req_bts[int(i)];
				bt.x = 0;
				bt.visible = false;
			}
			
			for(i = 0; i < total; i++){
				req = reqs[int(i)];
				
				//reset the req
				req.disabled = false;
				
				if(req_bts.length > i){
					bt = req_bts[int(i)];
					bt.visible = true;
				}
				else {
					bt = new Button({
						graphic_placement: 'top',
						name: 'req',
						graphic_padd_t: 10,
						default_tf_padd_w: 2,
						draw_alpha: 0,
						disabled_c: 0xffffff,
						disabled_graphic_alpha: .5,
						default_tf_padd_w: 0,
						w: BUTTON_WIDTH,
						use_hand_cursor_always: true
					});
					claim_holder.addChild(bt);
					req_bts.push(bt);
				}
				
				if(bt.graphic && bt.graphic.name != req.item_class){
					bt.removeGraphic();
					bt.setGraphic(new ItemIconView(req.item_class, BUTTON_ICON_WH));
				}
				else if(!bt.graphic){
					bt.setGraphic(new ItemIconView(req.item_class, BUTTON_ICON_WH));
				}
				
				bt.label = getReqLabel(req);
				bt.tip = getReqTip(req);
				bt.disabled = req.disabled;
				bt.h = int(bt.label_tf.y + bt.label_tf.height) + 2;
				bt.x = next_x;
				next_x += BUTTON_WIDTH + 5;
				
				if(req.disabled) _can_claim = false;
			}
			
			//check to make sure they are a memeber of at least 1 group
			if(model.worldModel.getGroupsTsids(false).length == 0){
				_can_claim = false;
			}
		}
		
		private function getReqLabel(req:Requirement):String {
			var pc:PC = model.worldModel.pc;
			var total_items:int = pc.hasHowManyItems(req.item_class);
			var str:String = '<p class="job_item">';
			var need_num:String = StringUtil.crunchNumber(req.need_num);
			var got_num:String = StringUtil.crunchNumber(req.got_num);
						
			if(req.item_class == 'money_bag' && currants_snapshot < req.need_num){
				req.disabled = true;
			}
			else if(req.item_class != 'money_bag' && total_items == 0){
				req.disabled = true;
			}
			
			str += !req.disabled ? '' : '<span class="job_item_disabled">';
			str += '<span class="job_item_got">' + need_num + '</span>';
			str += !req.disabled ? '' : '</span>';
			
			str += '</p>';
			
			return str;
		}
		
		private function getReqTip(req:Requirement):Object {
			var txt:String;
			
			txt = !req.disabled ? req.desc : req.disabled_reason;
			
			if(!txt) return null;
			
			return {
				txt: txt,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		private function jigger():void {		
			var job_info:JobInfo = JobManager.instance.job_info;
			if(!job_info) return;
			
			var phase_count:int = job_info.phases.length;
			var options_length:int = job_info.options.length;
			var g:Graphics = bg.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, _w, _h);
			
			//set the TF offsets
			intro_tf.x = rewards_title.x = rewards_body.x = _padd;
			
			//place the rewards text			
			if(phase_count == 1){
				intro_tf.width = rewards_title.width = rewards_body.width = TEXT_WIDTH;
				rewards_body.y = int(bg.height - rewards_body.height - _padd);
				
				close_bt.x = intro_tf.x + int(intro_tf.width/2 - close_bt.width/2);
				close_bt.y = intro_tf.y + intro_tf.height + 30;
				claim_bt.x = intro_tf.x + int(intro_tf.width/2 - claim_bt.width/2);
			}
			else {
				intro_tf.width = rewards_title.width = rewards_body.width = (options_length == 0 ? _w - _padd*2 : TEXT_WIDTH);
				rewards_body.y = int(close_bt.y - rewards_body.height - _padd);
				
				close_bt.x = job_info.options.length == 0 ? int(_w - _padd - close_bt.width) : _padd;
				close_bt.y = _h - _padd - close_bt.height + 4;
				claim_bt.x = job_info.options.length == 0 ? int(_w - _padd - claim_bt.width) : _padd;
			}
			
			rewards_title.y = int(rewards_body.y - rewards_title.height - 5);
			
			//move the map
			if(map_bg){
				map_bg.x = _w - map_bg.width;
				map_bg.y = int(intro_tf.height/2);
			}
			
			//phase thing
			phase_ui.x = claim_reqs_tf.visible ? _padd : int(_w/2 - phase_ui.w/2);
			phase_ui.y = rewards_title.visible ? int((rewards_title.y - intro_tf.y + intro_tf.height)/2 - phase_ui.h/2) : intro_tf.y + intro_tf.height + 20;
			
			//claim stuff
			if(claim_reqs_tf.visible){
				claim_reqs_tf.x = phase_ui.visible ? int(phase_ui.x + phase_ui.width - _padd/2) : int(_w/2 - claim_reqs_tf.width/2);
				claim_reqs_tf.y = phase_ui.visible ? phase_ui.y : int(intro_tf.y + intro_tf.height + 20);
				
				claim_holder.x = claim_reqs_tf.x + int(claim_reqs_tf.width/2 - claim_holder.width/2);
				claim_holder.y = int(claim_reqs_tf.y + claim_reqs_tf.height);
				
				custom_name_holder.x = int(claim_reqs_tf.x + (claim_reqs_tf.width/2 - custom_name_holder.width/2));
				custom_name_holder.y = int(claim_reqs_tf.y + claim_reqs_tf.height + 15);
				
				claim_bt.x = claim_reqs_tf.x + int(claim_reqs_tf.width/2 - claim_bt.width/2);
			}			
			claim_bt.disabled = !_can_claim;
			claim_bt.y = claim_reqs_tf.visible ? claim_holder.y + claim_holder.height + 20 : close_bt.y;
			claim_bt.tip = _can_claim ? null : {
				txt: model.worldModel.getGroupsTsids(false).length == 0 ? 'You need to be a member of a group!' : 'You need to meet all the requirements', 
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			};
			
			//move the group selector
			if(group_selector.visible){
				group_selector.x = phase_ui.visible ? int(phase_ui.width/2 - group_selector.w/2) : intro_tf.x + int(intro_tf.width/2 - group_selector.w/2);
				group_selector.y = phase_ui.visible ? phase_ui.y + phase_ui.height + 30 : claim_holder.y + claim_holder.height + 10;
				
				if(!phase_ui.visible){
					//nudge the claim button down
					claim_bt.y += group_selector.h + 10;
				}
				else {
					//move it to make some more sense, for now
					claim_bt.y = int(claim_holder.y + claim_holder.height + 25);
				}
			}
			
			//claim/duration?
			if(claimed_tf.visible){
				claimed_tf.y = close_bt.y;
				timeout_tf.y = int(claimed_tf.y + claimed_tf.height);
			}
		}
		
		private function onCloseClick(event:TSEvent):void {
			if(close_bt.disabled) return;
			
			//if we are needing to see some group info, we should see it
			if(close_bt.value){
				TSFrontController.instance.openGroupsPage(null, close_bt.value);
			}
			else {
				dispatchEvent(new TSEvent(TSEvent.CLOSE, close_bt));
			}
		}
		
		private function onClaimClick(event:TSEvent):void {
			if(claim_bt.disabled) return;
			
			claim_bt.value = group_selector.visible ? group_selector.getSelectedGroupTsid() : null;
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED, claim_bt));
		}
		
		private function onTimerTick(event:TSEvent):void {
			//if the claim name has changed
			/* This may be better on performance, but for now we'll see
			if(JobManager.instance.job_info.owner_tsid != model.worldModel.pc.tsid && claimed_tf.text != 'Claimed by '+JobManager.instance.job_info.owner_tsid){
				claimed_tf.htmlText = '<p class="job_claimed">Claimed by ' +
					'<a href="event:'+TSLinkedTextField.LINK_PC+'|'+JobManager.instance.job_info.owner_tsid+'">'+JobManager.instance.job_info.owner_label+'</a>' +
					'</p>';
			}
			else if(claimed_tf.text != 'Claimed by you!'){
				claimed_tf.htmlText = '<p class="job_claimed">Claimed by <b>you!</b></p>';
			}
			*/
			
			setClaimText();
			
			//is there time left?
			if(event.data < 60 && event.data > 0){
				timeout_tf.htmlText = '<p class="job_duration">Time left: <span class="job_item_disabled">Less than a minute!</span></p>';
			}
			else if(event.data > 0) {
				timeout_tf.htmlText = '<p class="job_duration">Time left: '+StringUtil.formatTime(event.data)+'</p>';
			}
			else {
				timeout_tf.text = '';
			}
			
			//do we show the TFs?
			claimed_tf.visible = int(event.data) > 0 && JobManager.instance.job_info.owner_tsid;
			timeout_tf.visible = claimed_tf.visible;
		}
		
		private function onAcceptClick(event:TSEvent):void {
			if(accept_bt.disabled || custom_name_tf.text == '') return;
			accept_bt.disabled = true;
			
			dispatchEvent(new TSEvent(TSEvent.ACTIVITY_HAPPENED, custom_name_tf.text));
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			if(!visible || !claim_holder.visible) return;
			if(currants_snapshot == pc_stats.currants) return;
			
			//currants have changed, let's update the claim reqs
			currants_snapshot = pc_stats.currants;
			showClaimReqs();
			jigger();
		}
		
		private function onGroupsChanged(event:TSEvent):void {
			if(!visible) return;
			
			//refresh the list
			if(JobManager.instance.job_info && JobManager.instance.job_info.type == JobInfo.TYPE_GROUP_HALL){
				show();
			}
		}
		
		public function set w(value:int):void {
			_w = value;
			phase_ui.w = _w - _padd*2;
			jigger();
		}
		
		public function set h(value:int):void {
			_h = value;
			jigger();
		}
		
		public function set padd(value:int):void {
			_padd = value;
			phase_ui.w = _w - _padd*2;
			jigger();
		}
		
		public function get can_close():Boolean { return close_bt.visible && !close_bt.value; }
		public function get can_claim():Boolean { return claim_bt.visible && !claim_bt.disabled; }
		public function get showing_custom_name():Boolean { return custom_name_holder.visible; }
		public function get custom_name():String { return custom_name_tf.text; }
		public function get group_tsid():String { return close_bt.value; }
	}
}