package com.tinyspeck.engine.model
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.data.Achievement;
	import com.tinyspeck.engine.data.garden.Garden;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCParty;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.data.transit.Transit;
	import com.tinyspeck.engine.data.transit.TransitLine;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	
	import flash.utils.Dictionary;
	
	import org.osflash.signals.Signal;
	
	CONFIG::locodeco { import locodeco.LocoDecoGlobals; }
	CONFIG::locodeco { import mx.collections.ArrayCollection; }

	public class WorldModel extends AbstractPropertyProvider {
		CONFIG::locodeco public var location_undoA:Array = [];
		
		public static const GOD:String = 'god';
		public static const NO_ONE:String = 'no_one';
		public static const ITEM_CLASSES_WITH_DOORS:Vector.<String> = new <String>['furniture_tower_chassis', 'furniture_chassis', 'furniture_door'];
		public static const ITEM_CLASSES_WITH_DOOR_ICONS:Vector.<String> = new <String>['furniture_tower_chassis', 'furniture_chassis'];
		
		public var prev_location:Location;
		private var _location:Location;
		
		public function get location():Location {
			return _location;
		}
		
		public function set location(value:Location):void {
			CONFIG::debugging {
				Console.info('LOCATION SET TO '+value.tsid+' '+StringUtil.getCallerCodeLocation());
			}

			_location = value;
			
			calcCanDecorateCultivate();
		}
		
		private function calcCanDecorateCultivate():void {
			TSModelLocator.instance.stateModel.can_decorate = (pc && location && ((location.is_decoratable) || (pc.home_info && location.tsid == pc.home_info.interior_tsid)));
			TSModelLocator.instance.stateModel.can_cultivate = TSModelLocator.instance.stateModel.can_decorate || (pc && location && pc.home_info && location.tsid == pc.home_info.exterior_tsid);
		}
				
		public const pcs:Dictionary = new Dictionary();
		public const locations:Dictionary = new Dictionary();
		public const search_locations:Dictionary = new Dictionary();
		public const physics_obs:Dictionary = new Dictionary();
		public const hubs:Dictionary = new Dictionary();
		public const items:Dictionary = new Dictionary();
		public const itemstacks:Dictionary = new Dictionary();
		public const groups:Dictionary = new Dictionary();
		public var skill_urls:Object = {};
		public const skill_details:Dictionary = new Dictionary();
		public const learnable_skills:Vector.<SkillDetails> = new Vector.<SkillDetails>();
		public const achievements:Dictionary = new Dictionary();
		public var recipes:Vector.<Recipe> = new Vector.<Recipe>();
		public const gardens:Vector.<Garden> = new Vector.<Garden>();
		public const transits:Vector.<Transit> = new Vector.<Transit>();
		public const poof_ins:Object = {};
		
		public var hi_emote_variant_sig:Signal = new Signal();
		
		public var hi_emote_variants:Array = [];
		public var hi_emote_variants_color_map:Object = {};
		public var hi_emote_variants_name_map:Object = {};
		public var yesterdays_hi_emote_variant_winner_count:int;
		public var yesterdays_hi_emote_top_infector_count:int;
		public var yesterdays_hi_emote_top_infector_tsid:String;
		public var yesterdays_hi_emote_top_infector_variant:String;
		
		private var _yesterdays_hi_emote_variant_winner:String;
		public var hi_emote_winner_sig:Signal = new Signal();
		public function get yesterdays_hi_emote_variant_winner():String {return _yesterdays_hi_emote_variant_winner;}
		public function set yesterdays_hi_emote_variant_winner(value:String):void {
			_yesterdays_hi_emote_variant_winner = value;
			hi_emote_winner_sig.dispatch();
		}
		
		private const _hi_emote_leaderboard:Object = {};
		public var hi_emote_leaderboard_sig:Signal = new Signal(Object);
		public function get hi_emote_leaderboard():Object {return _hi_emote_leaderboard;}
		public function set hi_emote_leaderboard(value:Object):void {
			for (var k:String in value) {
				_hi_emote_leaderboard[k] = value[k];
			}
			hi_emote_leaderboard_sig.dispatch(_hi_emote_leaderboard);
		}
		
		public function resetHiEmoteLeaderboard():void {
			for (var k:String in hi_emote_leaderboard) {
				_hi_emote_leaderboard[k] = 0;
			}
			hi_emote_leaderboard_sig.dispatch(_hi_emote_leaderboard);
		}
		
		public var ambient_hub_map:Object;
		
		private var _invoking:Object;
		private var _userdeco:Object;
		
		private var _pc:PC;
		private var _party:PCParty;
		
		private var _party_member_updates:Array = [];
		private var _party_member_adds:Array = [];
		private var _party_member_dels:Array = [];
		
		private var _loc_pc_updates:Array = [];
		private var _loc_pc_adds:Array = [];
		private var _loc_pc_dels:Array = [];
		
		private var _loc_itemstack_updates:Array = [];
		private var _loc_itemstack_adds:Array = [];
		private var _loc_itemstack_dels:Array = [];
		
		private var _pc_itemstack_updates:Array = [];
		private var _pc_itemstack_adds:Array = [];
		private var _pc_itemstack_dels:Array = [];
		
		private var _buff_updates:Array = [];
		private var _buff_adds:Array = [];
		private var _buff_dels:Array = [];
		
		private var _quests:Vector.<Quest> = new Vector.<Quest>();
		
		private const unique_items:Array = [];
		private var unique_item_street_tsid:String;
		
		private const location_search_results:Vector.<Location> = new Vector.<Location>();
		private const buddy_search_results:Vector.<PC> = new Vector.<PC>();
		private const buddy_search_sub_results:Vector.<PC> = new Vector.<PC>();
		private const item_search_results:Vector.<Item> = new Vector.<Item>();
		private const item_search_sub_results:Vector.<Item> = new Vector.<Item>();
		private const itemstack_search_results:Vector.<Itemstack> = new Vector.<Itemstack>();
		private const itemstack_search_sub_results:Vector.<Itemstack> = new Vector.<Itemstack>();
		private const recipe_search_results:Vector.<Recipe> = new Vector.<Recipe>();
		private const recipe_search_sub_results:Vector.<Recipe> = new Vector.<Recipe>();
		private const loc_itemstacks:Vector.<Itemstack> = new Vector.<Itemstack>();
		private const quest_reqs:Vector.<Requirement> = new Vector.<Requirement>();
		
		public function WorldModel() {
			//
		}
		
		public function upsertItemstack(itemstack_data:Object):Itemstack {
			var itemstack:Itemstack = getItemstackByTsid(itemstack_data.tsid);
			if (itemstack) {
				itemstack = Itemstack.updateFromAnonymous(itemstack_data, itemstack);
			} else {
				itemstack = Itemstack.fromAnonymous(itemstack_data, itemstack_data.tsid);
			}
			
			itemstacks[itemstack.tsid] = itemstack;
			
			return itemstack;
		}
		
		public function upsertPc(pc_data:Object):PC {
			if(!('tsid' in pc_data)){
				CONFIG::debugging {
					Console.warn('PC without a TSID, WTF?!');
					Console.dir(pc_data);
				}
				return null;
			}
			
			var pc:PC = getPCByTsid(pc_data.tsid);
			if (pc) {
				pc = PC.updateFromAnonymous(pc_data, pc);
			} else {
				pc = PC.fromAnonymous(pc_data, pc_data.tsid);
			}
			
			//to the world with you!
			pcs[pc.tsid] = pc;
			
			return pc;
		}
		
		public function getColorsForRightSide():Array {
			var colorsA:Array = [ColorUtil.colorStrToNum('002934'), ColorUtil.colorStrToNum('153440')]
			//#002934  (dark)- #153440 (light)
			
			if (TSModelLocator.instance.flashVarModel.colors_from_loc) {
				
				var loc:Location = location;
				if (loc.hasGradient()) {
					colorsA = [
						ColorUtil.colorStrToNum(loc.gradient.top),
						ColorUtil.colorStrToNum(loc.gradient.bottom)
					];
				}
			}
			
			return colorsA;
		}
		
		public function getItemByItemstackId(tsid:String):Item {
			const itemstack:Itemstack = (itemstacks[tsid] as Itemstack);
			return (itemstack ? (items[itemstack.class_tsid] as Item) : null);
		}
		
		public function getItemstackByTsid(tsid:String):Itemstack {
			return (itemstacks[tsid] as Itemstack);
		}
		
		public function getLocationItemstacksAByItemClass(item_class:String):Array {
			var A:Array = [];
			var itemstack:Itemstack;
			for (var k:String in location.itemstack_tsid_list) {
				itemstack = getItemstackByTsid(k);
				if (itemstack.class_tsid == item_class) {
					A.push(itemstack);
				}
			}
			return A;
		}
		
		public function getLocationFurnItemstacksA():Array {
			var A:Array = [];
			var itemstack:Itemstack;
			for (var k:String in location.itemstack_tsid_list) {
				itemstack = getItemstackByTsid(k);
				if (itemstack.item.is_furniture) {
					A.push(itemstack);
				}
			}
			return A;
		}
		
		public function getLocationItemstacksA():Array {
			var A:Array = [];
			var itemstack:Itemstack;
			for (var k:String in location.itemstack_tsid_list) {
				itemstack = getItemstackByTsid(k);
				A.push(itemstack);
			}
			return A;
		}
		
		public function getItemstacksInContainerTsid(container_tsid:String):Vector.<Itemstack> {
			//return a list of itemstacks in that container
			//putting the const here instead of outside in the event multiple calls to this have to happen at the same time
			const container_itemstacks:Vector.<Itemstack> = new Vector.<Itemstack>();
			
			var k:String;
			var itemstack:Itemstack;
			
			for(k in itemstacks){
				itemstack = itemstacks[k];
				if(itemstack.container_tsid && itemstack.container_tsid == container_tsid){
					container_itemstacks.push(itemstack);
				}
			}
			
			return container_itemstacks;
		}
		
		public function getItemByTsid(tsid:String):Item {
			return (items[tsid] as Item);
		}
		
		public function getItemTsidsByPartialName(partial_name:String):Array {
			var k:String;
			const tsids:Array = [];
			
			//the tsid must START with the partial name
			for(k in items){
				if(k.indexOf(partial_name) == 0) tsids.push(k);
			}
			
			return tsids;
		}
		
		public function getItemTsidsByTags(...tags:Array):Array {
			const tsids:Array = [];
			var k:String;
			var item:Item;
			var i:int;
			var total:int = tags.length;
			
			//hunt the item tags for matches
			for(k in items){
				item = items[k] as Item;
				
				for(i = 0; i < total; i++){
					if(item.hasTags(tags)){
						//nice, we've got a match
						tsids.push(k);
					}
				}
			}
			
			return tsids;
		}
		
		public function getPCByTsid(tsid:String):PC {
			return (pcs[tsid] as PC);
		}
		
		public function getSkillDetailsByTsid(tsid:String):SkillDetails {
			return (skill_details[tsid] as SkillDetails);
		}
		
		public function getAchievementByTsid(tsid:String):Achievement {
			return (achievements[tsid] as Achievement);
		}
		
		public function getGroupByTsid(tsid:String, include_perma:Boolean = true):Group {
			if(include_perma || 
				(tsid != ChatArea.NAME_GLOBAL && 
				tsid != ChatArea.NAME_HELP && 
				tsid != ChatArea.NAME_TRADE && 
				tsid != ChatArea.NAME_UPDATE_FEED)){
				return (groups[tsid] as Group);
			}
			
			return null;
		}
		
		public function getBuddyByTsid(tsid:String):String {
			return pc.buddy_tsid_list[tsid];
		}
		
		public function getLocationByTsid(tsid:String):Location {
			return locations[tsid];
		}
		
		public function searchLocations(str:String):Vector.<Location> {			
			var k:String;
			var location:Location;
			var hub:Hub;
			
			location_search_results.length = 0;
			
			//search the locations
			for(k in search_locations){
				if(String(search_locations[k]).toLowerCase().indexOf(str.toLowerCase()) != -1) {
					location = getLocationByTsid(k);
					
					//we must've hit a hub name, make a fake location to inject into the results
					//Look at HubMapDialog.showSearchResults to see how to handle fake inserts
					if(!location && getHubByTsid(k)){
						location = new Location(k);
						location.hub_id = k;
					}
					
					location_search_results.push(location);
				}
			}
			
			//sort by hub_id, then name
			SortTools.vectorSortOn(location_search_results, ['hub_id', 'label'], [Array.NUMERIC]);
			
			return location_search_results;
		}
		
		public function searchBuddies(str:String, tsids_to_exclude:Array = null):Vector.<PC> {
			var k:String;
			var buddy:PC;
			
			buddy_search_results.length = 0;
			buddy_search_sub_results.length = 0;
			
			//search the player's buddy list, only from the first letter on
			if(str.length && pc && pc.buddy_tsid_list){
				for(k in pc.buddy_tsid_list){
					buddy = getPCByTsid(k);
					if(buddy && buddy.label && buddy.label.toLowerCase().indexOf(str.toLowerCase()) == 0 && (tsids_to_exclude ? tsids_to_exclude.indexOf(k) == -1 : true)){
						buddy_search_results.push(buddy);
					}
				}
				
				//order them by label
				SortTools.vectorSortOn(buddy_search_results, ['label'], [Array.CASEINSENSITIVE]);
				
				//find any other buddies that match up
				for(k in pc.buddy_tsid_list){
					buddy = getPCByTsid(k);
					if(buddy && buddy_search_results.indexOf(buddy) == -1 && buddy.label && buddy.label.toLowerCase().indexOf(str.toLowerCase()) != -1 && (tsids_to_exclude ? tsids_to_exclude.indexOf(k) == -1 : true)){
						buddy_search_sub_results.push(buddy);
					}
				}
				
				//order them by label
				SortTools.vectorSortOn(buddy_search_sub_results, ['label'], [Array.CASEINSENSITIVE]);
			}
			
			return buddy_search_results.concat(buddy_search_sub_results);
		}
		
		private function searchItemsTagsOK(item:Item, tags_to_exclude:Array):Boolean {
			if (!tags_to_exclude) return true;
			if (!tags_to_exclude.length) return true;
			return !item.hasTags(tags_to_exclude);
		}
		
		private function searchItemsFlagsOK(item:Item, is_in_encyc:Boolean):Boolean {
			if (!is_in_encyc) return true; 
			return item.is_in_encyc;
		}
		
		public function searchItems(str:String, tags_to_exclude:Array, is_in_encyc:Boolean):Vector.<Item> {
			var k:String;
			var item:Item;
			
			item_search_results.length = 0;
			item_search_sub_results.length = 0;
			
			//search the items
			if(str.length >=2){ //anything less shits the bed while it tries to load all the images
				for(k in items){
					item = getItemByTsid(k);
					if(item && item.label.toLowerCase().indexOf(str.toLowerCase()) == 0){
						if (searchItemsTagsOK(item, tags_to_exclude) && searchItemsFlagsOK(item, is_in_encyc)) {
							item_search_results.push(item);
						}
					}
				}
				
				//order them by label
				SortTools.vectorSortOn(item_search_results, ['label'], [Array.CASEINSENSITIVE]);
				
				//find any other items that match the letters and attach them to the bottom
				for(k in items){
					item = getItemByTsid(k);
					if(item && item_search_results.indexOf(item) == -1 && item.label.toLowerCase().indexOf(str.toLowerCase()) != -1){
						if (searchItemsTagsOK(item, tags_to_exclude) && searchItemsFlagsOK(item, is_in_encyc)) {
							item_search_sub_results.push(item);
						}
					}
				}
				
				//order them by label
				SortTools.vectorSortOn(item_search_sub_results, ['label'], [Array.CASEINSENSITIVE]);
			}
			
			return item_search_results.concat(item_search_sub_results);
		}
		
		public function searchItemstacks(str:String, tsids_to_search:Dictionary = null):Vector.<Itemstack> {			
			//if no tsids, search em all!
			if(!tsids_to_search) tsids_to_search = itemstacks;
			var k:String;
			var itemstack:Itemstack;
			
			itemstack_search_results.length = 0;
			itemstack_search_sub_results.length = 0;
			
			//search the tsids and stuff
			if(str.length >=2){ //anything less shits the bed while it tries to load all the images
				for(k in tsids_to_search){
					itemstack = getItemstackByTsid(k);
					if(itemstack && itemstack.label.toLowerCase().indexOf(str.toLowerCase()) == 0){
						itemstack_search_results.push(itemstack);
					}
				}
				
				//order them by label
				SortTools.vectorSortOn(itemstack_search_results, ['label', 'container_tsid', 'slot'], [Array.CASEINSENSITIVE, Array.CASEINSENSITIVE, Array.NUMERIC]);
				
				//find any other items that match the letters and attach them to the bottom
				for(k in tsids_to_search){
					itemstack = getItemstackByTsid(k);
					if(itemstack && itemstack_search_results.indexOf(itemstack) == -1 && itemstack.label.toLowerCase().indexOf(str.toLowerCase()) != -1){
						itemstack_search_sub_results.push(itemstack);
					}
				}
				
				//order them by label
				SortTools.vectorSortOn(itemstack_search_sub_results, ['label', 'container_tsid', 'slot'], [Array.CASEINSENSITIVE, Array.CASEINSENSITIVE, Array.NUMERIC]);
			}
			
			//fire it off to whoever needs it
			return itemstack_search_results.concat(itemstack_search_sub_results);
		}
		
		public function searchRecipes(str:String, can_make:Boolean, and_furniture:Boolean = false, and_machines:Boolean = false):Vector.<Recipe> {
			const current_recipes:Vector.<Recipe> = recipes.concat();
			const total:int = current_recipes ? current_recipes.length : 0;
			var i:int;
			var recipe:Recipe;
			var output_class:String;
			
			recipe_search_results.length = 0;
			recipe_search_sub_results.length = 0;
			
			//search the player's buddy list, only from the first letter on
			if(str.length && total){
				for(i = 0; i < total; i++){
					recipe = current_recipes[int(i)];
					output_class = recipe ? recipe.outputs[0].item_class : '';
					
					if(recipe 
						&& recipe.name.toLowerCase().indexOf(str.toLowerCase()) == 0 
						&& (can_make ? recipe.can_make : true)
						&& (!and_furniture ? (output_class.indexOf('furniture_') != 0 && output_class.indexOf('bag_furniture_') != 0) : true)
						&& (!and_machines ? !recipe.isInput('fuel_cell') : true)
					){
						recipe_search_results.push(recipe);
					}
				}
				
				//order them by name
				SortTools.vectorSortOn(recipe_search_results, ['name'], [Array.CASEINSENSITIVE]);
				
				//find any other recipes that match up
				for(i = 0; i < total; i++){
					recipe = current_recipes[int(i)];
					output_class = recipe ? recipe.outputs[0].item_class : '';
					
					if(recipe 
						&& recipe_search_results.indexOf(recipe) == -1 
						&& recipe.name.toLowerCase().indexOf(str.toLowerCase()) != -1 
						&& (can_make ? recipe.can_make : true)
						&& (!and_furniture ? (output_class.indexOf('furniture_') != 0 && output_class.indexOf('bag_furniture_') != 0) : true)
						&& (!and_machines ? !recipe.isInput('fuel_cell') : true)
					){
						recipe_search_sub_results.push(recipe);
					}
				}
				
				//order them by name
				SortTools.vectorSortOn(recipe_search_sub_results, ['name'], [Array.CASEINSENSITIVE]);
			}
			
			return recipe_search_results.concat(recipe_search_sub_results);
		}
		
		public function getHubByTsid(tsid:String):Hub {
			return (hubs[tsid] as Hub);
		}
		
		public function getRecipeById(recipe_id:String):Recipe {
			var recipe:Recipe;
			var i:int;
			var total:int = recipes.length;
			
			for(i; i < total; i++){
				recipe = recipes[int(i)];
				if(recipe.id == recipe_id) return recipe;
			}
			
			return null;
		}
		
		public function getRecipeByOutputClass(class_tsid:String):Recipe {
			var recipe:Recipe;
			var i:int;
			var total:int = recipes.length;
			var j:int;
			
			for(i; i < total; i++){
				recipe = recipes[int(i)];
				for(j = 0; j < recipe.outputs.length; j++){
					if(recipe.outputs[int(j)].item_class == class_tsid) return recipe;
				}
			}
			
			return null;
		}
		
		public function getRecipesByTool(tool_class:String, can_make:Boolean = true, and_furniture:Boolean = false, and_machines:Boolean = false):Vector.<Recipe> {
			const V:Vector.<Recipe> = recipes.concat();
			const results:Vector.<Recipe> = new Vector.<Recipe>();
			const total:int = V.length;
			var i:int;
			var recipe:Recipe;
			var output_class:String;
			
			for(i; i < total; i++){
				recipe = V[int(i)];
				output_class = recipe ? recipe.outputs[0].item_class : '';
				if(recipe
					&& recipe.tool == tool_class
					&& (can_make ? recipe.can_make : true)
					&& (!and_furniture ? (output_class.indexOf('furniture_') != 0 && output_class.indexOf('bag_furniture_') != 0) : true)
					&& (!and_machines ? !recipe.isInput('fuel_cell') : true)
				){
					results.push(recipe);
				}
			}
			
			return results;
		}
		
		public function getGardenByTsid(tsid:String):Garden {
			var garden:Garden;
			var i:int;
			var total:int = gardens.length;
			
			for(i; i < total; i++){
				garden = gardens[int(i)];
				if(garden.itemstack_tsid == tsid) return garden;
			}
			
			return null;
		}
		
		public function getTransitByTsid(tsid:String):Transit {
			var transit:Transit;
			var i:int;
			var total:int = transits.length;
			
			for(i; i < total; i++){
				transit = transits[int(i)];
				if(transit.tsid == tsid) return transit;
			}
			
			return null;
		}
		
		public function getTransitTsidByLocationTsid(tsid:String):String {
			//this is going to be a loop party!
			var transit:Transit;
			var line:TransitLine;
			var i:int;
			var j:int;
			var total:int = transits.length;
			
			for(i = 0; i < total; i++){
				transit = transits[int(i)];
				if(transit.lines){
					for(j = 0; j < transit.lines.length; j++){
						line =  transit.lines[int(j)];
						if(line.getLocationByTsid(tsid)) return transit.tsid;
					}
				}
			}
			
			return null;
		}
		
		public function getPartyMemberByTsid(tsid:String):PC {
			if(party.member_tsids.indexOf(tsid) >= 0){
				return (pcs[tsid] as PC);
			}
			
			return null;
		}
		
		public function getQuestById(id:String):Quest 
		{
			var quest:Quest;
			var i:int = 0;
			var total:int = _quests.length;
			
			for(i; i < total; i++){
				quest = _quests[int(i)];
				if(quest.hashName == id){
					return quest;
				}
			}
			
			return null;
		}
		
		public function getQuestByReqId(id:String):Quest {
			//this will loop through the quests to try and find the requirement
			var quest:Quest;
			var req:Requirement;
			var i:int;
			var j:int;
			var total:int = _quests.length;
			
			for(i; i < total; i++){
				quest = _quests[int(i)];
				for(j = 0; j < quest.reqs.length; j++){
					req = quest.reqs[int(j)];
					if(req.id == id) return quest;
				}
			}
			
			return null;
		}
		
		public function getQuestReqsOnStreet():Vector.<Requirement> {
			const total:int = _quests.length;
			var quest:Quest;
			var req:Requirement;
			var i:int;
			var j:int;
			
			quest_reqs.length = 0;
			
			for(i = 0; i < total; i++){
				quest = _quests[int(i)];
				
				//no accept, complete?, no care
				if(!quest.accepted || quest.finished) continue;
				
				for(j = 0; j < quest.reqs.length; j++){
					//see if the req is an item, and it's on the street someplace
					req = quest.reqs[int(j)];
					if(req.item_class && !req.completed && isItemOnStreet(req.item_class)){
						quest_reqs.push(req);
					}
				}
			}
			
			return quest_reqs;
		}
		
		/** Returns tsids of stacks in pack root or in bags in pack (EXPENSIVE) */
		public function getPcItemstacksInPackTsidA():Array {
			var A:Array = [];
			var itemstack:Itemstack;
			var bag_itemstack:Itemstack;
			for (var k:String in pc.itemstack_tsid_list) {
				itemstack = (itemstacks[k] as Itemstack);
				if (itemstack.container_tsid) {
					bag_itemstack = (itemstacks[itemstack.container_tsid] as Itemstack);
					// this weeds out stacks that have containers we don't know about, like trophy case storage, and escrow bag
					if (!bag_itemstack) continue;
				}		
				
				A.push(k);
			}
			
			return A;
		}
		
		public function getBuddiesTsids(is_online:Boolean):Array {
			var buddies:Vector.<PC> = new Vector.<PC>();
			var buddy_tsids:Array = [];
			var buddy:PC;
			var k:String;
			var i:int;
			
			/** DEBUG 
			if(is_online){
				for(i = 0; i < 20; i++){
					buddy = new PC('P'+i);
					buddy.tsid = 'P'+i;
					buddy.label = 'Test'+i;
					buddy.online = is_online;
					pcs['P'+i] = buddy;
					pc.buddy_tsid_list['P'+i] = 'P'+i;
				}
			}
			//**/
			
			for(k in pc.buddy_tsid_list){
				buddy = getPCByTsid(k);
				if(buddy && !buddy.ignored){
					if(is_online && buddy.online){
						buddies.push(buddy);
					}
					else if(!is_online && !buddy.online){
						buddies.push(buddy);
					}
				}
			}
			
			//sort them alphabetically
			//SortTools.vectorSortOn(buddies, ['label'], [Array.CASEINSENSITIVE]);
			buddy_tsids.sortOn(['label'], [Array.CASEINSENSITIVE]);
			
			//loop through and pump out the TSIDs
			for(i = 0; i < buddies.length; i++){
				buddy_tsids.push(buddies[int(i)].tsid);
			}
			
			return buddy_tsids;
		}
		
		public function getItemstacksASortedByZ(tsids:Object):Array {
			var tsid:String;
			var itemstack:Itemstack;
			var itemstackA:Array = [];
			
			for each (tsid in tsids) {
				itemstack = getItemstackByTsid(tsid);
				if (itemstack) {
					itemstackA.push(itemstack);
				}
			}
			
			itemstackA.sortOn(['z'], [Array.NUMERIC]);
			
			return itemstackA;
		}
		
		public function getGroupsTsids(and_global:Boolean = true, and_updates:Boolean = false, just_perma:Boolean = false):Array {
			var groups:Vector.<Group> = new Vector.<Group>();
			var group_tsids:Array = [];
			var group:Group;
			var k:String;
			var i:int;
			var global_chat:Group;
			var live_help:Group;
			var updates:Group;
			var trade:Group;
			
			for(k in this.groups){
				group = this.groups[k];
				if(k == ChatArea.NAME_GLOBAL){
					global_chat = group;
				}
				else if(k == ChatArea.NAME_HELP) {
					live_help = group;
				}
				else if(k == ChatArea.NAME_UPDATE_FEED) {
					updates = group;
				}
				else if(k == ChatArea.NAME_TRADE) {
					trade = group;
				}
				else if(group.is_member && !just_perma) {
					groups.push(group);
				}
			}
			
			//sort them alphabetically
			SortTools.vectorSortOn(groups, ['label'], [Array.CASEINSENSITIVE]);
			
			//push updates to the top
			if(and_updates && updates){
				groups.unshift(updates);
			}
			
			//push the global channels to the top
			if(and_global){
				if(trade) groups.unshift(trade);
				if(global_chat) groups.unshift(global_chat);
				if(live_help) groups.unshift(live_help);
			}
			
			//loop through and pump out the TSIDs
			for(i; i < groups.length; i++){
				group_tsids.push(groups[int(i)].tsid);
			}
			
			return group_tsids;
		}
		
		public function areYouAloneInLocation():Boolean {
			for (var tsid:String in location.pc_tsid_list) if (tsid != pc.tsid) return false;
			return true;
		}
		
		public function getSortedItems():Array {
			var sortedA:Array = [];
			for (var key:String in items) sortedA.push(items[key]);
			sortedA.sortOn('label', [Array.CASEINSENSITIVE]);
			
			return sortedA;
		}
		
		public function getUniqueItemsOnStreet():Array {
			unique_items.length = 0;
			loc_itemstacks.length = 0;
			
			if(!location || !location.itemstack_tsid_list){
				//throw back the empty array
				return unique_items;
			}
			
			var k:String;
			unique_item_street_tsid = location.tsid;
			
			//toss the itemstacks in a vector so we can sort it
			for(k in location.itemstack_tsid_list){
				loc_itemstacks.push(getItemstackByTsid(location.itemstack_tsid_list[k]));
			}
			
			//sort by class
			SortTools.vectorSortOn(loc_itemstacks, ['class_tsid'], [Array.CASEINSENSITIVE]);
			
			//build the unique array
			const total:int = loc_itemstacks.length;
			var item_class:String;
			var last_class:String = '';
			var i:int;
			
			for(i = 0; i < total; i++){
				item_class = loc_itemstacks[i].class_tsid;
				if(item_class != last_class){
					unique_items.push(item_class);
					last_class = item_class;
				}
			}
			
			return unique_items;
		}
		
		public function isItemOnStreet(class_tsid:String):Boolean {
			//make sure we have the unique items built
			if(location && location.tsid != unique_item_street_tsid){
				getUniqueItemsOnStreet();
			}
			
			//loop through the array and see if we have a match
			const total:int = unique_items.length;
			var i:int;
			
			for(i; i < total; i++){
				if(unique_items[int(i)] == class_tsid) return true;
			}
			
			return false;
		}
		
		public function isSkillLearnable(skill_tsid:String):Boolean {
			//go through the skills, if we find a match, it means they don't know it yet
			const total:int = learnable_skills.length;
			var i:int;
			
			for(i; i < total; i++){
				if(learnable_skills[int(i)].class_tsid == skill_tsid) return true;
			}
			
			return false;
		}
		
		///////////////////////////////////////////
		
		public function set buff_updates(values:Array):void {
			_buff_updates = values;
			triggerCBPropDirect("buff_updates");
		}
		
		public function get buff_updates():Array {
			return _buff_updates;
		}
		
		public function set buff_dels(values:Array):void {
			_buff_dels = values;
			triggerCBPropDirect("buff_dels");
		}
		
		public function get buff_dels():Array {
			return _buff_dels;
		}
		
		public function set buff_adds(values:Array):void {
			_buff_adds = values;
			triggerCBPropDirect("buff_adds");
		}
		
		public function get buff_adds():Array {
			return _buff_adds;
		}
		
		///////////////////////////////////////////
		
		public function set loc_pc_updates(values:Array):void {
			_loc_pc_updates = values;
			triggerCBPropDirect("loc_pc_updates");
		}
		
		public function get loc_pc_updates():Array {
			return _loc_pc_updates;
		}
		
		public function set loc_pc_dels(values:Array):void {
			_loc_pc_dels = values;
			triggerCBPropDirect("loc_pc_dels");
		}
		
		public function get loc_pc_dels():Array {
			return _loc_pc_dels;
		}
		
		public function set loc_pc_adds(values:Array):void {
			_loc_pc_adds = values;
			triggerCBPropDirect("loc_pc_adds");
		}
		
		public function get loc_pc_adds():Array {
			return _loc_pc_adds;
		}
		
		///////////////////////////////////////////
		
		public function set loc_itemstack_updates(values:Array):void {
			_loc_itemstack_updates = values;
			triggerCBPropDirect("loc_itemstack_updates");
		}
		
		public function get loc_itemstack_updates():Array {
			return _loc_itemstack_updates;
		}
		
		public function set loc_itemstack_adds(values:Array):void {
			_loc_itemstack_adds = values;
			triggerCBPropDirect("loc_itemstack_adds");
		}
		
		public function get loc_itemstack_adds():Array {
			return _loc_itemstack_adds;
		}
		
		public function set loc_itemstack_dels(values:Array):void {
			_loc_itemstack_dels = values;
			triggerCBPropDirect("loc_itemstack_dels");
		}
		
		public function get loc_itemstack_dels():Array {
			return _loc_itemstack_dels;
		}
		
		///////////////////////////////////////////
		
		public function set pc_itemstack_updates(values:Array):void {
			_pc_itemstack_updates = values;
			triggerCBPropDirect("pc_itemstack_updates");
		}
		
		public function get pc_itemstack_updates():Array {
			return _pc_itemstack_updates;
		}
		
		public function set pc_itemstack_adds(values:Array):void {
			_pc_itemstack_adds = values;
			triggerCBPropDirect("pc_itemstack_adds");
		}
		
		public function get pc_itemstack_adds():Array {
			return _pc_itemstack_adds;
		}
		
		public function set pc_itemstack_dels(values:Array):void {
			_pc_itemstack_dels = values;
			triggerCBPropDirect("pc_itemstack_dels");
		}
		
		public function get pc_itemstack_dels():Array {
			return _pc_itemstack_dels;
		}
		
		///////////////////////////////////////////
		
		public function set pc(pc:PC):void {
			_pc = pc;
			NewxpLogger.setPC(pc);
			calcCanDecorateCultivate();
			triggerCBPropDirect("pc");
		}
		
		public function get pc():PC {
			return _pc;
		}
		
		///////////////////////////////////////////
		
		public function set party(party:PCParty):void {
			_party = party;
			triggerCBPropDirect("party");
		}
		
		public function get party():PCParty {
			return _party;
		}

		
		public function set party_member_updates(values:Array):void {
			_party_member_updates = values;
			triggerCBPropDirect("party_member_updates");
		}
		
		public function get party_member_updates():Array {
			return _party_member_updates;
		}
		
		public function set party_member_dels(values:Array):void {
			_party_member_dels = values;
			triggerCBPropDirect("party_member_dels");
		}
		
		public function get party_member_dels():Array {
			return _party_member_dels;
		}
		
		public function set party_member_adds(values:Array):void {
			_party_member_adds = values;
			triggerCBPropDirect("party_member_adds");
		}
		
		public function get party_member_adds():Array {
			return _party_member_adds;
		}
		
		///////////////////////////////////////////
		
		public function set quests(quests:Vector.<Quest>):void {
			_quests = quests;
			triggerCBPropDirect("quests");
		}
		
		public function get quests():Vector.<Quest> {
			return _quests;
		}
		
		public function get invoking():Object {
			return _invoking;
		}
		
		public function set invoking(ob:Object):void {
			
			CONFIG::locodeco {
				const invokingSets:ArrayCollection = LocoDecoGlobals.instance.invokingSets;
				invokingSets.removeAll();
				invokingSets.addItem({label: "None", data: null});
			}
			
			_invoking = ob;
			
			var blocker_item:Item;
			if (_invoking.blockers && _invoking.blockers.items) {
				for (var blocker:String in _invoking.blockers.items) {
					blocker_item = items[blocker];
					if (!blocker_item) continue;
					blocker_item.placement_w = _invoking.blockers.items[blocker].width;
				}
			}
			
			var proto_item:Item;
			var result_item:Item;
			var proto_item_ob:Object;
			var set_ob:Object;
			// mark item class defs appropriately
			for (var set:String in _invoking.sets) {
				set_ob = _invoking.sets[set];
				CONFIG::locodeco {
					invokingSets.addItem({label: set, data: set});
				}
				
				CONFIG::debugging {
					Console.priinfo(598, 'set:'+set);
				}
				
				for (var proto_item_class:String in set_ob) {
					
					proto_item = items[proto_item_class];
					proto_item_ob = set_ob[proto_item_class];
					if (!proto_item_ob) continue;
					
					if (proto_item) {
						proto_item.placement_w = proto_item_ob['width'];
						proto_item.is_proto = true;
						
						CONFIG::debugging {
							Console.priinfo(598, proto_item_class+' is_proto:'+proto_item.is_proto+' placement_w:'+proto_item.placement_w);
						}
						
						// end result items
						var result_itemsA:Array;
						 if (proto_item_ob['items'] && proto_item_ob['items'] is Array) {
							result_itemsA = proto_item_ob['items'];
						} else {
							result_itemsA = []; // just to be safe
						}
						
						for (var i:int=0;i<result_itemsA.length;i++) {
							result_item = items[result_itemsA[i]];
							if (!result_item) continue;
							if (!result_item.proto_item_tsidA) result_item.proto_item_tsidA = [];
							result_item.proto_item_tsidA.push(proto_item_class);
							
							CONFIG::debugging {
								if (result_item.placement_w) {
									Console.priinfo(598, 'multiple placement_w for '+result_item.tsid);
								}
							}
							
							result_item.placement_w = Math.max(result_item.placement_w, proto_item.placement_w);
							CONFIG::debugging {
								Console.priinfo(598, result_item.tsid+' is created from '+proto_item_class+' placement_w:'+result_item.placement_w);
							}
						}
						
					} else {
						CONFIG::debugging {
							Console.error('unknown class! '+proto_item_class);
						}
					}
				}
			}
		}
		
		/**
		"userdeco": {
			"sets": {
			 	"rug":
					["furniture_table"]
				"wall"
					["furniture_bed","furniture_cabinet","furniture_sofa","furniture_window"]
				"chair":
					["furniture_chair"]
			}
		}
		*/
		
		public function get userdeco():Object {
			return _userdeco;
		}
		
		public function set userdeco(ob:Object):void {
			_userdeco = ob;
			
			CONFIG::locodeco {
				const userdecoSets:ArrayCollection = LocoDecoGlobals.instance.userdecoSets;
				userdecoSets.removeAll();
				userdecoSets.addItem({label: "None", data: null});
			}
			
			var set_ob:Object;
			var A:Array;
			for (var set:String in _userdeco.sets) {
				set_ob = _userdeco.sets[set]; // this is a fucking hash/array thing with numeric string keys, so at bottom of this block we turn it into a true array
				CONFIG::locodeco {
					userdecoSets.addItem({label: set, data: set});
				}
				
				// turn this into a true array
				A = [];
				for (var userdeco_item_class_index:String in set_ob) {
					A.push(set_ob[userdeco_item_class_index])
				}
				_userdeco.sets[set] = A;
			}
			
			//_userdeco.sets['front'].push('furniture_armchair');
			//_userdeco.sets['chair'].push('furniture_table');
		}
		
		/*

		public function get proto_width():int {
			if (!_invoking) {
				CONFIG::debugging {
					Console.error('access of _invoking too early!');
				}
				return 0;
			}
			return _invoking.slot_width;
		}*/
	}
}