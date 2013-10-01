package com.tinyspeck.engine.view.gameoverlay.maps
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.map.MapData;
	import com.tinyspeck.engine.data.map.Street;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.transit.Transit;
	import com.tinyspeck.engine.data.transit.TransitLine;
	import com.tinyspeck.engine.data.transit.TransitStatus;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.net.NetOutgoingMapGetVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TransitManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.ui.Toast;
	import com.tinyspeck.engine.view.ui.map.LocationSearchMap;
	import com.tinyspeck.engine.view.ui.map.MapChatArea;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	public class HubMapDialog extends Dialog implements IMoveListener {
		
		/* singleton boilerplate */
		public static const instance:HubMapDialog = new HubMapDialog();
		
		public static const MAP_ACTUAL_W:int = 760; // this is the w of the loaded coordinate space
		public static const MAP_ACTUAL_H:int = 460; // this is the h of the loaded coordinate space
		public static const MAP_W:int = 760;
		public static const MAP_H:int = 460;
		
		private static const RESULTS_WIDTH:uint = 235;
		private static const RESULTS_HEIGHT:uint = 150;
		private static const STAR_COLOR:uint = 0xc50202;
		private static const STREET_ROTATION_BUFFER:uint = 5; //how many degrees from 90 does this mean the street is vertical
		private static const TRANSIT_PADD:uint = 5; //px between transit buttons
		
		public var current_street:Street;
		
		private var header_h:int = 60;
		private var next_transit_bt_x:int;
		
		private var map_hubsD:Dictionary = new Dictionary();
		private var map_transitsD:Dictionary = new Dictionary();
		private var loc_name_tf:TextField = new TextField();
		private var extra_tf:TextField = new TextField();
		private var search_results_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var current_hub_id:String;
		private var current_transit_tsid:String;
		private var current_location_id:String;
		private var hub_click_hub_id:String;
		private var hub_click_location_id:String;
		private var transition_direction:String;
		private var world_map_url:String;
		
		private var you_view_holder:Sprite = new Sprite();
		private var you_view_world_holder:Sprite = new Sprite();
		private var transit_you_view_holder:Sprite = new Sprite();
		private var all_maps_container:Sprite = new Sprite();
		private var all_maps_container_mask:Sprite = new Sprite();
		private var search_results_holder:Sprite = new Sprite();
		private var load_blocker:Sprite = new Sprite();
		
		private var transit_bt:Button;
		private var world_map_in_bt:Button;
		private var world_map_out_bt:Button;
		private var recenter_bt:Button;
		private var displayed_map_hub:MapHub;
		private var displayed_map_transit:MapTransit;
		private var location_search:LocationSearchMap;
		private var search_scroller:TSScroller;
		private var toast:Toast;
		
		private var region_rect:Rectangle;
		
		private var animate_transit_map:Boolean;
		private var hub_click_flash_loc:Boolean;
		private var showing_transit_map:Boolean;
		private var cancel_transit_display:Boolean;
		private var showing_world_map:Boolean;
		private var is_built:Boolean;
		private var is_map_loading:Boolean;
		private var _open_map_chat_when_closed:Boolean;
		private var start_with_world_map:Boolean;
		
		private var world_map_mc:MovieClip;
		private var world_map_clicked_region:DisplayObject;
		
		public function HubMapDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = MAP_W+(_border_w*2);
			_h = MAP_H+header_h+(_border_w*2);
			
			_draggable = true;
			close_on_editing = false;
			close_on_move = false;
			
			_construct();
		}
		
		override protected function _construct() : void {
			super._construct();
			
			all_maps_container_mask.y = _border_w;
			all_maps_container_mask.x = _border_w;
			
			//draw the mask, and when using a complex rect the corner_rad var needs to be divided by 2
			var g:Graphics = all_maps_container_mask.graphics;
			g.beginFill(0, 1);
			g.drawRoundRectComplex(0, header_h, _w-(_border_w*2), _h-header_h-(_border_w*2), 0, 0, corner_rad/2, corner_rad/2);
			addChild(all_maps_container_mask);
			
			all_maps_container.y = header_h+_border_w;
			all_maps_container.x = _border_w;
			all_maps_container.mask = all_maps_container_mask;
			addChild(all_maps_container);
			
			// loc_name_tf
			TFUtil.prepTF(loc_name_tf);
			loc_name_tf.width = _w;
			loc_name_tf.mouseEnabled = false;
			addChild(loc_name_tf);
			
			// extra_tf
			TFUtil.prepTF(extra_tf, false);
			CONFIG::god {
				extra_tf.htmlText = '<a href="event:geo" class="hub_map_admin_link">ADMIN: Edit Map</a>';
				addChild(extra_tf);
			}
			/*CONFIG::debugging {
				Console.warn(CONFIG::god+' ---- '+extra_tf.htmlText)
			}*/
			extra_tf.x = _base_padd;
			extra_tf.y = header_h-extra_tf.height+5;
			
			extra_tf.addEventListener(TextEvent.LINK, tfLinkHandler);
			
			recenter_bt = new Button({
				name: 'recenter',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				graphic: new AssetManager.instance.assets.recenter_link(),
				graphic_disabled: new AssetManager.instance.assets.recenter_disabled(),
				graphic_hover: new AssetManager.instance.assets.recenter_hover(),
				graphic_padd_w: 11,
				x: _base_padd+9,
				y: _base_padd+10,
				w: 36,
				h: 27,
				tip: {
					txt: 'Go to my location',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER	
				}
			});
			recenter_bt.addEventListener(TSEvent.CHANGED, onRecenterClick, false, 0, true);
			
			addChild(recenter_bt);
			
			//make sure the next button is in the right place
			next_transit_bt_x = recenter_bt.x + recenter_bt.width + TRANSIT_PADD;
			
			//search field
			location_search = new LocationSearchMap();
			location_search.x = int(_w - location_search.width - 53);
			location_search.y = int((header_h+_border_w*2)/2 - location_search.height/2);
			location_search.holder_offset = location_search.height + 17;
			addChild(location_search);
			
			//setup the scroller
			search_scroller = new TSScroller({
				name: 'search_scroller',
				w:RESULTS_WIDTH - 10,
				h:RESULTS_HEIGHT - 10,
				bar_wh: 12,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 36,
				scrolltrack_always: false,
				maintain_scrolling_at_max_y: true,
				use_auto_scroll: false,
				show_arrows: true
			});
			search_scroller.y = 2;
			search_results_holder.addChild(search_scroller);
			
			//throw the TF in the scroller
			TFUtil.prepTF(search_results_tf);
			search_results_tf.embedFonts = false;
			search_results_tf.x = 10;
			search_results_tf.width = RESULTS_WIDTH - 24;
			search_results_tf.addEventListener(TextEvent.LINK, closeResults, false, 0, true);
			search_scroller.body.addChild(search_results_tf);
			
			//make sure the results are available
			g = search_results_holder.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(0, 0, RESULTS_WIDTH, RESULTS_HEIGHT, 0, 0, 8, 8);
			search_results_holder.x = int(_w - search_results_holder.width - _border_w - 2);
			search_results_holder.y = int(-RESULTS_HEIGHT-10);
			search_results_holder.filters = StaticFilters.black2px90Degrees_DropShadowA;
			
			//load blocker, to show when transit maps are loading and you don't want to see what's behind it
			load_blocker.mouseEnabled = false;
			g = load_blocker.graphics;
			g.beginFill(0xffffff);
			g.drawRect(0, 0, MAP_W, MAP_H);
			const spinner:DisplayObject = new AssetManager.instance.assets.spinner();
			spinner.x = int(MAP_W/2 - spinner.width/2);
			spinner.y = int(MAP_H/2 - spinner.height/2);
			load_blocker.addChild(spinner);
		}
		
		private function buildBase():void {
			TSFrontController.instance.registerMoveListener(this);
			//hub you are here image
			buildYouView(you_view_holder);
			
			//transit you are here image
			var transit_star:DisplayObject = new AssetManager.instance.assets.subway_map_star();
			if(transit_star){
				SpriteUtil.setRegistrationPoint(transit_star);
				transit_you_view_holder.addChild(transit_star);
			}
			
			is_built = true;
		}
		
		public function loadWorldMapIfNeeded(swf_url:String):void {
			if (!swf_url || swf_url == world_map_url) {
				//nothing has changed, but make sure the regions are properly setup
				worldMapSetRegions();
				return;
			}
			
			world_map_url = swf_url;
			
			if (world_map_mc && world_map_mc.parent) world_map_mc.parent.removeChild(world_map_mc);
			world_map_mc = null;
			
			var sl:SmartLoader = new SmartLoader(world_map_url);
			sl.complete_sig.add(doneLoadingWorldMap);
			sl.load(new URLRequest(world_map_url));
		}
		
		private function doneLoadingWorldMap(sl:SmartLoader):void {
			world_map_mc = sl.content as MovieClip;
			if (!world_map_mc) return;
			
			//world_map_mc.setConsole(Console);
			world_map_mc.addClickCallback(worldMapClickHandler);
			world_map_mc.addHoverCallback(worldMapHoverHandler);
			world_map_mc.visible = false;
			worldMapSetRegions();
			
			all_maps_container.addChild(world_map_mc);
		}
		
		private function worldMapSetRegions():void {
			if (!world_map_mc) {
				//try again real fast
				StageBeacon.waitForNextFrame(worldMapSetRegions);
				return;
			}
						
			try {
				//tell the world map which hubs are allowed to be clicked
				const allowed_hub_ids:Array = [];
				var k:String;
				var location:Location;
				
				for(k in model.worldModel.search_locations){
					//if this ISN'T a location, then it's a hub ID (could also check if it's a number, but that's not future proof)
					location = model.worldModel.getLocationByTsid(k);
					if(!location){
						allowed_hub_ids.push(k);
					}
				}
				
				world_map_mc.buildRegions(allowed_hub_ids);
				
				//build a you star for the world map
				buildYouView(you_view_world_holder);
				you_view_world_holder.mouseEnabled = false;
				
				//let's see if our current location has a region
				showYouOnWorld();
			}
			catch(e:Error){
				CONFIG::debugging {
					Console.warn('World Map shit the bed, probably the old SWF', e.message);
				}
			}
		}
		
		private function worldMapClickHandler(target:DisplayObject):void {
			if (world_map_clicked_region) return;
			if (!target) return;
			
			var region_str:String = target.name;
			/*
			CONFIG::debugging {
				Console.info('region_str:'+region_str);
			}*/
			
			if (!region_str) return;
			
			var region_id:String = region_str.replace('region_', '');

			/*CONFIG::debugging {
				Console.info('region_id:'+region_id);
			}*/
			
			world_map_clicked_region = target;
			goToHubFromClick(region_id);
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function worldMapHoverHandler(target:MovieClip, is_hover:Boolean):void {
			if (!target) return;
			
			//if the star is on this region, we need to toggle it's visibility
			if(target.contains(you_view_world_holder)){
				//tween the time on hover since the over state doesn't animate right away
				TSTweener.removeTweens(you_view_world_holder);
				TSTweener.addTween(you_view_world_holder, {alpha:is_hover ? 0 : 1, time:is_hover ? .2 : 0, transition:'linear'});
			}
		}
		
		private function showYouOnWorld():void {
			if(!world_map_mc) return;
			
			//reset
			you_view_world_holder.alpha = 1;
			
			const region_mc:MovieClip = world_map_mc.getRegion(model.worldModel.location.hub_id);
			if(region_mc){
				//throw the star on there
				region_mc.gotoAndStop(1);
				region_rect = region_mc.getBounds(region_mc);
				you_view_world_holder.x = int(region_rect.x + region_rect.width/2);
				you_view_world_holder.y = int(region_rect.y + region_rect.height/2);
				region_mc.addChild(you_view_world_holder);
			}
			else if(you_view_world_holder.parent){
				//not on a region anymore, toss'r
				you_view_world_holder.parent.removeChild(you_view_world_holder);
			}
		}
		
		/*
		override public function init():void {
			super.init();
			TSFrontController.instance.registerMoveLister(this);
			//hub you are here image
			buildYouView(you_view_holder);
			
			//transit you are here image
			var transit_star:DisplayObject = new AssetManager.instance.assets.subway_map_star();
			if(transit_star){
				SpriteUtil.setRegistrationPoint(transit_star);
				transit_you_view_holder.addChild(transit_star);
			}
		}
		*/
		
		public function buildYouView(sp:Sprite):Sprite {
			if(!sp) sp = new Sprite();
			
			var g:Graphics = sp.graphics;
			g.beginFill(STAR_COLOR);
			g.lineStyle(0,0,0);
			DrawUtil.drawStar(10, g);
			g.endFill();
			
			sp.filters = StaticFilters.white3px_GlowA;
			
			return sp;
		}
		
		public function onLocationPathStarted():void {
			if (displayed_map_hub) displayed_map_hub.updateLocPath();
		}
		
		public function onLocationPathEnded():void {
			if (displayed_map_hub) displayed_map_hub.updateLocPath();
		}
		
		// IMoveListener funcs
		// -----------------------------------------------------------------
		
		public function moveLocationHasChanged():void {
		
		}
		
		public function moveLocationAssetsAreReady():void {
		
		}
		
		public function moveMoveStarted():void {
		
		}
		
		public function moveMoveEnded():void {			
			const hub:Hub = model.worldModel.getHubByTsid(model.worldModel.location.hub_id);
			if(hub && hub.map_data){
				loadWorldMapIfNeeded(hub.map_data.world_map);
			}
			else {
				//this is a hub map and we don't have a hub with data?! Bail out!!
				if(parent) end(false);
				return;
			}
			
			//update the hub map
			if (parent) {
				if (current_location_id != model.worldModel.location.tsid) {
					updateMapHub(model.worldModel.location.hub_id);
				}
				
				//place our star where it needs to go
				showYouOnWorld();
			}
		}
		
		// -----------------------------------------------------------------
		// END IMoveListener funcs
		
		public function goToHubFromClick(hub_id:String, loc_tsid:String='', transition_direction:String='', flash_loc:Boolean=false):void {
			if (!model.worldModel.location.show_hubmap) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				TSFrontController.instance.growl('The map is not available in this location');
				return;
			}
			
			//because mart has a link to a place in hell and you must be dead to see it
			//I'm putting a special case here
			if(hub_id == Hub.HELL_TSID){
				const pc:PC = model.worldModel.pc;
				if(!pc.is_dead){
					var msg_txt:String = 'You can only see the map of Naraka when you\'re dead.';
					model.activityModel.activity_message = Activity.createFromCurrentPlayer(msg_txt);
					TSFrontController.instance.growl(msg_txt);
					if(transitioning) end(true);
					SoundMaster.instance.playSound('CLICK_FAILURE');
					return;
				}
			}
			
			//if we are already loading a map (or animating one out of the way), bail out
			if((is_map_loading || hub_click_hub_id == hub_id) && !world_map_clicked_region){
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			this.transition_direction = transition_direction;
			hub_click_hub_id = hub_id;
			hub_click_location_id = loc_tsid;
			hub_click_flash_loc = flash_loc;
			
			//close the search thing
			closeResults();
			
			//disable the go to my location button
			recenter_bt.disabled = true;
			
			//make sure we don't see the transit map
			cancel_transit_display = true;
			hideTransitMap();
			
			if (!world_map_clicked_region) {
				simpleHideWorldMap();
				all_maps_container.addChildAt(load_blocker, 0);
			}
			
			is_map_loading = true;
			TSFrontController.instance.genericSend(new NetOutgoingMapGetVO(hub_id, loc_tsid), onMapData, onMapData);
		}
		
		public function changeSignpostVisibility(signpost:SignPost):void {
			var map_hub:MapHub = map_hubsD[current_hub_id];
			if (map_hub) map_hub.changeSignpostVisibility(signpost);
		}
		
		private function tfLinkHandler(e:TextEvent):void {
			var which:String = e.text;
			switch(which){
				case 'geo':
					CONFIG::god {
					navigateToURL(new URLRequest(model.flashVarModel.root_url+'god/world_hub_map.php?id='+current_hub_id), URLUtil.getTarget('loc'));
				}
			}
		}
		
		override public function end(release:Boolean):void {
			if (release && !transitioning) {
				transitioning = true;
				var self:HubMapDialog = this;
				var pt:Point = new Point(model.layoutModel.loc_vp_w-120, 50);
				pt.x += model.layoutModel.gutter_w;
				pt.y += model.layoutModel.header_h;
				
				//stop listening to move changes
				TransitManager.instance.removeEventListener(TSEvent.CHANGED, onTransitStatus);
				
				//play a sound
				if(parent) SoundMaster.instance.playSound('CLOSE_HUB_MAP');
				
				TSTweener.removeTweens(self);
				TSTweener.addTween(self, {y:pt.y, x:pt.x, scaleX:.02, scaleY:.02, time:.3, transition:'easeOutCubic', onComplete:function():void{
					self.end(true);
					self.scaleX = self.scaleY = 1;
					self.transitioning = false;
					if (displayed_map_hub) {
						displayed_map_hub.visible = false;
						displayed_map_hub = null;
					}
					
					if (displayed_map_transit) {
						displayed_map_transit.visible = false;
						displayed_map_transit = null;
					}
					
					//reset some stuff
					if(world_map_mc) world_map_mc.visible = false;
					showing_world_map = false;
					showing_transit_map = false;
					
					//close the search thing
					closeResults();
					
					//clean out the holder
					SpriteUtil.clean(all_maps_container);
					
					//maybe open the chat map
					if(_open_map_chat_when_closed){
						RightSideManager.instance.right_view.setChatMapTab(MapChatArea.TAB_MAP);
						_open_map_chat_when_closed = false;
					}
				}});
			} else {
				super.end(release);
				
				//close the search thing
				closeResults();
			}
		}
		
		private function closeResults():void {
			if(location_search){
				location_search.show();
				location_search.blurInput();
			}
		}
		
		public function onEnterFrame(ms_elapsed:int):void {
			updateYou();
		}
		
		private function updateYou():void {
			if (!parent) return;
			if (!is_built) buildBase();
			if (!you_view_holder) return;
			if (!current_street) return;
			
			//place it where it needs to go
			placeYouMarker(you_view_holder);
			
			//update the path on the street
			if(model.stateModel.current_path){
				const map_hub:MapHub = map_hubsD[current_hub_id];
				if(map_hub) map_hub.updateLocPath();
			}
		}
		
		public function placeYouMarker(you_holder:Sprite):void {
			use namespace client;
			const loc:Location = model.worldModel.location;
			if (loc.mapInfo && loc.mapInfo.showStreet && loc.mapInfo.showStreet != loc.tsid) { // we are in a street not represented on the map
				you_holder.y = -14;
				you_holder.x = Math.round(loc.mapInfo.showPos*current_street.scaled_distance) - (current_street.scaled_distance/2);
			} 
			else {
				you_holder.y = -6;
				
				//check for vertical streets
				if(current_street.rotation >= 90 - STREET_ROTATION_BUFFER && current_street.rotation <= 90 + STREET_ROTATION_BUFFER && loc.h > loc.w){
					//probably a vertical street
					//we want the bottom of the level to be the right most X
					you_holder.x = Math.round(((model.worldModel.pc.y-loc.b)/loc.h)*current_street.scaled_distance) + (current_street.scaled_distance/2);
				}
				else {
					you_holder.x = Math.round(((model.worldModel.pc.x-loc.l)/loc.w)*current_street.scaled_distance) - (current_street.scaled_distance/2);
				}
			}
			
			//update the path on the street
			if(model.stateModel.current_path){
				model.stateModel.current_path.you_pt.x = you_holder.x;
				model.stateModel.current_path.you_pt.y = you_holder.y;
			}
		}
		
		public function updateMapHubIfWeClickedOnIt(hub_id:String, flash_loc:Boolean=false):void {
			if (hub_click_hub_id == hub_id) {
				updateMapHub(hub_id, flash_loc)
			}
		}
		
		public function updateMapIfShowingHub(hub_id:String):void {
			if (current_hub_id == hub_id) {
				updateMapHub(hub_id)
			}
		}
		
		private function changeTitle(str:String):void {
			loc_name_tf.htmlText = '<p class="hub_map">'+str+'<p>';
			loc_name_tf.x = int((_w-loc_name_tf.width)/2);
			loc_name_tf.y = 10 + int((header_h-10-loc_name_tf.height)/2);
		}
		
		private function updateMapHub(hub_id:String, flash_loc:Boolean = false):void {			
			//Console.warn('updateMap '+hub_id);
			
			current_hub_id = hub_id;
			current_location_id = model.worldModel.location.tsid;
			
			if (displayed_map_hub) {
				TSTweener.addTween(displayed_map_hub, {alpha:0, time:.5, delay:0, transition:'linear'});
			}
			
			var map_hub:MapHub = map_hubsD[current_hub_id];
			if (!map_hub) {
				map_hub = map_hubsD[current_hub_id] = new MapHub(current_hub_id, you_view_holder);
				map_hub.addEventListener(TSEvent.COMPLETE, newMapHubReady);
			}
			map_hub.visible = false;
			if(showing_transit_map){
				all_maps_container.addChildAt(map_hub, displayed_map_transit ? Math.max(0, all_maps_container.getChildIndex(displayed_map_transit)-1) : 0);
			}
			else {
				all_maps_container.addChild(map_hub);
			}
			map_hub.build(hub_click_location_id, flash_loc); // will fire TSEvent.COMPLETE when done loading, and call newMapHubReady
		}
		
		private function doneTransitionFromWorldToHub():void {
			if (showing_world_map) {
				simpleHideWorldMap();
				showing_world_map = false;
			}
			
			if (displayed_map_hub) displayed_map_hub.unHideAllButGraphics();
		}
		
		private function newMapHubReady(e:TSEvent):void {
			// ignore this if not on stage http://bugs.tinyspeck.com/5945
			if (!parent) return;
			
			var map_hub:MapHub = map_hubsD[current_hub_id];
			map_hub.visible = true;
			
			var animation_delay:Number = .3; //how much time to wait before animating search street/you
			
			if (current_hub_id){
				var hub:Hub = model.worldModel.getHubByTsid(current_hub_id);
				if(hub && !showing_transit_map){
					changeTitle(hub.label);
				}
			}
			
			//if we are showing the transit map, and there is a region, kill the region since you won't see the animation anyways
			if(showing_transit_map) world_map_clicked_region = null;
			if(load_blocker.parent) load_blocker.parent.removeChild(load_blocker);
			
			if (world_map_clicked_region) { // this is from a click in the worldmap
				//Console.warn(1);
				//Console.info(getQualifiedClassName(e.data)+' '+e.data.name);
				
				var pt:Point = world_map_clicked_region.localToGlobal(new Point());
				// ideally we would measure these better, but that involves digging down the display list of world_map_clicked_region
				const mw:int = 135;
				const mh:int = 85;
				pt.x-= 10;
				pt = map_hub.parent.globalToLocal(pt);
				
				map_hub.x = pt.x;
				map_hub.y = pt.y;
				map_hub.width = mw;
				map_hub.height = mh;
				map_hub.alpha = 0;
				
				
				map_hub.hideAllButGraphics();
				
				TSTweener.addTween(map_hub, {alpha:1, time:.3, delay:0, transition:'linear'});
				TSTweener.addTween(map_hub, {x:0, y:0, time:.5, delay:.3, transition:'easeOutCubic'});
				TSTweener.addTween(map_hub, {width:MAP_ACTUAL_W, height:MAP_ACTUAL_H, time:.5, delay:.3, transition:'easeOutCubic', onComplete:doneTransitionFromWorldToHub});
				
				world_map_clicked_region = null;
				
				animation_delay += .8; //time + delay
				
			} else { // this is not from a world map click
				//Console.warn(getQualifiedClassName(e.data)+' '+e.data.name);
				//Console.error(2);
				
				if (displayed_map_hub && transition_direction) {
					map_hub.alpha = 1;
					
					switch (transition_direction) {
						case 'right':
							map_hub.x = MAP_W;
							map_hub.y = 0;
							break;
						case 'bottom':
							map_hub.x = 0;
							map_hub.y = MAP_H;
							break;
						case 'left':
							map_hub.x = -MAP_W;
							map_hub.y = 0;
							break;
						case 'top':
							map_hub.x = 0;
							map_hub.y = -MAP_H;
							break;
						default:
							CONFIG::debugging {
							Console.error('wtf');
						}
							break;
					}
					
					TSTweener.addTween(displayed_map_hub, {time:.2, delay:0, transition:'linear'});
					TSTweener.addTween(map_hub, {x:0, y:0, time:.3, delay:.3, transition:'linear'});
					
					animation_delay += .6; //time + delay
					
				} else {
					map_hub.x = 0;
					map_hub.y = 0;
					TSTweener.addTween(map_hub, {alpha:1, time:.3, delay:0, transition:'linear'});
				}
				
				showing_world_map = false;
				if(world_map_mc) world_map_mc.visible = false;
			}
						
			//if we need to flash a street, take care of that here
			if(!hub_click_hub_id || (map_hub.name == hub_click_hub_id)){
				map_hub.animateSearchOrYou(animation_delay);
			}
			
			displayed_map_hub = map_hub;
			transition_direction = '';
			
			//refresh the nav
			refreshNavButtons();
		}
		
		private function updateMapTransit(transit_tsid:String, animate:Boolean = false):void {
			var transit:Transit = model.worldModel.getTransitByTsid(transit_tsid);
			var transit_line:TransitLine;
			
			changeTitle(transit.name);
			
			showing_transit_map = true;
			current_transit_tsid = transit_tsid;
			
			var map_transit:MapTransit = map_transitsD[current_transit_tsid];
			if (!map_transit) {
				map_transit = map_transitsD[current_transit_tsid] = new MapTransit(current_transit_tsid, transit_you_view_holder);
				map_transit.addEventListener(TSEvent.COMPLETE, newMapTransitRdy);
			}
			//are we going to animate this?
			animate_transit_map = animate;
			
			map_transit.visible = false;
			all_maps_container.addChild(map_transit);
			//if(animate_transit_map) all_maps_container.addChild(load_blocker);
			
			//let's see if we are already riding a line, and show that line by default
			if(TransitManager.instance.current_location_tsid){
				transit_line = transit.getLineByCurrentAndNext(TransitManager.instance.current_location_tsid, TransitManager.instance.next_location_tsid);
			}

			map_transit.build(transit_line); // will fire TSEvent.COMPLETE when done loading, and call newMapTransitRdy
		}
		
		private function newMapTransitRdy(event:TSEvent):void {
			if(cancel_transit_display){
				cancel_transit_display = false;
				return;
			}
			var map_transit:MapTransit = map_transitsD[current_transit_tsid];
			map_transit.visible = true;
			
			//remove the load blocker
			if(all_maps_container.contains(load_blocker)) all_maps_container.removeChild(load_blocker);
			
			//if this is a new map, animate it in
			if(displayed_map_transit != map_transit){
				displayed_map_transit = map_transit;
				displayed_map_transit.y = -MAP_H;
			}
			
			//animate this bad boy
			if(displayed_map_transit.y < 0 && animate_transit_map){
				TSTweener.removeTweens(displayed_map_transit);
				TSTweener.addTween(displayed_map_transit, {y:0, time:.5, transition:'easeOutQuad',
					onComplete:function():void {
						//if we have a hub map
						if(displayed_map_hub && displayed_map_hub.parent && !showing_world_map){
							all_maps_container.setChildIndex(displayed_map_hub, Math.max(0, all_maps_container.getChildIndex(displayed_map_transit)-1));
							displayed_map_hub.visible = true;
						}
						//simpleHideWorldMap();
					}
				});
			}
			else {
				displayed_map_transit.y = 0;
			}
			
			//make sure we have the right title again!
			if(current_transit_tsid){
				var transit:Transit = model.worldModel.getTransitByTsid(current_transit_tsid);
				if(transit){
					changeTitle(transit.name);
				}
			}
		}
		
		override public function start():void {
			use namespace client;
			if (!model.worldModel.location.show_hubmap) {
				return;
			}
			const animate_in:Boolean = parent == null;
			if (!canStart(false)) return;
			
			if(!is_built) buildBase();
			
			//model.stateModel.loc_pathA[0] = model.worldModel.location.tsid;
			const hub:Hub = model.worldModel.getHubByTsid(model.worldModel.location.hub_id);
			
			if (!hub) {
				model.activityModel.growl_message = 'there is no hub for the current location!'
				end(true);
				return;
			}
			
			if (!hub.map_data){
				CONFIG::debugging {
					Console.warn('there is no map_data for this hub!!!');
				}
				end(true);
				return;
			}
			
			loadWorldMapIfNeeded(hub.map_data.world_map);
			buildWorldMapButtons();
			buildTransitButtons();
			
			//reset the current transit ID
			current_transit_tsid = null;
			showing_transit_map = false;
			
			//reset the old hub ID stuff
			hub_click_hub_id = null;
			hub_click_location_id = null;
			hub_click_flash_loc = false;
			
			//is our current location on a transit map?!
			var transit_tsid:String = model.worldModel.getTransitTsidByLocationTsid(model.worldModel.location.tsid);
			
			//no? how about the parent street
			if(!transit_tsid && model.worldModel.location.mapInfo && model.worldModel.location.mapInfo.showStreet){
				transit_tsid = model.worldModel.getTransitTsidByLocationTsid(model.worldModel.location.mapInfo.showStreet);
			}
			
			//maybe we are already on the transit line!
			if(!transit_tsid){
				transit_tsid = TransitManager.instance.current_transit_tsid;
			}
			
			//if we are on the transit, update the map based on where we are, otherwise go normal
			if(TransitManager.instance.current_status){
				showing_transit_map = true;
				current_transit_tsid = TransitManager.instance.current_transit_tsid;
				onTransitStatus();
			}
			
			//build out the transit map
			if(transit_tsid && !start_with_world_map){
				updateMapTransit(transit_tsid);
			}
			
			//show the hub map if we are not on the transit system
			if(!TransitManager.instance.current_status && !model.worldModel.location.is_pol && !start_with_world_map){
				updateMapHub(hub.tsid);
			}
			
			//if we are in POL land, open the world map
			if(!model.worldModel.location.no_world_map && (model.worldModel.location.is_pol || start_with_world_map)){
				if(!showing_world_map) onWorldMapBtClick();
				recenter_bt.disabled = !start_with_world_map || model.worldModel.location.is_pol;
			}
			
			refreshNavButtons();
			
			//listen for transit updates
			TransitManager.instance.addEventListener(TSEvent.CHANGED, onTransitStatus, false, 0, true);
			
			super.start();
			tweenOpen(animate_in);
			
			//play a sound
			if(parent && animate_in) SoundMaster.instance.playSound('OPEN_HUB_MAP');
		}

		public function startWithTransitTsid(tsid:String):void {			
			var transit:Transit = model.worldModel.getTransitByTsid(tsid);
			if(transit){
				start();
				if(parent) updateMapTransit(transit.tsid);
			}
			else {
				CONFIG::debugging {
					Console.warn('Could not find transit system with tsid: '+tsid);
				}
				end(true);
			}
		}
		
		public function startWithWorldMap():void {
			start_with_world_map = true;
			start();
			start_with_world_map = false;
		}
		
		public function refreshNavButtons():void {
			const loc:Location = model.worldModel.location;
			
			//are we allowed to see the buttons?
			if(loc.no_world_map){
				world_map_in_bt.visible = false;
				world_map_out_bt.visible = false;
			}
			else if(world_map_mc && world_map_mc.visible){
				world_map_in_bt.visible = false;
				world_map_out_bt.visible = true;
			}
			else {
				world_map_in_bt.visible = true;
				world_map_out_bt.visible = false;
			}
			
			//no hubs in pols!
			//world_map_in_bt.disabled = loc.is_pol;
			world_map_out_bt.disabled = loc.is_pol;
						
			transit_bt.visible = !loc.no_world_map;
			
			// no map search on Gentle Island
			const hub:Hub = model.worldModel.getHubByTsid(loc.hub_id);
			location_search.visible = (hub.label != 'Gentle Island');
		}
		
		public function showError(txt:String):void {
			if(!parent) return;
			
			//allows the dialog to show an error toast
			if(!toast){
				toast = new Toast(_w - _base_padd*2);
				toast.x = _base_padd;
				toast.y = _h - _border_w;
			}
			
			toast.show(txt, 5);
			addChild(toast);
		}
		
		private function buildWorldMapButtons():void {
			
			if (world_map_in_bt) {
				return;
			}

			world_map_in_bt = new Button({
				name: 'world_map_in',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				graphic: new AssetManager.instance.assets.world_map_zoomin_link(),
				graphic_disabled: new AssetManager.instance.assets.world_map_zoomin_disabled(),
				graphic_hover: new AssetManager.instance.assets.world_map_zoomin_hover(),
				graphic_padd_w: 7,
				graphic_padd_t: 5,
				x: recenter_bt.x + recenter_bt.width + TRANSIT_PADD,
				y: _base_padd+10,
				w: 41,
				h: 27,
				tip: {
					txt: 'World Map',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER	
				}
			});
			world_map_in_bt.addEventListener(TSEvent.CHANGED, onWorldMapBtClick, false, 0, true);
			world_map_in_bt.visible = false;
			
			addChild(world_map_in_bt);
			
			world_map_out_bt = new Button({
				name: 'world_map_out',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				graphic: new AssetManager.instance.assets.world_map_link(),
				graphic_disabled: new AssetManager.instance.assets.world_map_disabled(),
				graphic_hover: new AssetManager.instance.assets.world_map_hover(),
				graphic_padd_w: 7,
				graphic_padd_t: 5,
				x: recenter_bt.x + recenter_bt.width + TRANSIT_PADD,
				y: _base_padd+10,
				w: 41,
				h: 27,
				tip: {
					txt: 'World Map',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER	
				}
			});
			world_map_out_bt.addEventListener(TSEvent.CHANGED, onWorldMapBtClick, false, 0, true);
			
			addChild(world_map_out_bt);
			
			//make sure the next button is in the right place
			next_transit_bt_x = world_map_out_bt.x + world_map_out_bt.width + TRANSIT_PADD;
		}
		
		private function buildTransitButtons():void {
			var i:int;
			var transit:Transit;
			
			for(i; i < model.worldModel.transits.length; i++){
				transit = model.worldModel.transits[int(i)];
				
				//do we have the button already?
				if(!getChildByName(transit.tsid+'_bt')){
					transit_bt = new Button({
						name: transit.tsid+'_bt',
						value: transit.tsid,
						size: Button.SIZE_TINY,
						type: Button.TYPE_MINOR,
						graphic: new AssetManager.instance.assets['transit_'+transit.tsid](),
						graphic_hover: new AssetManager.instance.assets['transit_'+transit.tsid+'_hover'](),
						graphic_padd_w: 11,
						x: next_transit_bt_x,
						y: recenter_bt.y,
						w: 36,
						h: 27,
						tip: { txt:transit.name, pointer:WindowBorder.POINTER_BOTTOM_CENTER }
					});
					transit_bt.addEventListener(TSEvent.CHANGED, onTransitButtonClick, false, 0, true);
					addChild(transit_bt);
					
					next_transit_bt_x += transit_bt.width + TRANSIT_PADD;
				}
			}
		}
		
		private function onTransitButtonClick(event:TSEvent=null):void {
			if(transit_bt.disabled) return;
			
			//if we are already looking at this map, go ahead and hide it
			if (displayed_map_transit && displayed_map_transit.name == transit_bt.value && displayed_map_transit.visible){
				TSTweener.removeTweens(displayed_map_transit);
				TSTweener.addTween(displayed_map_transit, {y:-MAP_H, time:.5, transition:'easeInQuad', onComplete:hideTransitMap});
				showing_transit_map = false;
				
				if(!current_hub_id || model.worldModel.location.is_pol){
					//toggle the buttons so it doesn't bung up the loading if someone clicks it
					showing_world_map = true;
					if(world_map_mc) {
						world_map_mc.visible = true;
						if(!world_map_mc.parent) all_maps_container.addChildAt(world_map_mc,0);
						if(displayed_map_hub && displayed_map_hub.parent) displayed_map_hub.parent.removeChild(displayed_map_hub);
					}
				}
			} else {
				cancel_transit_display = false;
				//showing_world_map = false;
				updateMapTransit(transit_bt.value, true);
			}
			
			//update the nav buttons
			refreshNavButtons();
		}
		
		private function onTransitStatus(event:TSEvent = null):void {
			//looks like we have the map open and we are going for a little ride!
			if(current_transit_tsid){
				var transit:Transit = model.worldModel.getTransitByTsid(current_transit_tsid);
				if(!transit){
					CONFIG::debugging {
						Console.warn('No transit with TSID: '+current_transit_tsid);
					}
					return;
				}
				var transit_status:TransitStatus = TransitManager.instance.current_status;
				var transit_line:TransitLine = transit.getLineByCurrentAndNext(transit_status.current_tsid, transit_status.next_tsid);
				var loc:Location;
				
				//move the star to where it needs to go
				if(transit_line){
					if(displayed_map_transit) displayed_map_transit.setPlayerLocation(transit_line, transit_status.current_tsid);
					
					if(!transit_status.is_moving || !displayed_map_transit){
						loc = model.worldModel.getLocationByTsid(transit_line.getLocationByTsid(transit_status.current_tsid).station_tsid);
						if(loc){
							hub_click_hub_id = loc.hub_id;
							hub_click_location_id = transit_line.getLocationByTsid(transit_status.current_tsid).station_tsid;
							hub_click_flash_loc = true;
							
							//load the proper hub map when we stop
							if(hub_click_hub_id){
								//if we are showing the world map, then get the hub region so it can animate in
								if(world_map_mc && world_map_mc.visible){
									world_map_clicked_region = world_map_mc.getRegion(hub_click_hub_id);
								}
								
								//fetch!
								is_map_loading = true;
								TSFrontController.instance.genericSend(new NetOutgoingMapGetVO(hub_click_hub_id), onMapData, onMapData);
							}
						}
					}
				}
			}			
		}
		
		private function onWorldMapBtClick(event:TSEvent = null):void {
			if (!world_map_mc) {
				//try again real fast
				StageBeacon.waitForNextFrame(onWorldMapBtClick, event);
				return;
			}
			
			//if the button is disabled, don't do anything
			const bt:Button = event ? event.data as Button : null;
			if(bt) SoundMaster.instance.playSound(!bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(bt && bt.disabled) return;
			
			if (displayed_map_transit && displayed_map_transit.visible && showing_transit_map) {
				onTransitButtonClick();
			}
			
			var region_mc:MovieClip;
			if(current_hub_id){
				region_mc = world_map_mc.getRegion(current_hub_id);
			}
			
			if (world_map_mc.visible) { // then hide world map!
				if (region_mc) {
					// if there is a region for this hub, act like we clicked on the region on the map
					worldMapClickHandler(region_mc);
				} else if (displayed_map_transit && displayed_map_transit.visible){
					//no region? maybe we are riding the subway or some other form of transit
					onTransitButtonClick();
				} else {
					simpleHideWorldMap();
				}
				
			} else { // then show world map!				
				// some hubs do not have regions in the map, like uralia caverns stuff, I think, so check first
				if (region_mc && displayed_map_hub) {
					all_maps_container.addChild(world_map_mc);
					all_maps_container.addChild(displayed_map_hub);
					
					var pt:Point = region_mc.localToGlobal(new Point());
					pt = displayed_map_hub.parent.globalToLocal(pt);
					displayed_map_hub.alpha = 1;
					
					displayed_map_hub.hideAllButGraphics();
					
					// scale the displayed_map_hub down to the region
					TSTweener.addTween(displayed_map_hub, {alpha:0, time:.3, delay:.5, transition:'linear', onComplete:doneTransitionFromHubToWorld});
					TSTweener.addTween(displayed_map_hub, {x:pt.x+30, y:pt.y+20, time:.6, delay:0, transition:'easeOutCubic'});
					TSTweener.addTween(displayed_map_hub, {width:10, height:10, time:.6, delay:0, transition:'easeOutCubic'});
					
					world_map_clicked_region = null;
				} else {
					// just show it
					all_maps_container.addChild(world_map_mc);
				}
				
				changeTitle('World Map');
				showing_world_map = true;
				world_map_mc.visible = true;
				current_hub_id = model.worldModel.location.hub_id;
			}
			
			//toggle the buttons we can see
			refreshNavButtons();
		}
		
		private function onMapData(nrm:NetResponseMessageVO):void {
			recenter_bt.disabled = model.worldModel.location.is_pol;
			is_map_loading = false;
			
			if (nrm.success) { 
				if (nrm.payload.mapData) {
					//if we've got an "all" hash make sure to update the world
					if(nrm.payload.mapData.all){
						Hub.updateFromMapDataAll(nrm.payload.mapData);
					}
					
					//if we've got a "transit" hash make sure to update the world
					if(nrm.payload.mapData.transit){
						Transit.updateFromMapDataTransit(nrm.payload.mapData);
					}
					
					var hub:Hub = model.worldModel.hubs[NetOutgoingMapGetVO(nrm.request).hub_id];
					if (!hub) {
						CONFIG::debugging {
							Console.error('IMPOSSIBLE!');
						}
						return;
					}
					
					//add/update the map data
					if(!hub.map_data){
						hub.map_data = MapData.fromAnonymous(nrm.payload.mapData);
					}
					else {
						hub.map_data = MapData.updateFromAnonymous(nrm.payload.mapData, hub.map_data);
					}
					updateMapHubIfWeClickedOnIt(hub.tsid, hub_click_flash_loc);
					loadWorldMapIfNeeded(hub.map_data.world_map);
				} else {
					SoundMaster.instance.playSound('CLICK_FAILURE');
					CONFIG::debugging {
						Console.error('nrm.payload.mapData missing')
					}
				}
			} else {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				; // satisfy compiler
				CONFIG::debugging {
					Console.error(nrm)
				}
			}
		}
		
		private function simpleHideWorldMap():void {
			if (!world_map_mc) return;
			world_map_mc.visible = false;
			showing_world_map = false;
			
			const hub_id:String = displayed_map_hub ? displayed_map_hub.name : current_hub_id;
			const hub:Hub = model.worldModel.getHubByTsid(hub_id);
			
			if(hub && !showing_transit_map){
				changeTitle(hub.label);
				
				if(displayed_map_hub){
					if(displayed_map_hub != map_hubsD[hub_id]){
						//let's load it back up
						updateMapIfShowingHub(hub_id);
					}
					else if(!displayed_map_hub.visible){
						displayed_map_hub.visible = true;
					}
				}
			}
			
			refreshNavButtons();
		}
		
		private function doneTransitionFromHubToWorld():void {
			all_maps_container.addChild(world_map_mc);
			if (displayed_map_hub) {
				displayed_map_hub.x = 0;
				displayed_map_hub.y = 0;
				displayed_map_hub.width = MAP_ACTUAL_W;
				displayed_map_hub.height = MAP_ACTUAL_H;
				displayed_map_hub.alpha = 1;
				displayed_map_hub.unHideAllButGraphics();
				displayed_map_hub.visible = false;
			}
		}
		
		private function onRecenterClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!recenter_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if (recenter_bt.disabled) return;
			
			//reset any search flashing or search we may have done
			hub_click_hub_id = null;
			hub_click_location_id = null;
			hub_click_flash_loc = false;
			
			//hide the transit map if it's showing
			if(displayed_map_transit && displayed_map_transit.visible){
				TSTweener.removeTweens(displayed_map_transit);
				TSTweener.addTween(displayed_map_transit, {y:-MAP_H, time:.5, transition:'easeInQuad', onComplete:hideTransitMap});
				showing_transit_map = false;
				//return;
			}
			
			var region_mc:MovieClip;
			var loc:Location;
			
			//if we are riding the transit system, make sure the hub id is the right one
			if(TransitManager.instance.current_status){
				var transit:Transit = model.worldModel.getTransitByTsid(current_transit_tsid);
				var transit_status:TransitStatus = TransitManager.instance.current_status;
				if(transit){
					var transit_line:TransitLine = transit.getLineByCurrentAndNext(transit_status.current_tsid, transit_status.next_tsid);
					loc = model.worldModel.getLocationByTsid(transit_line.getLocationByTsid(transit_status.current_tsid).station_tsid);
					
					if(loc) region_mc = world_map_mc.getRegion(loc.hub_id);
				}
			}
			
			//set the location to where we are RIGHT NOW
			if(!loc) loc = model.worldModel.location;
			
			//if we are showing the world map, do pretty things
			if (showing_world_map) {
				region_mc = world_map_mc.getRegion(loc.hub_id);
				
				if (region_mc) {
					// if there is a region for this hub, act like we clicked on the region on the map
					worldMapClickHandler(region_mc)
					return;
				}
			}
			
			//otherwise go back to the hub we are at
			if (!displayed_map_hub || model.worldModel.location.hub_id != displayed_map_hub.name) {
				goToHubFromClick(loc.hub_id, loc.tsid);
			}
		}
		
		private function hideTransitMap():void {
			if(displayed_map_transit) displayed_map_transit.visible = false;
			showing_transit_map = false;
			
			if (showing_world_map) {
				changeTitle('World Map');
			} else {
				var hub:Hub;
				//make sure to put back the title
				if(displayed_map_hub){
					hub = model.worldModel.getHubByTsid(displayed_map_hub.name);
				}
				else if(current_hub_id){
					hub = model.worldModel.getHubByTsid(current_hub_id);
				}
				
				if(hub){
					changeTitle(hub.label);
				}
			}
		}
		
		private function tweenOpen(animate:Boolean = true):void {
			var self:HubMapDialog = this;
			TSTweener.removeTweens(self);
			
			if(animate){
				transitioning = true;
				scaleX = scaleY = .02;
				x = model.layoutModel.loc_vp_w - 120 + model.layoutModel.gutter_w;
				y = model.layoutModel.header_h + 50;
				
				TSTweener.addTween(self, {y:dest_y, x:dest_x, scaleX:1, scaleY:1, time:.3, transition:'easeInCubic', onComplete:function():void{
					self.transitioning = false;
					self._place();
				}});
			}
			else {
				scaleX = scaleY = 1;
				self.transitioning = false;
				self._place();
			}
		}
		
		public function set open_map_chat_when_closed(value:Boolean):void {
			_open_map_chat_when_closed = value;
		}
	}
}
