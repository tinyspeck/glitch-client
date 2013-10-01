package com.tinyspeck.engine.view.gameoverlay {
	
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.net.NetOutgoingConversationCancelVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbCancelVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.ChatBubble;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IChoiceProvider;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.iChoiceAgent;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.InteractionMenu;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	public class ChoicesDialog extends TSSpriteWithModel implements IFocusableComponent, ITipProvider {
		
		public static const CONVERSATION:String = 'conversation';
		public static const FAM_CONVERSATION:String = 'familiar_conversation';
		
		/* singleton boilerplate */
		public static const instance:ChoicesDialog = new ChoicesDialog();
		
		private var _new_top_tf:TSLinkedTextField = new TSLinkedTextField();
		private var _title_tf:TextField = new TextField();
		
		private var _choices_btA:Array = [];
		private var _current_choice_i:int = -1;
		private var _agent:iChoiceAgent;
		private var _provider:IChoiceProvider;
		private var chat_bubble:ChatBubble = new ChatBubble();
		
		private var _top_msg_sprite:Sprite = new Sprite();
		private var _bott_msg_sprite:Sprite = new Sprite();
		private var _extra_controls_holder:Sprite = new Sprite();
		private var _content_sprite:Sprite = new Sprite();
		private var _close_buttons_sprite:Sprite = new Sprite();
		private var _graphic_holder:Sprite = new Sprite();
		private var _rewards_holder:Sprite = new Sprite();
		private var _performance_rewards_holder:Sprite = new Sprite();
		
		private var _which:String;
		private var _base_which:String;
		private var _base_choice:Object;
		private var _base_choice_candidate:Object;
		private var _extra_controls:*;
		private var _cancel_interaction_msg_type:String;
		private var _cancel_interaction_msg_uid:String;
		private var _interaction_ob_tsid:String;
		
		private var _waiting:Boolean = false;
		private var _choices:Object;
		private var has_focus:Boolean;
		private var _bg_is_gray:Boolean = true;
		private var _no_escape:Boolean = false;
		public var click_loc_to_cancel:Boolean = false; // right now we never change this. but we could, based on the type of conversation
		private var padd:int = 10;
		
		public var buttons_sprite:Sprite = new Sprite();
		
		private var last_vp_scale:Number = 1.0;
		
		public function ChoicesDialog():void {
			super();
			_construct();
		}
		
		public function demandsFocus():Boolean {
			return false;
			return _no_escape;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			if (choices && choices.location_itemstack_tsid) return false;
			return true;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			has_focus = false;
			_stopListeningToInput();
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			_startListeningToInput();
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		override protected function _construct():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			super._construct();
			registerSelfAsFocusableComponent()
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			
			visible = false;
						
			//once the chat bubble is loaded, make sure to refresh again
			chat_bubble.showing_sig.add(refresh);
			chat_bubble.is_convo = true;
			
			_content_sprite.name = '_content_sprite';
			addChild(_content_sprite);
			
			_close_buttons_sprite.useHandCursor = _close_buttons_sprite.buttonMode = true;
			_close_buttons_sprite.addEventListener(MouseEvent.CLICK, _escKeyHandler, false, 0, true);
			_close_buttons_sprite.name = '_close_buttons_sprite';
			
			buttons_sprite.name = 'choices_dialog_buttons_sprite';
			_content_sprite.addChild(buttons_sprite);
			
			_top_msg_sprite.name = '_top_msg_sprite';
			_content_sprite.addChild(_top_msg_sprite);
			
			_bott_msg_sprite.name = '_bott_msg_sprite';
			_content_sprite.addChild(_bott_msg_sprite);
			
			_extra_controls_holder.name = '_extra_controls_holder';
			_content_sprite.addChild(_extra_controls_holder);
			
			_content_sprite.addChild(_graphic_holder);
			
			_content_sprite.addChild(_rewards_holder);
			
			_content_sprite.addChild(_performance_rewards_holder);
			
			var tf:TextField = new TextField();
			tf.name = 'tf';
			TFUtil.prepTF(tf);
			tf.width = 300;
			tf.height = 25;
			_top_msg_sprite.addChild(tf);
			
			tf = new TextField();
			tf.name = 'tf';
			TFUtil.prepTF(tf);
			tf.width = 300;
			tf.height = 25;
			_bott_msg_sprite.addChild(tf);
			
			_new_top_tf.name = '_new_top_tf';
			TFUtil.prepTF(_new_top_tf);
			_new_top_tf.antiAliasType = AntiAliasType.NORMAL; // :(
			_content_sprite.addChild(_new_top_tf);
			
			_title_tf.name = 'title_tf';
			TFUtil.prepTF(_title_tf, false);
			_content_sprite.addChild(_title_tf);

			CONFIG::debugging {
				Console.log(35, 'ended');
			}
		}
		
		private function _tab_links_tfLinkHandler(e:TextEvent):void {
			var A:Array = e.text.split('-_-_-');
			var which:String = A[0];
			var what_tsid:String = A[1];
			/*
			if (which == 'iteminfo') {
				model.stateModel.get_item_info_class = what_tsid;
				//navigateToURL(new URLRequest(model.flashVarModel.url_root+'/item.php?tsid='+what_tsid), 'iteminfo');
				_makeNoChoice();
			} else if (which == 'pcinfo') {
				navigateToURL(new URLRequest(model.flashVarModel.root_url+'profiles/'+what_tsid+'/'), 'iteminfo');
			}*/
		}
		
		override protected function _deconstruct():void {
			super._deconstruct();
			// does nothing, because we never get rid of this displaymanager
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
		}
		
		protected function _jigger():void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			graphics.clear();
			_content_sprite.graphics.clear();
			buttons_sprite.graphics.clear();
			if (chat_bubble.parent) chat_bubble.parent.removeChild(chat_bubble);
			if (_close_buttons_sprite.parent) _close_buttons_sprite.parent.removeChild(_close_buttons_sprite);
			while (_close_buttons_sprite.numChildren) _close_buttons_sprite.removeChildAt(0);
			
			padd = 6;
			var overall_w:int;
			var overall_h:int;
			var content_h:int;
			
			if (choices.layout == FAM_CONVERSATION) padd = 25;
			
			_content_sprite.x = 0;
			_content_sprite.y = 0;
			_content_sprite.addChild(buttons_sprite);
			
			_graphic_holder.x = 10;
			_graphic_holder.y = 10;
			
			_new_top_tf.height = _new_top_tf.textHeight+4;
			
			if (choices.layout == CONVERSATION || choices.layout == FAM_CONVERSATION) {
				var gap:int = 15;
				
				if (choices.graphic_on_left && _graphic_holder.numChildren > 0) {
					_title_tf.x = gap + _graphic_holder.x + _graphic_holder.width;
					_title_tf.y = gap;
					
					_new_top_tf.x = _title_tf.x;
					_new_top_tf.y = _title_tf.y+_title_tf.height+0;
					
					overall_w = _graphic_holder.width+_new_top_tf.width+(padd*2);
				} else {
					_title_tf.x = (_graphic_holder.numChildren > 0 ? gap + _graphic_holder.width + 6 : padd);
					_title_tf.y = gap + (_graphic_holder.numChildren > 0 ? int(_graphic_holder.height/2 - _title_tf.height/2) - 6 : 0);
					
					_new_top_tf.x = padd;
					_new_top_tf.y = (_graphic_holder.numChildren > 0 ? padd + _graphic_holder.height + gap : _title_tf.y+_title_tf.height+0);
					
					overall_w = Math.max(_new_top_tf.width+padd*2, 
						_performance_rewards_holder.width+padd*2, 
						_rewards_holder.width+padd*2,
						buttons_sprite.width+padd*2);
				}
				
				//if we have performance rewards than this is the job being done
				_performance_rewards_holder.x = padd;
				_performance_rewards_holder.y = int(_new_top_tf.y+_new_top_tf.height + gap);
				
				_rewards_holder.x = _performance_rewards_holder.numChildren == 0 ? int(overall_w/2 - _rewards_holder.width/2) : padd;
				_rewards_holder.y = int(_performance_rewards_holder.y + _performance_rewards_holder.height) + 
									(_performance_rewards_holder.numChildren == 0 ? 0 : gap);
				
				//Console.warn(overall_w+' '+buttons_sprite.width);
				//Console.warn(buttons_sprite.getRect(buttons_sprite));
				
				if (choices.graphic_on_left && _graphic_holder.numChildren > 0) {
					buttons_sprite.x = _graphic_holder.x+_graphic_holder.width+gap;
				} else {
					buttons_sprite.x = int(overall_w/2 - buttons_sprite.width/2);
				}
				
				buttons_sprite.y = _rewards_holder.y+_rewards_holder.height + (_rewards_holder.numChildren > 0 ? 20 : 0);
				
				overall_h = buttons_sprite.y+buttons_sprite.height+padd+5;
				
				_new_top_tf.visible = choices.layout == FAM_CONVERSATION ? true : false;
				_title_tf.visible = choices.layout == FAM_CONVERSATION ? true : false;
			} else {
				buttons_sprite.x = padd;
				buttons_sprite.y = padd;
				
				overall_h = buttons_sprite.height+(padd*2);
				overall_w = buttons_sprite.width+(padd*2);
			}
			
			if (choices.layout == FAM_CONVERSATION) {
				//overall_h+= padd;
				filters = null;
				graphics.lineStyle(0, 0xffffff, 0);
				graphics.beginFill(0xefefef, 0);
				graphics.drawRect(0, 0, overall_w, overall_h);
				graphics.endFill();
			} else {			
				filters = null;
				graphics.clear();
			}
			
			if (choices.layout == FAM_CONVERSATION && !choices.no_escape) {
				
				_close_buttons_sprite.addChild(new Button({
					graphic: new AssetManager.instance.assets['close_x_small_gray'](),
					name: '_close_bt',
					c: 0x0a181d,
					high_c: 0x0a181d,
					disabled_c: 0x0a181d,
					shad_c: 0x0a181d,
					inner_shad_c: 0xcccccc,
					h: 20,
					w: 20,
					disabled_graphic_alpha: .3,
					focus_shadow_distance: 1
				}));
				_close_buttons_sprite.x = _content_sprite.width-_close_buttons_sprite.width+4;
				_close_buttons_sprite.y = 10;
				_content_sprite.addChild(_close_buttons_sprite);
				
			}
			
			visible = true;
			alpha = 0;
			
			if (choices.add_to) {
				CONFIG::debugging {
					Console.log(35, 'choices.add_to:'+choices.add_to);
				}
				choices.add_to.addChoicesDialog(this);
			} else {
				CONFIG::debugging {
					Console.log(35, 'choices.add_to:'+choices.add_to+' so adding to calling addChoicesDialogToDefaultLocation');
				}
				TSFrontController.instance.getMainView().addChoicesDialogToDefaultLocation();
			}
			
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {alpha:1, time:.1, delay:0, transition:'linear'});
			
			//position everything!
			refresh();
		}
		
		public function refresh():void {
			if(!visible && !choices) return;
			
			var end_x:int;
			var end_y:int;
			
			//make sure the dialog stays where it's supposed to!
			if(choices.xy){
				//put the point above the xy
				end_x = choices.xy.x;
				end_y = choices.xy.y;
			}
			else if(chat_bubble.width > 0) {
				//center it
				end_x = model.layoutModel.loc_vp_w/2 + model.layoutModel.gutter_w;
				end_y = model.layoutModel.loc_vp_h/2 + model.layoutModel.header_h + chat_bubble.height/2;
			}
			
			//if there are any offsets, let's add those
			end_x += choices.offset_xy.x;
			end_y += choices.offset_xy.y;
			
			//make sure this thing stays on the stage
			if(choices.layout != FAM_CONVERSATION){
				var min_y:int = chat_bubble.height + model.layoutModel.header_h + 25;
				var max_y:int = model.layoutModel.header_h + model.layoutModel.loc_vp_h;
				
				if(end_x - chat_bubble.width/2 - 5 < 0){
					end_x = chat_bubble.width/2 + 5;
				}
				else if(end_x + chat_bubble.width/2 - 36 > model.layoutModel.overall_w){
					end_x = int(model.layoutModel.overall_w - chat_bubble.width/2 + 36);
				}
				
				if(end_y < min_y){
					end_y = min_y;
				}
				else if(end_y > max_y){
					end_y = max_y;
				}
			}
			
			x = end_x;
			y = end_y;
		}
				
		override protected function _draw():void {
			super._draw();
			
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			
			/*
			var h:int = 250;
			var w:int = 400;
			
			_content_sprite.x = -(w/2);
			_content_sprite.y = -(h/2);
			
			// box
			_content_sprite.graphics.beginFill(0xffffff);
			_content_sprite.graphics.lineStyle(0, 0x000000);
			_content_sprite.graphics.drawRect(0, 0, w, h);
			*/

			CONFIG::debugging {
				Console.log(35, 'ended');
			}
		}
		
		public function present(agent:iChoiceAgent, provider:IChoiceProvider, which:String, base_choice:Object = null, extra_controls:* = null, extra_choicesH:Object = null):void {
			CONFIG::debugging {
				Console.log(35, 'started _waiting:'+_waiting);
			}
			
			if (_provider && !_waiting) { 
				// this means we were not able to end things properly,
				// probably because an interaction was not finished before
				// someone else started an interaction
				CONFIG::debugging {
					Console.warn('not ended properly; we still have a provider');
				}
				goAway();
			}
			
			if (!_waiting) {
				// just to make sure, because the last time around an explicit cancel might never have happened
				_sendCancelInteractionMsgIfNeeded();
			}
			
			waiting = false;
			_agent = agent;
			_provider = provider;
			_which = which;
			_base_which = _which;
			_base_choice = base_choice;
			_base_choice_candidate = null;
			_extra_controls = extra_controls;
			
			_provider.choiceStarting();
			
			var choices:Object = _provider.getChoices(_which, _base_choice, _extra_controls, extra_choicesH);
			
			
			if (!choices) {
				_end();
				return;
			}
			
			if (!choices.choicesA || (choices.choicesA.length == 0)) {
				_end();
				return;
			}
			_no_escape = (choices.no_escape == true);
			
			// hrm. This means if you only provide two choices, and the latter is value:false, and the first does not specify requires_choosing, it does an auto _makeChoice; why???? 
			if ((choices.choicesA.length == 1 || choices.choicesA.length == 2 && choices.choicesA[1].value === false) && !choices.choicesA[0].requires_choosing) {
				_current_choice_i = 0;
				_choices = choices; // must store this for _makeChoice!
				_makeChoice();
				return;
			}
			_actuallyPresent(choices);
		}
		
		private function _presentFollowup(which:String, base_choice:Object):void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			_which = which;
			_base_choice = base_choice;
			var choices:Object = _provider.getChoices(_which, _base_choice, _extra_controls);
			if (!choices) {
				//YYYYYconsole.warn('ChoicesDialog._presentFollowup got no choices back for '+_which);
				_end();
				return;
			}
			
			if (!choices.choicesA || choices.choicesA.length == 0) {
				//YYYYYconsole.warn('ChoicesDialog._presentFollowup got no choices.choicesA (or an empty array) back for '+_which);
				_end();
				return;
			}
			_actuallyPresent(choices);
		}
		
		private function _actuallyPresent(choices:Object):void {
			CONFIG::debugging {
				Console.log(35, 'started with:'+getQualifiedClassName(choices.choicesA));
			}
			
			var was_choices:Object = _choices; // store this in case requestFocus fails so we can set it back to the way it was.
			
			// store this for later reference! (this has to be before requestFocus, because that will call back to check some props on choices)
			_choices = choices;
			
			if (_choices.dont_take_focus) {
				buttons_sprite.addEventListener(MouseEvent.CLICK, _clickHandler);
				buttons_sprite.addEventListener(MouseEvent.MOUSE_OVER, _overHandler);
				buttons_sprite.addEventListener(MouseEvent.MOUSE_OUT, _outHandler);
			} else {
				if (model.stateModel.focused_component == this) {
					// make sure we take proper key and click focus!
					focus();
				} else if (!TSFrontController.instance.requestFocus(this, _choices)) {
					CONFIG::debugging {
						Console.warn('could not take focus');
					}
					_choices = was_choices; //this is just in case
					return;
				}
				
				InteractionMenu.instance.goAway();
			}
			
			// if the choice has these props, we need to send a msg to the GS on cancel.
			
			if (_choices.hasOwnProperty('cancel_interaction_msg_type') && _choices.interaction_ob_tsid) {
				// set this so that when it is cancelled we notify the GS
				_interaction_ob_tsid = _choices.interaction_ob_tsid;
				CONFIG::debugging {
					Console.log(35, 'NOW SET _interaction_ob_tsid:'+_interaction_ob_tsid);
				}
				_cancel_interaction_msg_type = _choices.cancel_interaction_msg_type;
				_cancel_interaction_msg_uid = _choices.cancel_interaction_msg_uid;
			}
			
			// if the choice has these props, we need to send a msg to the GS at start. Unless of course we already did
			
			var i:int;
			
			//clean up the sprites holding stuff
			clean();
			
			_current_choice_i = -1;
			_choices_btA.length = 0;
			
			_content_sprite.visible = true;
			_top_msg_sprite.visible = false;
			
			//reset
			_new_top_tf.visible = false;
			_new_top_tf.htmlText = '';
			//_new_top_tf.height = _new_top_tf.width = 0; why this breaks things?
			
			
			//a graphic?
			if(choices.hasOwnProperty('graphic')){				
				_graphic_holder.addChild(choices.graphic);
			}
			
			//if we have a title param let's make a title tf
			if(choices.hasOwnProperty('title')){
				_title_tf.htmlText = choices.title;
			}
			else {
				_title_tf.htmlText = '';
			}
						
			_extra_controls = null;
			_extra_controls_holder.visible = false;
			_bott_msg_sprite.visible = false;
			
			var bt:Button
			
			var A:Array = _choices.choicesA;
			
			var butt_gap_y:int = 2;
			var butt_gap_x:int = 3;
			var butt_h:int = 18;
			
			var content_w:int = 300; // width of the content area (padding will get added on later)
			var final_butt_w:int = 85; // width of ok button
			
			
			var butt_w:int = content_w;
			
			if (choices.layout == CONVERSATION) {
				content_w = 300;
				butt_w = 250;
				_new_top_tf.width = content_w;
				_new_top_tf.htmlText = '<p class="choices_conversation">'+choices.top_msg+'</p>';
				_new_top_tf.visible = true;
			} else if (choices.layout == FAM_CONVERSATION) {
				content_w = model.layoutModel.familiar_dialog_min_w-20; // 20 is twice the padding for 
				if(choices.job_obj) content_w += 70; //give a little more when we have to show job stuff
				
				if (choices.graphic_on_left && choices.graphic) {
					content_w-= choices.graphic.width;
				}
				
				butt_w = content_w-50;
				
				_new_top_tf.width = content_w;
				
				_new_top_tf.htmlText = '<p class="choices_familiar_conversation">'+
										StringUtil.replaceHTMLTag(choices.top_msg, 'b', 'span', 'choices_familiar_bold_replace')+
										'</p>';

				/*CONFIG::debugging {
					Console.warn(_new_top_tf.htmlText);
				}*/
				_new_top_tf.visible = true;
			}
			
			var tf:TextField = TextField(_top_msg_sprite.getChildByName('tf'));
			tf.width = content_w;
			tf.height = 0;
			tf = TextField(_bott_msg_sprite.getChildByName('tf'));
			tf.width = content_w;
			tf.height = 0;
			
			//rewards hash?
			var rewards:Vector.<Reward>;
			
			//handle regular rewards
			if(choices.hasOwnProperty('rewards')){
				rewards = choices.rewards;
				
				parseRewards(rewards, content_w, false);
			}
			
			//if we have performance rewards, then we need to shuffle some stuff around
			if(choices.hasOwnProperty('performance_rewards')){
				rewards = choices.performance_rewards;
				
				parseRewards(rewards, content_w, true);
			}
			
			_bg_is_gray = (choices.layout != FAM_CONVERSATION);
			butt_gap_y = 10;
			bt = null;
			
			const max_w:uint = 280;
			var bt_padd:int = choices.layout != FAM_CONVERSATION ? 7 : 11;
			var next_x:int;
			var next_y:int;
			var widest_w:int;
			var w_before_break:int;
			var min_bt_w:uint = 180;
			var butt_size:String = Button.SIZE_TINY;
			var butt_type:String =  Button.TYPE_MINOR;
			
			if (choices.layout == FAM_CONVERSATION) {
				butt_size = Button.SIZE_CONVERSATION;
				butt_type = Button.TYPE_DARK;
			}
			
			if (choices.button_style_size) {
				var size_name:String = 'SIZE_'+choices.button_style_size.toUpperCase();
				if (size_name in Button) butt_size = Button[size_name];
			}
			
			if (choices.button_style_type) {
				var type_name:String = 'TYPE_'+choices.button_style_type.toUpperCase();
				if (type_name in Button) butt_type = Button[type_name];
			}
			
			CONFIG::debugging {
				Console.info('butt_size:'+butt_size+' butt_type:'+butt_type);
			}
			
			for (i=0;i<A.length;i++) {
				bt = new Button({
					label: A[int(i)].label,
					name: A[int(i)].label,
					//x: (i==A.length-1 && A.length>1 && A[int(i)].value === false) ? content_w-((content_w-butt_w)/2)-final_butt_w : Math.round((content_w-butt_w)/2),
					//y: (bt) ? int(bt.y+bt.h+butt_gap_y) : 0,
					size: butt_size,
					type: butt_type,
					disabled: A[int(i)].disabled
				});
				
				//shrink the height to 25px via Stewart
				if(bt.type == Button.TYPE_MINOR){
					bt.h = 25;
					bt.label_y_offset = 2;
				}
				
				//if the value is cancel, let's make a red button
				if(A[int(i)].value == 'cancel'){
					bt.type = Button.TYPE_CANCEL;
				}
				
				if (bt.disabled) {
					if (A[int(i)].disabled_reason) {
						bt.tip = {
							txt: A[int(i)].disabled_reason,
							pointer: WindowBorder.POINTER_BOTTOM_CENTER	
						};
					}
				}
				
				if (bt.w>widest_w) widest_w = bt.w;
				buttons_sprite.addChild(bt);
				_choices_btA.push(bt);
				
				//helps for the single button
				//if(A.length == 1) w_before_break = bt.width;
												
				if(A.length > 1 && next_x + bt.width + bt_padd > max_w && choices.layout != FAM_CONVERSATION){					
					//new line
					next_x = 0;
					next_y += bt.height + bt_padd;
				}
				
				//layout the buttons
				bt.x = next_x;
				bt.y = next_y;
								
				next_x += bt.width + bt_padd;
				
				//see which row is the fatest for centering
				if(next_x > w_before_break) w_before_break = next_x;
			}
			
			var columns:Boolean = A.length >= 7 ? true : false;
			
			if (columns) {
				var cols:int = Math.ceil(A.length / 7);
				var col:int;
				var row:int;
				for (i=0;i<_choices_btA.length;i++) {
					col = (i % cols);
					row = Math.floor(i / cols);
					bt = _choices_btA[int(i)] as Button;
					if(bt){
						bt.x = (col * (widest_w+10)) + (widest_w/2 - bt.width/2);
						bt.y = row *int(bt.h+butt_gap_y)
					}
				}
			}
			//center them pretty
			else {
				var bt_width:int;
				var bt_to_center:Vector.<Button> = new Vector.<Button>();
				var j:int;
				
				for(i = 0; i < _choices_btA.length; i++){
					bt = _choices_btA[int(i)];
					bt_width += bt.width;
					
					//throw the buttons in if they fit in the w_before_break
					if(bt_width < w_before_break){
						bt_width += bt_padd;
						bt_to_center.push(bt);
					}
					else {
						//remove the last button width and add it back after we've done the proper loop
						bt_width -= bt.width;
						
						//take the buttons that are ready to center, and center them
						for(j = 0; j < bt_to_center.length; j++){
							bt_to_center[int(j)].x += int((w_before_break - bt_width)/2);
						}
						
						//reset the vector
						bt_to_center.length = 0;
						
						//set the width to the latest button and shove it into the vector
						bt_width = bt.width + bt_padd;
						bt_to_center.push(bt);
					}					
				}
				
				//do we have any left overs?
				for(j = 0; j < bt_to_center.length; j++){
					bt_to_center[int(j)].x += int((w_before_break - bt_width)/2);
				}
			}
						
			_jigger();
			
			var default_choice_index:int = (_choices.default_choice_index) ? _choices.default_choice_index : 0;
			
			try {
				// check if we're alredy over a button, and use that as the default
				var pt:Point = new Point(buttons_sprite.mouseX, buttons_sprite.mouseY);
				var buttA:Array = buttons_sprite.getObjectsUnderPoint((pt));
				for (var m:int=0;m<buttA.length;m++) {
					if (buttA[m].parent == buttons_sprite) default_choice_index = buttA[m].parent.getChildIndex(buttA[m]);
				}
			} catch (err:Error) {}
			
			_focusChoice(default_choice_index);
			
			//_startListeningToInput();
			
			// kind of a hack to keep the tips from obscuring menus
			TipDisplayManager.instance.goAway();
			
			// this must be at the end, dud
			if (choices.give_focus_to_tf) {
				StageBeacon.stage.focus = choices.give_focus_to_tf;
				choices.give_focus_to_tf.setSelection(0, choices.give_focus_to_tf.text.length);
			}
			
			//var chat_width:int = buttons_sprite.numChildren > 1 ? 0 : buttons_sprite.width;
			
			//by default make sure the rewards are in the content sprite
			if(!_content_sprite.contains(_rewards_holder)) _content_sprite.addChild(_rewards_holder);
			
			//if this is an itemstack having a conversation, make it so.
			if(choices.location_itemstack_tsid) {
				if (!choices.dont_take_focus && !choices.dont_take_camera_focus) {
					TSFrontController.instance.setCameraCenter(null, choices.location_itemstack_tsid, null, 0, true);
				}
				
				//do we have rewards?
				if(_rewards_holder.numChildren > 0){
					_rewards_holder.x = 0;
					_rewards_holder.y = 0;
					
					if(buttons_sprite.width > _rewards_holder.width){
						_rewards_holder.x = int(buttons_sprite.width/2 - _rewards_holder.width/2) - 2; //-2 is a visual tweak to center it proper
					}
					else {
						//let's center the buttons to the rewards
						var left_over_w:int = (_rewards_holder.width - buttons_sprite.width)/2;
						
						for(i = 0; i < buttons_sprite.numChildren; i++){
							buttons_sprite.getChildAt(i).x += left_over_w;
						}
					}
					
					//push all the buttons down by the height of the rewards
					for(i = 0; i < buttons_sprite.numChildren; i++){
						buttons_sprite.getChildAt(i).y += int(_rewards_holder.height + 10);
					}
										
					buttons_sprite.addChild(_rewards_holder);
				}
				
				//TSFrontController.instance.getMainView().addView(chat_bubble);
				var convo_title:String = choices.hasOwnProperty('title') && choices.title != '' 
										? '<span class="choices_conversation_title">'+choices.title+'</span><font size="3"><br><br></font>' 
										: '';
				TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCHTop(chat_bubble, 'CD._actuallyPresent');
				chat_bubble.show(convo_title+choices.top_msg, getPtForLIV(), buttons_sprite, 0, getReversTalkBubblePointerForLIV());
				chat_bubble.bubble_pointer.visible = true;
				
				chat_bubble.keep_in_viewport = !choices.dont_take_focus;
				// if not always in viewport, then at least within reason
				if (!chat_bubble.keep_in_viewport) chat_bubble.keep_in_viewport_within_reason = true;
				
				// TODO check a choices prop here for this, if we decide the bbbles with buttons should ever have this ability
				chat_bubble.allow_out_of_viewport_top = false;
				
				var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(choices.location_itemstack_tsid);
				lis_view.getRidOfBubble(); // we may need to make this smarter, have it set a prop on the liv that keeps all bubbles from happening whie this convo is cative. We'll see
				TSFrontController.instance.registerDisposableSpriteChangeSubscriber(chat_bubble, lis_view);
			}
			else {
				TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(chat_bubble);
				chat_bubble.keep_in_viewport = false;
				chat_bubble.allow_out_of_viewport_top = false;
			}

			if(choices.layout != FAM_CONVERSATION && !choices.location_itemstack_tsid){
				_content_sprite.addChild(chat_bubble);
				chat_bubble.show(choices.top_msg, null, buttons_sprite);
				chat_bubble.bubble_pointer.visible = choices.xy;
			}
		}
		
		private function getReversTalkBubblePointerForLIV():Boolean {
			if (!choices) {
				CONFIG::debugging {
					Console.error('no choices; this should never happen');
				}
				return false;
			}
			
			var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(choices.location_itemstack_tsid);
			if (!lis_view) {
				CONFIG::debugging {
					Console.error('no lis_view; this should never happen');
				}
				return false;
			}
			if (!choices.offset_xy) {
				return false;
			}
			
			if (choices.offset_xy.x < 0) return true;
			
			return false;
		}
		
		private function getPtForLIV():Point {
			if (!choices) {
				CONFIG::debugging {
					Console.error('no choices; this should never happen');
				}
				return null;
			}
			var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(choices.location_itemstack_tsid);
			if (!choices) {
				CONFIG::debugging {
					Console.error('no lis_view; this should never happen');
				}
				return null;
			}
			
			var pt:Point = lis_view.localToGlobal(new Point(0,0));
			pt.x = 0;
			pt.y = lis_view.getYAboveDisplay() - chat_bubble.bubble_pointer.height;
			
			if (choices.offset_xy) {
				//if there are any offsets, let's add those
				pt.x += choices.offset_xy.x;
				pt.y += choices.offset_xy.y;
			}
			
			return pt;
		}
		
		private function parseRewards(rewards:Vector.<Reward>, content_w:int, is_performance:Boolean):void {
			var slug:Slug;
			var slug_gap:int = 5;
			var recipe_count:int;
			var next_x:int = 3;
			var next_y:int;
			var iiv:ItemIconView;
			var recipe_tf:TextField;
			var reward_head_tf:TextField;
			var child:DisplayObject;
			var i:int = 0;
			var holder:Sprite = is_performance ? _performance_rewards_holder : _rewards_holder;
			
			for(i = 0; i < rewards.length; i++){
				if(rewards[int(i)].type == Reward.RECIPES){
					recipe_count++;
				}
				//drop tables don't get slugs
				else if(rewards[int(i)].type != Reward.DROP_TABLE) {
					slug = new Slug(rewards[int(i)], rewards[int(i)].type != Reward.ITEMS);
					slug.draw_border = false;
					slug.draw_background = rewards[int(i)].type != Reward.ITEMS;
					slug.x = next_x;
					slug.y = next_y;
					next_x += slug.width + slug_gap;
					holder.addChild(slug);
				}
			}
			
			//put on the amount of recipes
			if(recipe_count > 0){
				recipe_tf = new TextField();
				TFUtil.prepTF(recipe_tf, false);
				recipe_tf.htmlText = '<p class="choices_rewards_recipe">+'+recipe_count+' new '+(recipe_count > 1 ? 'recipes' : 'recipe')+'</p>';
				recipe_tf.x = next_x;
				holder.addChild(recipe_tf);
			}
						
			if(is_performance){				
				//put the header on the rewards slugs
				reward_head_tf = new TextField();
				TFUtil.prepTF(reward_head_tf);
				reward_head_tf.width = Math.max(_rewards_holder.width, _performance_rewards_holder.width, content_w);
				reward_head_tf.htmlText = '<p class="choices_rewards_header">Participation Rewards!<br>' +
										  '<span class="choices_familiar_conversation">'+
										  StringUtil.replaceHTMLTag(choices.job_obj.participation_txt, 'b', 'span', 'choices_familiar_bold_replace')+
										  '</span></p>';
				_rewards_holder.addChild(reward_head_tf);
				
				next_y = reward_head_tf.height + 5;
				
				//shuffle
				for(i = 0; i < _rewards_holder.numChildren-1; i++){
					child = _rewards_holder.getChildAt(i);
					child.y = next_y;
				}
			}
			
			if(rewards.length > 0 && is_performance){
				reward_head_tf = new TextField();
				TFUtil.prepTF(reward_head_tf);
				reward_head_tf.htmlText = '<p class="choices_rewards_header">Performance Rewards!<br>' +
									      '<span class="choices_familiar_conversation">'+
										  StringUtil.replaceHTMLTag(choices.job_obj.performance_txt, 'b', 'span', 'choices_familiar_bold_replace')+
										  '</span></p>';
				
				//set the header width
				reward_head_tf.width = Math.max(_rewards_holder.width, _performance_rewards_holder.width, content_w);
				_performance_rewards_holder.addChild(reward_head_tf);
				
				next_y = reward_head_tf.height + 5;
				
				//shuffle
				for(i = 0; i < _performance_rewards_holder.numChildren-1; i++){
					child = _performance_rewards_holder.getChildAt(i);
					child.y = next_y;
				}
			}
		}
		
		private function _clickHandler(e:Event):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			if (e.target is Button) {
				const bt:Button = e.target as Button;
				if(bt.disabled){
					SoundMaster.instance.playSound('CLICK_FAILURE');
					return;
				}
				
				// for convos in location, we should not allow button clicks when menus_prohibited==true
				if (choices && choices.location_itemstack_tsid && model.stateModel.menus_prohibited && !(model.stateModel.focused_component is ChoicesDialog)) {
					SoundMaster.instance.playSound('CLICK_FAILURE');
					return;
				}
				
				_focusChoice(e.target.parent.getChildIndex(e.target));
				//SoundMaster.instance.playSound('CLICK_SUCCESS');
				_makeChoice();
			}
		}
		
		private function _enterHandler(e:*):void {
			if(StageBeacon.stage.focus is TextField) return;
			//SoundMaster.instance.playSound('CLICK_SUCCESS');
			_makeChoice();
		}
		
		private function _overHandler(e:*):void {
			if (e.target is Button) {
				_focusChoice(e.target.parent.getChildIndex(e.target));
			}
		}
		
		private function _outHandler(e:*):void {
			if (e.target is Button && _choices.hasOwnProperty('default_choice_index')) {
				_focusChoice(_choices.default_choice_index);
			} else if (e.target is Button) {
				_focusChoice(_current_choice_i); // this relies on use getting the mOUSE_OUT event AFTER the button itself has gotten it. Might need priority tweaking at some point, or turning off of OUT handler on the buttons
			}
		}
		
		private function _focusChoice(i:int):void {
			if (_current_choice_i != i) {
				if (_current_choice_i != -1) _choices_btA[_current_choice_i].blur();
				_current_choice_i = i;
			}
			_choices_btA[int(i)].focus();
		}
		
		private function _focusNextChoice(e:* = null):void {
			if (_current_choice_i+1 >= _choices_btA.length) {
				_focusChoice(0);
			} else {
				_focusChoice(_current_choice_i+1);
			}
		}
		
		private function _focusPrevChoice(e:* = null):void {
			if (_current_choice_i-1 < 0) {
				_focusChoice(_choices_btA.length-1);
			} else {
				_focusChoice(_current_choice_i-1);
			}
		}
		
		private function _makeChoice():void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			if (!_choices) {
				CONFIG::debugging {
					Console.warn('got no choices back for '+_which);
				}
				_end();
				return;
			}
			
			if (!_choices.choicesA || _choices.choicesA.length == 0) {
				CONFIG::debugging {
					Console.warn('got no _choices.choicesA (or an empty array) back for '+_which);
				}
				_end();
				return;
			}
			
			var choice:Object = _choices.choicesA[_current_choice_i];
			
			var bt:Button = (_current_choice_i != -1) ? _choices_btA[_current_choice_i] as Button : null;
			if (bt && bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			if (!choice) {
				CONFIG::debugging {
					Console.warn('got no choice for '+_which+' _current_choice_i:'+_current_choice_i);
				}
				_end();
				return;
			}
			
			if (choice.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			//if (sound) SoundMaster.instance.playSound(sound);
			
			// I am not sure this is toally right, but without it, a cancel button does not send the cancelinteraction message
			if (choice.value === false) {
				_makeNoChoice(); return;
			}
			
			// only store a candidate, because it might not validate
			// if this a followup, add the choice to the _base_choice; otherwise, set the _base_choice
			if (_base_choice && _which) {
				// copy the _base_choice
				var buffer:ByteArray = new ByteArray();
				buffer.writeObject(_base_choice);
				buffer.position = 0;
				_base_choice_candidate = buffer.readObject();
				
				_base_choice_candidate[_which] = choice.value;
			} else {
				
				_base_choice_candidate = choice;
			}
			
			
			/* above used to be
			if (_base_choice && _which) {
			_base_choice[_which] = choice.value;
			} else {
			_base_choice = choice;
			}
			*/
			
			// if there is a followup specified for the choice made, inspect followup choices and either present or choose [0] if allowed
			if (choice.followup) {
				
				// get the new choices
				var choices:Object = _provider.getChoices(choice.followup, _base_choice_candidate, _extra_controls);
				if (!choices) {
					//YYYYYconsole.warn('got no choices back for '+choice.followup);
					_end();
					return;
				}
				
				if (choices.validated === false) {
					//YYYYYconsole.warn('got choices.validated === false back for '+choice.followup+ '.');
					return;
				}
				
				if (!choices.choicesA || choices.choicesA.length == 0) {
					//YYYYYconsole.warn('got no choices.choicesA (or an empty array) back for '+choice.followup);
					_end();
					return;
				}
				
				// we're good, so store as the real _base_choice
				_base_choice = _base_choice_candidate;
				
				if (choices.choicesA.length > 0) {
					if ((choices.choicesA.length == 1 || choices.choicesA.length == 2 && choices.choicesA[1].value === false) && !choices.choicesA[0].requires_choosing) {
						// choose [0]
						_which = choice.followup;
						_current_choice_i = 0;
						_choices = choices; // must store this for _makeChoice!
						_makeChoice();
					} else {
						//present followup!
						_presentFollowup(choice.followup, _base_choice);
					}
				}
				
			} else {
				_tryToEndWithChoice({
					which: _base_which,
					choice: _base_choice_candidate,
					provider: _provider,
					extra_controls: _extra_controls,
					bt: bt
				});
			}
		}
		
		private function _makeNoChoice(e:* = null):void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			_sendCancelInteractionMsgIfNeeded();
			_end();
		}
		
		private function _sendCancelInteractionMsgIfNeeded():void {
			CONFIG::debugging {
				Console.log(35, '_cancel_interaction_msg_type: '+_cancel_interaction_msg_type);
			}
			
			if (!_interaction_ob_tsid) return;
			
			try {
				
				if (_cancel_interaction_msg_type == 'itemstack_verb_cancel') {
					TSFrontController.instance.genericSend(
						new NetOutgoingItemstackVerbCancelVO(_interaction_ob_tsid)
					);
				} else if (_cancel_interaction_msg_type == 'conversation_cancel') {
					TSFrontController.instance.genericSend(
						new NetOutgoingConversationCancelVO(_interaction_ob_tsid, _cancel_interaction_msg_uid)
					);
				} else if (_cancel_interaction_msg_type) {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('unknown _cancel_interaction_msg_type:'+_cancel_interaction_msg_type);
					}
				}
			} catch (err:Error) {
				BootError.handleError('_sendCancelInteractionMsgIfNeeded failed', err, null, true);
			}
			
			_cancel_interaction_msg_type = null;
			_cancel_interaction_msg_uid = null;
			_interaction_ob_tsid = null;
		}
		
		private function _end(data:Object = null):void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			
			var was_agent:iChoiceAgent = _agent;
			
			if (_waiting) {
				_content_sprite.visible = false;
			} else {
				_completeTheClosing();
			}
			
			if (was_agent) was_agent.handleChoice(data);
			
			//kill the listeners
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, _escKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, _enterHandler);
			buttons_sprite.removeEventListener(MouseEvent.CLICK, _clickHandler);
			buttons_sprite.removeEventListener(MouseEvent.MOUSE_OVER, _overHandler);
			buttons_sprite.removeEventListener(MouseEvent.MOUSE_OUT, _outHandler);

			CONFIG::debugging {
				Console.log(35, 'ended');
			}
		}
		
		private function _getFinalChoiceData():Object {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			_base_choice = _base_choice_candidate;
			return {
				which: _base_which,
				choice: _base_choice,
				provider: _provider,
				extra_controls: _extra_controls
			}
		}
		
		public function closeAfterWaiting():void {
			if (_waiting) {
				_completeTheClosing();
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('not waiting, but it is ok')
				}
			}
		}
		
		public function isWaiting():Boolean {
			return _waiting;
		}
		
		private function set waiting(w:Boolean):void {
			_waiting = w;
			CONFIG::debugging {
				Console.trackValue('CD waiting', _waiting);
			}
		}
		
		private function _completeTheClosing():void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			
			TSFrontController.instance.releaseFocus(this);
			
			var cd:ChoicesDialog = this;
			TSTweener.removeTweens(cd);
			TSTweener.addTween(cd, {alpha:0, time:.1, delay:0, transition:'linear', onComplete:function():void {
				if (cd.parent) cd.parent.removeChild(cd);
				cd.visible = false;
			}});
			
			//stop listen to changes if we need to
			if(choices.location_itemstack_tsid){
				if (model.stateModel.camera_center_itemstack_tsid == choices.location_itemstack_tsid) {
					TSFrontController.instance.resetCameraCenter();
				}
				
				if (chat_bubble) {
					TSTweener.removeTweens(chat_bubble);
					TSTweener.addTween(chat_bubble, {alpha:0, time:.1, transition:'linear', onComplete:function():void {
						if(chat_bubble.parent) chat_bubble.parent.removeChild(chat_bubble);
					}});
					
					TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(chat_bubble);
					chat_bubble.keep_in_viewport = false;
					chat_bubble.allow_out_of_viewport_top = false;
				}
			}
				
			// make sure these are nulled out; should only happen when a choice has been made, I think
			_cancel_interaction_msg_type = null;
			CONFIG::debugging {
				Console.log(35, 'NULLING _interaction_ob_tsid:'+_interaction_ob_tsid);
			}
			_interaction_ob_tsid = null;
			waiting = false;
			_no_escape = false;
			StageBeacon.stage.focus = StageBeacon.stage;
			
			if (_provider) {
				_provider.choiceEnding();
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('_completeTheClosing called, but there is no provider')
				}
			}
			
			_base_choice = null;
			_agent = null;
			_provider = null;
			_which = null;
			
			TipDisplayManager.instance.goAway();
			
			//TSFrontController.instance.afterMenuClose();
		}
		
		private function _tryToEndWithChoice(data:Object):void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			
			// disallow any more input!
			if (choices.location_itemstack_tsid) {
				//if our data had a button passed in, let's make it disabled right away
				var bt:Button = data && 'bt' in data ? data.bt as Button : null;
				if (bt) {
					bt.disabled = true;
					bt.tip = null;
					bt.show_spinner = true;
				}
				
				//loop through each of the buttons and make them disabled as well
				for each(bt in _choices_btA) {
					bt.disabled = true;
					bt.tip = null;
				}
			}
			
			// eventually I think we will want validateChoice to return more than a Boolean,
			// because false will always mean wait() right now, and this is maybe not flexible enough
			if (_agent && !_agent.validateChoice(data)) {
				waiting = true;
			}
			
			_end(_getFinalChoiceData());
		}
		
		private function _startListeningToInput(e:* = null):void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, _focusNextChoice, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, _focusPrevChoice, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, _focusNextChoice, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, _focusPrevChoice, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, _escKeyHandler, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, _enterHandler, false, 0, true);
			buttons_sprite.addEventListener(MouseEvent.CLICK, _clickHandler, false, 0, true);
			buttons_sprite.addEventListener(MouseEvent.MOUSE_OVER, _overHandler, false, 0, true);
			buttons_sprite.addEventListener(MouseEvent.MOUSE_OUT, _outHandler, false, 0, true);
			CONFIG::debugging {
				Console.log(35, 'ended');
			}
			
			// temporarily reset zoom so you can read the bubbles
			if (isNaN(last_vp_scale)) {
				last_vp_scale = model.layoutModel.loc_vp_scale;
				TSFrontController.instance.resetViewportScale(model.flashVarModel.auto_zoom_ms);
			}
			
			TSFrontController.instance.startListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function zoomKeyHandler(e:KeyboardEvent):void {
			// it's important that we don't add shared listeners directly to TSFC
			// because where one class has started listening, another might
			// remove the same listener by accident, so the first class fails
			TSFrontController.instance.zoomKeyHandler(e);
		}
		
		private function _stopListeningToInput(e:* = null):void {
			CONFIG::debugging {
				Console.log(35, 'started');
			}
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, _focusNextChoice);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, _focusPrevChoice);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, _focusNextChoice);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, _focusPrevChoice);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, _escKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, _enterHandler);
			//buttons_sprite.removeEventListener(MouseEvent.CLICK, _clickHandler);
			//buttons_sprite.removeEventListener(MouseEvent.MOUSE_OVER, _overHandler);
			//buttons_sprite.removeEventListener(MouseEvent.MOUSE_OUT, _outHandler);
			CONFIG::debugging {
				Console.log(35, 'ended');
			}
			
			// restore last zoom zoom
			if (!isNaN(last_vp_scale)) {
				// disabling for now since it zooms out incorrectly at times
				//TSFrontController.instance.setViewportScale(last_vp_scale, model.flashVarModel.auto_zoom_ms);
				last_vp_scale = NaN;
			}
			
			TSFrontController.instance.stopListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function _escKeyHandler(e:Event):void {
			if (_no_escape) return;
			
			if (choices.cancel_value && _choices.choicesA) {
				for (var i:int;i<_choices.choicesA.length;i++) {
					if (_choices.choicesA[int(i)].value == choices.cancel_value) {
						_focusChoice(i);
						_makeChoice();
						return
					}
				}
			}
			
			//if we are viewing job rewards let the esc key make the default choice on the last screen
			if (_choices && _choices.job_obj && _choices.job_obj != '' && _choices.choicesA){
				var choice:Object = _choices.choicesA[_current_choice_i];
				
				if(choice.followup){
					//there is more to go, so put this convo to sleep
					_makeNoChoice();
				}
				else {
					//we've seen the last screen, so go ahead and make the choice
					_makeChoice();
				}
				return;
			}
			
			_makeNoChoice();
		}		
		
		public function goAway():void {
			if (_no_escape) {
				CONFIG::debugging {
					Console.error('this convo is marked as no escape, so I can\'t go away!');
				}
				return;
			}
			
			if (!_provider) return;
			
			if (false) {
				// we are no longer doing this
				TSFrontController.instance.releaseFocus(this);
				if (!visible) _makeNoChoice();
			} else {
				// but instead doing this
				if (visible) _makeNoChoice();
			}
		}
		
		private function clean():void {
			var child:DisplayObject;
			
			if (_close_buttons_sprite.parent) {
				_close_buttons_sprite.parent.removeChild(_close_buttons_sprite);
			} 
			
			SpriteUtil.clean(_close_buttons_sprite);
			SpriteUtil.clean(_graphic_holder);
			SpriteUtil.clean(_extra_controls_holder);
			SpriteUtil.clean(_rewards_holder, true, 0, TipDisplayManager.instance.unRegisterTipTrigger);
			SpriteUtil.clean(_performance_rewards_holder, true, 0, TipDisplayManager.instance.unRegisterTipTrigger);
			
			while (buttons_sprite.numChildren) {
				child = buttons_sprite.getChildAt(0);
				if (child is TSSprite) TSSprite(child).dispose();
				buttons_sprite.removeChild(child);
				child = null;
			}
		}
		
		// a service method for IChoiceProviders to use to break up text containing <split butt_txt="go on..." /> tags 
		public static function buildChunksA(msg_str:String, last_button_txt:String = 'OK'):Array {
			var chunksA:Array = [];
			
			var r:RegExp = /<split( *butt_txt *= *"[^>]*")* *\/*>/g;
			
			var splitsA:Array = msg_str.match(r); // an array of the <split butt_txt="go on..." /> tags
			//Console.warn('splitsA.length '+splitsA.length);
			
			var temp_split_str:String = '----TEMP----'; // first we have to replce the split tags with this, so that the .split works (.split on the r does not work?!)
			
			// now split the str apart into the chunks delimited by the split tags
			var msgA:Array = msg_str.replace(r, temp_split_str).split(temp_split_str);
			//Console.warn('msgA.length '+msgA.length);
			//Console.dir(msgA);
			
			// if there is at least one split tag, and the number of messages we get is one more than that number, GO!
			if (splitsA.length > 0 && splitsA.length == msgA.length-1) {
				
				var do_break:Boolean = false;
				for (var i:int=0; i<msgA.length;i++) {
					
					var chunk:Object = {
						msg_str: StringUtil.trim(msgA[int(i)])
					}
					
					if (i == msgA.length-1 || msgA[i+1] == '') { //last one
						
						chunk.button_label = last_button_txt;
						
						if (i != msgA.length-1 && msgA[i+1] == '') do_break = true; // do no more, because there is a next one and it is empty
						
					} else {
						
						chunk.button_label = 'OK';
						
						var butt_txt_r:RegExp = /"[^"]*/g;
						var att_valueA:Array = splitsA[int(i)].match(butt_txt_r);
						if (att_valueA.length > 0) {
							chunk.button_label = att_valueA[0].replace('"', '') || chunk.button_label;
						}
						
					}
					
					chunksA.push(chunk);
					
					if (do_break) break;
					
				}
				
			} else { // just stick into a single chunk
				chunksA = [{
					msg_str: StringUtil.trim(msg_str),
					button_label: last_button_txt
				}]
			}
			
			return chunksA;
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			return {
				txt: tip_target.name,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER	
			}
		}
		
		public function get choices():Object {
			return _choices;
		}
		
		public function get graphic_holder():Sprite {
			return _graphic_holder;
		}
		
		public function get rewards_holder():Sprite {
			return _rewards_holder;
		}
		
		public function get close_button():Sprite {
			return _close_buttons_sprite;
		}
		
		public function repositionIfShowingConversationForThisLIV(tsid:String):void {
			if (!tsid) return;
			if (choices && choices.location_itemstack_tsid == tsid) {
				if (chat_bubble) chat_bubble.positionContainer(getPtForLIV());
			}
		}
	}
}