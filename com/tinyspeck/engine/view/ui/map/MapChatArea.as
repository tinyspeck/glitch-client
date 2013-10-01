package com.tinyspeck.engine.view.ui.map
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.house.PlayerSignpost;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.map.MapData;
	import com.tinyspeck.engine.data.map.Street;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.transit.Transit;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingMapGetVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.RightSideView;
	import com.tinyspeck.engine.port.TeleportationDialog;
	import com.tinyspeck.engine.port.TransitManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.gameoverlay.maps.MapHub;
	import com.tinyspeck.engine.view.gameoverlay.maps.MapStreet;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.chat.ChatDropdown;
	import com.tinyspeck.engine.view.ui.chat.ContactElement;
	import com.tinyspeck.engine.view.ui.chat.ContactList;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.Dictionary;

	public class MapChatArea extends Sprite
	{
		public static const TAB_MAP:String = 'Map';
		public static const TAB_TELEPORT:String = 'Teleport';
		public static const TAB_NOTHING:String = 'nothing'; //used when close is pressed
		public static const MIN_HEIGHT:uint = 148;
		public static const HUB_BLACKLIST:Array = ['66']; //hubs you NEVER want to see a map on 66 = Seam Streets
		
		public static var center_star:Boolean = true;
		
		private static const MAX_HEIGHT:uint = 200;
		private static const MAX_TITLE_LENGTH:uint = 23;
		private static const TOP_PADD:uint = 31;
		private static const BOTTOM_PADD:uint = 18;
		private static const DRAW_PADD:uint = 17;
		
		private var model:TSModelLocator;
		private var close_bt:Button;
		private var teleportation_dialog:TeleportationDialog;
		private var current_street:MapStreet;
		private var dropdown:MapChatDropdown = new MapChatDropdown();
		private var player_signpost:PlayerSignpost;
		
		private var hub_maps:Dictionary = new Dictionary();
		private var transit_maps:Dictionary = new Dictionary();
		
		private var main_holder:Sprite = new Sprite();
		private var map_holder:Sprite = new Sprite();
		private var map_loader:Sprite = new Sprite();
		private var map_mask:Sprite = new Sprite();
		private var title_holder:Sprite = new Sprite();
		private var title_drop_holder:Sprite = new Sprite();
		private var contact_bg:Sprite = new Sprite();
		private var tab_bg:Sprite = new Sprite();
		private var tab_holder:Sprite = new Sprite();
		private var tab_mask:Sprite = new Sprite();
		private var resizer:Sprite = new Sprite();
		private var you_view_holder:Sprite = new Sprite();
		
		private var you_pt:Point = new Point();
		private var you_global_pt:Point = new Point();
		private var map_pt:Point = new Point();
		private var map_global_pt:Point = new Point();
		
		private var title_tf:TextField = new TextField();
		
		private var drag_rect:Rectangle = new Rectangle();
		private var street_bounds:Rectangle = new Rectangle();
		
		private var drop_shadow:DropShadowFilter = new DropShadowFilter();
		private var drop_shadowA:Array = [drop_shadow];
		
		private var spinner:DisplayObject;
		
		private var current_tab:String;
		private var current_hub_tsid:String;
		
		private var h:int;
		private var map_h:int; //just something to remember the height when swapping to teleportation
		private var place_x:int;
		private var place_y:int;
		
		private var is_built:Boolean;
		private var is_visible:Boolean = true;
		private var map_hidden:Boolean;
		
		public function MapChatArea(){}
		
		private function buildBase():void {
			model = TSModelLocator.instance;
			
			const draw_w:int = RightSideView.MIN_WIDTH_CLOSED;
			var g:Graphics;
			
			//drop shadow (doing this here because teleport changes it)
			drop_shadow.distance = 4;
			drop_shadow.angle = 90;
			drop_shadow.quality = 2;
			drop_shadow.inner = false;
			drop_shadow.knockout = true;
			drop_shadow.blurX = 0;
			
			main_holder.addChild(map_holder);
			
			map_loader.mask = map_mask;
			map_holder.addChild(map_loader);
			map_holder.addChild(map_mask);
			
			//title
			const radius:Number = model.layoutModel.loc_vp_elipse_radius;
			TFUtil.prepTF(title_tf);
			title_tf.x = ChatDropdown.BT_WIDTH + 11;
			title_tf.y = 3;
			title_tf.width = draw_w - title_tf.x*2;
			title_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.4, angle:270}, StaticFilters.white1px90Degrees_DropShadowA);
			title_holder.addChild(title_tf);
			
			g = title_drop_holder.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(0, 0, draw_w, TOP_PADD, radius, radius, 0, 0);
			main_holder.addChild(title_drop_holder);
			
			g = title_holder.graphics;
			g.beginFill(0xffffff, .5);
			g.drawRoundRectComplex(0, 0, draw_w, TOP_PADD, radius, radius, 0, 0);
			main_holder.addChild(title_holder);
			
			title_holder.mouseChildren = false;
			title_holder.doubleClickEnabled = true;
			title_holder.addEventListener(MouseEvent.DOUBLE_CLICK, onTitleDoubleClick, false, 0, true);
			
			const divider:DisplayObject = new AssetManager.instance.assets.chat_divider();
			divider.x = int(draw_w/2 - divider.width/2);
			divider.y = 4;
			divider.alpha = .7;
			resizer.addChild(divider);
			resizer.addEventListener(MouseEvent.MOUSE_DOWN, onResizeStart, false, 0, true);
			g = resizer.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, draw_w, divider.height + divider.y*2);
			main_holder.addChild(resizer);
			
			//set the drag bounds
			drag_rect.y = MIN_HEIGHT - resizer.height - 2;
			drag_rect.height = MAX_HEIGHT - drag_rect.y - BOTTOM_PADD - 2;
			
			//set the height from LS if it's there
			if(LocalStorage.instance.getUserData(LocalStorage.MAP_Y) != undefined){
				h = LocalStorage.instance.getUserData(LocalStorage.MAP_Y);
			}
			else {
				h = drag_rect.y + resizer.height + 2;
			}
			map_h = h;
			
			main_holder.filters = StaticFilters.chat_right_shadowA;
			
			contact_bg.filters = StaticFilters.chat_left_shadow_innerA;
			addChild(contact_bg);
			
			tab_holder.mask = tab_mask;
			tab_bg.addChild(tab_holder);
			tab_bg.addChild(tab_mask);
			addChild(tab_bg);
			
			const close_DO:DisplayObject = new AssetManager.instance.assets.chat_close();
			close_bt = new Button({
				name: 'toggle',
				graphic: close_DO,
				draw_alpha: 0,
				w: close_DO.width + 4,
				h: close_DO.height + 4,
				y: 8
			});
			close_bt.x = int(draw_w - close_bt.width - 11);
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			main_holder.addChild(close_bt);
			
			//load the spinner
			spinner = new AssetManager.instance.assets.spinner();
			spinner.x = int(draw_w/2 - spinner.width/2);
			
			//build the thing that shows where you are
			HubMapDialog.instance.buildYouView(you_view_holder);
			
			//teleportation dialog
			teleportation_dialog = TeleportationDialog.instance;
			
			//build out each of the tabs
			buildTabs();
			
			//set the current selected tab
			if(LocalStorage.instance.getUserData(LocalStorage.LAST_MAP_TAB)){
				setCurrentTab(LocalStorage.instance.getUserData(LocalStorage.LAST_MAP_TAB));
			}
			else {
				current_tab = TAB_NOTHING;
			}
			
			//what mode did we save as?
			if(LocalStorage.instance.getUserData(LocalStorage.MAP_CENTERED)){
				center_star = LocalStorage.instance.getUserData(LocalStorage.MAP_CENTERED);
			}
			
			//did we have to hide the map?
			if(LocalStorage.instance.getUserData(LocalStorage.MAP_HIDDEN)){
				map_hidden = LocalStorage.instance.getUserData(LocalStorage.MAP_HIDDEN);
			}
			
			//dropdown
			dropdown.x = 9;
			dropdown.y = int(TOP_PADD/2 - ChatDropdown.BT_HEIGHT/2);
			dropdown.init('map_chat');
			main_holder.addChild(dropdown);
			
			//if this was closed before the reload, toggle it closed
			if(!map_hidden && current_tab == TAB_NOTHING){
				onCloseClick();
			}
			else {
				//was hidden before the reload, so hide it again
				hideHubMap();
			}
			
			is_built = true;
		}
		
		private function buildTabs():void {
			const tab_labels:Array = [TAB_MAP, TAB_TELEPORT];
			const total:int = tab_labels.length;
			const x_offset:int = 3;
			const gap:uint = 3;
			var next_y:int = 12;
			var i:int;
			var element:ContactElement;
			var label:String;
			
			for(i; i < total; i++){
				label = tab_labels[int(i)];
				element = new ContactElement(ContactElement.TYPE_ACTIVE, label);
				element.x = x_offset;
				element.y = next_y;
				element.w = ContactList.MAX_WIDTH - x_offset + 1;
				element.addEventListener(TSEvent.CHANGED, onElementClick, false, 0, true);
				
				//set it to lowercase to load in the icon images
				label = label.toLowerCase();
				
				//build the icons
				element.setIcon(new AssetManager.instance.assets['contact_'+label](), false, false);
				element.setIcon(new AssetManager.instance.assets['contact_'+label](), false, true);
				element.setIcon(new AssetManager.instance.assets['contact_'+label+'_hover'](), true, false);
				element.setIcon(new AssetManager.instance.assets['contact_'+label+'_hover'](), true, true);
				
				element.enabled = i == 0;
				next_y += element.height + gap;
				tab_holder.addChild(element);
			}
		}
		
		public function show():void {
			if(!is_built) buildBase();
			
			//if we are force hiding, let's set it to the map and see if we can see it yet
			if(map_hidden) {
				if(current_tab == TAB_NOTHING) {
					current_tab = TAB_MAP;
					is_visible = true;
				}
				map_hidden = false;
			}
			
			//update the dropdown
			dropdown.refreshMenu();
			
			//toggle the displaying of the tabs
			setTabVisibility();
			
			//show what we need to show
			showTab();
		}
		
		public function setCurrentTab(tab_name:String, from_click:Boolean = false):void {
			//same tab? bail out
			if(tab_name == current_tab) return;
			
			//map tab, make sure we can
			if(tab_name == TAB_MAP){
				if(!canClickMapTab()){
					//trying to click the map tab when we are forced to hide it
					if(from_click) SoundMaster.instance.playSound('CLICK_FAILURE');
					if(!map_hidden) {
						current_tab = TAB_MAP;
						hideHubMap();
					}
					return;
				}
				else {
					//no longer hidden
					map_hidden = false;
					LocalStorage.instance.setUserData(LocalStorage.MAP_HIDDEN, map_hidden);
				}
			}
			else if(tab_name == TAB_TELEPORT){
				const pc:PC = model.worldModel.pc;
				const loc:Location = model.worldModel.location;
				if(pc && pc.teleportation && pc.teleportation.skill_level > 0){
					//clean it out real quick
					SpriteUtil.clean(map_loader, false);
				}
				else if(loc && !loc.no_imagination){
					//show the teleportation skill
					TSFrontController.instance.showSkillInfo('teleportation_1');
					tab_name = TAB_NOTHING;
					return;
				}
				else {
					//can't do anything
					SoundMaster.instance.playSound('CLICK_FAILURE');
					return;
				}
			}
			else if(tab_name == TAB_NOTHING){
				//close it
				onCloseClick();
				return;
			}
			
			//reset
			is_visible = true;
			current_tab = tab_name;
			
			//toggle the displaying of the tabs
			setTabVisibility();
			
			//figure out what we are doing
			showTab(from_click);
			
			if(from_click) SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function setTabVisibility():void {
			const loc:Location = model.worldModel.location;
			const pc:PC = model.worldModel.pc;
			
			//handle the map
			var map_visible:Boolean;
			var element:ContactElement = tab_holder.getChildByName(TAB_MAP) as ContactElement;
			if(element){
				//figure out if our hub is legit
				const hub:Hub = loc && !loc.is_pol && loc.hub_id ? model.worldModel.getHubByTsid(loc.hub_id) : null;
				
				element.tip_text = (canClickMapTab() && canViewHub(hub ? hub.tsid : '')) ? 'Map' : 'Regional map not available here';
				element.visible = loc && !loc.no_current_location && (loc.show_worldmap || !loc.no_hubmap || loc.show_map);
				map_visible = element.visible;
			}
			
			//handle teleportation
			element = tab_holder.getChildByName(TAB_TELEPORT) as ContactElement;
			if(element){
				element.visible = pc && pc.teleportation && pc.teleportation.skill_level > 0 && map_visible;
			}
		}
		
		public function refresh():void {
			if(!is_built) return;
			
			const contact_list_w:int = RightSideManager.instance.right_view.contact_list_w;
			const radius:Number = model.layoutModel.loc_vp_elipse_radius;
			const draw_w:int = RightSideView.MIN_WIDTH_CLOSED;
			const is_showing_teleport:Boolean = current_tab == TAB_TELEPORT;
			const can_see:Boolean = (is_visible && !map_hidden) || is_showing_teleport;
			var draw_h:int = can_see ? Math.max(h, MIN_HEIGHT) : 0;
			var map_draw_h:int = draw_h-(!is_showing_teleport ? -2 : TOP_PADD+BOTTOM_PADD);
			var divider_y:int =  map_draw_h + (is_showing_teleport ? TOP_PADD : 0);
			if(!can_see) divider_y = TOP_PADD;
			
			resizer.y = draw_h - resizer.height - 2;
			
			//adjust the draw height if we are showing teleport or not
			draw_h += (is_showing_teleport ? -DRAW_PADD : 0); //visual tweak
			
			//take down the h if we are invisible
			if(!can_see){
				h = 0;
				resizer.y = 0;
				map_draw_h = 0;
			}
			
			var g:Graphics = main_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(0, 0, draw_w, draw_h, radius, radius, 0, 0);
			g.beginFill(0xc8d6dc);
			g.drawRect(0, divider_y, draw_w, 1);
			main_holder.x = contact_list_w;
			
			g = contact_bg.graphics;
			g.clear();
			g.beginFill(model.layoutModel.bg_color);
			g.drawRect(0, 0, contact_list_w, tab_height);
			g.moveTo(contact_list_w, 0);
			g.lineTo(contact_list_w + radius-1, 0);
			g.curveTo(contact_list_w, 0 + (radius-1)/2, contact_list_w, 0 + radius-1);
			g.lineTo(contact_list_w, 0);
			
			g = map_holder.graphics;
			g.clear();
			g.beginFill(!is_showing_teleport ? 0xffffff : 0xecf0f1);
			g.drawRoundRectComplex(0, 0, draw_w, map_draw_h, radius, radius, 0, 0);
			
			g = map_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRectComplex(0, 0, draw_w, map_draw_h, radius, radius, 0, 0);
			
			g = tab_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, contact_list_w, tab_height);
			
			//set our map points for recentering
			map_pt.x = draw_w/2;
			map_pt.y = map_draw_h/2;
			
			//place the spinner
			spinner.y = int(map_draw_h/2 - spinner.height/2 + TOP_PADD/2);
			
			//refresh the tabs
			const total:int = tab_holder.numChildren;
			var i:int;
			for(i; i < total; i++){
				(tab_holder.getChildAt(i) as ContactElement).refresh();
			}
		}
		
		public function updateYouOnMap():void {
			if(!is_built || model.moveModel.moving || !current_hub_tsid || current_tab == TAB_TELEPORT || map_hidden) return;
			
			const map_hub:MapHub = hub_maps[current_hub_tsid];
			const current_street:Street = HubMapDialog.instance.current_street;
			if(!current_street) return;
			
			//places the star on the map here
			HubMapDialog.instance.placeYouMarker(you_view_holder);
			
			//make sure our little marker is the center of attention
			recenterMap();
			
			//update the path on the street
			if(map_hub) map_hub.updateLocPath();
		}
		
		private function showTab(from_click:Boolean = false):void {
			//make sure things get cleaned up
			current_street = null;
			if(spinner && spinner.parent) spinner.parent.removeChild(spinner);
			
			//default fitler params
			drop_shadow.alpha = .45;
			drop_shadow.blurY = 6;
			
			//decide what we need to see
			const can_see:Boolean = (is_visible && !map_hidden) || current_tab == TAB_TELEPORT;
			resizer.visible = can_see;
			
			if(can_see && !main_holder.parent){
				addChild(main_holder);
			}
			else if(!can_see && main_holder.parent){
				main_holder.parent.removeChild(main_holder);
			}
			
			//set the height
			h = can_see ? Math.max(map_h, MIN_HEIGHT) : 0;
			
			switch(current_tab){
				case TAB_MAP:
					showHubMap();
					break;
				case TAB_TELEPORT:
					showTeleport();
					break;
			}
			
			//light up the right one
			const total:int = tab_holder.numChildren;
			var i:int;
			var element:ContactElement;
			
			for(i; i < total; i++){
				element = tab_holder.getChildAt(i) as ContactElement;
				element.enabled = current_tab == element.name;
			}
			
			//apply the filter
			title_drop_holder.filters = can_see ? drop_shadowA : null;
			
			//save it to local
			LocalStorage.instance.setUserData(LocalStorage.LAST_MAP_TAB, current_tab);
			
			//refresh
			RightSideManager.instance.right_view.refresh(from_click);
		}
		
		private function showHubMap():void {
			const loc:Location = model.worldModel.location;
			const hub:Hub = loc && !loc.is_pol && loc.hub_id ? model.worldModel.getHubByTsid(loc.hub_id) : null;
			
			setTitle(hub ? StringUtil.truncate(hub.label, MAX_TITLE_LENGTH) : 'Imagination Space');
			
			//clean out the loader if this is a different hub
			if(!hub || current_hub_tsid != hub.tsid){
				SpriteUtil.clean(map_loader, false);
			}
						
			current_hub_tsid = hub ? hub.tsid : null;
			map_holder.y = 0;
						
			if(hub){
				if(canClickMapTab() && canViewHub()){
					//for now, let's not even load a new map if we've already built it
					const map_hub:MapHub = hub_maps[hub.tsid];
					if(!map_hub){
						//show the spinner
						map_holder.addChild(spinner);
						
						TSFrontController.instance.genericSend(new NetOutgoingMapGetVO(hub.tsid, loc.tsid), onMapData, onMapData);
					}
					else {
						loadHubMap(hub.tsid);
					}
				}
				else {
					//we have a valid hub, but it must be hidden/instanced/whatever
					hideHubMap();
				}
			}
			else {
				//currently if we are iMG space, we are hiding the map
				hideHubMap();
				
				/** this is for the next version/when the design is done
				//go ask the server for signpost info on where we are				
				if(model.moveModel.loading_info.owner_tsid){
					TSFrontController.instance.genericSend(
						new NetOutgoingHousesSignpostVO(model.moveModel.loading_info.owner_tsid), onSignpostLoad, onSignpostLoad
					);
				}
				**/
			}
		}
		
		private function hideHubMap():void {
			//this is used when we NEED to hide it, not when the user hits close (no map available)
			map_hidden = true;
			
			//save it in a SO for reloading fun times
			LocalStorage.instance.setUserData(LocalStorage.MAP_HIDDEN, map_hidden);
			
			//deselect the current tab
			if(current_tab == TAB_MAP) {
				current_tab = TAB_NOTHING;
				showTab();
			}
		}
		
		private function onSignpostLoad(nrm:NetResponseMessageVO):void {
			if(nrm.success && 'tsid' in nrm.payload){
				player_signpost = PlayerSignpost.fromAnonymous(nrm.payload, nrm.payload.tsid);
				drawPlayerSignpost();
			}
			else {
				//ruh roh
				CONFIG::debugging {
					Console.warn('We tried to get signpost data, but it didn\'t work...');
				}
			}
		}
		
		private function drawPlayerSignpost():void {
			if(!player_signpost) return;
			
			//draw the ui to handle the deep linking fun times
			const total:int = player_signpost.signposts.length;
			var i:int;
			var j:int;
			var connects:Array;
			var pc:PC;
			
			for(i = 0; i < total; i++){
				connects = player_signpost.signposts[i];
				for(j = 0; j < connects.length; j++){
					pc = model.worldModel.getPCByTsid(connects[j]);
					if(pc){
						//this is where we do magic things once the design is done
					}
				}
			}
		}
		
		private function showTeleport():void {
			SpriteUtil.clean(map_loader, false);
			teleportation_dialog.visible = true;
			map_loader.addChild(teleportation_dialog);
			map_loader.x = 5;
			map_loader.y = 5;
			
			resizer.visible = false;
			h = MAX_HEIGHT + BOTTOM_PADD - 3;
			map_holder.y = TOP_PADD;
			
			//apply the filter
			drop_shadow.alpha = .2;
			drop_shadow.blurY = 5;
			
			setTitle('Teleport');
		}
		
		private function recenterMap():void {
			if(!current_street || !is_visible || map_hidden) return;
			
			you_global_pt = you_view_holder.localToGlobal(you_pt);
			map_global_pt = map_holder.localToGlobal(map_pt);
			
			if(!center_star){
				//move the map when the star is about to go offscreen
				const edge_buffer:uint = 15;
				const draw_w:int = RightSideView.MIN_WIDTH_CLOSED;
				const draw_h:int = Math.max(h, MIN_HEIGHT)-TOP_PADD-BOTTOM_PADD;
				const min_x:int = map_global_pt.x - draw_w/2 + edge_buffer;
				const max_x:int = map_global_pt.x + draw_w/2 - edge_buffer;
				const min_y:int = map_global_pt.y - draw_h/2 + edge_buffer;
				const max_y:int = map_global_pt.y + draw_h/2 - edge_buffer;
				
				//if we've gone too far, let's move this sucker over
				if(you_global_pt.x < min_x || you_global_pt.x > max_x || you_global_pt.y < min_y || you_global_pt.y > max_y){
					if(!TSTweener.isTweening(map_loader)) centerYou(true);
				}
			}
			else {
				centerYou(false);
			}
		}
		
		private function centerYou(animate:Boolean):void {
			//Place star in the center
			//set the x position
			place_x = map_loader.x + (map_global_pt.x - you_global_pt.x);
			place_x = Math.max(Math.min(0, place_x), -(map_loader.width - map_mask.width));
			
			//set the y position
			place_y = map_loader.y + (map_global_pt.y - you_global_pt.y);
			place_y = Math.max(Math.min(0, place_y), -(map_loader.height - map_mask.height));
			
			if(!animate){
				map_loader.x = place_x;
				map_loader.y = place_y;
			}
			else {
				//tween it
				TSTweener.addTween(map_loader, {x:place_x, y:place_y, time:.3});
			}
		}
		
		private function setTitle(txt:String):void {
			title_tf.htmlText = '<p class="chat_area_title">'+txt+'</p>';
		}
		
		private function canClickMapTab():Boolean {
			const loc:Location = model.worldModel.location;
			if(!loc) return false;
			
			//make sure we aren't at home
			const hub:Hub = !loc.is_pol && loc.hub_id ? model.worldModel.getHubByTsid(loc.hub_id) : null;
			
			//no hub map allowed
			if(!loc.show_hubmap) return false;
			
			//no map info? kind of need that for a map
			if(!loc.mapInfo) return false;
			
			//if we are on a transit line, close'r up
			var transit_tsid:String = model.worldModel.getTransitTsidByLocationTsid(model.worldModel.location.tsid);
			
			//no? how about the parent street
			if(!transit_tsid && loc.mapInfo && loc.mapInfo.showStreet){
				transit_tsid = model.worldModel.getTransitTsidByLocationTsid(loc.mapInfo.showStreet);
			}
			
			//maybe we are already on the transit line!
			if(!transit_tsid){
				transit_tsid = TransitManager.instance.current_transit_tsid;
			}
			
			//we are doing some sort of transit thing...
			if(transit_tsid) return false;
			
			//if we've got a hub with data
			return (hub && hub.map_data);
		}
		
		private function canViewHub(check_id:String = ''):Boolean {
			if(!current_hub_tsid && !check_id) return false;
			
			//set our check_id
			if(current_hub_tsid && !check_id) check_id = current_hub_tsid;
			
			//loop through each of the blacklisted ids, if we find a match, return false
			const total:uint = HUB_BLACKLIST.length;
			var i:int;
			for(i; i < total; i++){
				if(check_id == HUB_BLACKLIST[int(i)]) return false;
			}
			
			return true;
		}
		
		private function onMapData(nrm:NetResponseMessageVO):void {
			if (nrm.success && nrm.payload.mapData) { 
				//if we've got an "all" hash make sure to update the world
				if(nrm.payload.mapData.all){
					Hub.updateFromMapDataAll(nrm.payload.mapData);
				}
				
				//if we've got a "transit" hash make sure to update the world
				if(nrm.payload.mapData.transit){
					Transit.updateFromMapDataTransit(nrm.payload.mapData);
				}
				
				const hub:Hub = model.worldModel.getHubByTsid(NetOutgoingMapGetVO(nrm.request).hub_id);
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
				loadHubMap(hub.tsid);
			} 
			else {
				CONFIG::debugging {
					Console.error(nrm);
				}
			}
		}
		
		private function loadHubMap(hub_tsid:String):void {			
			var map_hub:MapHub = hub_maps[hub_tsid];
			if (!map_hub) {
				map_hub = hub_maps[hub_tsid] = new MapHub(hub_tsid, you_view_holder);
				map_hub.addEventListener(TSEvent.COMPLETE, onMapLoaded, false, 0, true);
			}
			map_hub.visible = current_hub_tsid == hub_tsid;
			map_hub.build('', false, false);
			
			current_hub_tsid = hub_tsid;
		}
		
		private function onMapLoaded(event:TSEvent):void {			
			if(spinner && spinner.parent) spinner.parent.removeChild(spinner);
			
			//last ditch effort to get any race conditions
			if(!canClickMapTab() && current_tab == TAB_MAP){
				hideHubMap();
				return;
			}
			
			const map_hub:MapHub = hub_maps[current_hub_tsid];
			map_hub.visible = true;
			map_loader.addChild(map_hub);
			
			current_street = map_hub.getYourStreet();
			if(current_street){
				street_bounds = current_street.getBounds(current_street);
			}
			
			//update the path on the street
			if(model.stateModel.current_path && map_hub){				
				map_hub.updateLocPath();
			}
			
			//place it where it needs to go
			recenterMap();
		}
		
		private function onResizeStart(event:MouseEvent):void {			
			StageBeacon.mouse_move_sig.add(onResizeMove);
			StageBeacon.mouse_up_sig.add(onResizeEnd);
			
			resizer.startDrag(false, drag_rect);
		}
		
		private function onResizeMove(e:MouseEvent):void {
			h = resizer.y + resizer.height + 2;
			map_h = h;
			RightSideManager.instance.right_view.refresh();
		}
		
		private function onResizeEnd(e:MouseEvent):void {
			StageBeacon.mouse_move_sig.remove(onResizeMove);
			StageBeacon.mouse_up_sig.remove(onResizeEnd);
			resizer.stopDrag();
			
			//record it one last time
			onResizeMove(e);
			
			//save the Y value for next refresh
			LocalStorage.instance.setUserData(LocalStorage.MAP_Y, h);
		}
		
		private function onElementClick(event:TSEvent):void {
			const clicked_element:ContactElement = event.data as ContactElement;
			
			//special case for clicking the map tab, but it's in an area that isn't allowed to be clicked
			if(clicked_element.name == TAB_MAP && !canClickMapTab()){
				const loc:Location = model.worldModel.location;
				if(loc && !loc.no_world_map){
					if(!HubMapDialog.instance.parent){
						HubMapDialog.instance.startWithWorldMap();
						
						//if we couldn't open up the dialog, we must not be allowed!
						if(!HubMapDialog.instance.parent) SoundMaster.instance.playSound('CLICK_FAILURE');
					}
					else {
						HubMapDialog.instance.end(true);
					}
					return;
				}
			}
			
			//set the current tab
			setCurrentTab(clicked_element.name, true);			
		}
		
		private function onCloseClick(event:TSEvent = null):void {
			is_visible = false;
			
			//deselect the current tab
			current_tab = TAB_NOTHING;
			showTab();
			
			//save the Y value for next refresh
			LocalStorage.instance.setUserData(LocalStorage.MAP_Y, h);
			
			//no longer hidden
			map_hidden = false;
			LocalStorage.instance.setUserData(LocalStorage.MAP_HIDDEN, map_hidden);
			
			if(event) SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function onTitleDoubleClick(event:MouseEvent):void {
			//open the hub map if we can
			if(canClickMapTab() && canViewHub()){
				if(!HubMapDialog.instance.parent){
					HubMapDialog.instance.start();
				}
				else {
					//close'r up
					HubMapDialog.instance.end(true);
				}
			}
		}
		
		override public function get height():Number {
			if(!is_built) return 0;
			if(current_tab == TAB_NOTHING) return 0;
			
			const extra_padd:int = current_tab == TAB_TELEPORT ? -DRAW_PADD : 3;
			return h + extra_padd;
		}
		
		override public function set height(value:Number):void {
			h = Math.min(MAX_HEIGHT, value);
			RightSideManager.instance.right_view.refresh();
		}
		
		override public function get width():Number {
			return RightSideView.MIN_WIDTH_CLOSED;
		}
		
		public function get tab_height():Number {
			const padd:uint = 3;
			const total:uint = tab_holder.numChildren;
			var next_y:int;
			var i:int;
			var element:ContactElement;
			
			for(i = total-1; i >= 0; i--){
				element = tab_holder.getChildAt(i) as ContactElement;
				if(element.visible) {
					next_y = element.y + element.height;
					break;
				}
			}
			
			return next_y ? next_y + padd : 0;
		}
		
		public function get tab_name():String { return current_tab; }
	}
}