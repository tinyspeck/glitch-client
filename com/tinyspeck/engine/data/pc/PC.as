package com.tinyspeck.engine.data.pc 
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.glitchr.filters.GlitchrFilter;
	
	import flash.utils.Dictionary;

	public class PC extends AbstractPCEntity {
		/** Don't need these, but they exist
		public static const ROLE_PEON:String = 'peon';
		public static const ROLE_HELP:String = 'help';
		public static const ROLE_GOD:String = 'god';
		public static const ROLE_GUIDE:String = 'guide';
		**/
		
		client var physWidth:Number = NaN;
		client var physHeight:Number = NaN;
		client var physRadius:Number = NaN;
		
		public static var HAPPY:String = 'happy';
		public static var ANGRY:String = 'angry';
		public static var SURPRISE:String = 'surprise';
		
		public var apo:AvatarPhysicsObject; // namespace client fucks fbuilder up
		
		public var role:String;
		public var can_nudge_cultivations:Boolean;
		public var can_nudge_others:Boolean;
		public var hi_emote_variant:String;
		
		public var physics_adjustments:Object; // we'll stuff this here so we can use it when we add the setting to the pc.apo in PhysciController
		public var s:String;
		private var _y:Number;
		private var _x:Number;
		public var location:Object;
		public var level:int;
		public var online:Boolean = false;
		public var in_school:Boolean;
		public var pack_slots:int = 16;
		public var label:String;
		public var buffs:Dictionary = new Dictionary();
		public var itemstack_tsid_list:Dictionary = new Dictionary(); // all in pack, even in containers
		public var buddy_tsid_list:Dictionary = new Dictionary(); // list of buddies by TSID
		public var tsid:String;
		private var _a2011:Object;
		
		private var _sheet_url:String;
		public function get sheet_url():String {
			return _sheet_url || TSModelLocator.instance.flashVarModel.placeholder_sheet_url || '';
		}
		public function set sheet_url(value:String):void {
			_sheet_url = value;
		}

		private var _singles_url:String;
		public function get singles_url():String {
			return _singles_url || ''; // if we had a default singles url we could return it here
		}
		public function set singles_url(value:String):void {
			_singles_url = value;
		}
		
		public var sheet_pending:Boolean = false;
		public var stats:PCStats;
		public var following_pc_tsid:String; // empty unless you are following someone
		public var familiar:PCFamiliar; // TODO make this a class when we know how ew're goint to use it
		public var emotion:String;
		public var afk:Boolean;
		public var doing:Boolean;
		public var hit:String;
		public var skill_training:PCSkill; // this mofo is the skill you are currently learning
		public var skill_unlearning:PCSkill; // this mofo is the skill you are currently un-learning
		public var escrow_tsid:String; // private bag ID used when trading
		public var mail_bag_tsid:String; // private bag ID used for mail
		public var furniture_bag_tsid:String; // bag that holds all furniture
		public var rewards_bag_tsid:String; // private bag ID used for holding rewards when bag is full
		public var trophy_storage_tsid:String; // private bag ID used for holding trophies
		public var auction_storage_tsid:String; // private bag ID used for holding items on auction
		public var teleportation:PCTeleportation;
		public var path:Array;
		public var color_group:String = '';
		public var game_text:String = '';
		public var show_color_dot:Boolean = false;
		public var secondary_color_group:String = '';
		public var last_game_flag_sig:String = '';
		private var _game_flag_sig:String = '';
		public var rs:int;
		public var pol_tsid:String;
		public var home_info:PCHomeInfo;
		public var is_admin:Boolean;
		public var is_guide:Boolean;
		public var guide_on_duty:Boolean;
		public var reversed:Boolean;
		private var _ac:AvatarConfig;
		public var ignored:Boolean; //for the future
		public var cam_speed_multiplier:Number = 1; // the scale to apply to increment in CameraMan
		public var cam_range:uint = 100; // the number of pixels from the pc the cam may range; 0 means no restriction (this is set very low so we spot when the server does not send it)
		public var cam_can_snap:Boolean = false;
		public var cam_filters:Vector.<GlitchrFilter>;
		public var can_contact:Boolean = true; // when calling the API for info about a player, this can get set to false. Used in player info window.
		public var fake:Boolean; // used in performance testing
		public var is_dead:Boolean;
		public var needs_account:Boolean; //if the player needs to create an account still
		public var previous_location_tsid:String;
		public var previous_looks:Vector.<AvatarLook>;
		client var isPlayersPC:Boolean;
		
		public function PC(hashName:String, isPlayersPC:Boolean = false) {
			super(hashName);
			this.client::isPlayersPC = isPlayersPC;
			apo = new AvatarPhysicsObject(this);
		}
		
		public function get game_flag_sig():String {
			return _game_flag_sig;
		}
		
		public function get ac():AvatarConfig {
			return _ac;
		}
		
		public function get scale():Number {
			if (apo && apo.setting) {
				return apo.setting.pc_scale;
			}
			var loc:Location = TSModelLocator.instance.worldModel.location;
			if (loc && loc.physics_setting && loc.physics_setting.pc_scale) {
				return loc.physics_setting.pc_scale
			}
			return 1;
		}

		/*public function get a2011():Object {
			return _a2011;
		}*/

		public function set a2011(value:Object):void {
			//Console.info('a2011 set for '+label+' '+tsid);
			//Console.dir(value)
			_a2011 = value;
			_a2011.pc_tsid = tsid;
			// this of course we means once we have it, we do not change it
			if (!_ac) _ac = AvatarConfig.fromAnonymous(_a2011, Boolean(client::isPlayersPC));
		}
		
		public static function parseMultiple(object:Object):Vector.<PC> {
			var V:Vector.<PC> = new Vector.<PC>;
			var j:String;
			
			for(j in object){
				if('tsid' in object[j]){
					V.push(fromAnonymous(object[j], object[j].tsid));
				}
				else {
					CONFIG::debugging {
						Console.warn('Need a TSID to make a PC!');
					}
				}
			}
			
			return V;
		}

		public static function fromAnonymous(object:Object, hashName:String, isPlayersPC:Boolean = false):PC {
			var pc:PC = new PC(hashName, isPlayersPC);
			pc.tsid = hashName;
			return PC.updateFromAnonymous(object, pc);
		}
		
		public static function updateFromAnonymous(object:Object, pc:PC):PC {
			var model:TSModelLocator = TSModelLocator.instance;
			var wm:WorldModel = model.worldModel;
			
			// handle cases where location hash is not sent by GS
			if (!object.hasOwnProperty('location')) {
				//Console.error('pc data lacks location');

				// if location_tsid is here, let's create a location hash
				if (object.hasOwnProperty('location_tsid')) {
					if (wm.locations[object.location_tsid]) {
						object.location = {
							tsid: object.location_tsid,
							label: wm.locations[object.location_tsid].label
						}
					} else {
						object.location = {
							tsid: object.location_tsid,
							label: 'crap, unknown location'
						}
					}
				}
			} 
			
			for(var j:String in object){
				var val:* = object[j];
				if (j == 'rs'){
					if (object['rs'] === true) object['rs'] = 1;
				}
				
				if(j in pc){
					if(j == "skill_training" && val['tsid']){
						pc.skill_training = PCSkill.fromAnonymous(val, val['tsid']);
					} else if(j == 'skill_unlearning' && val['tsid']){
						pc.skill_unlearning = PCSkill.fromAnonymous(val, val['tsid']);
					} else if(j == "stats"){
						pc.stats = PCStats.fromAnonymous(val,j);
						pc.level = pc.stats.level;
						if (pc == wm.pc) { // not that we should even get stats for other players, but just in case
							wm.triggerCBProp(false,false,"pc","stats");
						}
					} else if(j == "home_info"){
						pc.home_info = PCHomeInfo.fromAnonymous(val);
					}else{
						pc[j] = val;
					}
				}else{
					if(j == "vx"){
						if (pc.apo) pc.apo.vx = object['vx'];
					} else if(j == "vy"){
						if (pc.apo) pc.apo.vy = object['vy']
					} else if(j == "itemstacks"){
						
					} else if(j == "location_tsid"){
					
					} else if(j == "version"){
						
					} else if(j == "name"){
						pc.label = object[j];
					} else {
						resolveError(pc,object,j);
					}
				}
			}
			if (!pc.location) {
				if (pc.online) { 
					pc.location = {
						label: 'Unknown Location',
						tsid: '00000000000001'
					}
				} else {
					pc.location = {
						label: 'offline',
						tsid: '00000000000002'
					}
				}
			}
			
			// until myles moves it
			if (!pc.skill_training && object.hasOwnProperty('stats') && object.stats.skill_training && object.stats.skill_training['tsid']) {
				pc.skill_training = PCSkill.fromAnonymous(object.stats.skill_training, object.stats.skill_training['tsid']);
			}
			
			if (!pc.skill_unlearning && object.hasOwnProperty('stats') && object.stats.skill_unlearning && object.stats.skill_unlearning['tsid']) {
				pc.skill_unlearning = PCSkill.fromAnonymous(object.stats.skill_unlearning, object.stats.skill_unlearning['tsid']);
			}

			pc._game_flag_sig = pc.color_group+pc.game_text+String(pc.show_color_dot);
			
			//make sure a PCs label doesn't have any fucking HTML garbage in it
			if(pc.label){
				if(pc.label.indexOf('<') != -1 || pc.label.indexOf('>') != -1){
					pc.label = StringUtil.encodeHTMLUnsafeChars(pc.label, false);
				}
			}
			
			return pc;
		}
		
		public function set y(y:Number):void {
			if (isNaN(y) && y != _y) {
				//Console.error('NaN!!!!! '+y);
			}
			_y = y;
			//_y = NaN;
		}
		
		public function get y():Number {
			return _y;
		}
		
		public function set x(x:Number):void {
			if (isNaN(x) && x != _x) {
				//Console.error('NaN!!!!! '+x);
			}
			/*if (_x != x && tsid == TSModelLocator.instance.flashVarModel.pc_tsid) {
				var st:String = StringUtil.getCurrentStackTrace(0, 7897)
				if (st.indexOf('setAndBoundPositionOnSelf') == -1) {
					CONFIG::debugging {
						Console.info(st);
					}
				}
			}*/
			_x = x;
			//_x = NaN;
		}
		
		public function get x():Number {
			return _x;
		}
		
		public function isPackEmpty():Boolean {
			for (var tsid:String in this.itemstack_tsid_list) return false;
			return true;
		}
		
		public function hasXItems(x:int, item_class:String):Boolean {
			return hasHowManyItems(item_class) >= x;
		}
		
		public function tsidsOfAllStacksOfItemClass(item_class:String):Array {
			var A:Array = [];
			var stack:Itemstack;
			for (var k:String in itemstack_tsid_list) {
				stack = TSModelLocator.instance.worldModel.getItemstackByTsid(k);
				if (!k) continue;
				if (stack.class_tsid != item_class) continue;
				A.push(stack.tsid)
			}
			
			return A;
		}
		
		public function hasHowManyItems(item_class:String, consumable:Boolean = false):int {
			var c:int = 0;
			var stack:Itemstack;
			for (var k:String in itemstack_tsid_list) {
				stack = TSModelLocator.instance.worldModel.getItemstackByTsid(k);
				if (!k) continue;
				if (stack.class_tsid != item_class) continue;
				c+= (!consumable ? stack.count : (stack.consumable_state ? stack.consumable_state.count : stack.count));
			}
			return c;
		}
		
		public function hasItemsFromList(item_classes:Array, consumable:Boolean = false):Array {
			var has_items:Array = new Array();
			var has:int;
			var i:int;
			
			for(i; i < item_classes.length; i++){
				has = hasHowManyItems(item_classes[int(i)], consumable);
				if(has) has_items.push(item_classes[int(i)]);
			}
			
			return has_items;
		}
		
		public function isContainerPrivate(container_tsid:String):Boolean {
			if (!container_tsid) return false;
			if (container_tsid == trophy_storage_tsid) return true;
			if (container_tsid == escrow_tsid) return true;
			if (container_tsid == rewards_bag_tsid) return true;
			if (container_tsid == mail_bag_tsid) return true;
			if (container_tsid == auction_storage_tsid) return true;
			return false;
		}
		
		public function getItemstackOfWorkingTool(tool_tsid:String):String {
			var i:int;
			var itemstack:Itemstack;
			var itemstack_tsids:Array = tsidsOfAllStacksOfItemClass(tool_tsid);
			var itemstack_tsid:String;
			
			for(i; i < itemstack_tsids.length; i++){
				itemstack = TSModelLocator.instance.worldModel.getItemstackByTsid(itemstack_tsids[int(i)]);
				if(itemstack && itemstack.tool_state){
					if(!itemstack.tool_state.is_broken){
						itemstack_tsid = itemstack.tsid;
						break;
					}
					else {
						itemstack_tsid = null;
					}
				}
			}
			
			return itemstack_tsid;
		}
		
		public function getItemstackTsidsFromNeeded(class_tsid:String, needed:int = 1, max_to_return:int = 0):Array {
			var got_count:int;
			var itemstacks:Array = tsidsOfAllStacksOfItemClass(class_tsid);
			var return_itemstacks:Array = new Array();
			var stack:Itemstack;
			var i:int;
			var total:int = itemstacks.length;
			
			if(total){
				var stacks_to_order:Vector.<Itemstack> = new Vector.<Itemstack>();
				for(i = 0; i < total; i++){
					//go through the itemstacks and order them by count so we take chunks out of the full stacks first
					stack = TSModelLocator.instance.worldModel.getItemstackByTsid(itemstacks[int(i)]);
					if(stack) stacks_to_order.push(stack);
				}
				
				//sort em
				SortTools.vectorSortOn(stacks_to_order, ['count'], [Array.NUMERIC | Array.DESCENDING]);
				
				//start looping to get the amount we need
				for(i = 0; i < total; i++){
					if(got_count < needed && (max_to_return ? return_itemstacks.length < max_to_return : true)){
						stack = stacks_to_order[int(i)];
						got_count += stack.count;
						return_itemstacks.push(stack.tsid);
					}
					else {
						break;
					}
				}
			}
			
			return return_itemstacks;
		}
		
		public function getImaginationCardById(id:int):ImaginationCard {
			if(!stats || !stats.imagination_hand) return null;
			var i:int;
			var total:int = stats.imagination_hand.length;
			var card:ImaginationCard;
			
			for(i; i < total; i++){
				card = stats.imagination_hand[int(i)];
				if(card.id == id) return card;
			}
			
			return null;
		}
		
		public function getImaginationCardByTsid(tsid:String):ImaginationCard {
			if(!stats || !stats.imagination_hand) return null;
			var i:int;
			var total:int = stats.imagination_hand.length;
			var card:ImaginationCard;
			
			for(i; i < total; i++){
				card = stats.imagination_hand[int(i)];
				if(card.class_tsid == tsid) return card;
			}
			
			return null;
		}
		
		public function getLookById(outfit_id:String):AvatarLook {
			if(!previous_looks || !previous_looks.length) return null;
			const total:int = previous_looks.length;
			var i:int;
			var look:AvatarLook;
			
			for(i; i < total; i++){
				look = previous_looks[int(i)];
				if(look.outfit_id == outfit_id) return look;
			}
			
			return null;
		}
		
		public function toString():String {
			return 'PC[tsid:' + tsid + ', x:' + x + ', y:' + y + ', label:' + label + ']';
		}
	}
}