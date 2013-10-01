package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.SDBItemInfo;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingGenericMsgVO;
	import com.tinyspeck.engine.net.NetOutgoingGetPathToLocationVO;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.GetInfoVO;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.gameoverlay.AchievementView;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.ItemSellersUI;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.utils.getTimer;


	public class GetInfoDialog extends BigDialog implements IMoveListener
	{
		/* singleton boilerplate */
		public static const instance:GetInfoDialog = new GetInfoDialog();
		
		private const ICON_WH:uint = 100;
		private const INFO_X:int = 200;
		
		private var reward_slug:Slug;
		private var item_info_ui:ItemInfoUI;
		private var skill_info_ui:SkillInfoUI;
		private var item_sellers_ui:ItemSellersUI;
		private var icon_view:ItemIconView;
		private var skill_icon:SkillIcon;
		private var share_bt:Button;
		private var chat_bt:Button;
		private var ok_bt:Button;
		private var auction_bt:Button;
		private var find_bt:Button;
		private var back_bt:Button;
		private var info_bt:Button;
		private var seller_bt:Button;
		private var info_url:URLRequest = new URLRequest();
		private var economy_api_call:APICall;
		
		private var find_icon:DisplayObject;
		private var find_icon_disabled:DisplayObject;
		
		private var burst_holder:Sprite = new Sprite();
		private var header_mask:Sprite = new Sprite();
		private var find_holder:Sprite = new Sprite();
		private var button_holder:Sprite = new Sprite();
		private var seller_divider:Shape = new Shape();
		private var button_cover:Shape = new Shape();
		private var button_shadow:Shape = new Shape();
		
		private var new_tf:TextField = new TextField();
		private var skill_time_tf:TextField = new TextField();
		private var find_tf:TSLinkedTextField = new TSLinkedTextField();
		private var no_sellers_tf:TextField = new TextField();
		
		private var item_class:String;
		private var skill_class:String;
		private var itemstack_tsid:String;
		private var routing_class:String;
		
		private var is_built:Boolean;
		private var is_item:Boolean;
		
		public function GetInfoDialog()
		{
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			close_on_move = false;
			
			_close_bt_padd_right = 8;
			_close_bt_padd_top = 8;
			_base_padd = 15;
			_w = 540;
			_title_padd_left = INFO_X;
			_head_min_h = 60;
			_body_min_h = 165;
			_body_max_h = 350;
			_draggable = true;
			_construct();
			
			item_info_ui = new ItemInfoUI(_w - INFO_X - _base_padd*2);
			TSFrontController.instance.registerMoveListener(this);
		}
		
		public function init():void {
			//listen for player changes
			model.worldModel.registerCBProp(onSkillComplete, "pc", "skill_training_complete");
			model.worldModel.registerCBProp(onSkillChange, "pc", "skill_training");
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			
			QuestManager.instance.addEventListener(TSEvent.QUEST_COMPLETE, onQuestComplete, false, 0, true);
			AchievementView.instance.addEventListener(TSEvent.COMPLETE, onAchievementComplete, false, 0, true);
		}
		
		private function buildBase():void {
			//title
			_title_tf.wordWrap = true;
			_title_tf.multiline = true;
			
			//set the header mask
			_head_sp.addChild(header_mask);
			_head_sp.mask = header_mask;
			
			//share button
			share_bt = new Button({
				name: 'share',
				label: 'See in Encyclopedia',
				label_face: 'Arial',
				label_size: 11,
				label_bold: true,
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				label_offset: 1,
				text_align: 'left',
				graphic: new AssetManager.instance.assets.encyclopedia_link(),
				graphic_placement: 'left',
				graphic_padd_l: 1,
				draw_alpha: 0,
				tip: {
					txt: 'Opens in a new window',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			});
			share_bt.x = _base_padd;
			share_bt.addEventListener(TSEvent.CHANGED, onEncyclopediaClick, false, 0, true);
			_body_sp.addChild(share_bt);
			
			chat_bt = new Button({
				name: 'chat',
				label: 'Create link for chat',
				label_face: 'Arial',
				label_size: 11,
				label_bold: true,
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				label_offset: 1,
				text_align: 'left',
				graphic: new AssetManager.instance.assets.encyclopedia_link(),
				graphic_placement: 'left',
				graphic_padd_l: 1,
				draw_alpha: 0
			});
			chat_bt.x = _base_padd;
			chat_bt.addEventListener(TSEvent.CHANGED, onChatClick, false, 0, true);
			_body_sp.addChild(chat_bt);
			
			//auction button
			const auction_DO:DisplayObject = new AssetManager.instance.assets.info_auction();
			auction_bt = new Button({
				name: 'auction',
				label: 'Find auctions',
				value: -1,
				label_face: 'Arial',
				label_size: 11,
				label_bold: true,
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				label_offset: 1,
				text_align: 'left',
				graphic: auction_DO,
				graphic_placement: 'left',
				graphic_padd_l: 3,
				draw_alpha: 0,
				tip: {
					txt: 'Opens in a new window',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			});
			auction_bt.x = _base_padd;
			auction_bt.addEventListener(TSEvent.CHANGED, onAuctionClick, false, 0, true);
			_body_sp.addChild(auction_bt);

			//find nearest
			find_icon = new AssetManager.instance.assets.find_nearest();
			find_icon.y = 3;
			find_holder.addChild(find_icon);
			find_icon_disabled = new AssetManager.instance.assets.find_nearest_disabled();
			find_icon_disabled.y = find_icon.y;
			find_holder.addChild(find_icon_disabled);
			
			TFUtil.prepTF(find_tf);
			find_tf.embedFonts = false;
			find_tf.x = find_icon.width + 2;
			find_tf.width = INFO_X - _base_padd*2 - find_tf.x;
			find_holder.addChild(find_tf);
			find_holder.x = int(_base_padd + auction_DO.width/2 - 2);
			_body_sp.addChild(find_holder);
			
			find_bt = new Button({
				name: 'find_action',
				label: 'Set as destination',
				label_face: 'Arial',
				label_size: 11,
				label_bold: true,
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				text_align: 'left',
				graphic: buildArrow(false),
				graphic_hover: buildArrow(true),
				graphic_placement: 'left',
				graphic_padd_l: 4,
				graphic_padd_r: -2,
				graphic_padd_t: 6,
				draw_alpha: 0,
				h: 12
			});
			find_bt.addEventListener(TSEvent.CHANGED, onFindClick, false, 0, true);
			find_bt.x = find_tf.x;
			find_holder.addChild(find_bt);
			
			//back button
			var back_DO:DisplayObject = new AssetManager.instance.assets.back_circle();

			back_bt = new Button({
				label: '',
				name: 'back',
				graphic: back_DO,
				graphic_hover: new AssetManager.instance.assets.back_circle_hover(),
				graphic_disabled: new AssetManager.instance.assets.back_circle_disabled(),
				w: back_DO.width,
				h: back_DO.height,
				draw_alpha: 0
			});
			back_bt.x = -back_DO.width/2 + 1;
			back_bt.y = 12;
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			
			//ok button 
			ok_bt = new Button({
				name: 'ok',
				label: 'OK!',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			ok_bt.x = _w-ok_bt.width-15;
			ok_bt.addEventListener(TSEvent.CHANGED, onOKClick, false, 0, true);
			button_holder.addChild(ok_bt);
			
			//new item text
			TFUtil.prepTF(new_tf, false);
			new_tf.htmlText = '<p class="get_info_new">You discover a useful new item!</p>';
			new_tf.mouseEnabled = false;
			new_tf.x = INFO_X;
			new_tf.y = 18;
			new_tf.visible = false;
			_head_sp.addChild(new_tf);
			
			//reward slug
			var reward:Reward = new Reward(Reward.IMAGINATION);
			reward.type = Reward.IMAGINATION;
			reward.amount = 5;
			reward_slug = new Slug(reward);
			reward_slug.x = int(INFO_X + new_tf.width + 5);
			reward_slug.visible = false;
			_head_sp.addChild(reward_slug);
			
			//handle the burst
			burst_holder.mouseEnabled = false;
			burst_holder.mouseChildren = false;
			burst_holder.visible = false;
			_head_sp.addChild(burst_holder);
			var burst_loader:MovieClip = new AssetManager.instance.assets.item_info_burst();
			burst_loader.addEventListener(Event.COMPLETE, placeBurst, false, 0, true);
			
			//the item info ui
			item_info_ui.x = INFO_X;
			item_info_ui.y = _base_padd/2;
			item_info_ui.addEventListener(TSEvent.CHANGED, onItemInfoChanged, false, 0, true);
			
			//the skill info ui
			skill_info_ui = new SkillInfoUI(_w - INFO_X - _base_padd*2, this);
			skill_info_ui.x = INFO_X;
			skill_info_ui.y = _base_padd/2;
			skill_info_ui.addEventListener(TSEvent.CHANGED, onSkillInfoChanged, false, 0, true);
			
			//time to learn skill
			TFUtil.prepTF(skill_time_tf);
			skill_time_tf.wordWrap = false;
			_body_sp.addChild(skill_time_tf);
						
			addChild(_close_bt); // make sure it stays on top
			
			if(model.flashVarModel.use_economy_info){
				const bt_h:uint = 23;
				
				//api call to view recent sellings of an item
				economy_api_call = new APICall();
				economy_api_call.addEventListener(TSEvent.COMPLETE, onEconomyComplete, false, 0, true);
				
				info_bt = new Button({
					name: 'info',
					label: 'Info',
					size: Button.SIZE_VERB,
					type: Button.TYPE_INFO_TAB,
					use_hand_cursor_always: true,
					h: bt_h
				});
				info_bt.x = 15;
				info_bt.y = -11;
				info_bt.addEventListener(TSEvent.CHANGED, onInfoClick, false, 0, true);
				button_holder.addChild(info_bt);
				
				seller_bt = new Button({
					name: 'sale',
					label: 'Find Sellers',
					size: Button.SIZE_VERB,
					type: Button.TYPE_INFO_TAB,
					use_hand_cursor_always: true,
					disabled: true,
					h: bt_h
				});
				seller_bt.x = int(info_bt.x + info_bt.width + 5);
				seller_bt.y = info_bt.y;
				seller_bt.addEventListener(TSEvent.CHANGED, onSellerClick, false, 0, true);
				button_holder.addChild(seller_bt);
				
				item_sellers_ui = new ItemSellersUI(_w - INFO_X);
				item_sellers_ui.x = INFO_X;
				
				seller_divider.x = INFO_X+1;
				seller_divider.y = _head_min_h;
				seller_divider.visible = false;
				addChild(seller_divider);
				
				//setup the button covers
				addChild(button_cover);
				
				button_shadow.filters = StaticFilters.copyFilterArrayFromObject({knockout:true}, StaticFilters.black3px90DegreesInner_DropShadowA);
				addChild(button_shadow);
				
				//the text field for selling things
				TFUtil.prepTF(no_sellers_tf);
				no_sellers_tf.width = 200;
				no_sellers_tf.htmlText = '<p class="get_info_no_sellers">Darn!<br>It seems that no one is selling these.<br><br>Maybe you should jump on this untapped market!</p>';
				no_sellers_tf.x = int(INFO_X + (_w - INFO_X)/2 - no_sellers_tf.width/2);
			}
			
			is_built = true;
		}
		
		private function buildArrow(is_hover:Boolean):Sprite {
			const arrow_bm:Bitmap = new AssetManager.instance.assets['solid_arrow'+(is_hover ? '_hover' : '')]();
			const arrow:Sprite = new Sprite();
			arrow_bm.smoothing = true;
			SpriteUtil.setRegistrationPoint(arrow_bm);
			arrow.addChild(arrow_bm);
			arrow.rotation = 180;
			arrow.scaleX = arrow.scaleY = .6;
			
			return arrow;
		}
		
		private function placeBurst(event:Event):void {
			var burst:MovieClip = Loader(event.target.getChildAt(0)).content as MovieClip;
			
			if(burst){
				SpriteUtil.setRegistrationPoint(burst);
				burst_holder.addChild(burst);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('SOMETHING WRONG WITH ADDING THE BURST!');
				}
			}
			burst_holder.x = int(INFO_X/2);
			
			_jigger();
		}
		
		public function showInfo(giVO:GetInfoVO):void {
			if (giVO.type == GetInfoVO.TYPE_ITEM) {
				showItemInfo(giVO.item_class, giVO.itemstack_tsid);
			} else if (giVO.type == GetInfoVO.TYPE_SKILL) {
				showSkillInfo(giVO.skill_class);
			} else {
				;
				CONFIG::debugging {
					Console.error('WTF type:'+giVO.type);
				}
			}
		}
		
		private function showItemInfo(item_class:String, itemstack_tsid:String):void {
			this.skill_class = null;
			this.routing_class = null;
			
			this.item_class = item_class;
			this.itemstack_tsid = itemstack_tsid;
			
			var item:Item = model.worldModel.getItemByTsid(item_class);
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(itemstack_tsid);
			
			if (itemstack) {
				routing_class = itemstack.routing_class;
			} else {
				routing_class = item.routing_class;
			}
			
			CONFIG::debugging {
				Console.info('routing_class:'+routing_class);
			}
			
			
			//build the base stuff 
			if(!is_built) buildBase();
			
			new_tf.visible = burst_holder.visible = reward_slug.visible = false;
						
			start();
		}
		
		private function showSkillInfo(skill_class:String):void {
			this.item_class = null;
			this.skill_class = skill_class;
			
			//build the base stuff 
			if(!is_built) buildBase();
			
			new_tf.visible = burst_holder.visible = reward_slug.visible = false;
						
			start();
		}
		
		private var callback_msg_when_closed:String;
		public function startFromServer(payload:Object):void {
			if(payload.class_tsid){
				if (payload.callback_msg_when_closed) {
					callback_msg_when_closed = payload.callback_msg_when_closed;
				}
				
				TSFrontController.instance.showItemInfo(payload.class_tsid);
				
				new_tf.visible = burst_holder.visible = payload.is_new;
				
				if ('xp' in payload && int(payload.xp) > 0) {
					reward_slug.visible = true;
					reward_slug.amount = payload.xp;
				} else {
					reward_slug.visible = false;
				}
				
				_jigger();
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Can\'t view an item without a class_tsid!');
				}
			}
		}
		
		override public function start():void {
			if(!canStart(model.flashVarModel.ok_on_info)) return;
			
			//build the base stuff 
			if(!is_built) buildBase();
						
			auction_bt.visible = false;
			find_holder.visible = false;
			
			if(model.flashVarModel.use_economy_info){
				info_bt.visible = false;
				info_bt.disabled = false;
				seller_bt.visible = false;
				seller_bt.disabled = true;
				button_cover.visible = false;
				button_shadow.visible = false;
				if(no_sellers_tf.parent) no_sellers_tf.parent.removeChild(no_sellers_tf);
			}
			
			//see what we need to show
			if(item_class){
				showItem();
			}
			else if(skill_class){
				showSkill();
			}
			else {
				CONFIG::debugging {
					Console.warn('Missing item_class AND skill_class');
				}
				return;
			}
			
			//handle the back button
			if(model.stateModel.get_info_history.length > 1){
				var giVO:GetInfoVO = model.stateModel.get_info_history[model.stateModel.get_info_history.length-2];
				var bt_tip:Object = { pointer: WindowBorder.POINTER_BOTTOM_CENTER };
				
				switch(giVO.type){
					case GetInfoVO.TYPE_ITEM:
						var item:Item = model.worldModel.getItemByTsid(giVO.item_class);
						if(item) bt_tip.txt = item.label;
						break;
					
					case GetInfoVO.TYPE_SKILL:
						var skill_details:SkillDetails = model.worldModel.getSkillDetailsByTsid(giVO.skill_class);
						if(skill_details) bt_tip.txt = skill_details.name;
						break;
					
					default:
						bt_tip = null;
						break;
				}
				
				addChild(back_bt);
				back_bt.tip = bt_tip;
			}
			else if(back_bt.parent){
				back_bt.parent.removeChild(back_bt);
			}
			
			if (model.flashVarModel.ok_on_info && item_class) {
				_setFootContents(button_holder);
			} else {
				_setFootContents(null);
			}
			
			//only recall start if there isn't a parent
			if(!parent) {
				super.start();
			} else {
				// pop it to the top
				TSFrontController.instance.getMainView().addView(this);
			}
			
			//set the last_x and last_y so this thing doesn't go all over the place
			last_x = x;
			last_y = y;
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			last_x = 0;
			last_y = 0;
			
			//only once the window is closed do we wipe the item history
			model.stateModel.get_info_history.length = 0;
			
			if (callback_msg_when_closed) {
				TSFrontController.instance.genericSend(new NetOutgoingGenericMsgVO(callback_msg_when_closed));
				callback_msg_when_closed = null;
			}
		}
		
		public function preloadItems(item_tsids:Array):void {
			item_info_ui.preloadItems(item_tsids);
		}
		
		private function showItem():void {
			if (!item_class) {
				CONFIG::debugging {
					Console.warn('no item_class')
				}
				return;
			}
			var item:Item = model.worldModel.getItemByTsid(item_class);
			if (!item) {
				CONFIG::debugging {
					Console.warn('invalid item_class: '+item_class)
				}
				return;
			}
			
			is_item = true;
			share_bt.visible = false;
			
			if(_scroller.body.contains(skill_info_ui)) _scroller.body.removeChild(skill_info_ui);
			if(item_sellers_ui && _scroller.body.contains(item_sellers_ui)) {
				_scroller.body.removeChild(item_sellers_ui);
				seller_divider.visible = false;
				button_cover.visible = false;
				button_shadow.visible = false;
			}
			if(no_sellers_tf.parent) no_sellers_tf.parent.removeChild(no_sellers_tf);
			if(!_scroller.body.contains(item_info_ui)) _scroller.body.addChild(item_info_ui);
			
			//no longer caching information as it is per player (red box showing why they can't use an item for example
			_setTitle('<p class="get_info_title">'+item.label+'</p>');
			
			//load the item data
			var itemstack:Itemstack = (itemstack_tsid) ? model.worldModel.getItemstackByTsid(itemstack_tsid) : null;
			var item_state:String = (!itemstack || !itemstack.itemstack_state || !Item.shouldUseCurrentStateForIconView(itemstack.class_tsid)) ? null : itemstack.itemstack_state.value;
			item_info_ui.visible = true;
			
			var force_reload:Boolean = !item.details || item.details.warnings.length != 0 || item.details.tips.length != 0;
			if (force_reload && item.details) {
				if (getTimer() - item.details_retrieved_ms < 5000) {
					force_reload = false;
				}
			}
			item_info_ui.show(item_class, force_reload, routing_class);
			
			// if we hve a stack, use its class for the icon, because it might be different than item_class due to Item.proxy_item
			var icon_item_class:String = (itemstack) ? itemstack.class_tsid : item_class;
			
			//set the url for when the encyclopedia link is clicked (starts with a / so we cut that off)
			info_url.url = item.details && item.details.info_url != null ? model.flashVarModel.root_url+item.details.info_url.substr(1) : null;
			
			//load the icon
			if(icon_view && icon_view.name == icon_item_class && (!icon_view || icon_view.s == item_state)) {
				//nuffin'
			}
			else {				
				if(icon_view && icon_view.parent){
					icon_view.parent.removeChild(icon_view);
					icon_view.dispose();
					icon_view = null;
				}
				/*
				CONFIG::debugging {
					Console.warn(item_state);
				}
				*/
				icon_view = new ItemIconView(icon_item_class, ICON_WH, item_state, 'default', false, true, false, true);
				icon_view.visible = false;
				icon_view.x = int(INFO_X/2 - ICON_WH/2);
				if (icon_view.loaded) {
					onIconLoad();
				} else {
					icon_view.addEventListener(TSEvent.COMPLETE, onIconLoad, false, 0, true);
				}
				icon_view.name = icon_item_class;
				icon_view.mouseEnabled = false;
				addChild(icon_view);
			}
			
			//kill the skill icon
			if(skill_icon && skill_icon.parent){
				skill_icon.parent.removeChild(skill_icon);
				skill_icon = null;
			} 
			skill_info_ui.visible = false;
			skill_time_tf.visible = false;
		}
		
		private function onIconLoad(e:TSEvent=null):void {	
			_jigger();
			if (icon_view) icon_view.visible = true;
		}
		
		private function showSkill():void {			
			if (!skill_class) {
				CONFIG::debugging {
					Console.warn('no skill_class')
				}
				return;
			}
			
			is_item = false;
			
			if(_scroller.body.contains(item_info_ui)) _scroller.body.removeChild(item_info_ui);
			if(item_sellers_ui && _scroller.body.contains(item_sellers_ui)) {
				_scroller.body.removeChild(item_sellers_ui);
				seller_divider.visible = false;
				button_cover.visible = false;
				button_shadow.visible = false;
			}
			if(no_sellers_tf.parent) no_sellers_tf.parent.removeChild(no_sellers_tf);
			if(!_scroller.body.contains(skill_info_ui)) _scroller.body.addChild(skill_info_ui);
			
			_setTitle('<p class="get_info_title">&nbsp;</p>');
			
			skill_info_ui.visible = true;
			skill_info_ui.show(skill_class, true);
			share_bt.visible = false;
			skill_time_tf.visible = false;
			
			//load the icon
			if(skill_icon && skill_icon.name == skill_class) {
				//nuffin'
			}
			else {				
				if(skill_icon && skill_icon.parent){
					skill_icon.parent.removeChild(skill_icon);
					skill_icon = null;
				} 
				
				skill_icon = new SkillIcon(skill_class, SkillIcon.SIZE_100);
				skill_icon.mouseEnabled = false;
				skill_icon.x = int(INFO_X/2 - skill_icon.width/2);
				addChild(skill_icon);
			}
			
			//kill the item icon
			if(icon_view && icon_view.parent){
				icon_view.parent.removeChild(icon_view);
				icon_view.dispose();
				icon_view = null;
			}
			item_info_ui.visible = false;
		}
		
		private function onItemInfoChanged(event:TSEvent):void {
			_jigger();
		}
		
		private function onSkillInfoChanged(event:TSEvent):void {
			//becuase we don't know things until the API sends them to us, we populate them here
			_setTitle('<p class="get_info_title">'+skill_info_ui.current_details.name+'</p>');
			
			//set the url for when the encyclopedia link is clicked
			info_url.url = skill_info_ui.current_details.url;
			share_bt.visible = true;
			
			if(skill_info_ui.current_details.got){
				skill_time_tf.htmlText = '<p class="get_info_skill_time"><span class="get_info_skill_learn">You know this skill</span></p>';
				skill_time_tf.visible = true;
			}
			else if(skill_info_ui.current_details.seconds){
				skill_time_tf.htmlText = '<p class="get_info_skill_time">'+StringUtil.formatTime(skill_info_ui.current_details.seconds, true, true, 2) +
										 '<br><span class="get_info_skill_learn">to learn</span></p>';
				skill_time_tf.visible = true;
			}
			
			_jigger();
		}
		
		private function onEncyclopediaClick(event:TSEvent):void {
			//what happens when we click a link
			navigateToURL(info_url, URLUtil.getTarget("iteminfo"));
		}
		
		private function onOKClick(event:TSEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			end(true);
		}
		
		private function onFindClick(event:TSEvent):void {
			//depending on what we are showing, do different things
			if(find_bt.value == 'return'){
				//head back to the real world
				TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO('/leave'));
				//end(true);
			}
			else {
				//set the location
				if(MiniMapView.instance.visible){
					//tsid is in the find_bt.value
					TSFrontController.instance.genericSend(new NetOutgoingGetPathToLocationVO(find_bt.value));
					end(true);
				}
				else {
					//no dice, throw a message in local activity
					model.activityModel.activity_message = Activity.createFromCurrentPlayer('Your mini map must be visible in order to set a destination');
				}
			}
		}
		
		private function onInfoClick(event:TSEvent = null):void {
			if(!info_bt.disabled) return;
			
			//show the base item info
			if(item_sellers_ui.parent) {
				item_sellers_ui.parent.removeChild(item_sellers_ui);
			}
			
			if(!_scroller.body.contains(item_info_ui)) _scroller.body.addChild(item_info_ui);
			
			if(model.flashVarModel.use_economy_info){
				seller_bt.disabled = true;
				info_bt.disabled = false;
				seller_divider.visible = false;
				if(no_sellers_tf.parent) no_sellers_tf.parent.removeChild(no_sellers_tf);
			}
			
			_jigger();
		}
		
		private function onSellerClick(event:TSEvent = null):void {
			if(!seller_bt.disabled) return;
			
			//display the api data about recent sales
			if(item_info_ui.parent) item_info_ui.parent.removeChild(item_info_ui);
			
			//get the sales info for this bad boy
			if(model.flashVarModel.use_economy_info && item_class){
				economy_api_call.economyBestSDBs(item_class);
				seller_bt.disabled = false;
				info_bt.disabled = true;
			}
			
			_jigger();
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			if (button_holder.parent) { // item info
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				end(true);
			} else if (skill_info_ui.parent) { // skill info
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				skill_info_ui.dialogEnterKeyHandler(e);
			}
		}
		
		override protected function leftArrowKeyHandler(e:KeyboardEvent):void {
			if (back_bt.parent && model.stateModel.get_info_history.length > 1) {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				goBack();
			}
		}
		
		private function onBackClick(event:TSEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			goBack();
		}
		
		private function goBack():void {
			//remove the last element and then view the one before that
			model.stateModel.get_info_history.pop();
			var giVO:GetInfoVO = model.stateModel.get_info_history[model.stateModel.get_info_history.length-1];
			showInfo(giVO);
		}
		
		private function onAuctionClick(event:TSEvent):void {
			TSFrontController.instance.openAuctionsPage(null, auction_bt.value);
		}
		
		private function onSkillComplete(pc_skill:PCSkill):void {
			//player has changed!
			reload();
		}
		
		private function onSkillChange(pc_skill:PCSkill):void {
			//player is doing something with skill, reload
			if(!is_item) reload();
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {			
			//new stats, let's reload the data -- commented out for now as this could get nuts
			//reload();
		}
		
		private function onQuestComplete(event:TSEvent):void {
			if(parent) reload();
		}
		
		private function onAchievementComplete(event:TSEvent):void {
			if(parent) reload();
		}
		
		private function onChatClick(event:TSEvent):void {
			//puts the link in the chat window
			const chat_area:ChatArea = RightSideManager.instance.right_view.getChatToFocus();
			var label:String;
			var link_txt:String;
			
			if(is_item){
				const item:Item = model.worldModel.getItemByTsid(item_class);
				if(item){
					label = item.label;
					link_txt = TSLinkedTextField.LINK_ITEM+'|'+item_class;
				}
			}
			else {
				const skill:SkillDetails = model.worldModel.getSkillDetailsByTsid(skill_class);
				if(skill){
					label = skill.name;
					link_txt = TSLinkedTextField.LINK_SKILL+'|'+skill_class;
				}
			}
			
			//toss it in the chat area
			if(chat_area && label){
				chat_area.input_field.setLinkText(label, link_txt);
				chat_area.focus();
			}
		}
		
		private function onEconomyComplete(event:TSEvent):void {
			//enable us to click things
			if(item_sellers_ui && event && event.data) {
				if(!_scroller.body.contains(item_sellers_ui)) _scroller.body.addChild(item_sellers_ui);
				seller_divider.visible = true;
				const item_infos:Vector.<SDBItemInfo> = event.data as Vector.<SDBItemInfo>;
				item_sellers_ui.show(item_infos);
				
				if(item_infos && !item_infos.length){
					//no sellers!
					addChild(no_sellers_tf);
				}
				else if(item_infos && item_infos.length && no_sellers_tf.parent){
					//get outta here
					no_sellers_tf.parent.removeChild(no_sellers_tf);
				}
				
				_jigger();
			}
		}
		
		private function reload():void {
			//if we are open, let's reload the data
			if(parent) start();
		}
		
		override protected function _jigger():void {
			super._jigger();
						
			//setup the title so it wraps nice
			_title_tf.width = _close_bt.x - _title_tf.x - 5;
			
			//slug
			reward_slug.y = int(new_tf.y + (new_tf.height/2 - reward_slug.height/2));
						
			_head_h = Math.max(_head_padd_top + _title_tf.height + _head_padd_bottom, _head_min_h);
			
			if(new_tf.visible){
				_title_tf.y = new_tf.y + new_tf.height;
				_head_h = _title_tf.y + _title_tf.height + _head_padd_bottom;
			}
			else {
				_title_tf.y = int(_head_h/2 - _title_tf.height/2) + _border_w;
			}
			
			_body_sp.y = _head_h;
			
			//draw stuff
			var g:Graphics = header_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, _head_sp.width, _head_h);
			
			_body_h = Math.max(_body_min_h, (is_item ? item_info_ui.height : skill_info_ui.height) + _base_padd*2);
			_body_h = Math.min(_body_max_h, _body_h);
			
			//draw the divider
			g = seller_divider.graphics;
			g.clear();
			g.beginFill(_body_border_c);
			g.drawRect(0, 0, 1, _body_h);
						
			//move the burst
			burst_holder.y = _head_h + 8;
			
			//icon moving			
			if(icon_view){
				icon_view.y = _head_h-ICON_WH/2 + 10;
			}
			
			if(skill_icon){
				skill_icon.y = _head_h-ICON_WH/2 + 10;
				
				//skill time
				skill_time_tf.x = int(INFO_X/2 - skill_time_tf.width/2);
				skill_time_tf.y = ICON_WH - _head_h + 22;
				
				//put the chat button below the time
				chat_bt.y = int(skill_time_tf.y + skill_time_tf.height + 23);
			}
			else {
				chat_bt.y = ICON_WH - 25;
			}
			
			share_bt.y = int(chat_bt.y + chat_bt.height + 5);
			
			//if this item is good for auctions, let's show it
			const item:Item = model.worldModel.getItemByTsid(item_class);
			if(item && item.details) {
				if(item.is_auctionable){
					auction_bt.value = item.details.item_url_part;
					auction_bt.visible = true;
				}
				
				if(item.details.is_sdbable && model.flashVarModel.use_economy_info){
					info_bt.visible = true;
					seller_bt.visible = true;
					button_cover.visible = true;
					button_shadow.visible = true;
				}
				
				info_url.url = item.details && item.details.info_url ? model.flashVarModel.root_url+item.details.info_url.substr(1) : null;
				share_bt.visible = item.details.info_url != null;
				
				//set the auction button
				auction_bt.y = int((share_bt.visible ? share_bt.y + share_bt.height : chat_bt.y + chat_bt.height) + 5);
				
				//show the find nearest
				find_holder.visible = routing_class && item_info_ui.retrieved_routing;
				if (routing_class && item_info_ui.retrieved_routing) {
					const bt_padd:uint = 7;
					setFindNearest();
					
					if (auction_bt.visible) {
						find_holder.y = auction_bt.y + auction_bt.height + bt_padd;
					} else if (share_bt.visible) {
						find_holder.y = share_bt.y + share_bt.height + bt_padd;
					} else {
						find_holder.y = chat_bt.y + chat_bt.height + bt_padd;
					}
					
					//if the body height is the min and we are showing this, let's bump it up
					const body_padd:uint = 25;
					if(_body_h <= _body_min_h + body_padd){
						_body_h = _body_min_h + body_padd;
					}
				}
			}
			
			//set the ok button
			if (button_holder.parent) {
				_foot_h = 60;
				_foot_max_h = _foot_h;
				
				if(!model.flashVarModel.use_economy_info){
					button_holder.y = Math.round((_foot_h-button_holder.height-4)/2);
				}
				else {
					button_holder.y = int(_foot_h/2 - ok_bt.height/2 - 1);
				}
				
				_foot_sp.y = _head_h + _body_h;
			} else {
				// I am not sure why all these calcs, I think it should always be zero
				_foot_h = _scroller.body_h > _scroller.h ? _foot_min_h : 0;
			}
			
			//draw the button covers (-2, +2 account for the borders)
			if(model.flashVarModel.use_economy_info){
				g = button_cover.graphics;
				g.clear();
				g.beginFill(_body_fill_c);
				g.drawRect(0, 0, int(info_bt.disabled ? seller_bt.width : info_bt.width) - 2, 2);
				button_cover.y = int(_foot_sp.y + button_holder.y + info_bt.y);
				button_cover.x = button_holder.x + (info_bt.disabled ? seller_bt.x : info_bt.x) + 2;
				
				g = button_shadow.graphics;
				g.clear();
				g.beginFill(0);
				g.drawRect(0, 0, int(info_bt.disabled ? info_bt.width : seller_bt.width), 6);
				button_shadow.y = int(_foot_sp.y + button_holder.y + info_bt.y + 1);
				button_shadow.x = button_holder.x + (info_bt.disabled ? info_bt.x : seller_bt.x) + 1;
				
				//mode the no seller text
				if(no_sellers_tf.parent){
					no_sellers_tf.y = int(_head_h + _body_h/2 - no_sellers_tf.height/2);
				}
			}
			
			_scroller.h = _body_h - _divider_h*2;
			_scroller.refreshAfterBodySizeChange();
			
			//draw it up
			_h = _head_h + _body_h + _foot_h;
			_draw();
		}
		
		private function setFindNearest():void {
			const item:Item = model.worldModel.getItemByTsid(item_class);
			find_icon.visible = item_info_ui.routing_location != null;
			find_icon_disabled.visible = !find_icon.visible;
			find_bt.visible = true;
			
			var txt:String = '<p class="get_info_near">';
			
			if (item_info_ui.routing_location) {
				const loc:Location = item_info_ui.routing_location;
				
				if (loc == model.worldModel.location) {
					txt += 'The nearest '+item.label+' is right here in your location!';
					find_bt.visible = false;
				} else {
					txt += 'The nearest '+item.label+
						   ' is in <a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+loc.hub_id+'#'+loc.tsid+'"><b>'+loc.label+'</b></a>';
					find_bt.label = 'Set as destination';
					find_bt.value = loc.tsid;
				}
				
			} else {
				txt += 'Can’t find any '+item.label_plural+' where you are now';
				find_bt.label = 'Return to the Real World';
				find_bt.value = 'return';
				find_bt.visible = model.worldModel.location.is_pol;
			}
			
			txt += '</p>';
			find_tf.htmlText = txt;
			find_bt.y = find_bt.visible ? int(find_tf.y + find_tf.height + 1) : 0;
		}
		
		// IMoveListener funcs
		// -----------------------------------------------------------------
		
		public function moveLocationHasChanged():void {
			
		}
		
		public function moveLocationAssetsAreReady():void {
			
		}
		public function moveMoveStarted():void {
			this.visible = false;
		}
		
		public function moveMoveEnded():void {
			this.visible = true;
			if (!parent) return;
			// make it refresh
			if(item_class){
				showItem();
			}
		}
	}
}