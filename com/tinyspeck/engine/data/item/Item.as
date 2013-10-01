package com.tinyspeck.engine.data.item
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.ObjectUtil;
	
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	public class Item extends AbstractItemEntity
	{
		public static const client_verbs:Object = {};
		public static var client_verbs_inited:Boolean = false;
		public static const CLIENT_INFO:String = 'client_info';
		public static const CLIENT_OPEN:String = 'client_open';
		public static const CLIENT_CLOSE:String = 'client_close';
		public static const CLIENT_EDIT_PROPS:String = 'client_edit_props';
		public static const CLIENT_EDIT_ITEM:String = 'client_edit_item';
		public static const CLIENT_DESTROY:String = 'client_destroy';
		public static const CLIENT_COPY_TSID:String = 'client_copy_tsid';
		public static const CLIENT_COPY_CLASS:String = 'client_copy_class';
		public static const TYPE_PLACEHOLDER_THROBBER:String = 'item_throbber';
		public static const TYPE_PLACEHOLDER_MISSING:String = 'asset_missing';
		
		public static const MISSING_ASSET_IMG_STR:String = 
			'iVBORw0KGgoAAAANSUhEUgAAABcAAAAUCAYAAABmvqYOAAABv0lEQVQ4y62VTUtCQRSG' +
			'Z1OLIBKqvUQ/4P4Eg7aBP6DwVuQqUjAqMEIUod3dRNFKAgkhjBZFuDKoXVBtMoLw1qJF' +
			'0IfRpwuZ5pVzQtT7kTfhZe7MvOeZ8cw9c4WUUtipazymKWWUXpQktehrTrFOYJ2AVtI7' +
			'gqvAoAOYFfwTXAX4RlJrucHwsi0Y8/DB7xo+EI6v9k4ufkW2dr+tFsA45uGDvy1cGQ06' +
			'pCh2ACGAIaGN7er0Zk7yImjRxzh7yO8jRYlniIPzUnYokqrB1D0xX+kJLRw377JvaqnK' +
			'MLToN3sQh3g8gwcutq89vX3cJfMFyYtYaf/s0vYMEA8OeOByfnAgCSXTLng2k0/ZzSOe' +
			'OL62B+oR3nKgKJQEyfACp3hm6cI/l7xyWSxu4L8CV5xcl0+PSjeS5QXeyAG3/rYoBVge' +
			'cx5okNZynwxH0x3BKS7YUv50SZn/lHOTF+Hyl/0z8Vosu1fPl9V9YgWHH3GIB4ffHLGy' +
			'c1hAVT2/f1bUagbyVX54fB1Nr7uCwwc/5dkABzxwkRa9sapIfqXixe19fTd8DgxHH+OY' +
			'h4/8zdWuC4dPlUb/BmWN3xi1Jo3bfup+AMuvHRf6+A1OAAAAAElFTkSuQmCC';
		
		public static const LOADING_THROBBER_STR:String = 
			'iVBORw0KGgoAAAANSUhEUgAAAB4AAAARCAYAAADKZhx3AAACXklEQVRIx2NgIAMoyyvw' +
			'ArEUFLP9//+fgVRMrEUgCyyBOBiI07DgBCB2A2I1Yh1CyEKQQZE4LMOK1ZSUE6GOZCPZ' +
			'YqgPUSy0trDI6Wxvb0pNTi4P8vMvBImBaJDY9GnTOmBiaA7QJcpikCuhroUbADLw1MmT' +
			'c+/cvr3A1dEpE5sv66prcr9//7747t27KyvKymvQ5N2w+R7FUg0V1VBkH+7bu3cGUNHy' +
			'mzdu+mipqSejWwhy1PNnz9cB1ZQDMQ8QGwBxP8gByCEANZcNw2KgoDA0aMAKQa5+9/bd' +
			'KqCCEJC8nZW1JzafHjl8pA+oRgVLUBqAQgAUDbgsB1uqrqySBFMAii+Qq4FYAik0sCak' +
			'7du2BaBbimQ4KASaQeZhs5xBX1snDiYBiktQsGFJaFgt9nJ3D0WzVDcmMkoZzTHl6JbD' +
			'fAwWgManB3oK3751mxWBLOQDxMZA7ADiL1640A5L0JejpXpdBlBCuHL58uLJEyfFQFMg' +
			'L7LFoDgkJR+fPnXaHD3ooeaC5UHZ8f3796EM0JRoA5OAxrcasuXIQYUPgxIlKG0gWSqM' +
			'nFNAln779m06KP7hhoOCGksQgn3/5cuXMlD2wmcpSP7B/QftSL40RpYHpXCYpSj5GJR1' +
			'0PMfFDuAEszTp0+XgFyMzVKQHpA80PE6IAuRsyYIb9q4cRIohcMsxSi5YPkPpBDdcFAU' +
			'dHd2VYEshzkARIOCd97cuU0mhoZR2IIeGJ9bgOYmECyroa5KAGkAxS2hIMYV16DQg5UH' +
			'JNVOUA2gonAzKNWDHIErqGEVCCidQH3YD020OGsnAGJ37loO4bzSAAAAAElFTkSuQmCC';

		private static var class_prefixes_that_are_snappable:Array;
		{ // static init
			class_prefixes_that_are_snappable = CSSManager.instance.getArrayValueFromStyle('rendering_exceptions', 'class_prefixes_that_are_snappable', null);
		}
		
		public var asset_swf_v:String;
		public var label:String;
		public var obey_physics:Boolean = true;
		public var admin_props:Boolean = false;
		public var hasConditionalEmoteVerbs:Boolean = false;
		public var hasConditionalVerbs:Boolean = true;
		public var verbs:Dictionary = new Dictionary();
		public var has_info:Boolean = false;
		public var stackmax:int = 1;
		public var subclasses:Dictionary;
		public var is_routable:Boolean = false;
		public var is_invoking:Boolean = false;
		public var is_hidden:Boolean = false;
		public var has_status:Boolean = false;
		public var has_infopage:Boolean = false;
		public var in_foreground:Boolean = false;
		public var in_foremostground:Boolean = false;
		public var in_background:Boolean = false;
		public var not_selectable:Boolean = false;
		public var tsid:String;
		public var proxy_item:String;
		public var tags:Array;
		public var loc_verb_key_triggers:Dictionary = new Dictionary();
		public var pack_verb_key_triggers:Dictionary = new Dictionary();
		public var any_verb_key_triggers:Dictionary = new Dictionary();
		public var pickupable:Boolean; // client sets this
		public var dropable:Boolean; // client sets this
		public var giveable:Boolean; // client sets this
		public var consumable_label_single:String;
		public var consumable_label_plural:String;
		public var oneclick_verb:Verb;
		private var _oneclick_pickup_verb:Verb;
		public var adjusted_scale_as_loaded:Number = 1; // don't reference this externally unless you know what you are doing! use the scale getter
		public var adjusted_scale:Number = 1; // don't reference this externally unless you know what you are doing! use the scale getter

		public function get oneclick_pickup_verb():Verb {
			if (!_oneclick_pickup_verb) return null;
			if (!TSModelLocator.instance.prefsModel.do_oneclick_pickup) return null;
			if (KeyBeacon.instance.pressed(Keyboard.SHIFT)) return null;
			return _oneclick_pickup_verb;
		}
		
		public function get info_class():String {
			if (proxy_item) return proxy_item;
			if (has_info) return tsid;
			return null;
		}
		
		public function get routing_class():String {
			if (is_routable) {
				if (proxy_item) return proxy_item;
				return tsid;
			} else {
				if (!proxy_item) return null;
				var proxy:Item = TSModelLocator.instance.worldModel.getItemByTsid(proxy_item);
				if (!proxy || !proxy.is_routable) return null;
				return proxy_item;
			}
		}
		
		public function get is_shrine():Boolean {
			return tsid.indexOf('npc_shrine') == 0;
		}
		
		public function get is_in_encyc():Boolean {
			if (proxy_item) return false;
			if (has_infopage && has_info) return true;
			return false;
		}

		public function get scale():Number {
			// for now...
			if (!CONFIG::god && tsid != 'garden_new') {
				return 1;
			}
			
			// we do not want to adjust furniture scale until we sort out how to deal with source platforms
			if (is_furniture || is_special_furniture) {
				return 1;
			}
			
			return adjusted_scale;
		}
		
		public function get is_auctionable():Boolean {
			if (!details) return false;
			if ((details.max_stack || is_furniture || is_special_furniture) && details.item_url_part && details.base_cost && has_infopage) return true;
			return false;
		}
		
		/** @private */
		public var is_furniture:Boolean; // for now we set this internally with hasTags('furniture') && !hasTags('furniture_placed_normally')
		
		/** @private */
		public var is_special_furniture:Boolean; // for now we set this internally with hasTags('furniture_placed_normally');
		
		private var _is_interactable_furniture:Boolean; // for now we set this internally with hasTags('furniture_interactable');
		public function get is_interactable_furniture():Boolean {
			return _is_interactable_furniture;
		}
		
		private var _is_trophy:Boolean; // for now we set this internally with indexOf('trophy_');
		public function get is_trophy():Boolean {
			return _is_trophy;
		}
		
		private var _label_plural:String;
		
		public var DEFAULT_STATE:Object; // hacky way to store default state for admin created items. need to adjust itemDef from GS to provide this
		public var DEFAULT_CONFIG:Object; // hacky way to store default config for admin created items. need to adjust itemDef from GS to provide this
		private var _details:ItemDetails; //cache the data from the API
		public function get details():ItemDetails { return _details; }
		public function set details(value:ItemDetails):void {
			_details_retrieved_ms = (value) ? getTimer() : 0;
			_details = value;
		}
		private var _details_retrieved_ms:int; // getTimer() set when details are set
		public function get details_retrieved_ms():int {
			if (!details) return 0;
			return _details_retrieved_ms;
		}
		
		// these are set in the wm.invoking / wm.userdceo setter
		public var proto_item_tsidA:Array; // the tsids of the proto items that create this item
		public var is_proto:Boolean = false;
		
		private var _placement_w:int = 0;
		public function get placement_w():int {
			return _placement_w;
		}

		public function set placement_w(value:int):void {
			// enforce that values are even so that widths are equal on both sides of an item
			if (value % 2 == 1) value++;
			_placement_w = value;
		}

		CONFIG::god public var amf:Object; // this is the incoming object pass to fromAnonymous
		
		public function Item(hashName:String) {
			super(hashName);
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function hasAnyVerbKeyTriggers():Boolean {
			for (var k:String in any_verb_key_triggers) return true;
			return false;
		}
		
		public function getAnyVerbKeyTriggerByVerbTsid(verb_tsid:String):VerbKeyTrigger {
			var vkt:VerbKeyTrigger;
			for (var key_code:String in any_verb_key_triggers) {
				vkt = getAnyVerbKeyTriggerByKeyCode(parseInt(key_code));
				if (vkt.verb_tsid == verb_tsid) return vkt;
			}
			return null;
		}
		
		public function getAnyVerbKeyTriggerByKeyCode(key_code:uint):VerbKeyTrigger {
			return any_verb_key_triggers[String(key_code)];
		}
		
		public function getAnyVerbTsidByKeyCode(key_code:uint):String {
			var vkt:VerbKeyTrigger = getAnyVerbKeyTriggerByKeyCode(key_code);
			return (vkt) ? vkt.verb_tsid : '';
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function hasLocVerbKeyTriggers():Boolean {
			for (var k:String in loc_verb_key_triggers) return true;
			return false;
		}
		
		public function getLocVerbKeyTriggerByVerbTsid(verb_tsid:String):VerbKeyTrigger {
			var vkt:VerbKeyTrigger;
			for (var key_code:String in loc_verb_key_triggers) {
				vkt = getLocVerbKeyTriggerByKeyCode(parseInt(key_code));
				if (vkt.verb_tsid == verb_tsid) return vkt;
			}
			return null;
		}
		
		public function getLocVerbKeyTriggerByKeyCode(key_code:uint):VerbKeyTrigger {
			return loc_verb_key_triggers[String(key_code)];
		}
		
		public function getLocVerbTsidByKeyCode(key_code:uint):String {
			var vkt:VerbKeyTrigger = getLocVerbKeyTriggerByKeyCode(key_code);
			return (vkt) ? vkt.verb_tsid : '';
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function hasPackVerbKeyTriggers():Boolean {
			for (var k:String in pack_verb_key_triggers) return true;
			return false;
		}
		
		public function getPackVerbKeyTriggerByVerbTsid(verb_tsid:String):VerbKeyTrigger {
			var vkt:VerbKeyTrigger;
			for (var key_code:String in pack_verb_key_triggers) {
				vkt = getPackVerbKeyTriggerByKeyCode(parseInt(key_code));
				if (vkt.verb_tsid == verb_tsid) return vkt;
			}
			return null;
		}
		
		public function getPackVerbKeyTriggerByKeyCode(key_code:uint):VerbKeyTrigger {
			return pack_verb_key_triggers[String(key_code)];
		}
		
		public function getPackVerbTsidByKeyCode(key_code:uint):String {
			var vkt:VerbKeyTrigger = getPackVerbKeyTriggerByKeyCode(key_code);
			return (vkt) ? vkt.verb_tsid : '';
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function getVerbByTsid(verb_tsid:String):Verb {
			return verbs[verb_tsid];
		}
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public static function parseMultiple(object:Object, items:Dictionary):Dictionary {
			for(var j:String in object){
				items[j] = fromAnonymous(object[j],j);
			}
			return items;
		}
		
		private static const reusable_oneclick_pickup_verb:Verb = Verb.fromAnonymous({
			'label': 'pick up',
			'ok_states': ['in_location'],
			'requires_target_pc': false,
			'requires_target_item': false,
			'include_target_items_from_location': false,
			'is_default': false,
			'is_emote': false,
			'sort_on': 50,
			'tooltip': 'Put it in your pack',
			'is_drop_target': false
		}, 'pickup');
		
		public static function fromAnonymous(object:Object, hashName:String):Item {
			const item:Item = new Item(hashName);
			item.tsid = hashName;
			CONFIG::god {
				item.amf = ObjectUtil.copyOb(object);
			}
			
			var loc_verb_key_triggers_count:int;
			
			const model:TSModelLocator = TSModelLocator.instance;
			
			
			if ('subclasses' in object) {
				for (var sc_tsid:String in object.subclasses) {
					
					if (model.worldModel.getItemByTsid(sc_tsid)) {
						/*CONFIG::debugging {
							Console.warn(sc_tsid+' is already an item (this one is from '+hashName+')');
						}*/
						continue;
					}/* else {
						;
						CONFIG::debugging {
							Console.info('creating '+sc_tsid+' (from '+hashName+')');
						}
					}*/
					
					// copy this object for the subclass
					var s_object:Object = ObjectUtil.copyOb(object);
					// change name
					s_object.label = object.subclasses[sc_tsid].name;
					s_object.name_plural = object.subclasses[sc_tsid].name;
					
					// the whole point of a subclass is that it has info and is routable
					s_object.has_info = true;
					s_object.has_infopage = true;
					s_object.is_routable = true;
					
					delete s_object.subclasses;
					model.worldModel.items[sc_tsid] = Item.fromAnonymous(s_object, sc_tsid);
					
				}
			}
			
			for(var i:String in object){
				if(i in item){
					if(i == "verbs"){
						// we used to load verbs from here
					}else if(i == "oneclick_verb"){
						item.oneclick_verb = Verb.fromAnonymous(object[i], object[i].id);
					}else if(i == "subclasses"){
						for (sc_tsid in object[i]) {
							
							var isc:Item = model.worldModel.items[sc_tsid];
							if (!isc) {
								CONFIG::debugging {
									Console.error('no subclass '+sc_tsid);
								}
								continue;
							}
							
							// lazy
							if (!item.subclasses) item.subclasses = new Dictionary();
							
							/*CONFIG::debugging {
							Console.info('adding subclass '+sc_tsid+' to '+item.tsid);
							}*/
							
							item.subclasses[sc_tsid] = isc;
						}

					}else{
						item[i] = object[i];
					}
				}else{
					if(i == "asset_swf"){
						// we used to get asset_swf
					}else if(i == "emote_verbs"){
						// we used to load verbs from here
					}else if(i == "verbs"){
						// we used to load verbs from here
					}else if(i == "name_plural"){
						//sometimes plural names are the same as singular, so we set this special
						item.label_plural = object[i];
					}else if(i == "keys"){
					}else if(i == "keys_in_pack" || i == "keys_in_location"){
						for (var k:String in object[i]) {
							var key_str:String = k;
							var verb_tsid:String = object[i][k];
							var fixed_key_str:String = key_str.toUpperCase().charAt(0); // upper case first char
							var key_code:uint = Keyboard[fixed_key_str];
							
							if (model.flashVarModel.do_single_interaction_sp_keys && KeyBeacon.CLIENT_KEYS.indexOf(key_code) > -1) {
								CONFIG::debugging {
									Console.warn(item.tsid+' '+verb_tsid+' '+key_code+ ' ('+fixed_key_str+') is already in CLIENT_KEYS');
									Console.dir(object);
								}
								continue;
							}
							
							var vkt:VerbKeyTrigger = new VerbKeyTrigger(String(key_code));
							vkt.key_str = fixed_key_str;
							vkt.verb_tsid = verb_tsid;
							item.any_verb_key_triggers[key_code] = vkt;
							if (i == "keys_in_pack") item.pack_verb_key_triggers[key_code] = vkt;
							if (i == "keys_in_location") {
								item.loc_verb_key_triggers[key_code] = vkt;
								loc_verb_key_triggers_count++;
							}
							
							if (vkt.verb_tsid == 'pickup') {
								item.pickupable = true;
							} else if (vkt.verb_tsid == 'drop') {
								item.dropable = true;
							} else if (vkt.verb_tsid == 'give') {
								item.giveable = true;
							}
							
						}
					}else{
						resolveError(item,object,i);
					}
				}
			}
			
			if (loc_verb_key_triggers_count == 1 && item.loc_verb_key_triggers[Keyboard.P] && item.loc_verb_key_triggers[Keyboard.P].verb_tsid == 'pickup') {
				item._oneclick_pickup_verb = reusable_oneclick_pickup_verb;
			}
			
			if (item.tsid == 'crusher') {
				item.in_foremostground = true;
				item.in_background = false;
				item.in_foreground = false;
			}
			
			// see comments above for DEFAULT_STATE
			if (hashName.indexOf('trant_') == 0) {
				item.DEFAULT_STATE = {
					m:7,
					h:7,
					f_cap:0,
					f_num:0
				};
			}
			
			switch (hashName) {
				case 'street_spirit':
					// street_spirit is being deprecated in favor of street_spirit_*, but we're in transition at the time of writing
				case 'street_spirit_groddle':
					item.DEFAULT_CONFIG = {
						skull: 'skull_L0dirt',
						eyes: 'eyes_L0eyes1',
						top: 'none',
						bottom: 'none',
						base: 'base_L0dirt'
					};
					break;
					
				case 'street_spirit_firebog':
					item.DEFAULT_CONFIG = {
						size: 'large'
					};
					break;
			
				case 'npc_squid':
					item.DEFAULT_CONFIG = {
						variant: 'squidYellow'
					};
					break;
				
				case 'npc_widget':
					item.DEFAULT_CONFIG = {
						variant: 'widgetPink'
					};
					break;
				
				case 'paper_tree':
					item.DEFAULT_CONFIG = {
						needs_water: false,
						needs_pet: false,
						paper_count: 21
					};
					break;
				
				case 'wood_tree':
					item.DEFAULT_CONFIG = {
						maturity: 3,
						variant: 1
					};
					break;
				
				case 'mortar_barnacle':
					item.DEFAULT_CONFIG = {
						blister: 'bliser1'
					};
					break;
				
				case 'jellysac':
					item.DEFAULT_CONFIG = {
						blister: 'jellySack1'
					};
					break;
				
				case 'firefly_jar':
					item.DEFAULT_CONFIG = {
						num_flies: '1'
					};
					break;
				
				case 'npc_bureaucrat':
					item.DEFAULT_CONFIG = {
						torso: '01',
						arms: '01',
						legs: '01',
						hair: '01',
						necklace: '01',
						tie: 'none',
						glasses: 'none'
					};
					break;
				
				case 'npc_juju_bandit':
					item.DEFAULT_CONFIG = {
						variant: 'red',
						bandana: 'blue'
					};
					break;
				
				case 'npc_smuggler':
					item.DEFAULT_CONFIG = {
						variant: 'red',
						head: '2'
					};
					break;
				
				default:
					break;
			}
			
			// if we do an updateFromAnon for this class, this should be placed at end of fromanonymous
			addClientVerbs(item);
			
			item._is_interactable_furniture = item.hasTags('furniture') && item.hasTags('furniture_interactable');
			
			item.is_special_furniture = item.hasTags('furniture') && item.hasTags('furniture_placed_normally');
			
			// if it _is_special_furniture, then it cannot be furniture, due to logic used to differentiate
			item.is_furniture = !item.is_special_furniture && item.hasTags('furniture');
			
			item._is_trophy = item.tsid.indexOf('trophy_') == 0;
			
			item.adjusted_scale_as_loaded - item.adjusted_scale;
			
			if (item.tsid == 'physics' || item.tsid == 'ctpc' || item.tsid == 'ctgc' || item.tsid == 'cteb' || item.tsid == 'clickable_broadcaster') {
				item.has_ct_box = true;
			}
			
			/*if (item.asset_swf_v.indexOf('/dullite-') > -1 || item.tsid == 'apple') {
				item.asset_swf_v+= 'BREAK';
			}*/
			
			return item;
		}
		
		public var has_ct_box:Boolean;
		
		public static function shouldUseCurrentStateForIconView(item_class:String):Boolean {
			if (item_class == 'npc_butterfly') return false;
			if (item_class == 'npc_sloth') return false;
			return true;
		}
		
		public static function initClientVerbs():void {
			client_verbs_inited = true;

			client_verbs[CLIENT_INFO] = Verb.fromAnonymous({
				sort_on: 0,
				ok_states: ['in_pack', 'in_location'],
				requires_target_pc: false,
				label: 'Info',
				is_single: false,
				is_all: true,
				enabled: true,
				disabled_reason: '',
				requires_target_item: false,
				requires_target_item_count: false,
				is_emote: false,
				tooltip: 'Get information.',
				effects: {},
				is_client: true
			}, CLIENT_INFO);
			
			client_verbs[CLIENT_OPEN] = Verb.fromAnonymous({
				sort_on: 100,
				ok_states: ['in_pack'],
				requires_target_pc: false,
				label: 'Open',
				is_single: false,
				is_all: true,
				enabled: true,
				disabled_reason: '',
				requires_target_item: false,
				requires_target_item_count: false,
				is_emote: false,
				tooltip: 'Open this container.',
				effects: {},
				is_client: true
			}, CLIENT_OPEN);
			
			client_verbs[CLIENT_CLOSE] = Verb.fromAnonymous({
				sort_on: 100,
				ok_states: ['in_pack'],
				requires_target_pc: false,
				label: 'Close',
				is_single: false,
				is_all: true,
				enabled: true,
				disabled_reason: '',
				requires_target_item: false,
				requires_target_item_count: false,
				is_emote: false,
				tooltip: 'Close this container.',
				effects: {},
				is_client: true
			}, CLIENT_CLOSE);
			
			CONFIG::god {
				client_verbs[CLIENT_EDIT_ITEM] = Verb.fromAnonymous({
					sort_on: 3,
					ok_states: ['in_pack', 'in_location'],
					requires_target_pc: false,
					label: 'Open Item Page',
					is_single: false,
					is_all: true,
					enabled: true,
					disabled_reason: '',
					requires_target_item: false,
					requires_target_item_count: false,
					is_emote: false,
					tooltip: 'ADMIN ONLY: Open item page in god',
					effects: {},
					is_client: true
				}, CLIENT_EDIT_ITEM);
				
				client_verbs[CLIENT_EDIT_PROPS] = Verb.fromAnonymous({
					sort_on: 3,
					ok_states: ['in_pack', 'in_location'],
					requires_target_pc: false,
					label: 'Edit Props',
					is_single: false,
					is_all: true,
					enabled: true,
					disabled_reason: '',
					requires_target_item: false,
					requires_target_item_count: false,
					is_emote: false,
					tooltip: 'ADMIN ONLY: Edit stack properties.',
					effects: {},
					is_client: true
				}, CLIENT_EDIT_PROPS);
				
				client_verbs[CLIENT_DESTROY] = Verb.fromAnonymous({
					sort_on: 1,
					ok_states: ['in_pack', 'in_location'],
					requires_target_pc: false,
					label: 'Destroy',
					is_single: false,
					is_all: true,
					enabled: true,
					disabled_reason: '',
					requires_target_item: false,
					requires_target_item_count: false,
					is_emote: false,
					tooltip: 'ADMIN ONLY: Nuke this stack.',
					effects: {},
					is_client: true
				}, CLIENT_DESTROY);
				
				client_verbs[CLIENT_COPY_TSID] = Verb.fromAnonymous({
					sort_on: 2,
					ok_states: ['in_pack', 'in_location'],
					requires_target_pc: false,
					label: 'Copy TSID',
					is_single: false,
					is_all: true,
					enabled: true,
					disabled_reason: '',
					requires_target_item: false,
					requires_target_item_count: false,
					is_emote: false,
					tooltip: 'ADMIN ONLY: puts the stack\'s tsid in your clipboard.',
					effects: {},
					is_client: true
				}, CLIENT_COPY_TSID);
				
				client_verbs[CLIENT_COPY_CLASS] = Verb.fromAnonymous({
					sort_on: 2,
					ok_states: ['in_pack', 'in_location'],
					requires_target_pc: false,
					label: 'Copy item class',
					is_single: false,
					is_all: true,
					enabled: true,
					disabled_reason: '',
					requires_target_item: false,
					requires_target_item_count: false,
					is_emote: false,
					tooltip: 'ADMIN ONLY: puts the stack\'s item class in your clipboard.',
					effects: {},
					is_client: true
				}, CLIENT_COPY_CLASS);
			}
		}
			
		public static function addClientVerbs(item:Item):void {
			if (!client_verbs_inited) {
				initClientVerbs();
			}
			
			var vkt:VerbKeyTrigger
			if (item.info_class || item.subclasses) {
				item.verbs[CLIENT_INFO] = client_verbs[CLIENT_INFO];
				
				vkt = new VerbKeyTrigger(String(Keyboard.I));
				vkt.key_str = 'I';
				vkt.verb_tsid = CLIENT_INFO;
				item.any_verb_key_triggers[Keyboard[vkt.key_str]] = vkt;
				item.pack_verb_key_triggers[Keyboard[vkt.key_str]] = vkt;
				item.loc_verb_key_triggers[Keyboard[vkt.key_str]] = vkt;
			}
			
			item.verbs[CLIENT_OPEN] = client_verbs[CLIENT_OPEN];
			/*
			vkt = new VerbKeyTrigger(String(Keyboard.P));
			vkt.key_str = 'O';
			vkt.verb_tsid = CLIENT_OPEN;
			item.any_verb_key_triggers[Keyboard[vkt.key_str]] = vkt;
			item.pack_verb_key_triggers[Keyboard[vkt.key_str]] = vkt;*/
			
			item.verbs[CLIENT_CLOSE] = client_verbs[CLIENT_CLOSE];
			/*
			vkt = new VerbKeyTrigger(String(Keyboard.C));
			vkt.key_str = 'C';
			vkt.verb_tsid = CLIENT_CLOSE;
			item.any_verb_key_triggers[Keyboard[vkt.key_str]] = vkt;
			item.pack_verb_key_triggers[Keyboard[vkt.key_str]] = vkt;*/
			
			CONFIG::god {
				if (item.admin_props) {
					item.verbs[CLIENT_EDIT_PROPS] = client_verbs[CLIENT_EDIT_PROPS];
				}
				item.verbs[CLIENT_EDIT_ITEM] = client_verbs[CLIENT_EDIT_ITEM];
				item.verbs[CLIENT_DESTROY] = client_verbs[CLIENT_DESTROY]
				item.verbs[CLIENT_COPY_TSID] = client_verbs[CLIENT_COPY_TSID]
				item.verbs[CLIENT_COPY_CLASS] = client_verbs[CLIENT_COPY_CLASS]
			}
			
		}

		public function hasTags(...tags_to_check:Array):Boolean {
			if (!tags || !tags.length) return false;
			
			// check if this is being called with an array as the argument, and if so, use that as tags_to_check
			if (tags_to_check && tags_to_check.length && tags_to_check[0] is Array) {
				tags_to_check = tags_to_check[0];
			}
			
			//hunt through the tags and see if we have any strict matches
			var i:int;
			var m:int;
			var total:int = tags_to_check.length;
			var tag:String;
			var tag_to_check:String;
			
			for (i; i < total; i++){
				tag_to_check = String(tags_to_check[int(i)]).toLowerCase();
				//loop through tags so we can get an exact match
				for (m=0; m < tags.length; m++){
					tag = String(tags[int(m)]).toLowerCase();
					if (tag == tag_to_check){
						//nice, we've got a match
						return true;
					}
				}
			}
			
			return false;
		}
		
		public function get label_plural():String {
			return (_label_plural == '') ? label : _label_plural;
		}
		
		public function set label_plural(name:String):void {
			_label_plural = name;
		}
		
		public static function confirmValidClass(class_tsid:String, stack_tsid:String):Boolean {
			// confirm we have a valid class_tsid
			if (!TSModelLocator.instance.worldModel.getItemByTsid(class_tsid)) {
				CONFIG::debugging {
					Console.error('itemstack:'+stack_tsid+' has an invalid class_tsid:'+class_tsid);
				}
				return false;
			}
			
			return true;
		}
		
		private var _placement_rect:Rectangle;

		public function get placement_rect():Rectangle {
			return _placement_rect;
		}

		public function setPlacementRect(value:Object):void {
			if (value is Rectangle) {
				_placement_rect = value as Rectangle;
			} else if (value) {
				if (placement_rect) {
					placement_rect.x = value.x;
					placement_rect.y = value.y;
					placement_rect.width = value.w;
					placement_rect.height = value.h;
				} else {
					_placement_rect = new Rectangle(
						value.x,
						value.y,
						value.w,
						value.h
					);
				}
			} else {
				_placement_rect = null;
			}
		}

		public var is_fetching_placement:Boolean;
		public var has_fetched_placement:Boolean;
		public var is_fetching_missing_asset:Boolean;
		public var has_fetched_missing_asset:Boolean;
		public var missing_asset:String;// = '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';
		
		public function isSnappable():Boolean {
			for each (var sprite_class:String in class_prefixes_that_are_snappable) {
				if (tsid.indexOf(sprite_class) == 0) {
					return true;
				}
			}
			return false;
		}
	}
}
