package com.tinyspeck.engine.port {
	
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.net.NetIncomingMessageVO;
	import com.tinyspeck.engine.net.NetOutgoingConversationChoiceVO;
	import com.tinyspeck.engine.net.NetOutgoingQuestConversationChoiceVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.IChoiceProvider;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.iChoiceAgent;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class ConversationManager extends TSSpriteWithModel implements IChoiceProvider, iChoiceAgent {
		/* singleton boilerplate */
		public static const instance:ConversationManager = new ConversationManager();
		
		public static const TYPE_GREETER_COMING:String = 'greeter_coming';
		public static const TYPE_GREETER_ARRIVED:String = 'greeter_arrived';
		public static const TYPE_GREETER_PRESENT:String = 'greeter_present';
		public static const TYPE_QUEST_OFFER:String = 'quest_offer';
		public static const TYPE_QUEST_FINISHED:String = 'quest_finished';
		private var _uid:String;
		private var _itemstack_tsid:String;
		private var _dont_take_focus:Boolean;
		private var _dont_take_camera_focus:Boolean;
		private var _choicesA:Array = [];
		private var _cancel_value:String = '';
		private var _msg:String = '';
		private var _title:String = '';
		private var _graphic:DisplayObject;
		private var _rewards:Vector.<Reward>;
		private var _performance_rewards:Vector.<Reward>;
		private var _inited:Boolean = false;
		private var _cancel_interaction_msg_type:String = '';
		private var _quest_id:String;
		private var _job_obj:Object = {};
		private var _offset_xy:Point = new Point(0,0);
		private var _conv_type:String;
		private var _button_style_type:String;
		private var _button_style_size:String;
		
		/* constructor */
		public function ConversationManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init():void {
			_inited = true;
		}
		
		private var _choosing_started:Boolean;
		public function choiceStarting():void {
			_choosing_started = true;
			
		}
		
		public function choiceEnding():void {
			if (_itemstack_tsid == model.worldModel.pc.familiar.tsid) {
				CONFIG::debugging {
					Console.warn('fam_dialog_conv_is_active is now false');
				}
				model.stateModel.fam_dialog_conv_is_active = false;
				TSFrontController.instance.endFamiliarConversation(_conv_type, _quest_id);
			}
			_choosing_started = false;
			
			//_itemstack_tsid = '';
			//_uid = '';
			//_quest_id = ''; if we do this, because we return true in validateChoice, so the dialog is not waiting, _quest_id is empty in doChoice
		}
		
		public function actuallyStart(payload:Object):void {
			if (_choosing_started) {
				// we are currently running a convo, cancel
				ChoicesDialog.instance.goAway();
			}
			
			_quest_id = (payload.quest_id) ? payload.quest_id : '';
			_conv_type = (payload.conv_type) ? payload.conv_type : '';
			_itemstack_tsid = payload.itemstack_tsid;
			_uid = payload.uid;
			_dont_take_focus = payload.dont_take_focus === true;
			_dont_take_camera_focus = payload.dont_take_camera_focus === true;
			
			if (!_dont_take_camera_focus && !_dont_take_focus && _itemstack_tsid && model.worldModel.location.itemstack_tsid_list[_itemstack_tsid]) {
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(_itemstack_tsid);
				if (itemstack) {
					var pc:PC = model.worldModel.pc;
					var dist:int = Math.abs(Point.distance(new Point(pc.x, pc.y), new Point(itemstack.x, itemstack.y)));
					var dist_limit:int = 200;
					if (dist < dist_limit) {
						CONFIG::debugging {
							Console.warn('NOT taking camera focus for conversation because dist:'+dist+'<'+dist_limit);
						}
						_dont_take_camera_focus = payload.dont_take_camera_focus = true;
					}
				}
			}
			
			_button_style_type = payload.button_style_type || null;
			_button_style_size = payload.button_style_size || null;
			
			_presentChoices(payload);
		}
		
		// only to be called from NetController on an incoming message
		public function startWithIncomingMsg(payload:Object):void {
			// copy it, so we leave the underlying im.payload pristine
			// because we're going to be adding a DO to the payload
			payload = ObjectUtil.copyOb(payload);
			start(payload);
		}
		
		public function start(payload:Object):void {
			if (!payload.txt) return;
			
			if (payload.quest_id) {
				if (!payload.conv_type) {
					var quest:Quest = model.worldModel.getQuestById(payload.quest_id);
					if (quest) {					
						payload.conv_type = ConversationManager.TYPE_QUEST_FINISHED;
						payload.title = '<span class="choices_quest_title">Quest complete!</span>';
						payload.txt = '<span class="choices_quest_start_finish">'+quest.title+'</span><br>'+
									  StringUtil.injectClass(payload.txt, 'a', 'familiar_conversation_link');
						// if the msg specifies rewards, use that, otherwise use the default rewards for the quest
						if (!payload.rewards) payload.rewards = quest.rewards;
						payload.graphic = new AssetManager.instance.assets.familiar_dialog_quests_small();
					}
				} 
			}
			
			//if the type is a regular convo, but the server sends a title, we add the quest graphic as well
			if(!payload.conv_type && payload.title && payload.itemstack_tsid == model.worldModel.pc.familiar.tsid){
				payload.title = '<span class="choices_quest_title">'+payload.title+'</span>';
				if('feat_id' in payload){
					//show the little feat image
					payload.graphic = new AssetManager.instance.assets.feat_badge_small();
				}
				else {
					payload.graphic = new AssetManager.instance.assets.familiar_dialog_quests_small();
				}
			}
			
			if (isGreeterConv(payload.conv_type) && payload.greeter_ava_url) {
				//payload.title = '<span class="choices_quest_title">Welcome!</span>';
				payload.graphic = new Sprite();
				var g:Graphics = payload.graphic.graphics;
				g.beginFill(0xffffff, 0);
				g.drawRect(0, 0, 100, 144);
				
				var addGraphic:Function = function(filename:String, bm:Bitmap):void {
					if (!bm) {
						CONFIG::debugging {
							Console.error('WTF failed to load '+filename);
						}
						return;
					}
					
					bm.scaleX = -1;
					bm.x+= bm.width;
					payload.graphic.addChild(bm);
				}
				
				var ava_url:String = payload.greeter_ava_url+'_100.png';
				
				if (AssetManager.instance.getLoadedBitmapData(ava_url)) {
					addGraphic(ava_url, AssetManager.instance.getLoadedBitmap(ava_url));
				} else {
					AssetManager.instance.loadBitmapFromWeb(ava_url, addGraphic, 'CM.start()');
				}
				
				// if we're showing that a greeter is coming, and this is an annc that the greeter has arrived, switch now!
				if (payload.conv_type == TYPE_GREETER_ARRIVED) {
					if (ChoicesDialog.instance.choices && ChoicesDialog.instance.choices.conv_type == TYPE_GREETER_COMING) {
						ChoicesDialog.instance.goAway();
					}
				}
			}
						
			if(payload.job_id){
				if(!payload.conv_type){
					var title_txt:String = payload.hasOwnProperty('is_phase') && payload.is_phase ? 'Phase complete!' : 'Project complete!';
					payload.txt = '<span class="choices_quest_start_finish">'+title_txt+'</span><br>'+payload.txt;
				}
			}
			
			// if it is a familiar conversation, it needs to be routed through TSFrontController
			if (payload.itemstack_tsid == model.worldModel.pc.familiar.tsid) {
				// we pass force:true as second argument because we want it to happen immediately
				TSFrontController.instance.startFamiliarConversationWithPayload(payload, true);
			} else {
				if (payload.itemstack_tsid) {
					var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(payload.itemstack_tsid);
					
					if (lis_view) {
						NewxpLogger.log('conv_starting', payload.itemstack_tsid+' '+lis_view.item.tsid+' '+payload.txt);
					} else {
						NewxpLogger.log('conv_starting', payload.itemstack_tsid+' '+payload.txt);
					}
					if (lis_view && !lis_view.is_loaded) {
						lis_view.convo_to_run_after_load = payload;
						CONFIG::debugging {
							Console.info('DELAYING CONVO FOR LIS_VIEW:'+lis_view.tsid);
						}
						return;
					}
				}
				
				// I am not 100% sure this will always work, like if there are multiple things in the familiar q. but, we shall see
				if (model.stateModel.fam_dialog_conv_is_active) {
					TSFrontController.instance.endFamiliarDialog();
				}
				
				actuallyStart(payload);
			}
		}
		
		// gets called from TSFrontController when displaying the fam dialog conversation
		public function presentFamiliarChoices(payload:Object):void {
			model.stateModel.fam_dialog_conv_is_active = true;
			actuallyStart(payload);
		}
		
		public function isGreeterConv(conv_type:String):Boolean {
			if (conv_type == ConversationManager.TYPE_GREETER_COMING) return true;
			if (conv_type == ConversationManager.TYPE_GREETER_ARRIVED) return true;
			if (conv_type == ConversationManager.TYPE_GREETER_PRESENT) return true;
			return false;
		}
		
		public function getChoices(which:String = null, base_choice:Object = null, extra_controls:* = null, extra_choicesH:Object = null):Object {
			var choices:Object = {
				//			top_msg: _msg,
				//			choicesA: _choicesA,
				layout: 'conversation',
				conv_type: _conv_type,
				// these are required to send the GS notice when the conversation is cancelled
				cancel_interaction_msg_type: _cancel_interaction_msg_type, // this is not actually always needed, because no message shoudl be sent if a choices was received with no choices in it.
				cancel_interaction_msg_uid: _uid,
				interaction_ob_tsid: _itemstack_tsid,
				dont_take_focus: _dont_take_focus,
				dont_take_camera_focus: _dont_take_camera_focus
			}
			
			if (_itemstack_tsid == model.worldModel.pc.familiar.tsid) { // a fam conv
				
				// never send a cancel if we have no uid for a fam conv
				if (!_uid) { 
					delete choices.cancel_interaction_msg_type;
					delete choices.cancel_interaction_msg_uid;
				}
				
				choices.layout = ChoicesDialog.FAM_CONVERSATION;
				
				choices.xy = {
					x: 0,
					y: 0
				}
				
				choices.add_to = FamiliarDialog.instance;
				
				if (_conv_type == ConversationManager.TYPE_QUEST_OFFER) {
					choices.dont_take_focus = true;
				}
				
				if (isGreeterConv(_conv_type)) {
					choices.dont_take_focus = true;
					choices.graphic_on_left = true;
				}
			} else if (_itemstack_tsid) {
				// this allows the convo to stay on screen and you to move around at the saem time
				// but of course it also keeps you from being able to control the choicesDialog with keys
				//choices.dont_take_focus = true;
				
				choices.button_style_size = _button_style_size;
				choices.button_style_type = _button_style_type;
			}
			
			choices.cancel_value = _cancel_value;
			
			//let's add title and graphic shall we?
			choices.title = _title;
			if(_graphic) choices.graphic = _graphic;
			
			//make the door talk
			if (_itemstack_tsid.indexOf('geo:door:') != -1){
				choices.layout = ChoicesDialog.CONVERSATION;
				
				var door_id:String = _itemstack_tsid.substr(9); //'geo:door:'
				var door:DoorView = TSFrontController.instance.getMainView().gameRenderer.getDoorViewByTsid(door_id);
				var door_point:Point = door.localToGlobal(new Point(0, 0));
				
				// adjust to place it by the interaction_target
				if (door.interaction_target && door.interaction_target != door) {
					var rect:Rectangle = door.interactionBounds;
					door_point.x+= rect.x+Math.round(rect.width/2);
				}
								
				choices.xy = {
					x: door_point.x,
					y: door_point.y - 120//door.height
				}
			}
			
			//make the signpost talk
			if (_itemstack_tsid.indexOf('geo:signpost:') != -1){
				choices.layout = ChoicesDialog.CONVERSATION;
				
				var signpost_id:String = _itemstack_tsid.substr(13); //'geo:signpost:' 
				var signpost:SignpostView = TSFrontController.instance.getMainView().gameRenderer.getSignpostViewByTsid(signpost_id);
				var signpost_point:Point = signpost.localToGlobal(new Point(0, 0));
				
				choices.xy = {
					x: signpost_point.x,
					y: signpost_point.y - signpost.height
				}
			}
			
			var chunksA:Array = ChoicesDialog.buildChunksA(_msg);
			
			if (chunksA.length == 1) {
				
				// NORMAL NON CHUNKED SHIT
				
				choices.top_msg = _msg;
				choices.choicesA = _choicesA;
				
				if(_rewards) {
					choices.rewards = _rewards;
				}
				
				if(_performance_rewards) {
					choices.performance_rewards = _performance_rewards;
				}
				
			} else {
				
				// default is the first one
				var which_chunk_index:int = 0;
				
				// first time clicked, value of button will be in base_choice.value
				// subsequent times it will be in base_choice.chunked (because followup='chunked')
				if (base_choice && base_choice.chunked) {
					which_chunk_index = base_choice.chunked
				} else if (base_choice && base_choice.value) {
					which_chunk_index = base_choice.value;
				}
				
				var chunk:Object = chunksA[which_chunk_index];
				
				choices.top_msg = chunk.msg_str;
				
				if (which_chunk_index == chunksA.length - 1) { // if it is the last one, then show all the normal choices
					
					choices.choicesA = _choicesA;
					if(_rewards) {
						choices.rewards = _rewards;
					}
					
					if(_performance_rewards) {
						choices.performance_rewards = _performance_rewards;
					}
					
				} else {
					
					choices.choicesA = [{
						label: chunk.button_label,
						value: (which_chunk_index+1 == chunksA.length) ? false : which_chunk_index+1,
						followup: (which_chunk_index+1 == chunksA.length) ? null : 'chunked',
						requires_choosing: true
					}]
					
				}
			}
			
			var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(_itemstack_tsid);
			
			if (lis_view) {
				choices.location_itemstack_tsid = _itemstack_tsid; //store a reference to get it's current point when needed
			}
			
			//do we have a job?
			if(_job_obj.job_id != '') choices.job_obj = _job_obj;
			
			//throw the offsets in there
			choices.offset_xy = _offset_xy;
			
			return choices;
		}
		
		public function validateChoice(choice_data:Object):Boolean {
			CONFIG::debugging {
				Console.log(35, 'validateChoice');
			}
			
			if (choice_data.choice.value === false) {
				return true;
				//THIS NOW SHOULD NEVER HAPPEN, AS CLICKING A CHOICE WITH VALUE:false IS TREATED as makeNoChoice()
			} else {
				if (_conv_type == ConversationManager.TYPE_QUEST_OFFER) return true;  // in the case of quest offer conversation, we do not want to wait, just close normally
				if (_conv_type == ConversationManager.TYPE_QUEST_FINISHED) return true;  // this is optimistic and assume we will never get more choices or txt back in the rsp from the GS. PROBABLY NOT SAFE, but we now at least catch it in conversationChoiceHandler() if we do get choices back
				return false;
			}
		}
		
		public function handleChoice(choice_data:Object):void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}

			if (!choice_data) {
				//Console.warn('ConversationManager.handleChoice has no "choice_data" so we\'re ending this')
				return;
			}
			
			var choice:Object = choice_data.choice;
			var provider:* = choice_data.provider;
			var which:* = choice_data.which;
			
			if (!provider) {
				CONFIG::debugging {
					Console.warn('ConversationManager.handleChoice has no "provider"')
				}
				return;
			}
			
			if (!choice) {
				CONFIG::debugging {
					Console.warn('ConversationManager.handleChoice has no "choice", so we\'re not doing anything')
				}
				return;
			}
	
			CONFIG::debugging {
				Console.log(35, 'which: '+which)
				//Console.dir(choice);
			}
			
			if (choice_data.choice.value === false) {
				
				//THIS NOW SHOULD NEVER HAPPEN, AS CLICKING A CHOICE WITH VALUE:false IS TREATED as makeNoChoice()
				
			} else {
				
				if (_conv_type == ConversationManager.TYPE_QUEST_OFFER) {
					TSFrontController.instance.genericSend(
						new NetOutgoingQuestConversationChoiceVO(
							_quest_id,
							((choice_data.choice.chunked) ? choice_data.choice.chunked : choice_data.choice.value)
						)
					);
					
				} else {
					var msg:NetOutgoingConversationChoiceVO = new NetOutgoingConversationChoiceVO(
						_itemstack_tsid,
						((choice_data.choice.chunked) ? choice_data.choice.chunked : choice_data.choice.value),
						_uid
					)
					StageBeacon.setTimeout(_sendConversationChoice, 200, msg);
				}
			}
		}
		
		private function _sendConversationChoice(msg:NetOutgoingConversationChoiceVO):void {
			TSFrontController.instance.genericSend(msg);
		}
		
		public function conversationCancelHandler(im:NetIncomingMessageVO):void {
			
			if (im is NetResponseMessageVO) {
				// if it is a response to a message we sent, ignore.
			} else {
				// it is an event message, so let's close it down
				if (im.payload.itemstack_tsid == _itemstack_tsid) { // should also check here that
					ChoicesDialog.instance.goAway();
					//InteractionMenu.instance.goAway(); // I am not 100% sure this is needed
				}
			}
		}
		
		public function conversationChoiceHandler(rm:NetResponseMessageVO):void {
			var payload:Object = rm.payload;
			if (rm.success) {
				if (!payload.choices && !payload.txt) {
					ChoicesDialog.instance.closeAfterWaiting();
				} else {
					if (ChoicesDialog.instance.isWaiting()) {
						_presentChoices(payload);
					} else {
						// This can happen if we get choices back from a ConversationManager.TYPE_QUEST_FINISHED conversation choice msg. see validate choice
						// THE SERVER SHOULD NOT BE SENDING CHOICES BACK
						CONFIG::debugging {
							Console.error('WTF NOT WAITING')
						}
						BootError.handleError('conversationChoiceHandler_but_not_waiting '+rm.type+' '+StringUtil.getJsonStr(rm.payload)+'', new Error('conversationChoiceHandler_but_not_waiting'), ['conversation'], !CONFIG::god);
					}
				}
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.log(35, 'success!=true');
				}
				// NEED TO DO SOMETHIGN HERE! CLOSE THE CONVERSATION, ALERT THE USER TO THE ERROR.
				
				/*payload.error = {
				code:12,
				msg:'dddd'
				}*/
				var err_msg:String = 'ERROR';
				if (payload.error) {
					err_msg+= ' It was: code:'+payload.error.code+' msg:'+payload.error.msg
				}
				
				ChoicesDialog.instance.closeAfterWaiting();
			}
		}
		
		private function _presentChoices(payload:Object):void {
			_cancel_value = (payload.cancel_value) ? payload.cancel_value : '';
			_msg = (payload.txt) ? payload.txt : '';
			_title = (payload.title) ? payload.title : '';
			_graphic = (payload.graphic) ? payload.graphic : null;
			_rewards = (payload.rewards) ? (
														payload.rewards is Vector.<Reward> ? 
														payload.rewards : 
														Rewards.fromAnonymous(payload.rewards)
													) : null;
			_performance_rewards = (payload.performance_rewards) ? (
														payload.performance_rewards is Vector.<Reward> ? 
														payload.performance_rewards : 
														Rewards.fromAnonymous(payload.performance_rewards)
													) : null;
			_job_obj.job_id = (payload.job_id) ? payload.job_id : '';
			_job_obj.performance_txt = (payload.performance_txt) ? payload.performance_txt : '';
			_job_obj.participation_txt = (payload.participation_txt) ? payload.participation_txt : '';
			_job_obj.job_location = (payload.job_location) ? payload.job_location : '';
			_job_obj.is_phase = payload.hasOwnProperty('is_phase') ? payload.is_phase : false;
			_job_obj.teleport_txt = (payload.teleport_txt) ? payload.teleport_txt : '';
			_job_obj.show_teleport = payload.hasOwnProperty('show_teleport') ? payload.show_teleport : false;
			
			//check for offsets
			_offset_xy.x = payload.hasOwnProperty('offset_x') ? payload.offset_x : 0;
			_offset_xy.y = payload.hasOwnProperty('offset_y') ? payload.offset_y : 0;
			
			_cancel_interaction_msg_type = ''; // only set it if we have choices to display, because no cancel is nec if the server ends no choices
			//_msg = 'testing<split />'+payload.txt; // FOR TESTING chunkS
			_choicesA.length = 0;
			if (payload.choices) {
				_cancel_interaction_msg_type = 'conversation_cancel';
				for (var k:String in payload.choices) {
					if (!payload.choices[k].hasOwnProperty('txt') || !payload.choices[k].hasOwnProperty('value')) continue;
					_choicesA.push({
						label: payload.choices[k].txt,
						value: payload.choices[k].value,
						requires_choosing: true,
						order: ('order' in payload.choices[k] ? payload.choices[k].order : 0)
					});
					
					if (payload.choices[k].value == 'accept_and_start' && model.worldModel.location.no_starting_quests) {
						_choicesA[_choicesA.length-1].disabled = true;
						_choicesA[_choicesA.length-1].disabled_reason = 'Starting new quests is not allowed right now!';
					}
				}
			}
			
			//sort by order
			_choicesA.sortOn('order', Array.NUMERIC);
				
			if (_choicesA.length < 1) {
				_choicesA.push({
					label: 'OK',
					value: false,
					requires_choosing: true
				})
			} else {
				//_choicesA.push({
				//	label: 'never mind',
				//	requires_choosing: true,
				//	value: false
				//});
			}
			
			ChoicesDialog.instance.present(this, this, null);
		}
	}
}