package com.tinyspeck.engine.data.itemstack {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.giant.GiantFavor;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	public class Itemstack extends AbstractItemstackEntity {
		client var physWidth:Number = NaN;
		client var physHeight:Number = NaN;
		client var physRadius:Number = NaN;
		client var door:Door;
		client var door_offset_x:int;
		client var door_offset_y:int;
		
		public var count:int;
		public var class_tsid:String;
		public var subclass_tsid:String;
		public var label:String;
		public var tooltip_label:String;
		public var x:int;
		public var y:int;
		public var z:uint = uint.MAX_VALUE; // only used for furniture right now
		public var display_z:uint; // only used for furniture right now
		public var slot:int;
		public var tsid:String;
		public var version:String;
		public var status:ItemstackStatus;
		public var bubble_msg:Object = {};
		public var bubble_duration:int = 0;
		public var store_ob:Object; // TODO formalize this into a Class when we're settled on how it should work
		public var slots:int = 0; // number of items that can fit in the container (0 means it is not a container)
		public var description:String;
		public var trophy_items:Object;
		public var waiting_on_verb:Boolean;
		public var tool_state:ItemstackToolState;
		public var consumable_state:ItemstackConsumableState;
		public var rs:uint; // rookstatus : rookstate
		public var date_aquired:String;
		public var created:uint;
		public var collection_id:String;
		public var is_soulbound_to_me:Boolean;
		private var _on_furniture:String; // client only
		
		public function get routing_class():String {
			if (subitem) return subitem.routing_class;
			return item.routing_class;
		}
		
		public function get info_class():String {
			if (subitem) return subitem.info_class;
			return item.info_class;
		}

		public function get on_furniture():String {
			return _on_furniture;
		}

		public function set on_furniture(value:String):void {
			/*if (!value) {
				CONFIG::debugging {
					Console.error(tsid+' NOT ON FURN');
				}
			}*/
			_on_furniture = value;
		}

		
		private var _path_tsid:String;
		
		/** @private */
		public var container_tsid:String;
		
		/** @private */
		public var itemstack_state:ItemstackState;
		
		/** @private */
		public var item:Item;

		private var _subitem:Item;
		public function get subitem():Item{
			return _subitem;
		}
		
		public function Itemstack(hashName:String) {
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Itemstack {
			var itemstack:Itemstack = new Itemstack(hashName);
			itemstack.tsid = hashName;
			itemstack.itemstack_state = new ItemstackState(itemstack.tsid);
			itemstack.itemstack_state.type = ItemstackState.TYPE_DEFAULT;
			/* check and make sure we are not getting bad tsid values
			if (itemstack.tsid.indexOf('/') > -1) {
				Console.error("itemstack.tsid.indexOf('/') > -1 "+itemstack.tsid);
			}
			*/
			
			return Itemstack.updateFromAnonymous(object, itemstack);
		}
		
		public function get scale():Number {
			// we do not want to adjust furniture scale until we sort out how to deal with source platforms
			if (item.is_furniture || item.is_special_furniture) {
				return item.scale;
			}
			
			const loc:Location = TSModelLocator.instance.worldModel.location;
			if (loc && loc.physics_setting && loc.physics_setting.item_scale) {
				return loc.physics_setting.item_scale * item.scale;
			}
			return item.scale;
		}

		
		//////////////////////////////////////////////////////////////////////////////////////////
		// NOt sure if this is how we want to do this, but it works for now for storage display boxes
		
		public function get furn_sale_price():Number {
			var sconfig:SpecialConfig = itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_FURN_PRICE_TAG);
			if (sconfig) {
				return sconfig.sale_price || NaN;
			}
			return NaN;
		}
		
		public function get sdb_sale_price():Number {
			var sconfig:SpecialConfig = itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_SDB_COST);
			if (sconfig) {
				return sconfig.sale_price || NaN;
			}
			return NaN;
		}
		
		public function get sdb_item_class():String {
			var sconfig:SpecialConfig = itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_SDB_ITEM_CLASS);
			if (sconfig) {
				return sconfig.item_class || null;
			}
			return null;
		}
		
		public function get sdb_item_count():int {
			var sconfig:SpecialConfig = itemstack_state.getSpecialConfigByType(SpecialConfig.TYPE_SDB_ITEM_CLASS);
			if (sconfig) {
				return sconfig.item_count || 0;
			}
			return 0;
		}
		//////////////////////////////////////////////////////////////////////////////////////////
		
		
		public function get is_glowey():Boolean {
			if (class_tsid == 'npc_sloth') return false;
			if (class_tsid.indexOf('esquibeth_note_') == 0) return false;
			return true;
		}
		
		public function get placement_w():int {
			if (class_tsid == 'garden_new' && itemstack_state.config && itemstack_state.config.proto_class) {
				var proto_item:Item = TSModelLocator.instance.worldModel.getItemByTsid(itemstack_state.config.proto_class);
				if (proto_item && proto_item.placement_w) {
					return proto_item.placement_w;
				}
			}
			
			return item.placement_w;
		}
		
		/**
		 * Does it glow and get a menu or by keyboard?
		 */
		public function get is_selectable():Boolean {
			if (item.is_interactable_furniture) {
				/*if (tsid == 'BPF13I00CRU2BBE' || tsid == 'BMF105P54FR299E') {
					Console.info(class_tsid+' '+itemstack_state.not_selectable +' '+ item.not_selectable)
				}
				*/
				return (!(itemstack_state.not_selectable || item.not_selectable));
			}

			return (!(itemstack_state.not_selectable || item.is_furniture || item.is_special_furniture || item.not_selectable));
		}

		/**
		 * Should clicking on it do anything?
		 */
		public function get is_clickable():Boolean {
			var sm:StateModel = TSModelLocator.instance.stateModel;
			
			// if it is selectable, it has got to be clickable...
			if (is_selectable) {
				return true;
			}
			
			// ...but it might be clickable even if not selectable
			
			// if sdb has something for sale, then it is clickable
			if (class_tsid == 'bag_furniture_sdb') {
				if (!isNaN(sdb_sale_price)) {
					return true;
				}
			}
			
			// allow a menu for the customize verb, for the owner
			if (class_tsid == 'furniture_tower_chassis' || class_tsid == 'furniture_chassis') {
				if (sm.can_cultivate) {
					return true;
				}
			}
			
			// furniture is clickable all the time if you can decorate, never if you can't 
			// (unless it is selectable or an sdb with something for sale, which is covered above)
			if (item.is_furniture || item.is_special_furniture) {
				if (!isNaN(furn_sale_price)) {
					return true;
				}
				return sm.can_decorate
			}
			
			return item.oneclick_verb != null || item.oneclick_pickup_verb != null;
		}
		
		public static function updateFromAnonymous(object:Object, itemstack:Itemstack):Itemstack {
			const wm:WorldModel = TSModelLocator.instance.worldModel;
			
			// this is only sent when it is true, so let's add it on with false value if it missing, so we can handle the prop like all the other props below
			if (!object.hasOwnProperty('not_selectable') && object.class_tsid != 'bag_furniture_sdb') {
				object.not_selectable = false;
			}
			/*
			CONFIG::debugging {
				if (object.hasOwnProperty('ctor_func') && object.ctor_func == 'make_item') {
					Console.info(object.class_tsid+' crtd with make_item');
				}
			}
			*/
			delete object['ctor_func'];
			
			if (!object.hasOwnProperty('z')) {
				object.z = uint.MAX_VALUE;
			}
			
			// do this ASAP!
			if (object.class_tsid && !itemstack.item) {
				itemstack.item = wm.getItemByTsid(object.class_tsid);
			}
			if (object.subclass_tsid && !itemstack.subitem) {
				itemstack._subitem = wm.getItemByTsid(object.subclass_tsid);
			}
			
			for(var j:String in object){
				if (j == 'rs'){
					if (object['rs'] === true) object['rs'] = 1;
					// does it make me dirty?
					if (itemstack.rs != object[j]) itemstack.itemstack_state.is_value_dirty = true;
					itemstack.rs = object[j];
				} else if(j == 'count'){
					// does it make me dirty?
					if (itemstack.count != object[j]) itemstack.itemstack_state.is_value_dirty = true;
					itemstack.count = object[j];
				} else if(j == 'config'){
					if (!object[j]) continue;
					
					// first let's get what the sig was
					var was_config_sig:String = itemstack.itemstack_state.config_sig;
					
					// now set the config
					itemstack.itemstack_state.config = object[j];
					
					// is it different?
					if (was_config_sig != itemstack.itemstack_state.config_sig) {
						itemstack.itemstack_state.is_config_dirty = true;
					}
					
				}
				else if(j == 'not_selectable'){
					var was_not_selectable:Boolean = itemstack.itemstack_state.not_selectable;
					itemstack.itemstack_state.not_selectable = (object.not_selectable === true);
					if (itemstack.itemstack_state != was_not_selectable) {
						//wm.triggerCBProp(false,false,"itemstacks", itemstack.tsid, "is_selectable");
					}
				}
				else if(j == 'soulbound_to'){
					itemstack.is_soulbound_to_me = (object.soulbound_to == wm.pc.tsid);
				}
				else if(j == 's'){
					
					if (!object[j]) continue; // bail if there is no value
					var s:* = object[j];
					var last_value:* = itemstack.itemstack_state.value;
					
					// defaults for an itemstack with a .s (otherwise defaults to )
					itemstack.itemstack_state.type = ItemstackState.TYPE_ANIMATION_NAME;
					itemstack.itemstack_state.raw_s_value = s;
					itemstack.itemstack_state.visibility = true;
					itemstack.itemstack_state.facing_right = true;
					
					//trants (and more in the future)
					if (typeof s == 'object') {
						itemstack.itemstack_state.type = ItemstackState.TYPE_ARGS;
						
					// special case where JS sends a scene: prefix
					} else if (s is String && s.length > 6 && s.substr(0,6) == 'scene:') {
						itemstack.itemstack_state.type = ItemstackState.TYPE_SCENE_NAME;
						itemstack.itemstack_state.scene_name =  s.replace('scene:', '');
						
					// special case where we want to switch back to default after sending visible:false
					} else if (s is int || s is Number) {
						itemstack.itemstack_state.type = ItemstackState.TYPE_DEFAULT;
						
					// special case where JS sends a visible: prefix
					} else if (s is String && s.length > 7 && s.substr(0,8) == 'visible:') {
						itemstack.itemstack_state.type = ItemstackState.TYPE_VISIBILITY;
						itemstack.itemstack_state.visibility = (s == 'visible:true');
					
					// it's a string, check for orientation
					} else if (s is String) {
						itemstack.itemstack_state.type = ItemstackState.TYPE_ANIMATION_NAME; // this is redundant, because already set above
						if (s.indexOf('-') == 0) {
							s = s.substr(1, s.length-1); // chop of the '-'
							itemstack.itemstack_state.facing_right = false;
						}
						itemstack.itemstack_state.animation_name = s;
						
					// this is a weird case
					} else {
						itemstack.itemstack_state.type = ItemstackState.TYPE_ANIMATION_NAME; // this is redundant, because already set above
						itemstack.itemstack_state.animation_name = String(s);
					}
					
					// has it changed?
					if (last_value != itemstack.itemstack_state.value) {
						itemstack.itemstack_state.is_value_dirty = true;
					}
					
				} 
				else if(j == 'tool_state'){
					itemstack.tool_state = ItemstackToolState.fromAnonymous(object[j], itemstack.tsid);
				}
				else if(j == 'consumable_state'){
					itemstack.consumable_state = ItemstackConsumableState.fromAnonymous(object[j], itemstack.tsid);
				}
				else if(j == 'status'){
					if (itemstack.status) {
						itemstack.status = ItemstackStatus.resetAndUpdateFromAnonymous(object[j], itemstack.status);
					} else {
						itemstack.status = ItemstackStatus.fromAnonymous(object[j], itemstack.tsid);
					}
					
					if (itemstack.status.is_dirty) wm.triggerCBProp(false,false,"itemstacks", itemstack.tsid, "status");
					itemstack.status.is_dirty = false;
				}
				else if(j in itemstack){
					itemstack[j] = object[j];
//				else if(j == 'itemstacks'){
//					//probably an open bag on the ground
//					var world:WorldModel = wm;
//					
//					for(var v:String in itemstack[j]){
//						if (world.getItemstackByTsid(v)) {
//							world.getItemstackByTsid(v) = updateFromAnonymous(itemstack[j][v], world.getItemstackByTsid(v));
//						} else {
//							world.getItemstackByTsid(v) = fromAnonymous(itemstack[j][v], v);
//						}
//					}
				}else{
					resolveError(itemstack,object,j);
				}
			}
			/*
			if (itemstack.class_tsid == 'furniture_window') {
				itemstack._itemstack_state.config = {
					swf_url: 'http://c2.glitch.bz/items/2009-12/1261531656-1786.swf'
				}
			}
			*/
			
			return itemstack;
		}
		
		
		public function get path_tsid():String {
			return _path_tsid;
		}
		
		public function get swf_url():String {
			if (itemstack_state && itemstack_state.furn_config && itemstack_state.furn_config.swf_url) {
				return itemstack_state.furn_config.swf_url;
			}
			return item.asset_swf_v;
		}
		
		public function get furn_upgrade_id():String {
			if ((item.is_furniture || item.is_special_furniture) && itemstack_state && itemstack_state.furn_config && itemstack_state.furn_config.upgrade_id) {
				return String(itemstack_state.furn_config.upgrade_id);
			}
			return '0';
		}
		
		public function get furn_stacking_sig():String {
			var sig:String = class_tsid+furn_upgrade_id;
			var furn_config:FurnitureConfig = itemstack_state.furn_config;
			if (furn_config && furn_config.upgrade_ids) {
				sig+= ':'+furn_config.upgrade_ids.join(',');
			}
			return sig;
		}
		
		// really just so we can sort
		public function get furn_facing_right():Boolean {
			if ((item.is_furniture || item.is_special_furniture) && itemstack_state && itemstack_state.furn_config) {
				return itemstack_state.furn_config.facing_right;
			}
			return true;
		}

		// tsid/tsid/.../tsid
		public function set path_tsid(value:String):void {
			if (_path_tsid != value) {
				_path_tsid = value;
				
				// precompute container_tsid
				container_tsid = null;
				if (value && tsid != value) {
					const A:Array = value.split('/');
					CONFIG::debugging {
						if (A.length<1) Console.warn(tsid+' has a path with less that two segments that is not the same as its tsid');
					}
					if (A.length) container_tsid = A[A.length-2];
				}
			}
		}
		
		public function getLabel():String {
			var this_label:String;
			
			if (subitem) {
				this_label = subitem.label;
			} else {
				this_label = (label && label != item.label) ? label : item.label;
			}
			
			//return ss_state+' '+ss_state_sent
			
			CONFIG::god {
				var itemstack_state:ItemstackState = itemstack_state;
				if (itemstack_state.config) {
					if (itemstack_state.config.preview_deco) {
						this_label+= '<br>POL: '+itemstack_state.config.pol_chassis+' ('+itemstack_state.config.deco+')';
					}
				}
			}
			
			return this_label;
		}
		
		/*
		
		1:56 PM <stewart> for non-selling SDBs, I'd recommend "5 $itemName (in a $furnitureUpgradeName)"
		1:57 PM <eric> that is complicated
		1:57 PM <stewart> and if they are selling, "$itemName selling for N currants (x remaining)"
		1:57 PM <stewart> ok! how about I bug it ... for the future
		*/
		
		public function getLocationTip(pt:Point, tip_target:DisplayObject = null):Object {
			var tsid_str:String = '';
			
			var model:TSModelLocator = TSModelLocator.instance;
			
			// for certain things in newxp, before the img menu is shown, we want no tips
			if (model.worldModel.location && model.worldModel.location.no_imagination) {
				if (class_tsid == 'magic_rock') {
					return null;
					
				}
			}
			
			// no furn tips when not in a home location! (mainly for newxp)
			if (model.worldModel.location && !model.worldModel.location.is_home) {
				if (item.is_furniture || item.is_special_furniture) {
					return null;
				}
			}
			
			CONFIG::god {
				tsid_str = ' '+tsid+' sc:'+item.adjusted_scale+' x:'+x+' y:'+y;
			}
			
			var contains_label:String = '';
			
			if (furn_sale_price) {
				return {
					txt: getLabel()+' on sale for ₡'+furn_sale_price+tsid_str,
					placement: {x:pt.x, y:pt.y + 10}
				}
			}
			
			if (sdb_item_count > -1) { // this is just for bag_furniture_sdb right now
				var count_item:Item = model.worldModel.getItemByTsid(sdb_item_class);
				if (count_item) {
					if (sdb_sale_price) {
						contains_label =  count_item.label_plural+' selling for '+StringUtil.formatNumberWithCommas(sdb_sale_price)+'₡ ('+sdb_item_count+' remaining) ';
						return {
							txt: contains_label+tsid_str,
							placement: {x:pt.x, y:pt.y + 10}
						}
					} else {
						//if (is_selectable) {
							contains_label =  sdb_item_count+' '+(sdb_item_count==1?count_item.label:count_item.label_plural)+' ';
						//} else {
						//	contains_label = count_item.label_plural+' ';
						//}
					}
				}
			}
			
			if (item.oneclick_verb && !model.stateModel.decorator_mode && is_clickable) { //oneclick_verbs do not work in deco mode
				
				// special case this until we have dynamic oneclick verbs on stacks
				if (item.tsid == 'bag_furniture_sdb' && sdb_item_count < 1) {
					if (model.stateModel.open_menu_when_one_click_is_disabled) {
						// fall through to below, we'll be opening a menu
					} else {
						return {
							txt: 'Click to deposit an item'+tsid_str,
							placement: {x:pt.x, y:pt.y + 10},
							pointer: WindowBorder.POINTER_TOP_CENTER,
							color: 0xe7f0db
						}
					}
				} else if (item.tsid == 'note_pole') {
					
					return {
						txt: 'Click to read: '+getLabel()+tsid_str,
						placement: {x:pt.x, y:pt.y + 10},
						pointer: WindowBorder.POINTER_TOP_CENTER,
						color: 0xe7f0db
					}
					
				} else {
					
					if (item.oneclick_verb.tooltip) {
						return {
							txt: item.oneclick_verb.tooltip+contains_label+tsid_str,
							placement: {x:pt.x, y:pt.y + 10},
							pointer: WindowBorder.POINTER_TOP_CENTER,
							color: 0xe7f0db
						}
					}
					
					// if no tooltip, show no tip
					return null;
				}
			}
			
			if (item.oneclick_pickup_verb && is_clickable) {
				return {
					txt: ((count == 1) ? 'Pick up this '+item.label : 'Pick up all '+count+' of these '+item.label_plural)+contains_label+tsid_str,
					placement: {x:pt.x, y:pt.y + 10},
					pointer: WindowBorder.POINTER_TOP_CENTER,
					color: 0xe7f0db
				}
			}
			
			var label:String;
			if (tooltip_label) {
				label = tooltip_label;
			} else {
				label = (count>1) ? count+'&nbsp;'+item.label_plural : getLabel()+'';
			}
			
			if (contains_label) {
				label = '(in a '+getLabel()+')';
			}
			
			
			var favor_label:String = '';
			if (item.is_shrine) {
				const giant:String = class_tsid.substr(class_tsid.lastIndexOf('_')+1);
				const favor:GiantFavor = model.worldModel.pc.stats.favor_points.getFavorByName(giant);
				if (favor) {
					favor_label = ' (current favor is '+favor.current+'/'+favor.max+')';// with '+StringUtil.capitalizeFirstLetter(giant)+')';
				}
			}
			
			return {
				txt: contains_label+label+favor_label+tsid_str,
				placement: {x:pt.x, y:pt.y + 10}
			}
		}
	}
}