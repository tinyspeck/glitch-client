package com.tinyspeck.engine.data.location
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.map.MapData;
	import com.tinyspeck.engine.data.transit.Transit;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.avatar.PhysicsSetting;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	public class Location extends AbstractLocationEntity
	{
		public static const HOME_TYPE_INTERIOR:String = 'interior';
		
		public var l:int;
		public var r:int;
		public var t:int;
		public var b:int;
		public var ground_y:int;
		
		/** show the map, fog it up */
		public var fog_map:Boolean;				// can be changed permanently in LOCODECO
		
		/* 
		
		Many locations props (most with a "no_*" prefix) govern display of ui elements, in conjuction with 
		props (with "*_override" suffuxes) that can be flipped with ui_visible messages. We store the
		"*_override" props as ints, with -1 indicating it has not been set.
		
		This is the desired outcome map
		---------------------------------------
		state		|  no_map	no_map_overide	show_map
		
		loc			| true		-1				false
		disables	| true		0				true
		map			| true		1				false		
		
		loc			| false		-1				true
		allows		| false		0				true
		map			| false		1				false
		
		
		Below is the signature of the props and functions for such a prop set:
		
		public var no_XXX_overide:int = -1;
		public var no_XXX:Boolean;
		public function get show_XXX():Boolean {
			return (no_XXX) ? no_XXX_overide == 0 : no_XXX_overide != 1;
		}
		
		*/
		
		/** entirely hide map */
		public var no_map_overide:int = -1;
		public var no_map:Boolean;
		public function get show_map():Boolean {
			return (no_map) ? no_map_overide == 0 : no_map_overide != 1;
		}
		
		/** prevent user from changing zoom */
		public var no_zoom_overide:int = -1;
		public var no_zoom:Boolean;
		public function get allow_zoom():Boolean {
			return (no_zoom) ? no_zoom_overide == 0 : no_zoom_overide != 1;
		}
		
		/** disable hub map dialog */
		public var no_hubmap_overide:int = -1;
		public var no_hubmap:Boolean;
		public function get show_hubmap():Boolean {
			return (no_hubmap) ? no_hubmap_overide == 0 : no_hubmap_overide != 1;
		}
		
		/** disable world/transit map */
		public var no_world_map_overide:int = -1;
		public var no_world_map:Boolean;
		public function get show_worldmap():Boolean {
			return (no_world_map) ? no_world_map_overide == 0 : no_world_map_overide != 1;
		}
		
		public var no_familiar_overide:int = -1;
		public var no_familiar:Boolean;
		public function get show_familiar():Boolean {
			return (no_familiar) ? no_familiar_overide == 0 : no_familiar_overide != 1;
		}
		
		public var no_stats_overide:int = -1;
		public var no_stats:Boolean;
		public function get show_stats():Boolean {
			return (no_stats) ? no_stats_overide == 0 : no_stats_overide != 1;
		}
		
		public var no_avatar_overide:int = -1;
		public var no_avatar:Boolean;
		public function get show_avatar():Boolean {
			return (no_avatar) ? no_avatar_overide == 0 : no_avatar_overide != 1;
		}
		
		public var no_status_bubbles_overide:int = -1;
		public var no_status_bubbles:Boolean;
		public function get show_status_bubbles():Boolean {
			return (no_status_bubbles) ? no_status_bubbles_overide == 0 : no_status_bubbles_overide != 1;
		}
		
		public var no_pack_overide:int = -1;
		public var no_pack:Boolean;
		public function get show_pack():Boolean {
			return (no_pack) ? no_pack_overide == 0 : no_pack_overide != 1;
		}
		
		// -----------------------------------------------------------
		// THESE ARE NOT TO BE SAVED TO THE LOCATION IN AMF()
		
		public var no_furniture_bag:Boolean = false;
		public var no_swatches_button:Boolean = false;
		public var no_expand_buttons:Boolean = false;
		public var no_mood:Boolean = false;
		public var no_energy:Boolean = false;
		public var no_imagination:Boolean = false;
		public var no_decorate_button:Boolean = false;
		public var no_cultivate_button:Boolean = false;
		public var no_current_location:Boolean = false;
		public var no_currants:Boolean = false;
		public var no_inventory_search:Boolean = false;
		public var no_skill_learning:Boolean = false;
		public var no_home_street_visiting:Boolean = false;
		public var no_account_required_features:Boolean = false;
		
		public var is_decoratable:Boolean;
		
		// -----------------------------------------------------------
		
		
		public var no_camera_mode:Boolean;
		public var no_rook:Boolean;
		public var no_tips:Boolean; // tip visibility uses a lockers system to hide/show, so this value is never changed
		public var disallow_animals:Boolean;
		public var no_pc_interactions:Boolean;
		public var no_up_arrow_for_menus:Boolean;
		public var no_starting_quests:Boolean;
		public var no_pathing_out:Boolean;
		public var no_ambient_music:Boolean;
		public var no_physics_adjustments:Boolean;
		public var no_upgrade_physics_adjustments:Boolean;
		
		public var is_template:Boolean;
		public var is_instance:Boolean;
		public var gradient:Object;
		public var sources:Object;
		public var physics_setting:PhysicsSetting;
		public var label:String;
		public var loading_label:String;
		public var img_file_versioned:String;
		public var rookable_type:int;
		public var is_pol:Boolean; //if we are in POL land this is true
		public var is_home:Boolean;
		public var home_type:String;
		public var pol_img_150:String;
		public var music_file:String;
		public var ava_on_top:Boolean;
		
		public var layers:Vector.<Layer>;
		
		// should be client, but fuck alot of refs to change
		public var pc_tsid_list:Dictionary = new Dictionary();
		public var itemstack_tsid_list:Dictionary = new Dictionary(); // all in location, even in containers
		
		public var mapInfo:MapInfo;
		public var hub_id:String;
		public var mg:MiddleGroundLayer;
		client var w:int;
		client var h:int;
		client var swf_files:Array;
		client var swf_files_versioned:Array;
		
		private var _swf_file:String;
		private var _swf_file_versioned:String;
		
		public function Location(hashName:String) {
			super(hashName);
			this.tsid = hashName;
		}
		
		public function get instance_template_tsid():String {
			if (mapInfo && mapInfo.showStreet) return mapInfo.showStreet;
			return '';
		}
		
		public function get newxp_log_string():String {
			var str:String = tsid+' "'+label+'"';
			if (instance_template_tsid) str+= ' ('+instance_template_tsid+')';
			return str;
		}
		
		override public function AMF():Object {
			var start:int = getTimer();
			var i:int;
			var ob:Object = super.AMF();
			
			if (tsid) ob.tsid = tsid; // this is a prop of AbstractLocationEntity, but we do not want all AbstractLocationEntitys to have this
			
			ob.l = l;
			ob.r = r;
			ob.t = t;
			ob.b = b;
			ob.ground_y = ground_y;
			
			// set by locodeco
			if (fog_map) ob.fog_map = fog_map;
			if (no_map) ob.no_map = no_map;
			
			// set outside locodeco
			if (no_zoom) ob.no_zoom = no_zoom;
			if (no_hubmap) ob.no_hubmap = no_hubmap;
			if (no_familiar) ob.no_familiar = no_familiar;
			if (no_stats) ob.no_stats = no_stats;
			if (no_avatar) ob.no_avatar = no_avatar;
			if (no_status_bubbles) ob.no_status_bubbles = no_status_bubbles;
			if (no_pack) ob.no_pack = no_pack;
			if (no_rook) ob.no_rook = no_rook;
			if (no_camera_mode) ob.no_camera_mode = no_camera_mode;
			if (no_tips) ob.no_tips = no_tips;
			if (disallow_animals) ob.disallow_animals = disallow_animals;
			if (no_pc_interactions) ob.no_pc_interactions = no_pc_interactions;
			if (no_up_arrow_for_menus) ob.no_up_arrow_for_menus = no_up_arrow_for_menus;
			if (no_starting_quests) ob.no_starting_quests = no_starting_quests;
			if (no_pathing_out) ob.no_pathing_out = no_pathing_out;
			if (no_ambient_music) ob.no_ambient_music = no_ambient_music;
			if (no_physics_adjustments) ob.no_physics_adjustments = no_physics_adjustments;
			if (no_upgrade_physics_adjustments) ob.no_upgrade_physics_adjustments = no_upgrade_physics_adjustments;
			if (no_world_map) ob.no_world_map = no_world_map;
			
			if (gradient) ob.gradient = gradient;
			if (sources) ob.sources = sources;
			if (is_instance) ob.is_instance = is_instance;
			ob.label = label;
			ob.loading_label = loading_label;
			ob.music_file = music_file;
			ob.swf_file = swf_file;
			ob.swf_file_versioned = swf_file_versioned;
			ob.img_file_versioned = img_file_versioned;
			
			if (layers) { 
				ob.layers = {};
				for (i=layers.length-1; i>-1; i--) {
					ob.layers[layers[int(i)].hashName] = layers[int(i)].AMF();
				}
			}
			
			ob.rookable_type = rookable_type;
			CONFIG::debugging {
				Console.trackValue('LOCATION AMF ms', (getTimer()-start));
			}
			
			return ob;
		}
		
		public function getDecoById(decoID:String, layerID:String=''):Deco {
			var layer:Layer;
			if (layerID) {
				layer = getLayerById(layerID);
				return layer ? layer.getDecoByTsid(decoID) : null;
			} else {
				var deco:Deco;
				for each (layer in layers) {
					deco = layer.getDecoByTsid(decoID);
					if (deco) return deco;
				}
			}
			return null;
		}
		
		public function getDecoAndLayerByDecoId(decoID:String):Object {
			var layer:Layer;
			for each (layer in layers) {
				var deco:Deco = layer.getDecoByTsid(decoID);
				if (deco) return {
					layer: layer,
					deco: deco
				}
			}
			return null;
		}
		
		// returns all the decos in the location used for rendering home walls
		// TODO: for now this brute force calcs this every time. Maybe for performance we cache it later
		public function getWallPaperDecos():Vector.<Deco> {
			var V:Vector.<Deco> = new Vector.<Deco>();
			var deco:Deco;
			for each (deco in mg.decos) {
				if (deco.wp_key) {
					V.push(deco);
				}
			}
			
			return V;
		}
		
		// returns all the decos in the location used for rendering home ceilings
		// TODO: for now this brute force calcs this every time. Maybe for performance we cache it later
		public function getCeilingDecos():Vector.<Deco> {
			var V:Vector.<Deco> = new Vector.<Deco>();
			var deco:Deco;
			for each (deco in mg.decos) {
				if (deco.ceiling_key) {
					V.push(deco);
				}
			}
			
			return V;
		}
		
		
		// returns all the decos in the location used for rendering home floors
		// TODO: for now this brute force calcs this every time. Maybe for performance we cache it later
		public function getFloorDecos():Vector.<Deco> {
			var V:Vector.<Deco> = new Vector.<Deco>();
			var deco:Deco;
			for each (deco in mg.decos) {
				if (deco.floor_key) {
					V.push(deco);
				}
			}
			
			return V;
		}
		
		public function getDecoAndLayerByDecoName(deco_name:String):Object {
			var layer:Layer;
			for each (layer in layers) {
				var deco:Deco = layer.getDecoByName(deco_name);
				if (deco) return {
					layer: layer,
					deco: deco
				}
			}
			return null;
		}
		
		public function getLayerById(id:String):Layer {
			for each (var layer:Layer in layers) {
				if (id == layer.tsid) return layer;
			}
			return null;
		}
		
		public function getItemstackViewsOnThisFurniture(furn_view:LocationItemstackView):Vector.<LocationItemstackView> {
			var plV:Vector.<PlatformLine> = mg.getPlatformLinesBySource(furn_view.tsid);
			var lis_viewsV:Vector.<LocationItemstackView> = getItemstackViewsOnThesePlatformLines(plV, true);
			if (!lis_viewsV || !lis_viewsV.length) return null;
			
			var remove:Boolean;
			for each (var lis_view:LocationItemstackView in lis_viewsV) {
				remove = false;
				
				if (lis_view == furn_view) {
					remove = true;
				}
				
				var itemstack:Itemstack = lis_view.itemstack;
				if (itemstack.on_furniture && itemstack.on_furniture != furn_view.tsid) {
					remove = true;
				}
				
				if (remove) {
					lis_viewsV.splice(lis_viewsV.indexOf(lis_view), 1);
				} else {
					itemstack.on_furniture = furn_view.tsid;
				}
			}
			
			return lis_viewsV;
		}
		
		public function getItemstackViewsOnThisCPLS(cpls:ContiguousPlatformLineSet):Vector.<LocationItemstackView> {
			return getItemstackViewsOnThesePlatformLines(cpls.platform_lines);
		}
		
		public function getItemstackViewsOnThisPlatformLine(pl:PlatformLine):Vector.<LocationItemstackView> {
			var plV:Vector.<PlatformLine> = new Vector.<PlatformLine>();
			plV.push(pl);
			return getItemstackViewsOnThesePlatformLines(plV);
		}
		
		private static var ITEM_TO_PLAT_TOLERANCE:int = 10;
		public function getItemstackViewsOnThesePlatformLines(plV:Vector.<PlatformLine>, not_furniture:Boolean=false):Vector.<LocationItemstackView> {
			// iterate over all platforms with source==tsid and get the stacks on those platforms
			
			var lis_viewsV:Vector.<LocationItemstackView>; // we'll return this
			var pl_lis_viewsV:Vector.<LocationItemstackView>; // this will hold the results we get for each platform
			var lis_view:LocationItemstackView;
			
			if (!plV) return null;
			
			for each (var pl:PlatformLine in plV) {
				pl_lis_viewsV = pl.getClosestItemstackViews(ITEM_TO_PLAT_TOLERANCE, not_furniture);
				if (pl_lis_viewsV && pl_lis_viewsV.length) {
					if (!lis_viewsV) {
						lis_viewsV = new Vector.<LocationItemstackView>();
					}
					for each (lis_view in pl_lis_viewsV) { 
						if (lis_viewsV.indexOf(lis_view) != -1) continue;
						lis_viewsV.push(lis_view);
					}
				}
			}
			
			return lis_viewsV;
		}
		
		/* only return plats that are placment plats (for furniture) or that are part of furniture (for items that go on furniture) */
		public function getPlatformForStack(itemstack:Itemstack, use_view:Boolean, remove_from_furn:Boolean=true):PlatformLine {
			if (!itemstack) return null;
			
			var plats:Vector.<PlatformLine>;
			var lis_view:LocationItemstackView;
			var x_to_test:int;
			var y_to_test:int;
			
			if (use_view) {
				lis_view = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(itemstack.tsid);
				if (!lis_view) {
					//Console.error(itemstack.tsid+' NO VIEW')
					return null;
				}
				x_to_test = lis_view.x;
				y_to_test = lis_view.y;
			} else {
				x_to_test = itemstack.x;
				y_to_test = itemstack.y;
			}
			//Console.info(itemstack.tsid+' '+x_to_test+' '+y_to_test+' --------'+itemstack.x+' '+itemstack.y);
			
			// if it thinks it is on a stack, test and see if it really is, and return that pl
			if (itemstack.on_furniture && !itemstack.item.is_furniture) {
				var plats2:Vector.<PlatformLine> = mg.getPlatformLinesBySource(itemstack.on_furniture);
				for each (var furn_pl:PlatformLine in plats2) {
					//Console.warn(furn_pl.start.y +' '+ y_to_test)
					
					// OLD COMMENT NO LONGER SEEMS TO BE TRUE: if you actually test if it is within the pl, it fails!!!! I need to solve why, I guess.
					if (furn_pl.start.x <= x_to_test && furn_pl.end.x >= x_to_test && Math.abs(furn_pl.yIntersection(x_to_test) - y_to_test) <= ITEM_TO_PLAT_TOLERANCE) {
						return furn_pl;
					} else {
						if (remove_from_furn) itemstack.on_furniture = null;
					}
					
				}
			}
			
			if (itemstack.item.is_furniture) {
				plats = PlatformLine.getPlacementPlatsForItemClass(mg.platform_lines, itemstack.class_tsid);
			} else {
				plats = PlatformLine.getFurnPlatsPlatsSolidFromTopForItems(mg.platform_lines);
			}
			
			const pl:PlatformLine = PlatformLine.getClosestUnder(plats, x_to_test, y_to_test, ITEM_TO_PLAT_TOLERANCE);
			
			if (pl) {
				return pl;
			}
			
			if (itemstack.item.is_furniture) {
				// TODO: account here for the possibility that the furniture is in a furniture plane (not directly on a plat) before returning null here
			}
			
			return null;
		}
		
		public function hasHowManyItems(item_class:String, at_root:Boolean=true):int {
			var c:int = 0;
			var stack:Itemstack;
			for (var k:String in itemstack_tsid_list) {
				stack = TSModelLocator.instance.worldModel.getItemstackByTsid(k);
				if (!k) continue;
				if (stack.class_tsid != item_class) continue;
				if (at_root && stack.path_tsid != stack.tsid) continue;
				c+= stack.count;
			}
			return c;
		}
		
		public static function fromAnonymousLocationStub(dest:Object):Location {
			// create a stub location
			var model:TSModelLocator = TSModelLocator.instance;
			var loc:Location = model.worldModel.getLocationByTsid(dest.street_tsid);
			if (!loc) {
				loc = model.worldModel.locations[dest.street_tsid] = new Location(dest.street_tsid);
				loc.label = dest.label;
				loc.swf_file = dest.swf_file;
				loc.swf_file_versioned = dest.swf_file_versioned;
				loc.img_file_versioned = dest.img_file_versioned;
				loc.hub_id = dest.hub_id;
			}
			
			if('pol_img_150' in dest){
				loc.pol_img_150 = dest.pol_img_150;
			}
			
			if('image_full' in dest){
				//add the image to the mapInfo
				if(!loc.mapInfo) loc.mapInfo = new MapInfo();
				loc.mapInfo.image_full = MapInfoImage.fromAnonymous(dest.image_full);
			}
			
			return loc;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Location {
			const location:Location = new Location(hashName);
			return updateFromAnonymous(object, location);
		}
		
		public static function updateFromAnonymous(object:Object, location:Location):Location {
			var layers:Vector.<Layer>;
			var layer:Layer;
			for(var i:* in object){
				if (i in location) {
					if (i == "layers"){
						// parse layers
						layers = Layer.parseMultiple(object[i]);
						location.layers = layers;
						
						// process layers
						for (var k:int=0;k<layers.length;) {
							layer = layers[k];
							
							// maintain a reference to the middleground
							if (layer.tsid == 'middleground') {
								location.mg = layers[int(k)] as MiddleGroundLayer;
							}
							
							// remove hidden layers from model
							// unless in god/locodeco and unless it's the mg
							// (god/locodeco will just make them not visible)
							if (!CONFIG::god && layer.is_hidden && (layer != location.mg)) {
								layers.splice(k, 1);
							} else {
								k++;
							}
						}
					} else if (i == "mapInfo"){
						location.mapInfo = MapInfo.fromAnonymous(object[i]);
						if (location.mapInfo.hub_id) location.hub_id = location.mapInfo.hub_id;
					} else {
						location[i] = object[i];
					}
				} else if (i == "filters"){
					// ignore
				} else if (i == "mapData"){
					//if we have an "all" hash, parse that, then let it go to the bottom
					if(object[i] && object[i].all){
						Hub.updateFromMapDataAll(object[i]);
					}
					
					//if we have transit data, parse it
					if(object[i] && object[i].transit){
						Transit.updateFromMapDataTransit(object[i]);
					}
				} else { // legacy shit
					resolveError(location,object,i);
				}
			}

			CONFIG::locodeco {
				// we only store these when they are true
				// if they didn't come set to true, explicitely set them false
				// (since this is an 'updateFromAnonymous', it's possible that
				//  these properties should be set to false, but by their lack of
				//  presence in the object due to AMF(), they would not be set)
				if (!(object.fog_map)) location.fog_map = false;
				if (!(object.no_map)) location.no_map = false;
			}
			
			// calulate width/height now, since we're going to need them a lot
			location.client::w = location.r-location.l;
			location.client::h = location.b-location.t;
			
			if (location.hub_id) {
				var hub:Hub = TSModelLocator.instance.worldModel.hubs[location.hub_id];
				if (!hub) {
					hub = TSModelLocator.instance.worldModel.hubs[location.hub_id] = new Hub(location.hub_id);
					hub.label = location.mapInfo.hub_name;
				}
				if (object.mapData) {
					if(!hub.map_data){
						hub.map_data = MapData.fromAnonymous(object.mapData);
					}
					else {
						hub.map_data = MapData.updateFromAnonymous(object.mapData, hub.map_data);
					}
				}
			}
			/*
			if (location.tsid == 'LPF2PFISOE235MC') {
				location.is_decoratable = true;
			}
			*/
			return location;
		}
		
		public function hasGradient():Boolean {
			return (gradient && gradient.hasOwnProperty('top') && gradient.hasOwnProperty('bottom'));
		}
		
		public function getSignpostThatLinksToLocTsid(loc_tsid:String):SignPost {
			return mg.getSignpostThatLinksToLocTsid(loc_tsid);
		}
		
		public function getDoorThatLinksToLocTsid(loc_tsid:String):Door {
			return mg.getDoorThatLinksToLocTsid(loc_tsid);
		}
		
		public function get isFullyLoaded():Boolean {
			return (DecoAssetManager.isLocationReady() && !TSModelLocator.instance.moveModel.moving);
		}
		
		/** Might return multiple URLs in a comma-delimited list */
		public function get swf_file_versioned():String {
			return _swf_file_versioned;
		}
		
		public function set swf_file_versioned(value:String):void {
			_swf_file_versioned = value;
			client::swf_files_versioned = (value ? value.split(',') : []);
		}
		
		/** Might return multiple SWF names in a comma-delimited list */
		public function get swf_file():String {
			return _swf_file;
		}
		
		public function set swf_file(value:String):void {
			_swf_file = value;
			client::swf_files = (value ? value.split(',') : []);
		}
	}
}